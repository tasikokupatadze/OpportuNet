'use strict';
const { randomUUID } = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, FieldPath, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineString } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { sourceNotification, stableNotificationId, isAlreadyExists, messageFor,
  deviceCandidate, invalidRegistration, leaseState, groupByLang } = require('./notification-logic');

initializeApp();
const db = getFirestore();
const APP_URL = defineString('APP_URL', { default: '',
  description: 'HTTPS URL of the hosted Flutter web app. Optional; enables web click routing.' });
const region = 'europe-west1';

async function createNotification(type, snapshot) {
  if (!snapshot) return;
  const notification = sourceNotification(type, snapshot.id, snapshot.data());
  if (!notification) {
    logger.warn('Skipped notification: source has no valid author or type.', { type });
    return;
  }
  const id = stableNotificationId(type, snapshot.id);
  try {
    // Firestore create is atomic. Retried source events cannot create duplicates.
    await db.collection('notifications').doc(id).create({
      ...notification,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    if (!isAlreadyExists(error)) throw error;
  }
}

exports.notifyNewPost = onDocumentCreated({
  document: 'posts/{postId}', region, retry: true,
}, (event) => createNotification('post', event.data));

exports.notifyNewCalendarEvent = onDocumentCreated({
  document: 'calendarEvents/{eventId}', region, retry: true,
}, (event) => createNotification('calendar', event.data));

async function removeInvalidDevice(ref, expectedToken) {
  // A concurrent token refresh must not be removed by an older send result.
  await db.runTransaction(async (transaction) => {
    const current = await transaction.get(ref);
    if (current.exists && current.get('token') === expectedToken) transaction.delete(ref);
  });
}

exports.deliverNotificationPush = onDocumentCreated({
  document: 'notifications/{notificationId}', region,
  retry: true, timeoutSeconds: 540, memory: '256MiB', maxInstances: 4,
}, async (event) => {
  if (!event.data) return;
  const id = event.params.notificationId;
  const notification = event.data.data();
  // Validates the payload and APP_URL before taking the delivery lease.
  messageFor(id, notification, APP_URL.value());
  const stateRef = db.collection('_notificationDelivery').doc(id);
  const owner = randomUUID();
  const now = Date.now();
  const state = await db.runTransaction(async (transaction) => {
    const current = await transaction.get(stateRef);
    const data = current.data() || {};
    const status = leaseState(data, now);
    if (status === 'done') return null;
    if (status === 'busy') throw new Error('Delivery is already running; retry later.');
    transaction.set(stateRef, {
      owner,
      leaseUntil: Timestamp.fromMillis(now + 10 * 60 * 1000),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { cursor: typeof data.cursor === 'string' ? data.cursor : null };
  });
  if (!state) return;

  try {
    let cursor = state.cursor;
    let complete = false;
    while (Date.now() - now < 8 * 60 * 1000) {
      let query = db.collectionGroup('notificationDevices')
        .orderBy(FieldPath.documentId()).limit(500);
      if (cursor) query = query.startAfter(db.doc(cursor));
      const page = await query.get();
      if (page.empty) {
        complete = true;
        break;
      }
      const unique = new Map();
      for (const doc of page.docs) {
        const candidate = deviceCandidate(doc.ref.path, doc.data(), notification.actorId);
        if (candidate) {
          const entry = unique.get(candidate.token);
          if (entry) entry.refs.push(doc.ref);
          else unique.set(candidate.token, { ...candidate, refs: [doc.ref] });
        }
      }
      // One send per language: Georgian devices get the Georgian texts.
      for (const [lang, candidates] of groupByLang([...unique.values()])) {
        const result = await getMessaging().sendEachForMulticast({
          ...messageFor(id, notification, APP_URL.value(), lang),
          tokens: candidates.map((device) => device.token),
        });
        const cleanup = [];
        let retryNeeded = false;
        for (let i = 0; i < result.responses.length; i++) {
          const response = result.responses[i];
          if (response.success) continue;
          const code = response.error?.code;
          if (invalidRegistration(code)) {
            for (const ref of candidates[i].refs) {
              cleanup.push(removeInvalidDevice(ref, candidates[i].token));
            }
          } else {
            // Never log FCM tokens or the full error payload.
            logger.warn('Push send failed; this page will be retried.', { code: code || 'unknown' });
            retryNeeded = true;
          }
        }
        await Promise.all(cleanup);
        if (retryNeeded) throw new Error('Some push sends failed; retry this page.');
      }
      cursor = page.docs[page.docs.length - 1].ref.path;
      await stateRef.set({ cursor, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      if (page.size < 500) {
        complete = true;
        break;
      }
    }
    if (!complete) throw new Error('Delivery paused at its time budget; continue from checkpoint.');
    await stateRef.set({ done: true, completedAt: FieldValue.serverTimestamp(),
      leaseUntil: Timestamp.fromMillis(0), owner: FieldValue.delete() }, { merge: true });
  } catch (error) {
    await db.runTransaction(async (transaction) => {
      const current = await transaction.get(stateRef);
      if (current.get('owner') === owner) {
        transaction.set(stateRef, { leaseUntil: Timestamp.fromMillis(0),
          owner: FieldValue.delete() }, { merge: true });
      }
    });
    throw error;
  }
});

// ---------------------------------------------------------------------------
// Deadline reminders for saved opportunities.
// Every day at 10:00 Tbilisi time, users get a push 7 days and 1 day before
// the deadline of each opportunity they saved in the app. Push-only: these are
// personal, while the notifications collection is readable by every user.
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { SECTIONS, reminderDaysFor, titleOf, reminderMessage } = require('./reminder-logic');

async function sendReminder(uid, item, lang) {
  const devices = await db.collection('users').doc(uid)
    .collection('notificationDevices').get();
  const byToken = new Map();
  for (const device of devices.docs) {
    const token = device.get('token');
    if (typeof token === 'string' && token.trim()) byToken.set(token, device.ref);
  }
  // No devices means alerts are off for this user.
  if (!byToken.size) return 0;
  const tokens = [...byToken.keys()];
  const result = await getMessaging().sendEachForMulticast({
    ...reminderMessage(item.section, item.id, item.title, item.days, lang), tokens,
  });
  await Promise.all(result.responses.map((response, i) =>
    !response.success && invalidRegistration(response.error?.code)
      ? removeInvalidDevice(byToken.get(tokens[i]), tokens[i]) : null));
  return result.successCount;
}

exports.sendDeadlineReminders = onSchedule({
  schedule: 'every day 10:00', timeZone: 'Asia/Tbilisi', region,
  timeoutSeconds: 540, memory: '256MiB', retryCount: 1,
}, async () => {
  const now = new Date();
  // Opportunities whose deadline is exactly 7 or 1 days away, by "section/id".
  const due = new Map();
  for (const section of SECTIONS) {
    const snap = await db.collection(section).get();
    for (const doc of snap.docs) {
      const days = reminderDaysFor(doc.data(), now);
      if (days) {
        due.set(`${section}/${doc.id}`,
          { section, id: doc.id, days, title: titleOf(doc.data()) });
      }
    }
  }
  if (!due.size) return;

  // shortcut: reads every saved item once a day, fine for a few thousand
  // saves. Beyond that, add a collection-group index on `key` and query it.
  let reminders = 0;
  let pushes = 0;
  let cursor = null;
  for (;;) {
    let query = db.collectionGroup('savedOpportunities')
      .orderBy(FieldPath.documentId()).limit(500);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    for (const saved of page.docs) {
      const item = due.get(saved.get('key'));
      const userRef = saved.ref.parent.parent;
      if (!item || !userRef || userRef.parent.id !== 'users') continue;
      if (saved.get('lastReminderDays') === item.days) continue;
      pushes += await sendReminder(userRef.id, item, saved.get('lang'));
      reminders++;
      try {
        // Recorded after sending so a retried run skips it.
        await saved.ref.update({ lastReminderDays: item.days });
      } catch (error) {
        // The user unsaved it meanwhile; nothing to record.
        if (error?.code !== 5 && error?.code !== 'not-found') throw error;
      }
    }
    if (page.size < 500) break;
    cursor = page.docs[page.docs.length - 1];
  }
  logger.info('Deadline reminders sent.', { due: due.size, reminders, pushes });
});
