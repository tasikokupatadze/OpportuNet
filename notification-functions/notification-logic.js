'use strict';

function compactText(value, limit) {
  if (typeof value !== 'string') return '';
  return Array.from(value.replace(/\s+/gu, ' ').trim()).slice(0, limit).join('');
}

const CALENDAR_FALLBACK = 'A new event was added to the calendar.';

/** Language a device's pushes are sent in; English unless it says 'ka'. */
function langOf(value) {
  return value === 'ka' ? 'ka' : 'en';
}

/**
 * Push title and body in the device's language. The stored notification
 * (and the in-app feed) stays English; user text such as an event title
 * is sent as written.
 */
function pushText(notification, lang) {
  const english = { title: notification.title, body: notification.body };
  if (langOf(lang) !== 'ka') return english;
  if (notification.type === 'post') {
    const name = compactText(notification.actorName, 60);
    return {
      title: 'ახალი პოსტი საზოგადოებაში',
      body: name ? `ავტორი: ${name}` : 'საზოგადოებაში ახალი პოსტი გამოქვეყნდა.',
    };
  }
  if (notification.type === 'calendar') {
    return {
      title: 'ახალი მოვლენა აკადემიურ კალენდარში',
      body: notification.body === CALENDAR_FALLBACK || !notification.body
        ? 'კალენდარს ახალი მოვლენა დაემატა.' : notification.body,
    };
  }
  return english;
}

/** Splits send candidates into one list per language. */
function groupByLang(candidates) {
  const groups = new Map();
  for (const candidate of candidates) {
    const lang = langOf(candidate.lang);
    if (!groups.has(lang)) groups.set(lang, []);
    groups.get(lang).push(candidate);
  }
  return groups;
}

function sourceNotification(type, targetId, data) {
  if (!data || !['post', 'calendar'].includes(type) || typeof targetId !== 'string' || !targetId) {
    return null;
  }
  const actorId = type === 'post' ? data.userId : data.createdBy;
  if (typeof actorId !== 'string' || !actorId) return null;
  if (type === 'post') {
    const actorName = compactText(data.username, 60);
    const username = actorName || 'A community member';
    return {
      type, targetId, actorId, actorName,
      title: 'New community post',
      body: `${username} shared a new post.`,
      eventDate: '',
    };
  }
  return {
    type, targetId, actorId,
    title: 'New academic calendar event',
    body: compactText(data.title, 160) || CALENDAR_FALLBACK,
    eventDate: typeof data.date === 'string' && data.date.length <= 64 &&
      /^\d{4}-\d{2}-\d{2}/u.test(data.date) && Number.isFinite(Date.parse(data.date))
        ? data.date : '',
  };
}

function stableNotificationId(type, targetId) {
  if (!['post', 'calendar'].includes(type) || typeof targetId !== 'string' ||
      !targetId || targetId.includes('/')) throw new Error('Invalid notification source');
  return `${type}_${targetId}`;
}

function isAlreadyExists(error) {
  return error?.code === 6 || error?.code === 'already-exists';
}

function appLink(appUrl, data) {
  if (!appUrl || !appUrl.trim()) return undefined;
  const url = new URL(appUrl);
  if (url.protocol !== 'https:' || url.username || url.password) {
    throw new Error('APP_URL must be an HTTPS app URL without credentials.');
  }
  // Preserve an existing Flutter hash route while carrying the routing data
  // in the normal query string (available from Uri.base.queryParameters).
  for (const [name, value] of Object.entries(data)) {
    if (value) url.searchParams.set(name, value);
  }
  return url.toString();
}

function messageFor(notificationId, notification, appUrl = '', lang = 'en') {
  if (!['post', 'calendar'].includes(notification?.type) ||
      typeof notification.targetId !== 'string' || !notification.targetId) {
    throw new Error('Invalid notification payload');
  }
  const data = {
    notificationId,
    type: notification.type,
    targetId: notification.targetId,
    eventDate: typeof notification.eventDate === 'string' ? notification.eventDate : '',
  };
  const link = appLink(appUrl, data);
  const text = pushText(notification, lang);
  return {
    notification: {
      title: compactText(text.title, 120),
      body: compactText(text.body, 160),
    },
    data,
    android: {
      priority: 'high',
      notification: {
        tag: notificationId,
        sound: 'default',
      },
    },
    apns: { payload: { aps: { sound: 'default' } } },
    webpush: {
      notification: { tag: notificationId, renotify: false },
      ...(link ? { fcmOptions: { link } } : {}),
    },
  };
}

function deviceCandidate(path, data, actorId) {
  const pieces = path.split('/');
  if (pieces.length !== 4 || pieces[0] !== 'users' || pieces[2] !== 'notificationDevices' ||
      pieces[1] === actorId || typeof data?.token !== 'string' || !data.token.trim()) return null;
  return { uid: pieces[1], token: data.token, path, lang: langOf(data.lang) };
}

function invalidRegistration(code) {
  return code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/invalid-registration-token';
}

function leaseState(data, nowMillis) {
  if (data?.done === true) return 'done';
  const until = data?.leaseUntil?.toMillis?.() ?? 0;
  return until > nowMillis ? 'busy' : 'available';
}

module.exports = { compactText, sourceNotification, stableNotificationId, isAlreadyExists,
  appLink, messageFor, deviceCandidate, invalidRegistration, leaseState,
  langOf, pushText, groupByLang };
