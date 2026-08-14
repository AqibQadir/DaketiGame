import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

class GameBackground extends StatelessWidget {
  const GameBackground({
    super.key,
    required this.child,
    this.variant = 0,
    this.overlayOpacity,
  });

  /// 1 = bike/police background, 0 = client-supplied Chai Hotel background.
  final int variant;
  final Widget child;
  final double? overlayOpacity;

  @override
  Widget build(BuildContext context) {
    final bool useChaseBackground = variant == 1;
    final String asset = useChaseBackground
        ? AppAssets.chaseBackground
        : AppAssets.chaiHotelBackground;

    final double opacity = overlayOpacity ?? (useChaseBackground ? 0.32 : 0.12);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(
              color: Color(0xFF080808),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white38,
                  size: 48,
                ),
              ),
            );
          },
        ),
        ColoredBox(
          color: Colors.black.withValues(alpha: opacity),
        ),
        child,
      ],
    );
  }
}
