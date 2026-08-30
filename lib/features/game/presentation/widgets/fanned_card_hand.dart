import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/game_card.dart';

typedef FannedCardBuilder = Widget Function(
  BuildContext context,
  GameCard card,
  bool selected,
);

/// Lays out a hand around one virtual pivot below its bottom-center.
///
/// Unlike a horizontally offset stack, every card uses the same angle for its
/// circular position and rotation. This makes the bottom edges converge while
/// the card tops form a smooth, responsive arc.
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
    this.selectedLift = 25,
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
      final halfArc =
          count == 1 ? 0.0 : (.11 * (count - 1)).clamp(.28, .62).toDouble();
      final angleStep = count <= 1 ? 0.0 : (halfArc * 2) / (count - 1);

      // Target 20-35% card exposure, then shrink the circle only if the hand
      // would exceed the available width.
      final desiredExposure = (cardWidth * .28).clamp(13.0, 21.0);
      final desiredRadius = angleStep == 0 ? 0.0 : desiredExposure / angleStep;
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : cardWidth + desiredRadius * 2;
      final horizontalRoom = math.max(0.0, width - cardWidth - 8);
      final maximumRadius =
          halfArc == 0 ? 0.0 : horizontalRoom / (2 * math.sin(halfArc));
      final radius = math.min(desiredRadius, maximumRadius);
      final centerX = width / 2;

      final indexes = List<int>.generate(count, (index) => index);
      final selectedIndex =
          cards.indexWhere((card) => card.id == selectedCardId);
      if (selectedIndex >= 0) {
        indexes.remove(selectedIndex);
        indexes.add(selectedIndex);
      }

      return Stack(
        clipBehavior: Clip.none,
        children: indexes.map((index) {
          final card = cards[index];
          final normalizedIndex = index - centerIndex;
          final angle = normalizedIndex * angleStep;
          final x = radius * math.sin(angle);
          final y = radius * (1 - math.cos(angle));
          final selected = card.id == selectedCardId;

          return AnimatedPositioned(
            key: ValueKey(card.id),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: centerX + x - cardWidth / 2,
            bottom: 2 + y + (selected ? selectedLift : 0),
            width: cardWidth,
            height: cardHeight,
            child: AnimatedScale(
              scale: selected ? 1.05 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
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
            ),
          );
        }).toList(growable: false),
      );
    });
  }
}
