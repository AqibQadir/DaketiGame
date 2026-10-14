# Request for the backend/Firebase developer

Please provide the remaining Daketi push setup:

1. Firebase client files from the Firebase project used by the backend:
   - `google-services.json` for Android package `com.example.daketi_phase1_modular`.
   - `GoogleService-Info.plist` for iOS bundle `de.zamedia.daketigame`.
   Confirm these are the intended production identifiers before registering new apps.
2. Confirm Firebase Admin sending credentials are configured on the deployed backend and the FCM HTTP v1 API is enabled. Keep the service-account private key on the server; do not send it for inclusion in the Flutter app.
3. Confirm an APNs authentication key has been uploaded to Firebase and the Apple app ID/provisioning profile has Push Notifications enabled.
4. Provide the backend repository/access if we need to finish the server implementation, or confirm all four triggers send pushes: `app_live`, `waitlist_status`, `play_unlocked`, and `referral_credited`.
5. Provide a staging/test account and a way to trigger a notification for that account so we can verify the full path without broadcasting to production users.

The app already calls authenticated POST/DELETE `/api/devices`, refreshes authoritative API state on notification events, and offers notification permission controls. Production health, stats and WebSocket connectivity passed. Actual push delivery still needs verification.
