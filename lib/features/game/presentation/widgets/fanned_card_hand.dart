import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/game_card.dart';

typedef FannedCardBuilder = Widget Function(
  BuildContext context,
  GameCard card,
  bool selected,
);

/// Presents the game's own card artwork as a classic overlapping hand.
///
/// Each card advances by a consistent amount so every top-left rank and suit
/// remains visible. A mild rotation and shallow center lift create the fan
/// without forcing the cards around an exaggerated circular arc.
class FannedCardHand extends StatelessWidget {
  const FannedCardHand({
    super.key,
    required this.cards,
    required this.selectedCardId,
    required this.enabled,
    required this.onCardTap,
    required this.cardBuilder,
    this.cardWidth = 61,
    this.cardHeight = 91,
    this.selectedLift = 14,
  });

  final List<GameCard> cards;
  final String? selectedCardId;
  final bool enabled;
  final ValueChanged<GameCard> onCardTap;
  final FannedCardBuilder cardBuilder;
  final double cardWidth;
  final double cardHeight;
  final double selectedLift;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.expand();

    return LayoutBuilder(builder: (context, constraints) {
      final count = cards.length;
      final centerIndex = (count - 1) / 2;
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : cardWidth + (count - 1) * cardWidth * .42;
      final availableStep = count <= 1
          ? 0.0
          : math.max(0.0, width - cardWidth - 8) / (count - 1);
      // A little under half-card exposure keeps each top corner readable while
      // giving the hand the tighter layered appearance from the reference.
      final exposure = count <= 1
          ? 0.0
          : math.min(cardWidth * .42, availableStep).toDouble();
      final handWidth = cardWidth + exposure * (count - 1);
      final startX = (width - handWidth) / 2;
      final centerX = width / 2;

      // Preserve the natural left-to-right paint order even when a card is
      // selected. Promoting the selected card above its neighbours makes the
      // exposed parts of those cards impossible to tap.
      final indexes = List<int>.generate(count, (index) => index);

      return Stack(
        clipBehavior: Clip.none,
        children: indexes.map((index) {
          final card = cards[index];
          final normalizedIndex = index - centerIndex;
          final angle = count <= 1 ? 0.0 : normalizedIndex * .12;
          final distanceFromCenter = normalizedIndex.abs();
          final centerLift = math.max(0.0, centerIndex - distanceFromCenter) * 3;
          final selected = card.id == selectedCardId;

          return AnimatedPositioned(
            key: ValueKey(card.id),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: count == 1
                ? centerX - cardWidth / 2
                : startX + index * exposure,
            bottom: 4 + centerLift + (selected ? selectedLift : 0),
            width: cardWidth,
            height: cardHeight,
            child: Transform.rotate(
              angle: angle,
              alignment: Alignment.bottomCenter,
              child: Semantics(
                button: enabled,
                selected: selected,
                label: '${card.value} of ${card.suit}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled ? () => onCardTap(card) : null,
                  child: cardBuilder(context, card, selected),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      );
    });
  }
}
