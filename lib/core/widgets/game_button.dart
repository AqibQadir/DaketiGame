import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.text,
    required this.onTap,
    this.width = 155,
    this.icon,
    this.backgroundAsset = AppAssets.buttonBrush,
    this.splatterColor = const Color(0xFFFF8500),
  });

  final String text;
  final VoidCallback onTap;
  final double width;
  final IconData? icon;
  final String backgroundAsset;
  final Color splatterColor;

  @override
  Widget build(BuildContext context) {
    // Preserve the source artwork's 152:39 aspect ratio at every button width.
    final height = width * 39 / 152;
    final fontSize = (width * .085).clamp(13.0, 15.0);

    return Semantics(
      button: true,
      label: text,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _ButtonSplatterPainter(splatterColor),
                ),
                Positioned(
                  left: 5,
                  right: 7,
                  top: 5,
                  bottom: 5,
                  child: Image.asset(
                    backgroundAsset,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        text.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Dirty Brush',
                          fontSize: fontSize,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          shadows: const [
                            Shadow(
                              color: Color(0x66000000),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonSplatterPainter extends CustomPainter {
  const _ButtonSplatterPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;

    final drops = <(double, double, double)>[
      (.025, .22, 1.0),
      (.045, .34, 1.8),
      (.018, .51, 1.2),
      (.062, .66, 2.1),
      (.035, .79, .9),
      (.095, .12, 1.0),
      (.88, .13, 1.2),
      (.91, .20, 2.0),
      (.95, .16, 1.0),
      (.975, .25, 1.6),
      (.90, .34, 1.2),
      (.94, .39, 2.5),
      (.985, .44, .9),
      (.89, .49, 1.0),
      (.925, .54, 2.0),
      (.965, .58, 1.3),
      (.99, .65, 1.8),
      (.89, .68, 2.7),
      (.94, .73, 1.2),
      (.975, .79, 2.0),
      (.91, .84, 1.0),
      (.86, .91, 1.3),
    ];
    for (final drop in drops) {
      canvas.drawCircle(
        Offset(w * drop.$1, h * drop.$2),
        drop.$3,
        paint,
      );
    }

    final streak = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .01, h * .72), Offset(w * .12, h * .70), streak);
    canvas.drawLine(Offset(w * .88, h * .88), Offset(w * .99, h * .94), streak);
  }

  @override
  bool shouldRepaint(covariant _ButtonSplatterPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
