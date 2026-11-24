'use strict';
const { compactText } = require('./notification-logic');

// Deadline reminders for opportunities users saved in the app
// (users/{uid}/savedOpportunities). Pure helpers; index.js does the I/O.

const REMINDER_DAYS = [7, 1];
const SECTIONS = ['olympiads', 'volunteering', 'exchange'];
const TIME_ZONE = 'Asia/Tbilisi';

const dayFormat = new Intl.DateTimeFormat('en-CA', {
  timeZone: TIME_ZONE, year: 'numeric', month: '2-digit', day: '2-digit',
});

/** Calendar day in Tbilisi as YYYY-MM-DD. */
function tbilisiDay(date) {
  return dayFormat.format(date);
}

/** Whole days from one YYYY-MM-DD to another. */
function daysBetween(fromDay, toDay) {
  return Math.round((Date.parse(toDay) - Date.parse(fromDay)) / 86400000);
}

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === 'string') {
    const parsed = Date.parse(value.trim());
    return Number.isFinite(parsed) ? new Date(parsed) : null;
  }
  return null;
}

/** Same fields the app reads for deadlines (home_feed.dart _deadline). */
function deadlineOf(data) {
  return toDate(data?.deadline) || toDate(data?.registrationDeadline);
}

/** Same fields the app reads for titles (home_feed.dart _title). */
function titleOf(data) {
  for (const key of ['fullTitle', 'fullName', 'title']) {
    const value = compactText(data?.[key], 80);
    if (value) return value;
  }
  return '';
}

/** Days left (7 or 1) when today should send a reminder, else null. */
function reminderDaysFor(data, now) {
  const deadline = deadlineOf(data);
  if (!deadline) return null;
  const days = daysBetween(tbilisiDay(now), tbilisiDay(deadline));
  return REMINDER_DAYS.includes(days) ? days : null;
}

function reminderMessage(section, id, title, days, lang) {
  const ka = lang === 'ka';
  const name = title || (ka ? 'შენახული შესაძლებლობა' : 'A saved opportunity');
  const body = ka
    ? (days === 1 ? 'იხურება ხვალ. არ დააგვიანოთ!' : `იხურება ${days} დღეში.`)
    : (days === 1 ? "Closes tomorrow. Don't miss it!" : `Closes in ${days} days.`);
  const tag = `reminder_${section}_${id}`;
  return {
    notification: { title: name, body },
    // Opened by openAppNotification in notifications_screen.dart.
    data: { type: 'opportunity', section, targetId: id },
    android: { priority: 'high', notification: { tag, sound: 'default' } },
    apns: { payload: { aps: { sound: 'default' } } },
    webpush: { notification: { tag, renotify: false } },
  };
}

module.exports = { REMINDER_DAYS, SECTIONS, tbilisiDay, daysBetween, deadlineOf,
  titleOf, reminderDaysFor, reminderMessage };
