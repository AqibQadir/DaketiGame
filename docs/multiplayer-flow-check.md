# Multiplayer flow check — 2026-09-29

Checked the Flutter room flow against the regular game's shared GameScreen and
GameController. No backend source is present, so these are app tests with simulated
server responses, not a live multi-device acceptance run.

| Step | App-side result |
| --- | --- |
| Guest identity and room creation | Guest form now returns to the pending room operation and retains chosen capacity. |
| Room code entry | Four-digit validation, paste, leading zero and deletion tests pass. |
| Waiting and Ready | 2-, 3- and 4-player layouts pass; duplicate Ready is guarded; failed Ready can retry. |
| Starting | Already-started rooms open immediately; a late join/Ready acknowledgement cannot undo game_started. |
| Board and dealing | All three player counts use the same board, real human names, local hand and opening animation. Fixed player-count label overflow. |
| Card actions | Selecting a card exposes server-provided capture, steal, extend and discard controls; UI dispatch tests pass. Rules remain server-authoritative. |
| Presentation | Existing deal, steal overlay, steal count and table-slot regressions pass. |
| Rejoining | Mode survives restart; rejoin skips the opening hand/table deal. Already-expired local turns trigger timeout once. |
| Results and replay | Shared score/rank layout remains; multiplayer Play again returns to room setup instead of silently starting solo. A new room/code is required; automatic rematch is not implemented. |
| Regular game regression | Table difficulty selection, solo results layout and guest navigation tests pass. |

Validation: 61 targeted tests passed. Analysis of changed app areas and tests found
no issues. Whole-project analysis still reports the pre-existing TickerMode.of
deprecation in looping_video_background.dart.

Still requires the actual server and multiple clients: synchronized turn authority,
AI taking over offline players, secure same-seat reclaim, and expiry/reconnect races.
See game-recovery-server-requirements.md for those acceptance checks.
