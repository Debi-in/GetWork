Phase 1 — Firebase Project Setup
Create a Firebase project (console.firebase.google.com)
Add your Flutter app (Android package name + iOS bundle ID)
Download google-services.json (Android) → place in android/app/
Download GoogleService-Info.plist (iOS) → place in ios/Runner/
Enable Cloud Messaging in Firebase console
Phase 2 — Flutter App Setup
yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
Initialize Firebase in main()
Request notification permission on first launch (required Android 13+, iOS)
Get and store the device's FCM token
Send that token to your backend, tied to the logged-in user's account (userId → token mapping in your database)
Refresh token handling — tokens can change, listen for onTokenRefresh and re-send to backend
Phase 3 — Handle Notifications on the Device
Foreground (app open): FirebaseMessaging.onMessage → show your own in-app banner/toast
Background tap (app minimized): FirebaseMessaging.onMessageOpenedApp → deep-link to the right screen
Terminated tap (app fully closed, user taps notification): FirebaseMessaging.instance.getInitialMessage() → same deep-link logic, checked once at app startup
Phase 4 — Backend (the part that actually sends)

This is the missing piece for "Facebook-style" notifications — a server that decides when to send:

Set up Firebase Cloud Functions (Node.js) or your own backend with the Firebase Admin SDK
Write triggers for each event:
New job posted near a worker → notify workers in radius
Employer sends a message → notify that worker
Job accepted → notify employer
Manual/admin send → "Try our new feature" to all or a segment
Each trigger looks up the recipient's saved FCM token(s) and calls admin.messaging().send()
Phase 5 — Notification Payload Structure

Standardize this now so deep-linking works cleanly for every type:

json
{
  "notification": { "title": "New job near you", "body": "Cafe Helper — Rs 1200/day" },
  "data": { "type": "new_job", "jobId": "abc123" }
}
Phase 6 — Testing
Test via Firebase Console first (manual send to your own token) — confirms basic delivery works
Test all 3 states: app open, app minimized, app force-closed
Test deep-link routing for each notification type
Test on a real device, not just emulator — background/killed-state delivery behaves differently on real Android especially


Task: Fix onboarding + set up FCM notifications in Flutter app

1. Onboarding fix:
   - Add shared_preferences package
   - Save a "seen_onboarding" flag after intro screens complete
   - On app start, route to home if flag is true, else show onboarding

2. Push notifications:
   - Add firebase_messaging + firebase_core
   - Request notification permission on first launch
   - Save FCM device token, print it to console for now
   - Handle foreground messages (show in-app banner)
   - Handle background/terminated tap (deep link using message.data)
   - Add routing: type=new_job → job details screen, type=new_message → chat screen

Verify by running the app and showing me the onboarding no longer repeats,
and that a test FCM message deep-links correctly.

