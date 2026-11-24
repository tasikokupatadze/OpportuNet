'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { tbilisiDay, daysBetween, reminderDaysFor, titleOf, reminderMessage } =
  require('./reminder-logic');

// 2026-11-24 10:00 in Tbilisi (UTC+4).
const now = new Date('2026-11-24T06:00:00Z');

test('uses the Tbilisi calendar day, not UTC', () => {
  // 21:30 UTC on the 24th is already the 25th in Tbilisi.
  assert.strictEqual(tbilisiDay(new Date('2026-11-24T21:30:00Z')), '2026-11-25');
  assert.strictEqual(daysBetween('2026-11-24', '2026-12-01'), 7);
});

test('reminds exactly 7 and 1 days before', () => {
  // The app stores a picked date as local midnight: 20:00 UTC the day before.
  const at = (day) => ({ deadline: { toDate: () => new Date(`${day}T20:00:00Z`) } });
  assert.strictEqual(reminderDaysFor(at('2026-11-30'), now), 7); // Dec 1 in Tbilisi
  assert.strictEqual(reminderDaysFor(at('2026-11-24'), now), 1); // Nov 25
  assert.strictEqual(reminderDaysFor(at('2026-11-25'), now), null); // 2 days
  assert.strictEqual(reminderDaysFor({ deadline: '2026-12-01' }, now), 7);
  assert.strictEqual(reminderDaysFor({ registrationDeadline: '2026-11-25' }, now), 1);
  assert.strictEqual(reminderDaysFor({}, now), null);
  assert.strictEqual(reminderDaysFor({ deadline: 'next week' }, now), null);
});

test('builds a reminder the app can open', () => {
  assert.strictEqual(titleOf({ title: '  BTU   Camp ' }), 'BTU Camp');
  const msg = reminderMessage('exchange', 'abc', 'BTU Camp', 1, 'ka');
  assert.deepStrictEqual(msg.data, { type: 'opportunity', section: 'exchange', targetId: 'abc' });
  assert.strictEqual(msg.notification.body, 'იხურება ხვალ. არ დააგვიანოთ!');
  assert.strictEqual(reminderMessage('olympiads', 'x', '', 7, 'en').notification.body,
    'Closes in 7 days.');
});
