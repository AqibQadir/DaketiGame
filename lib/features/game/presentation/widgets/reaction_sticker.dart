import 'package:flutter/material.dart';
import '../../domain/models/game_reaction.dart';

/// Shared artwork for the reaction picker and player bubbles.
class ReactionSticker extends StatelessWidget {
  const ReactionSticker({super.key, required this.reaction, this.size = 32});
  final GameReaction reaction;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: reaction.caption,
        child: Image.asset(
          'assets/images/stickers/${reaction.name}.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      );
}
