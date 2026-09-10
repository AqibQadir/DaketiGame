import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';

class OpeningDealOverlay extends StatefulWidget {
  const OpeningDealOverlay({
    super.key,
    required this.playerCount,
    required this.cardsPerPlayer,
    required this.onComplete,
  });

  final int playerCount;
  final int cardsPerPlayer;
  final VoidCallback onComplete;

  @override
  State<OpeningDealOverlay> createState() => _OpeningDealOverlayState();
}

class _OpeningDealOverlayState extends State<OpeningDealOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final List<Offset> destinations;

  int get dealCount =>
      (widget.playerCount * widget.cardsPerPlayer).clamp(1, 20);

  @override
  void initState() {
    super.initState();
    destinations = switch (widget.playerCount) {
      2 => const [Offset(515, 89), Offset(560, 330)],
      3 => const [Offset(126, 212), Offset(515, 89), Offset(560, 330)],
      _ => const [
          Offset(126, 212),
          Offset(515, 89),
          Offset(700, 212),
          Offset(560, 330),
        ],
    };
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 650 + dealCount * 82),
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

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final scaled = controller.value * dealCount;
              final cardIndex = scaled.floor().clamp(0, dealCount - 1);
              final cardProgress = Curves.easeOutCubic.transform(
                (scaled - cardIndex).clamp(0.0, 1.0),
              );
              final destination = destinations[cardIndex % destinations.length];
              const source = Offset(735, 175);
              final arcHeight = 42 + (cardIndex % 3) * 8;
              final position = Offset.lerp(source, destination, cardProgress)! +
                  Offset(0, -math.sin(cardProgress * math.pi) * arcHeight);
              return Stack(
                children: [
                  Positioned(
                    left: source.dx - 25,
                    top: source.dy - 35,
                    child: const _DealCard(width: 50, height: 70),
                  ),
                  Positioned(
                    left: position.dx - 20,
                    top: position.dy - 28,
                    child: Transform.rotate(
                      angle: (1 - cardProgress) * .18,
                      child: const _DealCard(width: 40, height: 57),
                    ),
                  ),
                  Positioned(
                    left: 350,
                    top: 170,
                    child: Opacity(
                      opacity: (1 - controller.value * 1.3).clamp(0.0, 1.0),
                      child: const Text(
                        'DEALING CARDS…',
                        style: TextStyle(
                          color: Color(0xFFFFC575),
                          fontFamily: 'Dirty Brush',
                          fontSize: 19,
                          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
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

class _DealCard extends StatelessWidget {
  const _DealCard({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFC58B43)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black87, blurRadius: 6, offset: Offset(2, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.asset(
            AppAssets.cardBack,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
}
