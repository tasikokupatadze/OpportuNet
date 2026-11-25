OPPORTUNET NOTIFICATION FUNCTIONS

Creates an authenticated in-app notification record and sends opted-in phones/browsers a push when someone creates a document in posts or calendarEvents. Updates and edits do not create alerts. Existing content is not backfilled. Authors do not receive their own push. Shared records include all new activity; each user's inbox and bell filter out that user's own posts/events.

FILES
  index.js: Firestore creation triggers and FCM delivery.
  notification-logic.js: Payload creation and validation.
  test/notification-logic.test.js: Unit tests.
  firestore-notifications.rules.fragment: Matches to merge into existing rules.
  package.json / package-lock.json: Isolated Node 22 functions codebase.

FIREBASE SETUP
1. Cloud Functions deployment requires the Firebase Blaze billing plan. Use the same Firebase project as the app (uploaded configuration: opportunet-bd7b8). Verify it in your own console.
2. Install Node.js 22 and the Firebase CLI, then log in:
     npm install -g firebase-tools
     firebase login
3. Copy this entire notification-functions directory into the Flutter project root. If you already have an AI/backend functions directory, keep it.
4. If there is no firebase.json in your project root, create it with this COMPLETE content:

   {
     "functions": [
       { "source": "notification-functions", "codebase": "opportunet-notifications" }
     ]
   }

   If you already have firebase.json, merge the new codebase into it instead. For example, if the existing functions config is {"source":"functions"}, convert ONLY that property into an array, preserving existing options:

   "functions": [
     { "source": "functions", "codebase": "default" },
     { "source": "notification-functions", "codebase": "opportunet-notifications" }
   ]

   If the functions property is already an array, append the second object. If there are no existing functions, use:

   "functions": [
     { "source": "notification-functions", "codebase": "opportunet-notifications" }
   ]

   Preserve all other firebase.json settings. If your existing codebase has a different name, preserve that name rather than changing it to default.
5. Inside notification-functions run:
     npm ci
     npm test
6. Optional for web click-through: create notification-functions/.env.opportunet-bd7b8 containing your actual hosted HTTPS URL:
     APP_URL=https://YOUR-APP-HOST/
   This is public configuration, not a credential. The URL gets routing query parameters notificationId, type, targetId and eventDate. No APP_URL is necessary for Android. If you omit APP_URL, the messaging service worker determines the browser's fallback click behavior. Do not deploy the placeholder URL.
7. Merge firestore-notifications.rules.fragment into your existing Firestore rules. Keep the existing restrictions on posts/calendarEvents: for example, only organizers should be able to create calendar events. Existing recursive `allow read, write: if true` or authenticated-all-access rules would make these private device-token rules ineffective. Tighten those broad matches before use.
8. If you do not have a local rules file, open Firebase Console > Firestore Database > Rules. Copy the CURRENT rules to a backup. Merge the fragment's matches inside the existing /databases/{database}/documents match, then Publish. Keep the existing collection rules; do not paste the fragment as the whole file.

   If you already manage rules locally, deploy the merged rules using your normal process. If firebase.json points to your actual merged rules file:
     firebase deploy --only firestore:rules --project opportunet-bd7b8
9. From the Flutter project root deploy ONLY the new functions codebase:
     firebase deploy --only functions:opportunet-notifications --project opportunet-bd7b8
   This avoids replacing the existing AI functions. The Firebase CLI may request API enablement/permissions for the project's first Cloud Functions v2 deployment.

CLIENT SETUP
The Flutter notification service must request notification permission from a user action, then save the FCM token to:
  users/<uid>/notificationDevices/<deviceId>
with token, platform (web/android/ios), optional lang (en/ka; pushes use Georgian texts for ka, English otherwise), and updatedAt: serverTimestamp(). Delete the previous user's device registration before signing out or switching accounts. Never put service-account credentials, FCM server keys, or Admin SDK code in Flutter or the web service worker.

Android uses the FCM fallback notification channel; no custom channel needs to be created for this package. Keep the existing Firebase Android/Google Services setup. Android 13+ needs POST_NOTIFICATIONS in AndroidManifest.xml and an explicit runtime permission prompt. You can add a custom channel/icon later with matching native setup. Web requires HTTPS (or localhost for development), a Firebase messaging service worker, and the project's public VAPID key. Browser/OS settings determine whether delivery works while the browser is fully closed; do not assume every browser/phone behaves the same. iOS additionally requires APNs configuration in Firebase and Apple push entitlements.

In-app read status is private per user:
  users/<uid>/notificationReads/<notificationId>
with readAt: serverTimestamp(). All signed-in users can read notifications; clients cannot create or change them.

VERIFICATION
1. Deploy the functions and merged rules.
2. Open the app as User A and enable push; verify that A's device registration exists.
3. As a different User B, create a new post. User A should see one in-app record. With A's app in the background, check the OS/browser alert, then tap it to open the post.
4. As an organizer, create a calendar event. Check the in-app record, background alert, and event date routing.
5. Confirm author B does not receive their own push, a denied permission leaves the bell usable, disabling push removes the registration, and signing out removes the old user's registration.
6. Test a failed/expired token and verify that only invalid registrations are removed. A temporary FCM/network failure should retry, not delete the device.

DELIVERY AND SCALE
Notification creation is idempotent: stable IDs post_<postId> and calendar_<eventId> prevent duplicate in-app records when source triggers retry. A separate retry-enabled outbox trigger sends pushes. Delivery pages at 500 registered devices and checkpoints after a successful page; a lease prevents overlapping attempts. Permanent invalid-registration tokens are deleted only when the saved token still matches the failed send. Progress and completion are stored in the server-only _notificationDelivery collection.

FCM delivery is at least once, not exactly once. A crash after FCM accepts a send but before the checkpoint, or a partial page failure, can resend to some devices. Android/browser tags replace the same notification where supported. The bell stays deduplicated. FCM/OS delivery is not guaranteed; users can always see the persisted in-app feed. The scan reads every registered device per new post/event, so for a larger community use batching/preferences or subscription fan-out to control cost and volume. All three functions run in europe-west1 (Belgium). If your project requires a different European region, change the shared region constant in index.js to that exact supported region. This setting does not move your Firestore database or other Firebase services. Region choice alone does not confirm the cause of a deployment failure.

TEST STATUS
9 unit tests passed and JavaScript syntax checks passed. The tests cover source routing, stable IDs, source deduplication error handling, payload limits, URL validation, author exclusion, invalid-token classification, and lease decisions. No live deployment, Firestore-rule emulator test, or end-to-end FCM delivery was performed here.
