import '../../game/domain/models/game_card.dart';

class TutorialDemoState {
  const TutorialDemoState({
    required this.hand,
    required this.table,
    required this.ownStack,
    required this.opponentStack,
    required this.selectedCardId,
    required this.isPlayersTurn,
    required this.playerScore,
    required this.opponentScore,
    required this.message,
  });

  final List<GameCard> hand;
  final List<GameCard> table;
  final List<GameCard> ownStack;
  final List<GameCard> opponentStack;
  final String? selectedCardId;
  final bool isPlayersTurn;
  final int playerScore;
  final int opponentScore;
  final String? message;

  factory TutorialDemoState.forStep(int step) {
    final captured = step >= 5;
    final extended = step >= 7;
    final stolen = step >= 8;
    return TutorialDemoState(
      hand: [
        if (!captured) GameCard.fromId('7H'),
        if (!extended) GameCard.fromId('9C'),
        GameCard.fromId('JS'),
        GameCard.fromId('QD'),
      ],
      table: [
        GameCard.fromId('4C'),
        if (!captured) GameCard.fromId('7D'),
        GameCard.fromId('TS'),
      ],
      ownStack: [
        GameCard.fromId('7D'),
        if (captured) GameCard.fromId('7H'),
        if (extended) GameCard.fromId('9C'),
      ],
      opponentStack: stolen
          ? const <GameCard>[]
          : [GameCard.fromId('JS'), GameCard.fromId('JH')],
      selectedCardId: switch (step) {
        3 || 4 => '7H',
        5 || 6 => '9C',
        7 => 'JS',
        _ => null,
      },
      isPlayersTurn: step != 8,
      playerScore: step >= 9 ? 25 : (captured ? 15 : 5),
      opponentScore: step >= 9 ? 18 : 10,
      message: step == 8 ? 'Not allowed: wait for your turn.' : null,
    );
  }
}
