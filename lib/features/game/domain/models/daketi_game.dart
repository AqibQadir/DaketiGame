import 'game_card.dart';
import 'game_player.dart';

enum DaketiGameStatus { waiting, playing, finished, unknown }

class DaketiGame {
  const DaketiGame({
    required this.gameId,
    required this.status,
    required this.players,
    required this.maxPlayers,
    required this.table,
    required this.deckCount,
    required this.currentTurn,
    required this.currentPlayerId,
    required this.turnStartTime,
    required this.turnTimeLimit,
    required this.dealer,
    required this.round,
    required this.protectedValues,
    required this.winner,
  });

  final String gameId;
  final DaketiGameStatus status;
  final List<GamePlayer> players;
  final int maxPlayers;
  final List<GameCard> table;
  final int currentTurn;
  final int deckCount;
  final String? currentPlayerId;
  final int? turnStartTime;
  final int turnTimeLimit;
  final int dealer;
  final int round;
  final List<String> protectedValues;
  final String? winner;

  GamePlayer? playerById(String? id) {
    if (id == null) return null;
    for (final player in players) {
      if (player.id == id) return player;
    }
    return null;
  }

  factory DaketiGame.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString();
    final status = switch (rawStatus) {
      'waiting' => DaketiGameStatus.waiting,
      'playing' => DaketiGameStatus.playing,
      'finished' => DaketiGameStatus.finished,
      _ => DaketiGameStatus.unknown,
    };
    return DaketiGame(
      gameId: json['gameId']?.toString() ?? '',
      status: status,
      players: (json['players'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GamePlayer.fromJson)
          .toList(growable: false),
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 0,
      table: (json['table'] as List<dynamic>? ?? const [])
          .map((item) => GameCard.fromId(item.toString()))
          .toList(growable: false),
      deckCount: (json['deckCount'] as num?)?.toInt() ?? 0,
      currentTurn: (json['currentTurn'] as num?)?.toInt() ?? 0,
      currentPlayerId: json['currentPlayerId']?.toString(),
      turnStartTime: (json['turnStartTime'] as num?)?.toInt(),
      turnTimeLimit: (json['turnTimeLimit'] as num?)?.toInt() ?? 30,
      dealer: (json['dealer'] as num?)?.toInt() ?? 0,
      round: (json['round'] as num?)?.toInt() ?? 1,
      protectedValues: (json['protectedValues'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      winner: json['winner']?.toString(),
    );
  }
}
