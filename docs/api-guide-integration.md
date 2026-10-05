# Daketi API guide integration — 30 September 2026

Implemented against all 41 pages of `Daketi-API-Guide.pdf`. The supplied document is an integration reference, not backend source code. No backend repository, production credentials, Firebase project configuration or Meta app configuration was present in this workspace. Validation created unranked guest QA rooms only; no production accounts, authentication emails or notifications were created.

## Implemented and audited

| Guide feature | App implementation |
| --- | --- |
| Production REST and Socket.io | Same HTTPS base URL; WebSocket-only socket transport; release Android cleartext disabled. Health, stats and leaderboard read APIs supported. |
| Solo / multiplayer | Existing 1–3 AI selection, beginner/master selection, 2–4 human rooms, four-character string room codes and server-ready state retained. Live testing confirmed Unready is unsupported. Ready is one-way; the button shows Waiting after the server confirms readiness. |
| Reconnect contract | Secret per-game reconnect token saved in secure storage, sent on reclaim, changed socket player ID accepted only on confirmed reclaim, player_reconnected updates IDs. Missing local identity in a delayed AI snapshot also triggers authenticated seat recovery. NOT_IN_GAME retries get_actions after reclaim. Mutating card actions are not blindly retried. |
| App-restart recovery | Saved seat, current identity, mode and player name restored; account ID scopes new saved games even if JWT changes. Legacy saves without account ID require original token. Finished rooms clear saved credentials. |
| Accounts | Existing signup/login, secure 30-day token storage, startup/resume validation, profile, history, verification, reset and change password audited. Wrong current password does not log out a valid session. Async refresh, verification failures and old authenticated 401s cannot resurrect or expire a newer account session. Logout ends access immediately; secure-storage writes/deletes are serialized. |
| Results / leaderboard | Existing mixed-case parsing preserved; stats refreshed after game_over. No fabricated wallet or coin balance API. |
| Waiting list | Auto-join for signed-in users, refreshed status/position, verified/pending referral counts, error/retry, invited vs playable distinction. Only canPlay grants access, including before logged-in game creation/join. |
| Referrals | Debounced validation and submit validation, optional signup code, referral deep links, named referrer feedback, share sheet and copy link, referred friends and verification state. |
| Facebook | SDK token -> backend JWT, optional referral, linked/password flags, nullable email, cancellation/error states, retry once after token rejection, hide on 503. Feature disabled until configured. |
| Missing Facebook email | Profile offers adding email, always including name. If backend ignores email, UI reports that it was not saved. Existing email cannot be edited. |
| Account links | Trusted-origin parsing, password-reset and verify screens; native HTTPS/custom-scheme intake. Manual “Open email link” on Login works without domain association. No tokens in route names or logs. |
| Push | FCM permission button, registration on login/resume/token rotation, DELETE registration on logout, token invalidation on logout, foreground/open/cold-start routing. Relevant APIs re-read before access changes; no interrupting active games. Feature disabled until configured. |
| Rules / animation | Existing server get_actions governs capture, steal, extend and discard buttons. Server snapshots remain authoritative, including AI step animation and game_over results. Duplicate card submissions are blocked; a late action or join acknowledgement cannot undo a newer completion event. A new match disconnects the previous transport and cancels stale work. |

## Design decisions for contradictory guide sections

- Guests continue playing as explicitly documented on page 7. Signed-in accounts follow the waiting-list gate. The server must enforce its intended authorization policy too; a client-only gate is not protection. Confirm whether guest play should remain available before launch.
- Adding an email is attempted only for accounts without email, per Facebook instructions on page 14. Page 11 contradicts this. The app checks the returned user and does not claim success if email was ignored.
- `role` is display-independent; `user`, `player`, and `admin` do not unlock mobile features.
- Change-password 401 verifies `/api/auth/me` before expiring the session, because wrong current password and expired authorization both use 401.
- No WhatsApp login, wallet, stakes, coin redemption, payments, or runner-reward backend was invented: none is defined by this guide.

## Configuration needed for live integrations

Copy `config/providers.example.json` to ignored `config/providers.local.json`. Use separate platform-specific local files if the Firebase app IDs differ. These contain client configuration, never Firebase service-account keys or Meta app secrets.

Run with `flutter run --dart-define-from-file=config/providers.local.json` after supplying real configuration. Enable flags only after the corresponding console/native setup below is complete.

### Facebook

1. Obtain Daketi's real Meta app ID and public client token. Register Android package `com.example.daketi_phase1_modular` and iOS bundle `de.zamedia.daketigame`, or update the app identifiers consistently before distribution.
2. Android: add `DAKETI_FACEBOOK_APP_ID` and `DAKETI_FACEBOOK_CLIENT_TOKEN` to local Gradle properties. The build generates the manifest string resources and callback scheme. Do not use the Meta app secret.
3. iOS: create ignored `ios/Flutter/Social.local.xcconfig` with the same two settings. Info.plist uses these and the callback scheme. Default inactive build values are placeholders, not a working Facebook app.
4. Add developer/tester accounts while the Meta app is unpublished and register debug/release Android key hashes.
5. Set `FACEBOOK_ENABLED=true` in the local Dart configuration.
6. The guide supports Graph API access tokens only. New iOS Facebook SDKs can return Limited Login JWTs; those are explicitly rejected with a useful fallback message rather than passed to an incompatible endpoint. To support users who receive Limited Login tokens, backend must verify Meta's OIDC token/nonce contract. This cannot be implemented correctly from the current PDF alone. No tracking permission is requested automatically.

Official setup: https://facebook.meedu.app/docs/7.x.x/android/ and https://facebook.meedu.app/docs/7.x.x/ios/.

### Firebase / push

1. Supply actual per-platform `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID` and iOS bundle ID. The service initializes with explicit FirebaseOptions, so Android can use these without a google-services Gradle plugin. Alternatively configure native GoogleService files and leave API_KEY blank.
2. Enable Firebase Cloud Messaging and configure the backend credentials (the guide says these are still missing).
3. iOS: enable Push Notifications and Associated Domains for the Apple app ID/provisioning profile; upload the APNs key/certificate to Firebase. Entitlements and remote-notification background mode are included; Debug uses development APNs and Release/Profile uses production.
4. Set `FIREBASE_ENABLED=true`, sign in, then tap Enable notifications on the invitation/referrals screen. Permission is not required to play. APNs token delay or permission refusal is recoverable on resume/retry.
5. This implementation targets Android/iOS. Web FCM additionally requires a real web Firebase configuration, VAPID key, and a deployed service worker; these are not supplied or deployed here.

Official setup: https://firebase.google.com/docs/cloud-messaging/flutter/get-started and https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages.

### HTTPS account/referral links

- Host `docs/backend-config/apple-app-site-association` as `https://game.daketi.pk/.well-known/apple-app-site-association`, with JSON content type and no redirect. The checked-in identifiers match this project's current Apple team and bundle; confirm they are the intended production identifiers.
- Replace the fingerprint in `docs/backend-config/assetlinks.example.json`, confirm the Android package, and host the completed JSON as `https://game.daketi.pk/.well-known/assetlinks.json`.
- Android intent filters and iOS Associated Domains entitlement are included. The server must serve association files before HTTPS links reliably open the app.
- Existing `/?resetToken=...`, `/?verifyToken=...`, and `/?ref=...` URLs are accepted. `daketi://account?...` is also accepted for testing. Keep HTTPS links in production emails because they also support web fallback.
- App receives a referral but never creates a referral for an already-existing account. Password reset/verification require a confirmation tap in the app.

## Verification — latest pass

- The starting workspace already contained a substantial first integration pass. This completion pass audited it, fixed session/transport races, tested live gameplay, and corrected the unsupported Unready flow.
- Flutter suite: all 117 tests passed after the Ready-only adjustment. `flutter analyze` reports no issues; `git diff --check` passes.
- Added real local WebSocket tests for Engine.IO transport, authenticated seat join, malformed acknowledgements, disconnect cancellation and NOT_IN_GAME codes.
- Added delayed-response regression tests for logout during join, verification and authenticated requests; duplicate card moves; game_over arriving before an older acknowledgement; timeout requests crossing game sessions; and AI snapshots with obsolete player IDs.
- Live production guest solo: completed room 4589 with 20 human moves and 39 AI events; verified the reconnect token restores the seat on a new socket. No account statistics are recorded for these guest games.
- Live two-client guest multiplayer: completed room 6674 with 48 moves covering capture_table, discard, extend_stack and steal_opponent. Both players joined before ready; a ready player stayed ready after an isReady:false probe, confirming the extension is not supported.
- Public health, stats and WebSocket-only connection passed through the actual app clients.
- Authenticated account APIs, referrals, waitlist and device requests are covered by mock contract tests. No real user credentials were supplied for live account testing.
- Android compilation initially exposed Java 11 / Kotlin 17 target disagreement in flutter_facebook_auth. The root Gradle configuration now aligns this plugin's Java target to 17 without modifying the package cache.
- Android debug APK and iOS simulator debug builds succeeded. These are development builds, not signed store releases.
- Live Facebook sign-in, actual push delivery, domain association, and physical-device APNs require the configuration above and are not claimed as verified.

### Repeatable smoke checks

```sh
# Public reads and a WebSocket connection only:
dart run tool/backend_smoke.dart

# Creates one guest solo game, reclaims its seat, then plays it to completion:
dart run tool/backend_smoke.dart --play-guest

# Creates two guest seats, probes readiness, and plays a multiplayer game:
dart run tool/multiplayer_smoke.dart
```

Add `--reconnect-during-ai` to the solo command to reproduce the server race described below. This targeted diagnostic can currently fail even though an ordinary solo match completes.

The scripts accept an optional server URL for a staging environment. They never print JWTs or reconnect tokens. The multiplayer script deliberately probes isReady:false for diagnostics; the production app only sends the documented one-way Ready event.

### Backend follow-up observed during QA

Two early solo QA runs reconnected while the AI's turn was in progress. Later server snapshots no longer contained the reclaimed socket identity and the human turn stalled. Another solo run with the human turn active at reclaim completed normally. The app now detects a missing local identity and attempts to reclaim the seat again; a regression test covers this mitigation. A targeted live run in room 9592 confirmed the stale snapshot, but the subsequent recovery failed with `Player not found`. Client recovery cannot guarantee success until the server fixes this race. Backend owners should still serialize AI updates and seat reclaim against the latest room state so an in-flight AI update cannot restore obsolete player IDs. There is no backend source in this Flutter workspace, so this server-side concurrency behavior was not changed here.
