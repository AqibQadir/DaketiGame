import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/game_button.dart';
import '../../domain/tutorial_step.dart';

class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.stepCount,
    required this.targetRect,
    required this.canAdvance,
    required this.isFirst,
    required this.isLast,
    required this.onTargetTap,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
    required this.onRestart,
    required this.onFinish,
  });

  final TutorialStep step;
  final int stepIndex;
  final int stepCount;
  final Rect targetRect;
  final bool canAdvance;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTargetTap;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onRestart;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final bubbleOnLeft = targetRect.center.dx > 430;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                if (targetRect.inflate(8).contains(details.localPosition)) {
                  onTargetTap();
                }
              },
              child: CustomPaint(
                painter: _SpotlightPainter(targetRect: targetRect),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 322,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xEC15120F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orange),
              ),
              child: Text(
                'STEP ${stepIndex + 1} OF $stepCount',
                style: const TextStyle(
                  color: AppColors.cream,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 10,
            child: GameButton(
              text: 'Skip Tutorial',
              width: 155,
              onTap: onSkip,
            ),
          ),
          Positioned(
            left: bubbleOnLeft ? 20 : 505,
            top: 75,
            width: 315,
            child: _InstructionCard(step: step, pointsRight: bubbleOnLeft),
          ),
          Positioned(
            left: 270,
            bottom: 8,
            child: Row(
              children: [
                GameButton(
                  text: 'Back',
                  width: 105,
                  onTap: isFirst ? null : onBack,
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onRestart,
                  child: const Text(
                    'RESTART',
                    style: TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ),
                const SizedBox(width: 8),
                GameButton(
                  text: isLast ? 'Start Playing' : 'Next',
                  width: isLast ? 145 : 105,
                  onTap: isLast
                      ? onFinish
                      : canAdvance
                          ? onNext
                          : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.step, required this.pointsRight});

  final TutorialStep step;
  final bool pointsRight;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xF2181411),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.orange, width: 1.4),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 12),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontFamily: 'Dirty Brush',
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  step.instruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                if (step.requiresTargetTap) ...[
                  const SizedBox(height: 7),
                  const Text(
                    'TAP THE HIGHLIGHTED AREA TO CONTINUE',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 38,
            left: pointsRight ? null : -15,
            right: pointsRight ? -15 : null,
            child: Transform.rotate(
              angle: pointsRight ? 0 : 3.14159,
              child: const Icon(
                Icons.arrow_right_alt_rounded,
                color: AppColors.orange,
                size: 36,
              ),
            ),
          ),
        ],
      );
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.targetRect});

  final Rect targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final spotlight = Path()
      ..addRRect(RRect.fromRectAndRadius(
        targetRect.inflate(6),
        const Radius.circular(12),
      ));
    final shaded = Path.combine(PathOperation.difference, overlay, spotlight);
    canvas.drawPath(shaded, Paint()..color = const Color(0xA8000000));
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect.inflate(6), const Radius.circular(12)),
      Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect;
}
