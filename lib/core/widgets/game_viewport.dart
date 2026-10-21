import 'package:flutter/material.dart';

/// Scales one design canvas uniformly on every device. Any spare space stays
/// outside the canvas so cards, controls and their spacing keep their proportions.
class GameViewport extends StatelessWidget {
  const GameViewport({
    super.key,
    required this.child,
    this.designSize = const Size(844, 390),
  });

  static const canvasKey = ValueKey<String>('game-board-canvas');

  final Widget child;
  final Size designSize;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // The approved composition uses the full display. Insetting this entire
    // canvas for a cutout shrinks every card and moves all controls inward.
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: SizedBox(
          key: canvasKey,
          width: designSize.width,
          height: designSize.height,
          child: MediaQuery(
            // Descendants lay out in design units, not physical screen units.
            // Device padding must not inset the full-screen composition.
            data: media.copyWith(
              size: designSize,
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
              textScaler: TextScaler.noScaling,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
