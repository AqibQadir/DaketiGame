import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Winner celebration combining rupee notes with supplied angled card artwork.
class WinnerNoteRain extends StatefulWidget {
  const WinnerNoteRain({super.key});
  @override
  State<WinnerNoteRain> createState() => _WinnerNoteRainState();
}

class _WinnerNoteRainState extends State<WinnerNoteRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 9));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) &&
        !controller.isAnimating &&
        controller.value == 0) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: ClipRect(
            child: LayoutBuilder(builder: (context, constraints) {
              return AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final seconds = controller.value * 9;
                  final random = math.Random(89);
                  final cards = <Widget>[];
                  for (var i = 0; i < 18; i++) {
                    final x = random.nextDouble() * constraints.maxWidth;
                    final delay = random.nextDouble() * 3.5;
                    final duration = 3.5 + random.nextDouble() * 2;
                    final sway = random.nextDouble() * math.pi * 2;
                    final size = 54 + random.nextDouble() * 34;
                    final phase = (seconds - delay) / duration;
                    if (phase < 0 || phase > 1) continue;
                    cards.add(Positioned(
                      left: x - size / 2 + math.sin(phase * 5 + sway) * 24,
                      top: -size + phase * (constraints.maxHeight + size * 2),
                      child: Transform.rotate(
                        angle: math.sin(phase * 4 + sway) * .45,
                        child: Image.asset(
                          'assets/images/winner_cards/${i % 12 + 1}.png',
                          width: size,
                          height: size,
                          cacheWidth: 192,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                        ),
                      ),
                    ));
                  }
                  return Stack(children: [
                    ...cards,
                    Positioned.fill(
                      child: CustomPaint(painter: _NotesPainter(controller)),
                    ),
                  ]);
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NotesPainter extends CustomPainter {
  _NotesPainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;
  @override
  void paint(Canvas canvas, Size size) {
    final seconds = animation.value * 9;
    final random = math.Random(47);
    for (var i = 0; i < 36; i++) {
      final x = random.nextDouble() * size.width;
      final delay = random.nextDouble() * 4;
      final duration = 3 + random.nextDouble() * 2;
      final phase = (seconds - delay) / duration;
      final sway = random.nextDouble() * math.pi * 2;
      if (phase < 0 || phase > 1) continue;
      canvas.save();
      canvas.translate(x + math.sin(phase * 6 + sway) * 22,
          -60 + phase * (size.height + 120));
      canvas.rotate(math.sin(phase * 5 + sway) * .65);
      canvas.scale(.7 + .3 * math.sin(phase * 8 + sway).abs(), .8);
      final rect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-32, -15, 64, 30), const Radius.circular(2));
      canvas.drawShadow(Path()..addRRect(rect), Colors.black54, 3, false);
      canvas.drawRRect(
          rect,
          Paint()
            ..color =
                i.isEven ? const Color(0xFFB2C697) : const Color(0xFFD4B4C4));
      canvas.drawRect(
          const Rect.fromLTWH(-29, -12, 58, 24),
          Paint()
            ..color = const Color(0xFF456040)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7);
      // Portrait medallion and crescent identify the illustrated rupee motif.
      canvas.drawOval(const Rect.fromLTWH(12, -10, 14, 20),
          Paint()..color = const Color(0xFF789071));
      canvas.drawCircle(
          const Offset(19, -3), 3, Paint()..color = const Color(0xFFE1DCC1));
      canvas.drawOval(const Rect.fromLTWH(15, 1, 8, 7),
          Paint()..color = const Color(0xFFE1DCC1));
      final text = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
              text: 'PAKISTAN\nRs ${i.isEven ? '1000' : '5000'}',
              style: const TextStyle(
                  color: Color(0xFF294331),
                  fontSize: 6,
                  fontWeight: FontWeight.bold)))
        ..layout();
      text.paint(canvas, const Offset(-25, -8));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_NotesPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
