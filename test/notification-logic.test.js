'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { sourceNotification, stableNotificationId, isAlreadyExists, messageFor,
  appLink, deviceCandidate, invalidRegistration, leaseState } = require('../notification-logic');

test('post notification avoids copying full post contents into lock-screen alert', () => {
  const output = sourceNotification('post', 'p1', { userId: 'u1', username: '  Ana  K. ', text: 'private-looking content' });
  assert.deepEqual(output, { type: 'post', targetId: 'p1', actorId: 'u1',
    title: 'New community post', body: 'Ana K. shared a new post.', eventDate: '' });
});

test('calendar payload carries source date and caps long titles', () => {
  const output = sourceNotification('calendar', 'c1', { createdBy: 'u2', title: 'a'.repeat(300), date: '2026-12-01T00:00:00.000' });
  assert.equal(output.body.length, 160);
  assert.equal(output.eventDate, '2026-12-01T00:00:00.000');
  assert.equal(sourceNotification('calendar', 'c2', { createdBy: 'u2', date: 'a'.repeat(5000) }).eventDate, '');
});

test('invalid sources are skipped and stable IDs separate source collections', () => {
  assert.equal(sourceNotification('post', 'p', {}), null);
  assert.equal(sourceNotification('other', 'p', { userId: 'u' }), null);
  assert.equal(stableNotificationId('post', 'same'), 'post_same');
  assert.equal(stableNotificationId('calendar', 'same'), 'calendar_same');
  assert.throws(() => stableNotificationId('post', 'a/b'));
});

test('duplicate create events are ignored; unrelated errors propagate', () => {
  assert.equal(isAlreadyExists({ code: 6 }), true);
  assert.equal(isAlreadyExists({ code: 'already-exists' }), true);
  assert.equal(isAlreadyExists({ code: 'permission-denied' }), false);
});

test('message contains platform tags and string-only routing data', () => {
  const n = sourceNotification('post', 'p1', { userId: 'u1' });
  const msg = messageFor('post_p1', n, 'https://app.example/#/');
  assert.equal(msg.android.notification.channelId, undefined);
  assert.equal(msg.android.notification.tag, 'post_p1');
  assert.equal(msg.webpush.notification.tag, 'post_p1');
  assert.ok(Object.values(msg.data).every((value) => typeof value === 'string'));
  const link = new URL(msg.webpush.fcmOptions.link);
  assert.equal(link.searchParams.get('targetId'), 'p1');
  assert.equal(link.hash, '#/');
});

test('app URL rejects insecure targets and supports optional configuration', () => {
  assert.equal(appLink('', {}), undefined);
  assert.throws(() => appLink('http://app.example', {}));
  assert.throws(() => appLink('https://user:pass@app.example', {}));
  const msg = messageFor('post_p1', sourceNotification('post', 'p1', { userId: 'u1' }));
  assert.equal(msg.webpush.fcmOptions, undefined);
});

test('device selection excludes author and unrelated collection-group paths', () => {
  assert.equal(deviceCandidate('users/author/notificationDevices/x', { token: 't' }, 'author'), null);
  assert.equal(deviceCandidate('teams/team/notificationDevices/x', { token: 't' }, 'author'), null);
  assert.equal(deviceCandidate('users/u/notificationDevices/x', { token: '' }, 'author'), null);
  assert.equal(deviceCandidate('users/u/notificationDevices/x', { token: 't' }, 'author').uid, 'u');
});

test('only permanently invalid registrations are deleted', () => {
  assert.equal(invalidRegistration('messaging/registration-token-not-registered'), true);
  assert.equal(invalidRegistration('messaging/invalid-registration-token'), true);
  assert.equal(invalidRegistration('messaging/invalid-argument'), false);
  assert.equal(invalidRegistration('messaging/server-unavailable'), false);
});

test('completed deliveries are skipped and active leases block concurrent work', () => {
  assert.equal(leaseState({ done: true }, 100), 'done');
  assert.equal(leaseState({ leaseUntil: { toMillis: () => 200 } }, 100), 'busy');
  assert.equal(leaseState({ leaseUntil: { toMillis: () => 100 } }, 100), 'available');
  assert.equal(leaseState({}, 100), 'available');
});
