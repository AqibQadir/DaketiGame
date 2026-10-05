# Backend integration review - 5 October 2026

## Conclusion

The client contains implementations for all 24 REST method/path combinations in the 41-page Daketi API Guide dated 30 September 2026. Core game socket events are wired into the controller and UI. This is API coverage, not evidence that every feature is configured and working in production. Remaining work includes provider setup, HTTPS domain association, real-account verification, backend recovery follow-up, and agreeing on the timer contract.

Source: `/Users/aqibqadir/Downloads/Daketi-API-Guide (1).pdf`. Read all pages; visually checked the status summary, Facebook caveats, endpoint table, device payload, and game-state example. Instructions and examples in the PDF were treated as reference material. No application or server code was changed in this review.

## Implemented coverage

| Area | Implemented API and app behavior | Main evidence |
| --- | --- | --- |
| Public/game REST (6 endpoints) | Health, stats, solo creation with AI count/difficulty, multiplayer creation/capacity, state lookup, leaderboard | `lib/features/game/data/game_rest_client.dart`; `lib/features/menu/data/leaderboard_client.dart` |
| Accounts (11 endpoints) | Signup, login, current user/stats, history, profile, change/forgot/reset password, verify/resend email, Facebook token exchange | `lib/features/auth/data/auth_rest_client.dart`; auth controller; login/signup/profile/history/account-link screens |
| Access/referrals/devices (7 endpoints) | Join/status waitlist, eligibility, referral details/validation, register/unregister FCM token | `lib/features/access/presentation/access_controller.dart`; waitlist screen; signup validation; push service |
| Game sockets | WebSocket-only connection; join with account JWT and reconnect token; ready; get actions; capture, steal, extend, discard; all ten documented incoming events | `lib/features/game/data/game_socket_service.dart`; game controller |
| Recovery | Secure saved seat, replacement player ID on reclaim, NOT_IN_GAME recovery for get_actions, stale identity detection | game controller; `lib/features/game/data/previous_game_storage.dart` |
| Account/session correctness | Secure JWT storage, restore/resume/pre-game validation, rate-limit messages, post-game stats refresh, mixed-case response parsing | auth controller, auth models, game provider wiring |
| Rules | Actions derived from server get_actions; server state controls auto-draw, hidden cards, protected cards and endgame | game controller, domain models, game screen |

`draw_card` has no dedicated UI/controller command. The socket abstraction can emit it, but normal gameplay uses server auto-draw as recommended on page 28. This is not a required missing feature. Admin dashboard routes are explicitly excluded from the mobile app by the guide.

## Remaining work

### 1. Facebook configuration and device testing

`FacebookSignInService.enabled` reads FACEBOOK_ENABLED, which defaults to false; the checked-in provider example also disables it. Native default settings are placeholders. Supply the real Meta app/client settings, register package/bundle IDs and Android signing hashes, add testers while the Meta app is unpublished, and test the actual SDK-to-backend login.

The service explicitly rejects iOS Limited Login tokens. Supporting those users needs a backend verification contract beyond the Graph access-token contract in this PDF. The configured Android application ID is currently `com.example.daketi_phase1_modular`; confirm the intended release identifier before configuring providers.

### 2. Push configuration and delivery verification

FIREBASE_ENABLED defaults to false. Registration on account bind/token refresh, logout cleanup, permission handling and notification routing are present. Supply Firebase client settings, confirm backend FCM credentials, configure iOS APNs/provisioning, enable the feature, and test foreground, background, cold-start, token rotation and logout on physical devices.

The PDF says backend Firebase credentials were missing on 30 September; this review cannot confirm whether that server configuration has since changed. Web push additionally needs its service worker/VAPID deployment if web is in scope.

### 3. HTTPS account/referral links: confirmed deployment gap

Live read-only checks on 5 October returned HTTP 404 for both:

- `https://game.daketi.pk/.well-known/assetlinks.json`
- `https://game.daketi.pk/.well-known/apple-app-site-association`

The app already parses resetToken, verifyToken and ref links and includes native association declarations. Deploy valid association files with the real release signing/team/bundle identifiers, then test installed-app links. Templates are in `docs/backend-config/`. Browser completion and manual account-link entry remain fallback paths.

### 4. Timer contract needs alignment

The guide's game-state example includes `turnTimeLimit: 30` (page 32). The model parses turnTimeLimit, but `game_screen.dart` uses a fixed 20-second duration instead. The preceding requested change resets each move and holds the local timer at zero during the steal animation; it does not send a pause/reset command to the backend, and no such event is documented.

Agree on whether 20 seconds is the intended rule or the server-provided limit is authoritative, and how animation delays affect multiplayer deadlines. If the backend enforces a timer, it must support the intended reset/pause semantics. This is a contract mismatch/risk, not proof that production currently enforces a conflicting timeout. The requested animation behavior was preserved in this review.

### 5. AI-turn reconnect: previous backend issue still needs closure

Existing QA records in `docs/api-guide-integration.md` report that reclaim during an AI move could later be overwritten by a stale server snapshot and recovery could fail with `Player not found`. The current app detects missing identity and attempts reclaim; regression tests cover that mitigation.

This review did not reproduce that live game mutation or inspect backend source. Treat it as a previously reported issue needing backend confirmation/fix and a fresh targeted retest, not a newly verified production failure.

### 6. Real-account end-to-end verification

Unit/widget/transport tests cover the contracts but do not establish real account persistence or external delivery. Still verify:

- Signed-in completed game appears in current-user stats, history and leaderboard.
- Signup, email verification, password-reset email delivery and link completion.
- Verified referral changes counts/position; admin access changes are reflected by canPlay.
- Facebook and actual push delivery after provider setup.

No credentials were supplied; this review created no accounts, games, emails or notifications.

### 7. Resolve contradictory guide requirements

- Guests: page 7 permits all game modes; pages 19-24 describe access gating. Current app allows guests and gates signed-in users with canPlay. Confirm the launch policy and enforce it server-side as necessary.
- Email-less Facebook account: page 11 says email cannot be edited; page 14 instructs adding it with PATCH /api/auth/me. The app attempts it only for missing-email accounts and detects an ignored update. Confirm backend support before calling this flow complete.

## Outside this PDF

Wallet/coins, purchases, quest/runner rewards, clans, personal chat, issue submission and WhatsApp authentication have no API contract here. They cannot be counted as integrated based on this guide. Room-chat events in the app are also an extension beyond the documented API and need separate contract/live validation. Existing static/local screens do not prove backend support.

## Verification performed now

- Full Flutter test suite: **118 passed**.
- `flutter analyze`: **no issues**.
- Read-only `tool/backend_smoke.dart`: **health, stats and WebSocket-only connection passed** against the production base URL.
- Domain association checks: **both HTTP 404**, as listed above.
- No new native release build, real-account transaction, Facebook login or notification-delivery test performed.

The older endpoint-by-endpoint matrix remains in `docs/api-guide-audit.md`; its historical test counts and previous live gameplay results should not be confused with this review's current checks. Provider setup instructions are in `docs/api-guide-integration.md`.
