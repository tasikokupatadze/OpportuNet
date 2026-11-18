'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const vm = require('node:vm');
const source = readFileSync(join(__dirname, '../web/firebase-messaging-sw.js'), 'utf8');

function runWorker(windows = []) {
  const callbacks = {};
  const calls = [];
  const self = {
    location: { origin: 'https://opportunet.example' },
    addEventListener(name, callback) { callbacks[name] = callback; calls.push('listener'); },
    clients: {
      async matchAll() { return windows; },
      async openWindow(url) { calls.push(['open', url]); },
    },
  };
  vm.runInNewContext(source, {
    self, URL,
    importScripts() { calls.push('import'); },
    firebase: { initializeApp() {}, messaging() {} },
  });
  async function click(payload) {
    let pending;
    callbacks.notificationclick({
      notification: {data: payload ? {FCM_MSG: payload} : {}, close() { calls.push('close'); }},
      stopImmediatePropagation() { calls.push('stop'); },
      waitUntil(promise) { pending = promise; },
    });
    await pending;
  }
  return { click, calls };
}

test('handler precedes Firebase and routes a cold open with data', async () => {
  const worker = runWorker();
  assert.equal(worker.calls[0], 'listener');
  await worker.click({data: {type: 'post', targetId: 'abc', notificationId: 'post_abc'}});
  assert(worker.calls.includes('stop'));
  const url = new URL(worker.calls.find(call => Array.isArray(call) && call[0] === 'open')[1]);
  assert.equal(url.origin, 'https://opportunet.example');
  assert.equal(url.searchParams.get('targetId'), 'abc');
});

test('existing tab navigates before focus, including APP_URL path', async () => {
  const actions = [];
  const worker = runWorker([{
    url: 'https://opportunet.example/app/',
    async navigate(url) { actions.push(['navigate', url]); return this; },
    async focus() { actions.push(['focus']); },
  }]);
  await worker.click({fcmOptions: {link: 'https://opportunet.example/app/'},
    data: {type: 'calendar', targetId: 'event1', eventDate: '2026-12-01'}});
  assert.equal(actions[0][0], 'navigate');
  assert.equal(new URL(actions[0][1]).pathname, '/app/');
  assert.equal(new URL(actions[0][1]).searchParams.get('eventDate'), '2026-12-01');
  assert.equal(actions[1][0], 'focus');
  assert(!worker.calls.some(call => Array.isArray(call) && call[0] === 'open'));
});

test('foreign links stay on app origin', async () => {
  const worker = runWorker();
  await worker.click({fcmOptions: {link: 'https://unrelated.example/'}, data: {type: 'post', targetId: 'x'}});
  const url = new URL(worker.calls.find(call => Array.isArray(call) && call[0] === 'open')[1]);
  assert.equal(url.origin, 'https://opportunet.example');
});

test('non-FCM notifications are left to their own handler', async () => {
  const worker = runWorker();
  await worker.click(null);
  assert(!worker.calls.includes('stop'));
  assert(!worker.calls.some(call => Array.isArray(call) && call[0] === 'open'));
});
