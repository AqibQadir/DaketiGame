# Remaining server work for uninterrupted multiplayer

The Flutter workspace has no server implementation. The app now retains a joined
room across disconnects and restarts, offers Join previous game on Home, validates
that rejoining restores the original player ID, and chooses the lowest legal
discard for a local timeout. Solo and multiplayer both use GameScreen.

This does not provide offline AI takeover. A client cannot advance an offline
player's turn authoritatively. The documented join_game API accepts gameId,
playerName and an optional account token; it does not document a resume credential
or an explicit seat-reclaim operation. Restoration must be verified against the
actual server implementation.

Required server behavior:

- Own every turn deadline independently of socket connectivity. On expiry, apply
  the smallest legal discard using the existing rank order (2 through A). If a
  discard is not legal, resolve required legal actions with the game's rules,
  then end the turn. Broadcast normal action and turn events for animations.
- Retain a disconnected player's seat, hand, stack, score and account association.
  AI handles their subsequent turns without blocking connected players.
- Reclaim the original seat after authentication. Use verified account identity
  for members and a server-issued opaque resume credential for guests; names
  alone cannot authorize reclaiming another player's hand. Return the original
  playerId and the latest authorized gameState. Coordinate any new credential
  fields with the Flutter storage and socket integration.
- Serialize deadline moves, human moves and reconnects per room/turn so a late
  client timeout or an old socket cannot play a second card for an expired turn.
- Preserve deadlines across process restart and multiple server workers, and
  remove jobs when the game completes. Rejoining must not reset the turn timer.
- Return a definitive expired/not-found response when a room cannot be resumed.

Acceptance checks on a running server:

1. Disconnect the current player in a two-player and a four-player game. Confirm
   a legal small card moves and the next player's turn starts on every device.
2. Leave that player offline for multiple rounds and confirm AI continues.
3. Kill/reopen the app, use Join previous game, and verify the same seat, hand,
   score and current state return without adding a new player to a full room.
4. Race reconnect and a manual move with expiry; confirm exactly one valid move.
5. Repeat with all phones disconnected and with a server restart.
6. Complete or expire the game while offline; confirm the app offers new play
   and removes the stale previous-game shortcut after checking the server.

## Ready / Unready toggle

The client now sends `player_ready` with `{gameId, isReady: true|false}`.
This extends the supplied API guide, which only documents `{gameId}` and marking
ready. Backend support for `isReady: false` is not verified. The server must apply
the requested value to the authenticated caller only while the room is waiting,
broadcast the updated `gameState`, and serialize this with automatic game start.
The client waits for server state before changing the button from Ready to yellow
Unready, or back. It does not locally claim that a player became unready.
