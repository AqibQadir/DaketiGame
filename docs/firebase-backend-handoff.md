# Daketi Firebase backend handoff — 14 October 2026

## Project created

- Firebase project name: Daketi
- Project ID: `daketi-ea2dc`
- Project number / FCM sender ID: `367564985041`
- Plan: Spark
- Firebase Cloud Messaging HTTP v1 API: Enabled (verified in console).
- Android app ID: `1:367564985041:android:a755c79a52c9f41bb12bf0`
- Android package: `com.example.daketi_phase1_modular`
- iOS app ID: `1:367564985041:ios:64a989b67d67d7e6b12bf0`
- iOS bundle: `de.zamedia.daketigame`

Both mobile apps were verified in project settings after refreshing the console. Optional Developer Program enrollment, Gemini and Analytics were disabled in the creation wizard.

## Flutter client configuration imported

Both downloaded client files were validated against the registered app identifiers and project `daketi-ea2dc`, then imported on 14 October 2026. Firebase is enabled in ignored `config/providers.android.local.json` and `config/providers.ios.local.json`. Use the corresponding configuration when running/building; a plain build without these defines still leaves push disabled.

```sh
flutter run --dart-define-from-file=config/providers.android.local.json -d <android-device-id>
flutter run --dart-define-from-file=config/providers.ios.local.json -d <iphone-device-id>
# Build the configured iOS archive for the normal TestFlight upload workflow:
flutter build ipa --dart-define-from-file=config/providers.ios.local.json
```

VS Code launch profiles for each platform are included. The configurations initialize Firebase through explicit FirebaseOptions; native client file copying and Android Google Services plugin setup are not needed for this path. No service-account private key is bundled in the app.

The existing Flutter integration uses this API contract:

- `POST /api/devices`, Bearer JWT, JSON `{ "token": "<FCM token>", "platform": "android|ios" }`.
- `DELETE /api/devices`, Bearer JWT, JSON `{ "token": "<FCM token>" }` on logout.
- Re-register after login, resume and token rotation. The same device token reassigned to another account must stop receiving the previous account's notifications.

## Backend developer action

Configure Firebase Admin credentials for project `daketi-ea2dc` on the backend host. Prefer the hosting platform's supported application default credentials/workload identity; if a service-account key is required, provision it through a secure server-only process. Do not place private keys in Flutter, Git or ordinary chat. No server credential was generated in this setup.

Send a notification block and string-valued data using the existing event triggers:

```json
{
  "notification": {
    "title": "You're in!",
    "body": "Your Daketi invitation is ready."
  },
  "data": {
    "type": "waitlist_status",
    "status": "invited"
  }
}
```

Support `app_live`, `waitlist_status`, `play_unlocked`, and `referral_credited`, as documented by the API guide. Clean up invalid/expired device tokens on FCM send responses. Do not log full device tokens or account JWTs. Ensure production and staging devices are targeted intentionally and server eligibility remains authoritative.

## Apple setup and testing still required

Upload the correct Apple team's APNs authentication key to this Firebase project's iOS app configuration, with its key ID and team ID. Enable Push Notifications for the existing Apple app ID and regenerate/refresh provisioning as necessary. The local Flutter project already has APNs entitlements and remote-notification background mode. No APNs key has been generated or uploaded by this setup.

After client configuration and backend sending are configured, test a real account/device through registration, a Firebase-console test, a backend-triggered notification, tap routing, denied permission, logout/account switching, and foreground/background/terminated states. Actual delivery is not yet verified.

Official client setup: https://firebase.google.com/docs/cloud-messaging/flutter/get-started

## Client build verification

On 14 October 2026, the real Android configuration passed `flutter build apk --debug --no-pub --dart-define-from-file=config/providers.android.local.json` and the real iOS configuration passed `flutter build ios --simulator --debug --no-pub --dart-define-from-file=config/providers.ios.local.json`. The importer passed all four tests. These verify compilation/configuration, not signed-device APNs delivery. Apple Developer sign-in was opened for the remaining APNs setup.

## Apple team verified

The signed-in Apple Developer team is `M6S4T8V7RU` (za:media GmbH) and owns `de.zamedia.daketigame`. Flutter's Debug/Profile/Release DEVELOPMENT_TEAM values were corrected from `6GRACQQ8YL` to `M6S4T8V7RU`; the Xcode project passed plist validation. No APNs credential has yet been created or uploaded. A production, topic-specific APNs key draft is prepared for `de.zamedia.daketigame`, pending explicit credential-creation approval. Debug/sandbox delivery requires a separate environment-specific key for this restricted configuration.

## Production APNs key created

With explicit user approval, Apple APNs key `US2DA9YYY8` named `Daketi Firebase Push` was registered for team `M6S4T8V7RU`. It is production-only and topic-specific to `de.zamedia.daketigame`. The `.p8` file has not yet been downloaded or uploaded to Firebase. Because Apple permits a one-time download and in-app configuration downloads failed earlier, the Apple download page remains open for the owner to download the key safely. Firebase's production upload dialog is prepared with the key/team IDs and is awaiting the file. No private key has been included in the project or this document. Sandbox/debug push requires separate configuration.

## Production APNs upload completed

Firebase Cloud Messaging settings now confirm `Production APNs auth key` with key ID `US2DA9YYY8` and team `M6S4T8V7RU`. This supersedes the earlier pending upload notes. The approved downloaded key was uploaded directly from Downloads; its contents were not printed or copied into the Flutter repository. There is no development APNs key configured. Production/TestFlight delivery still needs a signed-device test and backend Firebase Admin sending configuration.

## Normal TestFlight builds now enable mobile push

The real public Android/iOS FirebaseOptions are included in `lib/core/config/daketi_firebase_options.dart`. Mobile push defaults to enabled, so ordinary Xcode archives and `flutter build ipa --release` use the Daketi project without special Dart defines. Explicit FIREBASE_* defines still support an alternate project, and `FIREBASE_ENABLED=false` disables push. Build version is `2.6.0+17`. Firebase client API keys are public app identifiers; the APNs private key and backend service-account secrets remain outside the app. Web push remains separately configured.

The push-control, API-contract, waitlist and app-startup regression suite passed all 18 tests after this change. A signed release archive is being checked to verify Apple provisioning; actual phone receipt remains unverified.

## Release archive result — build 17

`flutter build ipa --release --no-pub` created `build/ios/archive/Runner.xcarchive` for version 2.6.0/build 17. App settings validation passed. IPA export failed because this Mac lacks the team's iOS Distribution signing certificate and the export provisioning profile must include Associated Domains and Push Notifications. The archive is currently development-signed (APNs environment `development`); it must be distribution-signed/exported before TestFlight delivery with the production APNs key. Do not treat this archive as a verified production push build until export succeeds.

Open the archive in Xcode Organizer, sign in with the correct Apple team M6S4T8V7RU, and distribute using automatic signing after provisioning the distribution certificate/profile with both capabilities. Recheck the exported app's APNs entitlement is `production`. Actual TestFlight notification delivery remains unverified. The placeholder launch-image asset notice is unrelated to this signing failure.
