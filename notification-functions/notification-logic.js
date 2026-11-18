'use strict';

function compactText(value, limit) {
  if (typeof value !== 'string') return '';
  return Array.from(value.replace(/\s+/gu, ' ').trim()).slice(0, limit).join('');
}

function sourceNotification(type, targetId, data) {
  if (!data || !['post', 'calendar'].includes(type) || typeof targetId !== 'string' || !targetId) {
    return null;
  }
  const actorId = type === 'post' ? data.userId : data.createdBy;
  if (typeof actorId !== 'string' || !actorId) return null;
  if (type === 'post') {
    const username = compactText(data.username, 60) || 'A community member';
    return {
      type, targetId, actorId,
      title: 'New community post',
      body: `${username} shared a new post.`,
      eventDate: '',
    };
  }
  return {
    type, targetId, actorId,
    title: 'New academic calendar event',
    body: compactText(data.title, 160) || 'A new event was added to the calendar.',
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

function messageFor(notificationId, notification, appUrl = '') {
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
  return {
    notification: {
      title: compactText(notification.title, 120),
      body: compactText(notification.body, 160),
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
  return { uid: pieces[1], token: data.token, path };
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
  appLink, messageFor, deviceCandidate, invalidRegistration, leaseState };
