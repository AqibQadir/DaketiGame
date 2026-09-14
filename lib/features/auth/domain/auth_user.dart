class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.role,
    this.dateOfBirth,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final bool emailVerified;
  final String role;
  final String? dateOfBirth;
  final DateTime? createdAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        emailVerified: json['emailVerified'] == true,
        role: json['role']?.toString() ?? 'user',
        dateOfBirth: json['dateOfBirth']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class AuthStats {
  const AuthStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.totalScore = 0,
  });

  final int gamesPlayed;
  final int gamesWon;
  final int totalScore;

  factory AuthStats.fromJson(Map<String, dynamic> json) => AuthStats(
        gamesPlayed: (json['games_played'] as num?)?.toInt() ?? 0,
        gamesWon: (json['games_won'] as num?)?.toInt() ?? 0,
        totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      );
}

class GameHistoryEntry {
  const GameHistoryEntry({
    required this.gameId,
    required this.playerName,
    required this.score,
    required this.isWinner,
    required this.maxPlayers,
    required this.playedAt,
    required this.opponents,
  });

  final String gameId;
  final String playerName;
  final int score;
  final bool isWinner;
  final int maxPlayers;
  final DateTime? playedAt;
  final List<GameHistoryOpponent> opponents;

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) =>
      GameHistoryEntry(
        gameId: json['game_id']?.toString() ?? '',
        playerName: json['player_name']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        isWinner: json['is_winner'] == true,
        maxPlayers: (json['max_players'] as num?)?.toInt() ?? 0,
        playedAt: DateTime.tryParse(json['played_at']?.toString() ?? ''),
        opponents: (json['opponents'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => GameHistoryOpponent.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value))))
            .toList(growable: false),
      );
}

class GameHistoryOpponent {
  const GameHistoryOpponent({
    required this.name,
    required this.type,
    required this.score,
    required this.isWinner,
  });

  final String name;
  final String type;
  final int score;
  final bool isWinner;

  factory GameHistoryOpponent.fromJson(Map<String, dynamic> json) =>
      GameHistoryOpponent(
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        isWinner: json['isWinner'] == true,
      );
}
