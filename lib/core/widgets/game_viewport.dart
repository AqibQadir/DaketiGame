import 'package:flutter/material.dart';

/// Fits the classic board to the full display without distorting its artwork.
/// The board already has edge spacing for its controls; applying SafeArea to
/// the entire canvas adds that spacing twice and shrinks every game element.
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
  Widget build(BuildContext context) => SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            key: canvasKey,
            width: designSize.width,
            height: designSize.height,
            child: child,
          ),
        ),
      );
}
