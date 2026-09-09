enum TutorialTarget {
  table,
  hand,
  turn,
  handCard,
  tableCards,
  actions,
  ownStack,
  opponentStack,
  blockedCard,
  score,
}

class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.instruction,
    required this.target,
    this.requiresTargetTap = false,
  });

  final String title;
  final String instruction;
  final TutorialTarget target;
  final bool requiresTargetTap;
}

const tutorialSteps = <TutorialStep>[
  TutorialStep(
    title: 'GAME OVERVIEW',
    instruction:
        'This is the game table. Your cards, captured stack, opponents, score, and the shared table all stay visible here.',
    target: TutorialTarget.table,
  ),
  TutorialStep(
    title: 'THIS IS YOUR HAND',
    instruction:
        'These are the cards available to you. The server decides which moves are legal for each card.',
    target: TutorialTarget.hand,
  ),
  TutorialStep(
    title: 'IT IS YOUR TURN',
    instruction:
        'The highlighted turn indicator and timer show when you may act. You cannot play while another player has the turn.',
    target: TutorialTarget.turn,
  ),
  TutorialStep(
    title: 'SELECT A CARD',
    instruction: 'Tap the highlighted 7 of hearts in your hand.',
    target: TutorialTarget.handCard,
    requiresTargetTap: true,
  ),
  TutorialStep(
    title: 'CAPTURE FROM THE TABLE',
    instruction:
        'The legal-action list allows this capture. Tap the highlighted matching table card to perform it.',
    target: TutorialTarget.tableCards,
    requiresTargetTap: true,
  ),
  TutorialStep(
    title: 'LEGAL MOVE CONTROLS',
    instruction:
        'After selecting a card, compact controls list every move approved by the server. Tap the highlighted move.',
    target: TutorialTarget.actions,
    requiresTargetTap: true,
  ),
  TutorialStep(
    title: 'EXTEND YOUR STACK',
    instruction:
        'When the server offers this move, tap your captured stack to add the selected card.',
    target: TutorialTarget.ownStack,
    requiresTargetTap: true,
  ),
  TutorialStep(
    title: 'STEAL A STACK',
    instruction:
        'When steal is a legal move, select the card and tap the highlighted opponent stack.',
    target: TutorialTarget.opponentStack,
    requiresTargetTap: true,
  ),
  TutorialStep(
    title: 'INVALID MOVE',
    instruction:
        'It is now the opponent’s turn. Tap your highlighted card to see why the move is blocked.',
    target: TutorialTarget.blockedCard,
    requiresTargetTap: true,
  ),
  TutorialStep(
    title: 'SCORES AND RESULTS',
    instruction:
        'Scores come from the server. At game over, your player ID means you win, another ID means you lose, and “draw” means a draw.',
    target: TutorialTarget.score,
  ),
];
