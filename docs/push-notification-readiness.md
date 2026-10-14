# Push notification readiness — 14 October 2026

## Current verdict

The Flutter app is integrated with the guide's push/device contract, but live delivery is not verified or enabled. The production backend exists: this review passed `GET /health`, `GET /api/stats`, and a WebSocket-only Socket.io connection using `tool/backend_smoke.dart`. This does not establish that Firebase sending is configured.

The supplied 30 September API guide explicitly says device registration is live and server Firebase credentials are pending. This checkout contains Flutter clients, not the backend source. There are no real Firebase client configuration files in `config`, Android, or iOS; `config/providers.example.json` has blank Firebase values and `FIREBASE_ENABLED=false`. No authenticated production device request or actual push was sent during this review.

## App integration

- Registers `POST /api/devices` with JWT, FCM token and platform on login/resume and token rotation.
- Sends `DELETE /api/devices` on logout and invalidates the local FCM token.
- Requests permission through an explicit user action. The notification button is now available in Account Settings as well as on the waitlist, with pending-request protection and useful unavailable/error messages.
- Handles `app_live`, `waitlist_status`, `play_unlocked`, and `referral_credited`. Re-reads server data; `play_unlocked` now also reads `/api/play/eligibility`.
- Foreground notifications show an in-app message; background/terminated notification display uses the guide's OS `notification` payload. Tap handlers refresh and route without interrupting an active game. Failed refreshes do not grant access; async failures are caught.
- Android notification permission and iOS remote-notification background mode are present. iOS APNs signing/capability provisioning still needs physical-device verification.
- Web push requires a separately configured Firebase messaging service worker and VAPID setup. It is not ready in this checkout.

## Required next steps to start sending

1. Obtain the Firebase project's Android and iOS public client configuration. Confirm the registered Android package `com.example.daketi_phase1_modular` and iOS bundle `de.zamedia.daketigame` match the intended distributed apps.
2. Copy `config/providers.example.json` to ignored `config/providers.local.json`. Fill `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID` and the iOS bundle ID; use a separate local file per platform because app IDs differ. Set `FIREBASE_ENABLED=true`. Run `flutter run --dart-define-from-file=config/providers.local.json`. Explicit FirebaseOptions are supported. If choosing native Android google-services.json instead, configure the Google Services Gradle plugin too; simply dropping the file into this project is insufficient.
3. Backend owner: configure Firebase Admin credentials in the server's secret/environment configuration for the same Firebase project and enable the FCM HTTP v1 API. Never put service-account private keys in this Flutter app. Verify each of the four documented backend event triggers actually sends the documented `notification` plus string-valued `data` payload. Backend source/access is needed to implement or verify this work.
4. iOS owner: enable Push Notifications for the Apple app ID/provisioning profile, upload the APNs authentication key to Firebase, and use a correctly signed physical-device build. Confirm development/production APNs environments match the build.
5. Sign in on a test device and tap Enable notifications. Verify authenticated device registration returns success. First send a Firebase-console test to that device to isolate client/APNs setup; then trigger a backend event to verify the full path.
6. Repeat with the app foregrounded, backgrounded and terminated. Test all four types, stale/duplicate messages, denied permission, resume, token rotation, and logout/account switching. Confirm a logged-out handset no longer receives the former account's messages and an active match stays uninterrupted. Use test accounts/staging for invitation and broadcast tests.

## Acceptance criteria

- Android and iOS receive backend-generated notifications on physical devices.
- Device POST and DELETE succeed using an actual test-account JWT.
- Server event -> FCM send -> device display -> tap -> refreshed API state is demonstrated.
- Permission refusal and transient failures preserve ordinary app use.
- No signed-in access is granted solely from push payload fields.

## Verification in this review

The live public smoke check passed. Automated push-control, waitlist and API-contract results are recorded in the accompanying chat. Actual notification delivery, authenticated production endpoints, Firebase Admin setup and APNs provisioning remain unverified.

References: the supplied Daketi API guide, pages 1 and 23–24; Firebase Flutter setup https://firebase.google.com/docs/cloud-messaging/flutter/get-started and message handling https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages.

## Firebase file import added

Downloads, the Daketi full-project folder, and both Daketi ZIP archives were checked; no Firebase client files or backend source were found. The available additional API guides do not supply them.

When the developer provides the public Firebase client files, run from this project:

```sh
python3 scripts/configure_push.py \
  --android "/path/to/google-services.json" \
  --ios "/path/to/GoogleService-Info.plist"
```

Either platform may be supplied independently. The command checks app identifiers, rejects service-account files and mismatched projects, and generates ignored `config/providers.android.local.json` and/or `config/providers.ios.local.json` with Firebase enabled. Existing generated files are preserved unless `--force` is supplied. It uses the app's explicit FirebaseOptions path, so native Google Services plugin setup is unnecessary for these generated configurations. This prepares client configuration only; it does not provision Firebase, upload an APNs key, or deploy backend credentials.

Run the corresponding generated configuration on the chosen device:

```sh
flutter run --dart-define-from-file=config/providers.android.local.json -d <android-device-id>
flutter run --dart-define-from-file=config/providers.ios.local.json -d <iphone-device-id>
```

The importer passed four tests covering platform extraction, identifier and private-key rejection, output permissions/overwrite protection, and mismatched-project rejection. Copy the request in [push-setup-request.md](push-setup-request.md) to the backend developer.

## Firebase console setup progress

A new Daketi project `daketi-ea2dc` was created on 14 October 2026. Android and iOS apps are registered and FCM HTTP v1 is enabled. The earlier statement that no Firebase project was available is superseded by this update. Client downloads are blocked by the in-app browser; client activation, Apple APNs setup and real delivery testing remain pending. See [Firebase backend handoff](firebase-backend-handoff.md) for verified identifiers and server work.

## Client configuration imported

Both downloaded Firebase client files were validated and imported on 14 October 2026. Use the generated Android/iOS configurations or the VS Code Firebase launch profiles. This supersedes the earlier client-download blocker. Apple APNs setup, backend sending credentials and physical-device delivery tests remain pending.

## Production APNs configured

The production APNs key `US2DA9YYY8` for Apple team `M6S4T8V7RU` was uploaded and confirmed in Firebase. The Apple App ID capability edit page did not load its capability form in this browser, so portal capability/provisioning status is not claimed as verified. The project has local push entitlements and its signing team is corrected. Next verify a signed TestFlight/device build, backend Admin credentials and actual delivery. Sandbox/debug APNs remains unconfigured.
