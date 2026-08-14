enum GameActionType {
  captureTable,
  stealOpponent,
  extendStack,
  discard,
  unknown
}

class GameAction {
  const GameAction({
    required this.type,
    required this.cardId,
    this.targetPlayerId,
  });

  final GameActionType type;
  final String cardId;
  final String? targetPlayerId;

  factory GameAction.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type']?.toString()) {
      'capture_table' => GameActionType.captureTable,
      'steal_opponent' => GameActionType.stealOpponent,
      'extend_stack' => GameActionType.extendStack,
      'discard' => GameActionType.discard,
      _ => GameActionType.unknown,
    };
    return GameAction(
      type: type,
      cardId: json['cardId']?.toString() ?? '',
      targetPlayerId: json['targetPlayerId']?.toString(),
    );
  }
}
