# Reconnect contract and remaining backend checks

The 30 September 2026 API guide supersedes the earlier recovery assumptions.
The server issues a secret `reconnectToken` from `join_game`; the app stores it in
secure storage by game and sends it when rejoining. A successful reclaim returns
`reclaimed: true` and a **new** `playerId`. Hand, stack, score and ready state are
preserved. A valid account JWT provides a fallback when the seat token is absent.
The app must never require the old socket ID after a confirmed reclaim.

The app uses only documented gameplay APIs. Multiplayer Ready sends `{gameId}`;
Unready was removed after a live server probe confirmed that `isReady:false`
does not reverse readiness. No leave-room or server-timeout endpoint is invented.
Leaving the active session disposes its socket so old room events cannot leak
into the next game. A saved seat remains available from Home.

## Observed AI / reconnect race

During live QA, reconnecting while an AI turn was in flight sometimes produced a
later snapshot with the old player identity, removing the newly reclaimed ID.
A targeted live test reproduced this and the recovery returned `Player not found`.
The app now attempts seat reclaim again when its confirmed ID disappears from
the current room snapshot. It does not guess which hidden hand belongs to it.
The backend should serialize seat changes and AI saves using the latest state.

## Features not guaranteed by the supplied guide

The app cannot authoritatively advance an offline player's turn. The backend
must own turn deadlines, any AI takeover for disconnected humans, and locking
between timeout, AI and human actions. These features need separate server-side
implementation/verification; a local app timer alone does not provide them.

Checks for the backend owner:

1. Reconnect during each AI draw/capture/discard step; ensure subsequent snapshots
   retain the newly reclaimed ID and never duplicate or hide the human's seat.
2. Disconnect current players in two- and four-player games; verify the intended
   deadline and offline-player policy keeps the room moving.
3. Race an expiring turn with a human move and reconnect; only one legal action
   should be applied, and reconnect should not grant a new turn allowance.
4. Verify the same behavior across workers and process restarts.
5. Return an explicit not-found response for expired rooms so saved seats can be
   cleared; retain resumable seats through temporary connectivity failures.

See `api-guide-integration.md` for live smoke-test results and setup requirements.
