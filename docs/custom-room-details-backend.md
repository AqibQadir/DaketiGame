# Custom-room name and city integration

The host setup now requires a room name (trimmed, maximum 40 characters) and selection of one of the existing ten cities. These are currently host-side presentation details, keyed to the created game ID, and shown on that host's waiting screen.

The documented `POST /api/game/multiplayer` accepts only `playerName` and `maxPlayers`. Flutter continues to send this documented payload. It does not claim room names or city choices are saved by the server, visible to joining players, or restored after app restart.

To share these details, please define the room-name/city request fields and return the authoritative values in creation responses and room/game snapshots, including reconnects. City choices in this project are Lahore, Karachi, Multan, Islamabad, Faisalabad, Peshawar, Quetta, Gujranwala, Sialkot and Hyderabad. Agree stable server IDs before wiring the payload. Validate the room name and city server-side. The existing four-digit join code remains the room identity.
