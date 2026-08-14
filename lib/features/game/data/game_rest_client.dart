import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models/daketi_game.dart';
import 'game_api_exception.dart';

class CreatedGame {
  const CreatedGame({required this.gameId, required this.game});

  final String gameId;
  final DaketiGame game;
}

class GameRestClient {
  GameRestClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<bool> healthCheck() async {
    final response = await _client.get(Uri.parse('$baseUrl/health'));
    final data = _decode(response);
    return data['status'] == 'ok';
  }

  Future<CreatedGame> createSoloGame({
    required String playerName,
    int aiCount = 1,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/game/solo'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'playerName': playerName, 'aiCount': aiCount}),
    );
    return _createdGameFromResponse(response);
  }

  Future<CreatedGame> createMultiplayerRoom({
    required String playerName,
    int maxPlayers = 4,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/game/multiplayer'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'playerName': playerName,
        'maxPlayers': maxPlayers,
      }),
    );
    return _createdGameFromResponse(response);
  }

  Future<DaketiGame> getGame(String gameId) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/game/$gameId'));
    final data = _decode(response);
    return DaketiGame.fromJson(_map(data['gameState'], 'gameState'));
  }

  CreatedGame _createdGameFromResponse(http.Response response) {
    final data = _decode(response);
    return CreatedGame(
      gameId: data['gameId']?.toString() ?? '',
      game: DaketiGame.fromJson(_map(data['gameState'], 'gameState')),
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = _map(jsonDecode(response.body), 'response');
    } on FormatException {
      throw GameApiException(
        'The game server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GameApiException(
        data['error']?.toString() ?? 'Game server request failed.',
        statusCode: response.statusCode,
      );
    }
    if (data['success'] == false) {
      throw GameApiException(data['error']?.toString() ?? 'Request failed.');
    }
    return data;
  }

  Map<String, dynamic> _map(Object? value, String name) {
    if (value is! Map) {
      throw FormatException('$name is not an object');
    }
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  void dispose() => _client.close();
}
