'use strict';
const { randomUUID } = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, FieldPath, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineString } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { sourceNotification, stableNotificationId, isAlreadyExists, messageFor,
  deviceCandidate, invalidRegistration, leaseState } = require('./notification-logic');

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
  const baseMessage = messageFor(id, notification, APP_URL.value());
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
      const candidates = [...unique.values()];
      if (candidates.length) {
        const result = await getMessaging().sendEachForMulticast({
          ...baseMessage, tokens: candidates.map((device) => device.token),
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
