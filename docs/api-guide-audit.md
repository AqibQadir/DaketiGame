# Daketi API documentation audit

## Verdict

The Flutter project implements the documented core REST and Socket.io flows. It is **not yet fully configured and verified end to end for every feature**. Facebook, push delivery, domain-associated links, live account-result persistence, and a previously reproduced server reconnect race remain explicit release checks.

This audit read all 41 pages of `Daketi-API-Guide (1).pdf`. Its SHA-256 is identical to the earlier `Daketi-API-Guide.pdf`:

`bdadeaf7b765dbdd49b92e5cab53e87e932cbe7c28de7a2ffbd339c5ade229af`

It introduces no new API revision. The document was treated as an integration reference, not as authorization to run its examples or change the production server.

## Current verification

- `flutter analyze`: no issues.
- `flutter test --reporter expanded`: all 117 tests passed.
- `dart run tool/backend_smoke.dart`: live health, server stats, and WebSocket-only connection passed. This invocation created no game or account.
- Android debug and iOS simulator builds passed during the preceding integration pass. No runtime code changed in this audit, so native builds were not repeated.
- The preceding live guest tests completed one solo match (20 human moves, 39 AI events) and one multiplayer match (48 moves, all four action types).
- Account APIs, referrals, waitlist and device payloads have mock contract coverage; these results are not proof that a real signed-in user's completed game was persisted in production.

## REST coverage: all 24 documented method/path combinations

“Implemented” describes client code and UI wiring. It does not claim all real-account or third-party scenarios were tested live.

| Guide pages | API | Implementation | Verification / caveat |
| --- | --- | --- | --- |
| 4 | `GET /health` | `GameRestClient.healthCheck` | Live pass this audit |
| 4–5 | `GET /api/stats` | `GameRestClient.getServerStats` | Live pass; storage count not presented as currently playing users |
| 5–6 | `POST /api/game/solo` | REST client + game controller + solo/table selection | Previous live guest pass; 1–3 AI and difficulty supported |
| 6 | `POST /api/game/multiplayer` | REST client + multiplayer screen | Previous live guest pass; 2–4 seats |
| 6 | `GET /api/game/:gameId` | `GameRestClient.getGame` + resume flow | Recovery tests and previous live diagnostics |
| 7 | `GET /api/leaderboard` | `LeaderboardClient` + leaderboard screen | Implemented; server ranking retained |
| 9 | `POST /api/auth/signup` | `AuthRestClient.signup` + signup screen | Optional referral; usable JWT without requiring verification |
| 9 | `POST /api/auth/login` | `AuthRestClient.login` + login screen | Backend error preserved; secure token storage |
| 9–10 | `GET /api/auth/me` | Session restore/resume, profile, completion refresh | Mixed-case user/stats parsing tested |
| 10 | `GET /api/auth/me/history` | Auth client + history screen | Nested camelCase opponents parsed with snake_case rows |
| 11 | `PATCH /api/auth/me` | Profile edit + auth client | Always sends name; DOB format/age enforced by server; email contradiction below |
| 11 | `POST /api/auth/change-password` | Profile password dialog | Incorrect-password 401 is distinguished from expired login by checking `/me` |
| 11–12 | `POST /api/auth/forgot-password` | Login recovery UI + auth client | Backend non-enumerating message shown |
| 12 | `POST /api/auth/reset-password` | Account-link screen + auth client | Token/password submission tested; login offered afterward |
| 12 | `POST /api/auth/verify-email` | Account-link screen + auth client | Does not replace current identity with the link's account |
| 12 | `POST /api/auth/resend-verification` | Profile UI + auth client | Server message and rate-limit errors preserved |
| 12–15 | `POST /api/auth/facebook` | Facebook SDK → auth client → normal JWT session | Code present; disabled without provider configuration; iOS Limited Login unsupported by documented backend |
| 19–21 | `POST /api/waitlist/join` | `AccessController` | Auto-join for signed-in accounts; mocked contract tests |
| 21 | `GET /api/waitlist/me` | Access controller + invitation screen | Refreshes position/status; only waiting users show a position |
| 21 | `GET /api/play/eligibility` | Access controller + pre-game validation | Uses `canPlay`, not assumed status rules; guest-policy ambiguity below |
| 21–22 | `GET /api/referrals/me` | Access controller + invitation screen | Code/link, verified/pending counts and referred people |
| 22 | `GET /api/referrals/validate/:code` | Signup debounce and submit validation | Public request, case preserved, optional empty input |
| 23 | `POST /api/devices` | Push service on account bind/token rotation/permission | Implemented; real FCM configuration and delivery test pending |
| 23 | `DELETE /api/devices` | Push service invoked before logout cleanup | Authenticated JSON token payload tested; real-device logout test pending |

Primary files: `lib/features/auth/data/auth_rest_client.dart`, `lib/features/auth/presentation/controllers/auth_controller.dart`, `lib/features/access/presentation/access_controller.dart`, `lib/core/services/push_notification_service.dart`, `lib/features/game/data/game_rest_client.dart`, and `lib/features/menu/data/leaderboard_client.dart`.

## Socket, state and gameplay coverage

| Guide pages | Requirement | Result |
| --- | --- | --- |
| 2–4 | Same production HTTPS origin, WebSocket-only transport | Implemented; local transport tests and live connection pass |
| 7, 26 | Four-digit room code kept as a string; socket assigns player identity | Implemented; leading-zero and join tests |
| 26–27 | `join_game` with optional account JWT and per-game reconnect token | Implemented; secure seat persistence and account-scoped resume |
| 27 | `player_ready` once room is joined | Implemented as `{gameId}`. UI waits after Ready. Live server did not support Unready, so that control was removed |
| 28 | `draw_card` | Generic socket `performAction` can emit it; no dedicated manual-draw UI. Normal play uses server auto-draw as the guide recommends |
| 28–29 | Capture, steal, extend, discard | All dispatched by controller; all four exercised in previous live multiplayer test |
| 29–30 | `get_actions`, recover `NOT_IN_GAME`, then retry | Implemented and tested. Mutating actions are not blindly replayed |
| 30–32 | All ten documented incoming game events | Registered in `GameSocketService` and consumed by controller/UI |
| 31 | Each AI step uses its own snapshot | Implemented through queued visual updates |
| 31 | Refresh account statistics after `game_over` | Implemented; event is not treated as proof of successful database persistence |
| 32–33 | Hidden hands, top stack card/count, card strings, chronological protected values | Models preserve server values; parsing and UI tests |
| 33–34 | Legal captures/discards/steals/extensions and endgame auto-draw behavior | UI uses server actions and snapshots; no competing client game engine |
| 35–39 | Riverpod example behavior | Integrated into the project's existing controller/screen architecture rather than copying illustrative snippets verbatim |
| 40–41 | Common gotchas | WebSocket, IDs, token validation, casing, rate limits, required profile name and reconnect behavior covered |

## Features implemented but not fully operational/verified

1. **Facebook:** `FACEBOOK_ENABLED` defaults to false. Real Meta App ID/client token, platform registration, signing hashes and tester role are needed. iOS Limited Login requires an additional backend token-verification contract. Mocked Facebook response parsing does not establish successful real SDK login.
2. **Push:** `FIREBASE_ENABLED` defaults to false. Client Firebase settings and backend Firebase credentials are required; iOS also needs APNs configuration. Device API tests do not establish actual notification delivery.
3. **HTTPS deep links:** Native intake and reset/verification/referral routing exist. Domain association files must be deployed and Android signing fingerprints confirmed. Manual email-link entry remains available.
4. **AI-turn reconnect race:** Earlier live QA reproduced a stale server snapshot restoring obsolete player identity. The app detects the missing identity and retries reclaim, but a targeted recovery returned `Player not found`. Server-side serialization needs fixing; it was not retested or fixed in this audit.
5. **Real account persistence:** Still perform a completed game with a valid account JWT and compare `/api/auth/me`, history and leaderboard. No real account credentials were provided for this check.

## Conflicting guide passages and implementation decisions

- Page 7 explicitly permits guest play; pages 19–24 describe authenticated waiting-list gating. Guests retain gameplay and signed-in accounts use `canPlay`. Product/backend owners must confirm this is the intended launch policy.
- Page 11 says email cannot be edited; page 14 says email-less Facebook users should add email with the same PATCH endpoint. The UI attempts this only when email is absent and reports when the returned account still lacks an email. Backend support needs confirmation.
- Page 8 lists `user`/`admin` roles; page 13 uses `player`. Mobile access is not derived from role.
- The 401 guidance is broad, but change-password also uses 401 for a wrong current password. The app validates the session independently before logging the user out in that case.
- The example dependency versions are illustrative. The project uses its locked compatible dependencies; runtime contracts, analysis and tests are checked instead of downgrading to older example versions.

## App areas outside this documentation

This PDF does not define wallet balances, purchases, XP rewards, quest completion, clans, global player discovery, personal chat, issue submission or WhatsApp login. Existing Dukan/quest/social screens contain static or local behavior and should not be represented as completed backend features. The room-chat socket extension is also outside this guide and has no live verification in this audit. These require separate product/API specifications.

## Changes made by this audit

Added this traceable audit report. No new API differences or core implementation gap requiring a runtime change was established. Existing in-progress changes were preserved; provider flags remain disabled until real configuration is available.

See `api-guide-integration.md` for setup instructions and `game-recovery-server-requirements.md` for the server follow-up.
