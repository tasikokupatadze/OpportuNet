/* Served at /firebase-messaging-sw.js on the same HTTPS origin as the app.
 * FCM displays notification payloads automatically in the background.
 * Do not also call showNotification: that would duplicate the alert.
 */

// Register before Firebase: FlutterFire web does not expose notification-click
// events through onMessageOpenedApp. Navigate an existing tab so the Dart app
// can read the same routing query parameters on both warm and cold opens.
self.addEventListener('notificationclick', (event) => {
  const payload = event.notification.data && event.notification.data.FCM_MSG;
  if (!payload) return;
  event.stopImmediatePropagation();
  event.notification.close();

  const data = payload.data || {};
  let destination = new URL('/', self.location.origin);
  const configuredLink = payload.fcmOptions && payload.fcmOptions.link;
  if (typeof configuredLink === 'string') {
    try {
      const candidate = new URL(configuredLink, self.location.origin);
      if (candidate.origin === self.location.origin &&
          (candidate.protocol === 'https:' || candidate.hostname === 'localhost')) {
        destination = candidate;
      }
    } catch (_) {
      // Invalid links fall back to this application's origin.
    }
  }
  for (const key of ['notificationId', 'type', 'targetId', 'eventDate']) {
    if (typeof data[key] === 'string' && data[key]) {
      destination.searchParams.set(key, data[key]);
    }
  }

  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    for (const windowClient of windows) {
      if (new URL(windowClient.url).origin !== destination.origin) continue;
      try {
        const navigated = await windowClient.navigate(destination.href);
        if (navigated) {
          await navigated.focus();
          return;
        }
      } catch (_) {
        // A tab may close during the click. Try another, then open a window.
      }
    }
    await self.clients.openWindow(destination.href);
  })());
});

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBvMBPRuIbJVianzAjo1rRKyFY8RfNaF_g',
  appId: '1:150055874798:web:2333f51bf7c785b81203ff',
  messagingSenderId: '150055874798',
  projectId: 'opportunet-bd7b8',
  authDomain: 'opportunet-bd7b8.firebaseapp.com',
  storageBucket: 'opportunet-bd7b8.firebasestorage.app',
});

firebase.messaging();
