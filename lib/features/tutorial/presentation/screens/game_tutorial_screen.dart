import '../../../../core/widgets/game_styled_dialog.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_dialog_title.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../game/domain/models/game_card.dart';
import '../../../game/presentation/widgets/fanned_card_hand.dart';
import '../../domain/tutorial_demo_state.dart';
import '../../domain/tutorial_step.dart';
import '../controllers/tutorial_controller.dart';
import '../widgets/tutorial_overlay.dart';

class GameTutorialScreen extends StatefulWidget {
  const GameTutorialScreen({
    super.key,
    this.returnRoute = AppRoutes.welcome,
  });

  final String returnRoute;

  @override
  State<GameTutorialScreen> createState() => _GameTutorialScreenState();
}

class _GameTutorialScreenState extends State<GameTutorialScreen> {
  late final TutorialController controller;

  @override
  void initState() {
    super.initState();
    controller = TutorialController()..addListener(_refresh);
  }

  @override
  void dispose() {
    controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _exit({required bool completed}) async {
    if (completed) await controller.complete();
    if (!mounted) return;
    if (widget.returnRoute != AppRoutes.welcome && Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, widget.returnRoute);
    }
  }

  Future<void> _confirmSkip() async {
    final skip = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameStyledDialog(
        backgroundColor: const Color(0xF2181411),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.orange),
        ),
        title: const GameDialogTitle('SKIP TUTORIAL?'),
        content: const Text('Are you sure you want to skip the tutorial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue Tutorial'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Skip',
              style: TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
    if (skip == true) await _exit(completed: true);
  }

  Rect _targetRect(TutorialTarget target) => switch (target) {
        TutorialTarget.table => const Rect.fromLTWH(170, 55, 505, 265),
        TutorialTarget.hand => const Rect.fromLTWH(375, 270, 360, 112),
        TutorialTarget.turn => const Rect.fromLTWH(478, 92, 132, 42),
        TutorialTarget.handCard => const Rect.fromLTWH(405, 277, 66, 96),
        TutorialTarget.tableCards => const Rect.fromLTWH(342, 143, 175, 78),
        TutorialTarget.actions => const Rect.fromLTWH(674, 236, 156, 92),
        TutorialTarget.ownStack => const Rect.fromLTWH(292, 283, 62, 88),
        TutorialTarget.opponentStack => const Rect.fromLTWH(654, 119, 62, 88),
        TutorialTarget.blockedCard => const Rect.fromLTWH(405, 277, 66, 96),
        TutorialTarget.score => const Rect.fromLTWH(244, 270, 112, 102),
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppAssets.tableBackground, fit: BoxFit.cover),
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 844,
                  height: 390,
                  child: Stack(
                    children: [
                      _TutorialTable(demo: controller.demo),
                      TutorialOverlay(
                        step: controller.step,
                        stepIndex: controller.stepIndex,
                        stepCount: controller.stepCount,
                        targetRect: _targetRect(controller.step.target),
                        canAdvance: controller.canAdvance,
                        isFirst: controller.isFirst,
                        isLast: controller.isLast,
                        onTargetTap: controller.targetTapped,
                        onNext: controller.next,
                        onBack: controller.back,
                        onRestart: controller.restart,
                        onSkip: _confirmSkip,
                        onFinish: () => _exit(completed: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _TutorialTable extends StatelessWidget {
  const _TutorialTable({required this.demo});

  final TutorialDemoState demo;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned(
            left: 14,
            top: 12,
            child: _InfoChip(icon: Icons.group, text: '2/2'),
          ),
          const Positioned(
            left: 14,
            top: 54,
            child: _InfoChip(icon: Icons.casino, text: 'DEMO · ROUND 1'),
          ),
          Positioned(
            left: 355,
            top: 20,
            child: _PlayerBadge(
              name: 'HAMZA',
              score: demo.opponentScore,
              active: !demo.isPlayersTurn,
            ),
          ),
          Positioned(
            right: 128,
            top: 116,
            child: _StackPile(
              cards: demo.opponentStack,
              label: 'OPPONENT',
            ),
          ),
          Positioned(
            left: 290,
            top: 140,
            width: 280,
            height: 82,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final card in demo.table) ...[
                  _TutorialCard(card: card, width: 49, height: 70),
                  const SizedBox(width: 8),
                ],
                const SizedBox(width: 7),
                const _TutorialCard(
                  card: GameCard(id: 'hidden', value: '', suit: ''),
                  width: 49,
                  height: 70,
                ),
              ],
            ),
          ),
          Positioned(
            left: 478,
            top: 92,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: demo.isPlayersTurn
                    ? const Color(0xE0266B36)
                    : const Color(0xE06E2822),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cream),
              ),
              child: Text(
                demo.isPlayersTurn ? 'YOUR TURN · 20' : 'HAMZA’S TURN · 18',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          Positioned(
            left: 292,
            bottom: 18,
            child: _StackPile(cards: demo.ownStack, label: 'YOUR STACK'),
          ),
          Positioned(
            left: 244,
            bottom: 9,
            child: _PlayerBadge(
              name: 'YOU',
              score: demo.playerScore,
              active: demo.isPlayersTurn,
            ),
          ),
          Positioned(
            left: 375,
            right: 109,
            bottom: 8,
            height: 116,
            child: FannedCardHand(
              cards: demo.hand,
              selectedCardId: demo.selectedCardId,
              enabled: false,
              onCardTap: (_) {},
              cardBuilder: (context, card, selected) => _TutorialCard(
                card: card,
                width: 61,
                height: 91,
                selected: selected,
              ),
            ),
          ),
          if (demo.selectedCardId != null && demo.isPlayersTurn)
            Positioned(
              right: 14,
              bottom: 62,
              width: 154,
              child: Column(
                children: [
                  GameButton(
                    text: demo.selectedCardId == '9C'
                        ? 'Add to own deck'
                        : 'Play card',
                    width: 150,
                    onTap: () {},
                  ),
                  const SizedBox(height: 4),
                  const GameButton(
                    text: 'End turn',
                    width: 150,
                    onTap: _ignoreTap,
                  ),
                ],
              ),
            ),
          if (demo.message != null)
            Positioned(
              left: 338,
              top: 230,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xED8B211B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white54),
                ),
                child: Text(
                  demo.message!,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xD9151713),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFC58B43)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.cream),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 9)),
          ],
        ),
      );
}

class _PlayerBadge extends StatelessWidget {
  const _PlayerBadge({
    required this.name,
    required this.score,
    required this.active,
  });

  final String name;
  final int score;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        width: 112,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xE0161713),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.orange : const Color(0xFF75532E),
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(AppAssets.playerAvatar),
            ),
            const SizedBox(height: 3),
            Text(name, style: const TextStyle(fontSize: 9)),
            Text(
              '$score PTS',
              style: const TextStyle(
                color: AppColors.cream,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _StackPile extends StatelessWidget {
  const _StackPile({required this.cards, required this.label});

  final List<GameCard> cards;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 62,
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (cards.isEmpty)
              Container(
                width: 54,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white24),
                ),
              )
            else ...[
              if (cards.length > 1)
                Positioned(
                  left: 5,
                  top: 5,
                  child:
                      _TutorialCard(card: cards.first, width: 49, height: 70),
                ),
              _TutorialCard(card: cards.last, width: 49, height: 70),
              Positioned(
                right: 4,
                bottom: 13,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: const Color(0xE0181512),
                  child: Text('${cards.length}',
                      style: const TextStyle(fontSize: 8)),
                ),
              ),
            ],
            Positioned(
              bottom: 0,
              left: -8,
              right: -8,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 7, color: AppColors.cream),
              ),
            ),
          ],
        ),
      );
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.card,
    required this.width,
    required this.height,
    this.selected = false,
  });

  final GameCard card;
  final double width;
  final double height;
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? const Color(0xFFFFC75D) : const Color(0xFF59401D),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            const BoxShadow(
                color: Colors.black87, blurRadius: 5, offset: Offset(2, 3)),
            if (selected)
              const BoxShadow(color: Color(0xFFD99638), blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.asset(
            card.isHidden ? AppAssets.cardBack : _cardAsset(card),
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
}

String _cardAsset(GameCard card) {
  final suit = switch (card.suit) {
    'C' => 'Clubs',
    'D' => 'Diamonds',
    'H' => 'Hearts',
    'S' => 'Spades',
    _ => 'Clubs',
  };
  final value = switch (card.value) {
    'A' => 'Ace',
    'K' when card.suit == 'S' => 'KIng',
    'K' => 'King',
    'Q' => 'Queen',
    'J' => 'Jack',
    'T' => '10',
    _ => card.value,
  };
  return 'assets/images/cards/style01/$suit/$value.png';
}

void _ignoreTap() {}
