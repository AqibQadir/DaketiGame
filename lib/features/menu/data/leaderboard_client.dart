import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/backend_config.dart';
import '../../game/data/game_api_exception.dart';

class LeaderboardEntry {
  const LeaderboardEntry(
      {required this.name,
      required this.gamesPlayed,
      required this.gamesWon,
      required this.totalScore});
  final String name;
  final int gamesPlayed;
  final int gamesWon;
  final int totalScore;
}

class LeaderboardClient {
  LeaderboardClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<LeaderboardEntry>> load({int limit = 20}) async {
    final response = await _client.get(
        Uri.parse('${BackendConfig.serverUrl}/api/leaderboard?limit=$limit'));
    final body = jsonDecode(response.body);
    if (body is! Map ||
        response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] == false) {
      throw GameApiException(
          body is Map
              ? body['error']?.toString() ?? 'Unable to load leaderboard.'
              : 'Invalid server response.',
          statusCode: response.statusCode);
    }
    return (body['leaderboard'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => LeaderboardEntry(
              name: item['name']?.toString() ?? 'Player',
              gamesPlayed: (item['games_played'] as num?)?.toInt() ?? 0,
              gamesWon: (item['games_won'] as num?)?.toInt() ?? 0,
              totalScore: (item['total_score'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);
  }

  void dispose() => _client.close();
}
