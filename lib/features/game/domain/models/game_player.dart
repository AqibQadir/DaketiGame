import 'game_card.dart';

class GamePlayer {
  const GamePlayer({
    required this.id,
    required this.name,
    required this.type,
    required this.hand,
    required this.handCount,
    required this.stack,
    required this.stackCount,
    required this.topCard,
    required this.score,
    required this.isConnected,
    required this.isReady,
  });

  final String id;
  final String name;
  final String type;
  final List<GameCard> hand;
  final int handCount;
  final List<GameCard> stack;
  final int stackCount;
  final GameCard? topCard;
  final int score;
  final bool isConnected;
  final bool isReady;

  bool get isAi => type == 'ai';

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    List<GameCard> cards(Object? value) {
      return (value as List<dynamic>? ?? const [])
          .map((item) => GameCard.fromId(item.toString()))
          .toList(growable: false);
    }

    final topCardId = json['topCard']?.toString();
    return GamePlayer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Player',
      type: json['type']?.toString() ?? 'human',
      hand: cards(json['hand']),
      handCount: (json['handCount'] as num?)?.toInt() ?? 0,
      stack: cards(json['stack']),
      stackCount: (json['stackCount'] as num?)?.toInt() ?? 0,
      topCard: topCardId == null || topCardId.isEmpty
          ? null
          : GameCard.fromId(topCardId),
      score: (json['score'] as num?)?.toInt() ?? 0,
      isConnected: json['isConnected'] as bool? ?? false,
      isReady: json['isReady'] as bool? ?? false,
    );
  }
}
