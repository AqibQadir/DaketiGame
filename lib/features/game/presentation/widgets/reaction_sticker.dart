import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/game_reaction.dart';

/// Painted stickers stay consistent across platforms without emoji font support.
class ReactionSticker extends StatelessWidget {
  const ReactionSticker({super.key, required this.reaction, this.size = 32});
  final GameReaction reaction;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: reaction.caption,
        child: CustomPaint(
            size: Size.square(size), painter: _StickerPainter(reaction)),
      );
}

class _StickerPainter extends CustomPainter {
  const _StickerPainter(this.reaction);
  final GameReaction reaction;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final ink = Paint()..color = const Color(0xFF392415);
    final line = Paint()
      ..color = ink.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    if (reaction == GameReaction.tea) {
      canvas.drawOval(const Rect.fromLTWH(7, 49, 50, 8),
          Paint()..color = const Color(0xFFC58B43));
      canvas.drawArc(
          const Rect.fromLTWH(39, 24, 18, 23),
          -math.pi / 2,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFFE9D1A0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(12, 22, 33, 29), const Radius.circular(8)),
          Paint()..color = const Color(0xFFF6E5BA));
      canvas.drawOval(const Rect.fromLTWH(13, 19, 31, 10),
          Paint()..color = const Color(0xFF9D542A));
      final steam = Paint()
        ..color = const Color(0xFFD9C59A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      for (final x in [23.0, 34.0]) {
        canvas.drawPath(
            Path()
              ..moveTo(x, 15)
              ..cubicTo(x - 7, 10, x + 6, 8, x, 3),
            steam);
      }
    } else if (reaction == GameReaction.champion) {
      final flame = Path()
        ..moveTo(33, 2)
        ..cubicTo(40, 20, 53, 23, 54, 39)
        ..cubicTo(56, 65, 9, 68, 10, 41)
        ..quadraticBezierTo(10, 29, 21, 18)
        ..lineTo(22, 32)
        ..quadraticBezierTo(34, 24, 33, 2)
        ..close();
      canvas.drawPath(
          flame,
          Paint()
            ..shader = const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFC84B), Color(0xFFE34D17)])
                .createShader(const Rect.fromLTWH(8, 2, 48, 60)));
      canvas.drawPath(
          Path()
            ..moveTo(32, 31)
            ..quadraticBezierTo(51, 55, 33, 59)
            ..quadraticBezierTo(16, 57, 32, 31),
          Paint()..color = const Color(0xFFFFE9A2));
    } else {
      canvas.drawCircle(
          const Offset(32, 34), 28, Paint()..color = const Color(0x55000000));
      canvas.drawCircle(
          const Offset(32, 31),
          27,
          Paint()
            ..shader = const RadialGradient(
                center: Alignment(-.4, -.5),
                colors: [
                  Color(0xFFFFE58A),
                  Color(0xFFF4AC35),
                  Color(0xFFD57822)
                ]).createShader(const Rect.fromLTWH(5, 4, 54, 54)));
      if (reaction == GameReaction.challenge) {
        for (final x in [12.0, 35.0]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(x, 20, 18, 13), const Radius.circular(4)),
              ink);
          canvas.drawLine(
              Offset(x + 4, 23),
              Offset(x + 10, 23),
              Paint()
                ..color = const Color(0xFF7D9C92)
                ..strokeWidth = 2);
        }
        canvas.drawLine(const Offset(28, 23), const Offset(36, 23), line);
        canvas.drawArc(
            const Rect.fromLTWH(22, 31, 24, 17), 0, math.pi, false, line);
      } else if (reaction == GameReaction.surprise) {
        for (final x in [22.0, 42.0]) {
          canvas.drawOval(
              Rect.fromCenter(center: Offset(x, 23), width: 7, height: 11),
              ink);
        }
        canvas.drawOval(const Rect.fromLTWH(25, 36, 14, 17), ink);
      } else if (reaction == GameReaction.cheeky) {
        canvas.drawLine(const Offset(15, 24), const Offset(26, 22), line);
        canvas.drawCircle(const Offset(42, 24), 3, ink);
        canvas.drawArc(
            const Rect.fromLTWH(22, 30, 26, 18), .1, 2.3, false, line);
        canvas.drawLine(const Offset(36, 15), const Offset(48, 18), line);
      } else {
        for (final x in [15.0, 37.0]) {
          canvas.drawArc(
              Rect.fromLTWH(x, 18, 12, 12), math.pi, math.pi, false, line);
        }
        canvas.drawArc(
            const Rect.fromLTWH(17, 29, 31, 25), 0, math.pi, true, ink);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(21, 33, 23, 5), const Radius.circular(2)),
            Paint()..color = const Color(0xFFFFF6DF));
        for (final x in [9.0, 53.0]) {
          canvas.drawOval(
              Rect.fromCenter(center: Offset(x, 32), width: 7, height: 12),
              Paint()..color = const Color(0xFF71CDE3));
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StickerPainter oldDelegate) =>
      oldDelegate.reaction != reaction;
}
