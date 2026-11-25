'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { sourceNotification, messageFor, deviceCandidate, groupByLang } =
  require('./notification-logic');

test('posts get Georgian push texts on Georgian devices', () => {
  const post = sourceNotification('post', 'p1', { userId: 'u1', username: ' Nino ' });
  assert.strictEqual(post.actorName, 'Nino');
  assert.deepStrictEqual(messageFor('post_p1', post, '', 'ka').notification,
    { title: 'ახალი პოსტი საზოგადოებაში', body: 'ავტორი: Nino' });
  assert.deepStrictEqual(messageFor('post_p1', post).notification,
    { title: 'New community post', body: 'Nino shared a new post.' });
});

test('calendar events keep their own title in Georgian', () => {
  const event = sourceNotification('calendar', 'e1', { createdBy: 'u1', title: 'Exam week' });
  assert.strictEqual(messageFor('calendar_e1', event, '', 'ka').notification.body, 'Exam week');
  const untitled = sourceNotification('calendar', 'e2', { createdBy: 'u1' });
  assert.strictEqual(messageFor('calendar_e2', untitled, '', 'ka').notification.body,
    'კალენდარს ახალი მოვლენა დაემატა.');
});

test('devices without a language get English', () => {
  const ka = deviceCandidate('users/a/notificationDevices/1', { token: 't1', lang: 'ka' }, 'x');
  const old = deviceCandidate('users/b/notificationDevices/2', { token: 't2' }, 'x');
  const odd = deviceCandidate('users/c/notificationDevices/3', { token: 't3', lang: 'fr' }, 'x');
  const groups = groupByLang([ka, old, odd]);
  assert.deepStrictEqual(groups.get('ka').map((d) => d.token), ['t1']);
  assert.deepStrictEqual(groups.get('en').map((d) => d.token), ['t2', 't3']);
});
