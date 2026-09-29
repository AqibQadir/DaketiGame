import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreviousGame {
  const PreviousGame(
      {required this.gameId,
      required this.playerName,
      required this.playerId,
      this.ownerToken,
      this.isMultiplayer = false});

  final String gameId;
  final String playerName;
  final String playerId;
  final String? ownerToken;
  final bool isMultiplayer;
}

/// Keep the room across app restarts, scoped to the identity that joined it.
class PreviousGameStorage {
  static const _key = 'daketi_previous_game';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<PreviousGame?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return PreviousGame(
          gameId: data['gameId'] as String,
          playerName: data['playerName'] as String,
          playerId: data['playerId'] as String,
          ownerToken: data['ownerToken'] as String?,
          isMultiplayer: data['isMultiplayer'] == true);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> write(PreviousGame game) => _storage.write(
      key: _key,
      value: jsonEncode({
        'gameId': game.gameId,
        'playerName': game.playerName,
        'playerId': game.playerId,
        'isMultiplayer': game.isMultiplayer,
        'ownerToken': game.ownerToken
      }));

  Future<void> clear() => _storage.delete(key: _key);
}
