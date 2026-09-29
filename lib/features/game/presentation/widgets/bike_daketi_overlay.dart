import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/game_card.dart';

class BikeDaketiOverlay extends StatefulWidget {
  const BikeDaketiOverlay({
    super.key,
    required this.source,
    required this.destination,
    required this.cardCount,
    required this.cards,
    required this.onComplete,
    this.isLocalVictim = false,
  });

  final Offset source;
  final Offset destination;
  final int cardCount;
  final List<GameCard> cards;
  final VoidCallback onComplete;
  final bool isLocalVictim;

  @override
  State<BikeDaketiOverlay> createState() => _BikeDaketiOverlayState();
}

class _BikeDaketiOverlayState extends State<BikeDaketiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2150),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      })
      ..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  double interval(double start, double end) =>
      ((controller.value - start) / (end - start)).clamp(0.0, 1.0);

  Offset ridePath(double t) {
    final start = Offset(-120, widget.source.dy + 15);
    final end = widget.destination + const Offset(165, -5);
    final control = Offset(
      widget.source.dx,
      math.min(widget.source.dy, widget.destination.dy) - 65,
    );
    final inverse = 1 - t;
    return Offset(
      inverse * inverse * start.dx +
          2 * inverse * t * control.dx +
          t * t * end.dx,
      inverse * inverse * start.dy +
          2 * inverse * t * control.dy +
          t * t * end.dy,
    );
  }

  Offset cardPath(double t, int index) {
    final staggered = (t - index * .055).clamp(0.0, 1.0);
    final eased = Curves.easeInOutCubic.transform(staggered);
    final control = Offset(
      (widget.source.dx + widget.destination.dx) / 2 + 55,
      math.min(widget.source.dy, widget.destination.dy) - 85 - index * 7,
    );
    final inverse = 1 - eased;
    return Offset(
      inverse * inverse * widget.source.dx +
          2 * inverse * eased * control.dx +
          eased * eased * widget.destination.dx,
      inverse * inverse * widget.source.dy +
          2 * inverse * eased * control.dy +
          eased * eased * widget.destination.dy,
    );
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final dimIn = Curves.easeOut.transform(interval(0, .12));
              final dimOut = 1 - Curves.easeIn.transform(interval(.72, 1));
              final ride = Curves.easeInOutCubic.transform(interval(.05, .72));
              final cards = Curves.easeInOutCubic.transform(interval(.27, .76));
              final stampIn = Curves.elasticOut.transform(interval(.68, .84));
              final stampOut = 1 - interval(.91, 1);
              final shakeStrength = (1 - interval(.18, .38)) *
                  math.sin(controller.value * math.pi * 18) *
                  7;
              final bikePosition = ridePath(ride);
              final shownCards = widget.cards.length.clamp(0, 4);
              final visibleCards = widget.cards.length <= shownCards
                  ? widget.cards
                  : widget.cards.sublist(widget.cards.length - shownCards);

              return Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: .48 * dimIn * dimOut,
                      ),
                    ),
                  ),
                  if (controller.value < .48)
                    Positioned(
                      left: widget.source.dx - 43 + shakeStrength,
                      top: widget.source.dy - 43,
                      child: const _VictimShock(),
                    ),
                  for (var index = 0; index < shownCards; index++)
                    if (controller.value >= .25 && controller.value <= .84)
                      Positioned(
                        left: cardPath(cards, index).dx - 15,
                        top: cardPath(cards, index).dy - 21,
                        child: Transform.rotate(
                          angle: math.sin(cards * math.pi * 5 + index) * .18,
                          child: _FlyingCard(card: visibleCards[index]),
                        ),
                      ),
                  Positioned(
                    left: bikePosition.dx - 140,
                    top: bikePosition.dy - 85,
                    child: Transform.rotate(
                      angle: math.sin(ride * math.pi) * -.07,
                      child: Image.asset(
                        'assets/images/steal_bike_animation.gif',
                        width: 280,
                        height: 124,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        semanticLabel:
                            'Opponents escaping on a motorcycle with stolen cards',
                      ),
                    ),
                  ),
                  if (controller.value >= .66)
                    Center(
                      child: Opacity(
                        opacity: stampIn.clamp(0.0, 1.0) * stampOut,
                        child: Transform.scale(
                          scale: .65 + .35 * stampIn,
                          child: Transform.rotate(
                            angle: -.055,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xEBD64D15),
                                border: Border.all(
                                  color: const Color(0xFFFFC75D),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black87,
                                    blurRadius: 14,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.isLocalVictim
                                        ? 'YOU WERE ROBBED!'
                                        : 'DAKETI!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Dirty Brush',
                                      fontSize: 38,
                                      height: .9,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    widget.isLocalVictim
                                        ? '${widget.cardCount} ${widget.cardCount == 1 ? 'CARD' : 'CARDS'} TAKEN FROM YOUR STACK'
                                        : '${widget.cardCount} ${widget.cardCount == 1 ? 'CARD' : 'CARDS'} STOLEN · MAAL GAYA!',
                                    style: const TextStyle(
                                      color: AppColors.cream,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
}

class _VictimShock extends StatelessWidget {
  const _VictimShock();

  @override
  Widget build(BuildContext context) => Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFC75D), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xAAFF6A00), blurRadius: 18),
          ],
        ),
        child: const Center(
          child: Icon(Icons.priority_high, color: Colors.white, size: 38),
        ),
      );
}

class _FlyingCard extends StatelessWidget {
  const _FlyingCard({required this.card});

  final GameCard card;

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1C9),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF6B3B17), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 5)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
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
    'K' => 'King',
    'Q' => 'Queen',
    'J' => 'Jack',
    'T' => '10',
    _ => card.value,
  };
  return 'assets/images/cards/style01/$suit/$value.png';
}
