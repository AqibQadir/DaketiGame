import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

enum _Kind { coin, hurdle, overhead, train }

class _Item {
  _Item(this.lane, this.kind, this.depth);
  final int lane;
  final _Kind kind;
  double depth;
}

/// Standalone prototype. Demo coins never modify the account balance.
class RunnerTestScreen extends StatefulWidget {
  const RunnerTestScreen({super.key});

  @override
  State<RunnerTestScreen> createState() => _RunnerTestScreenState();
}

class _RunnerTestScreenState extends State<RunnerTestScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  final _random = math.Random();
  final _focus = FocusNode();
  final _items = <_Item>[];
  Duration? _last;
  Offset? _swipeStart;
  bool _started = false, _paused = false, _caught = false;
  int _lane = 1, _coins = 0;
  double _distance = 0, _jump = 0, _slide = 0, _spawn = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _started && !_caught) {
      setState(() => _paused = true);
    }
    _last = null;
  }

  void _start() {
    setState(() {
      _items.clear();
      _lane = 1;
      _coins = 0;
      _distance = _jump = _slide = 0;
      _spawn = 0.5;
      _started = true;
      _paused = _caught = false;
      _last = null;
    });
    _focus.requestFocus();
  }

  void _act(String action) {
    if (!_started || _paused || _caught) return;
    setState(() {
      if (action == 'left') _lane = math.max(0, _lane - 1);
      if (action == 'right') _lane = math.min(2, _lane + 1);
      if (action == 'jump' && _jump == 0 && _slide == 0) _jump = 0.9;
      if (action == 'slide' && _jump == 0 && _slide == 0) _slide = 0.85;
    });
  }

  void _pause() {
    if (!_started || _caught) return;
    setState(() => _paused = !_paused);
    _last = null;
    _focus.requestFocus();
  }

  void _tick(Duration elapsed) {
    final previous = _last;
    _last = elapsed;
    if (previous == null || !_started || _paused || _caught) return;
    final dt = math.min(0.05, (elapsed - previous).inMicroseconds / 1000000);
    setState(() {
      _jump = math.max(0, _jump - dt);
      _slide = math.max(0, _slide - dt);
      final speed = 0.28 + math.min(0.14, _distance / 2200);
      _distance += dt * speed * 100;
      _spawn -= dt;
      if (_spawn <= 0) {
        _spawn = 1.25;
        final lane = _random.nextInt(3);
        final kind = _Kind.values[1 + _random.nextInt(3)];
        // One obstacle per row always leaves two lanes open.
        _items.add(_Item(lane, kind, 0));
        final coinLane = (lane + 1 + _random.nextInt(2)) % 3;
        for (var i = 0; i < 3; i++) {
          _items.add(_Item(coinLane, _Kind.coin, -i * 0.085));
        }
      }
      for (final item in _items) {
        final oldDepth = item.depth;
        item.depth += dt * speed;
        if (oldDepth < 0.88 && item.depth >= 0.88 && item.lane == _lane) {
          if (item.kind == _Kind.coin) {
            _coins++;
            item.depth = 2;
          } else {
            final cleared = (item.kind == _Kind.hurdle && _jump > 0.12) ||
                (item.kind == _Kind.overhead && _slide > 0);
            if (!cleared) {
              _caught = true;
              break;
            }
          }
        }
      }
      _items.removeWhere((item) => item.depth > 1.15);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091626),
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final key = event.logicalKey;
          final action = {
            LogicalKeyboardKey.arrowLeft: 'left',
            LogicalKeyboardKey.keyA: 'left',
            LogicalKeyboardKey.arrowRight: 'right',
            LogicalKeyboardKey.keyD: 'right',
            LogicalKeyboardKey.arrowUp: 'jump',
            LogicalKeyboardKey.keyW: 'jump',
            LogicalKeyboardKey.space: 'jump',
            LogicalKeyboardKey.arrowDown: 'slide',
            LogicalKeyboardKey.keyS: 'slide',
          }[key];
          if (action != null) {
            _act(action);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.keyP ||
              key == LogicalKeyboardKey.escape) {
            _pause();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) => _swipeStart = details.localPosition,
                onPanUpdate: (details) {
                  if (_swipeStart == null) return;
                  final delta = details.localPosition - _swipeStart!;
                  if (delta.distance < 24) return;
                  _act(delta.dx.abs() > delta.dy.abs()
                      ? (delta.dx > 0 ? 'right' : 'left')
                      : (delta.dy > 0 ? 'slide' : 'jump'));
                  _swipeStart = null;
                },
                onPanEnd: (_) => _swipeStart = null,
                onPanCancel: () => _swipeStart = null,
                child: CustomPaint(
                  painter: _TrackPainter(
                    items: _items,
                    lane: _lane,
                    distance: _distance,
                    jump: _jump,
                    sliding: _slide > 0,
                    caught: _caught,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(children: [
                      IconButton.filledTonal(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 10),
                      const Text('DAKETI / NIGHT RUN',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900)),
                      const Spacer(),
                      _badge('● $_coins demo coins', Colors.amber),
                      const SizedBox(width: 10),
                      _badge('${_distance.floor()} m', Colors.white),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: _paused ? 'Resume' : 'Pause',
                        onPressed: _started && !_caught ? _pause : null,
                        icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                      ),
                    ]),
                    const Spacer(),
                    if (_started && !_caught && !_paused)
                      Row(children: [
                        _control('Left', Icons.arrow_back, 'left'),
                        const SizedBox(width: 8),
                        _control('Right', Icons.arrow_forward, 'right'),
                        const Spacer(),
                        _control(
                            'Slide', Icons.keyboard_double_arrow_down, 'slide'),
                        const SizedBox(width: 8),
                        _control(
                            'Jump', Icons.keyboard_double_arrow_up, 'jump'),
                      ]),
                  ],
                ),
              ),
            ),
            if (!_started || _paused || _caught)
              Positioned.fill(
                top: 70,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 440,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xF2112339),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                            _caught
                                ? 'BUSTED!'
                                : _paused
                                    ? 'RUN PAUSED'
                                    : 'NIGHT RUN',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 30,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(
                          _caught
                              ? 'The police caught you.\n$_coins coins collected • ${_distance.floor()} meters'
                              : _paused
                                  ? 'Take a breath. Your run is waiting.'
                                  : 'Collect coins. Keep ahead of the police.\nJump orange hurdles • Slide under pink bars\nDodge buses with left / right swipes.',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.white, height: 1.5),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                            'Swipe, use buttons, or use arrow keys / WASD.\nPrototype only • Coins do not affect your balance.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _paused && !_caught ? _pause : _start,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_caught
                              ? 'Run again'
                              : _paused
                                  ? 'Resume run'
                                  : 'Start run'),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      );

  Widget _control(String label, IconData icon, String action) =>
      FilledButton.tonalIcon(
        onPressed: () => _act(action),
        icon: Icon(icon),
        label: Text(label),
      );
}

class _TrackPainter extends CustomPainter {
  _TrackPainter(
      {required this.items,
      required this.lane,
      required this.distance,
      required this.jump,
      required this.sliding,
      required this.caught});
  final List<_Item> items;
  final int lane;
  final double distance, jump;
  final bool sliding, caught;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.23;
    final paint = Paint();
    canvas.drawRect(
        Offset.zero & size,
        paint
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF040916), Color(0xFF172B3C)],
          ).createShader(Offset.zero & size));
    paint.shader = null;
    // Moonlit skyline above the bazaar.
    canvas.drawCircle(Offset(w * 0.72, h * 0.12), h * 0.035,
        paint..color = const Color(0xFFE4E8D7));
    for (var i = 0; i < 45; i++) {
      canvas.drawCircle(Offset((i * 137.0) % w, (i * 31.0) % (horizon * 0.8)),
          i.isEven ? 0.8 : 1.2, paint..color = Colors.white38);
    }
    for (var i = 0; i < 22; i++) {
      final x = i * w / 21;
      final bh = h * (0.07 + (i * 7 % 5) * 0.026);
      canvas.drawRect(Rect.fromLTWH(x, horizon - bh, w / 23, bh),
          paint..color = const Color(0xFF101C30));
      canvas.drawRect(Rect.fromLTWH(x + 8, horizon - bh - 7, 14, 7),
          paint..color = const Color(0xFF0C1525));
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 3; col++) {
          if ((row + col + i) % 3 == 0) continue;
          canvas.drawRect(
              Rect.fromLTWH(
                  x + 5 + col * 10, horizon - bh + 8 + row * 12, 4, 6),
              paint..color = const Color(0xFFAD9566));
        }
      }
    }
    Offset point(double laneX, double depth) {
      final t = depth.clamp(0.0, 1.2);
      final spread = w * (0.045 + 0.24 * t * t);
      return Offset(w / 2 + laneX * spread, horizon + (h - horizon) * t * t);
    }

    final road = Path()
      ..moveTo(point(-1.65, 0).dx, horizon)
      ..lineTo(point(1.65, 0).dx, horizon)
      ..lineTo(point(1.65, 1.2).dx, point(1.65, 1.2).dy)
      ..lineTo(point(-1.65, 1.2).dx, point(-1.65, 1.2).dy)
      ..close();
    canvas.drawPath(road, paint..color = const Color(0xFF233342));
    // Asphalt, moving lane markings, and warm reflections from shopfronts.
    for (final edge in [-1.58, 1.58]) {
      canvas.drawLine(
          point(edge, 0),
          point(edge, 1.2),
          paint
            ..color = const Color(0xFFAF9570)
            ..strokeWidth = 5);
    }
    for (var i = 0; i < 18; i++) {
      final depth = (i / 18 + distance / 90) % 1.15;
      for (final edge in [-0.5, 0.5]) {
        canvas.drawLine(
            point(edge, depth),
            point(edge, depth + 0.022),
            paint
              ..color = const Color(0xFF8D998F)
              ..strokeWidth = 1 + depth * 3);
      }
      canvas.drawLine(
          point(-1.45, depth),
          point(-1.1, depth),
          paint
            ..color = const Color(0x227ED5C0)
            ..strokeWidth = 2 + depth * 4);
    }
    void lettering(String text, Rect rect, Color color,
        {double fontSize = 12}) {
      final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: color, fontSize: fontSize, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      final fit = math.min(1.0, rect.width / math.max(1, tp.width));
      canvas.scale(fit);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    const shops = [
      'CHAI DHABA',
      'KARACHI BIRYANI',
      'PAK GENERAL STORE',
      'LAHORE BAKERS',
      'BISMILLAH AUTOS',
      'QUETTA CHAI'
    ];
    const urdu = [
      'چائے ڈھابہ',
      'کراچی بریانی',
      'جنرل اسٹور',
      'لاہور بیکرز',
      'بسم اللہ آٹوز',
      'کوئٹہ چائے'
    ];
    // Adjacent shops share exact world-space boundaries. Recycle only beyond
    // the camera, keeping each shop's identity stable while it moves forward.
    const shopLength = 0.16;
    final travel = distance / 160 / shopLength;
    final passed = travel.floor();
    final phase = travel - passed;
    for (var segment = -1; segment < 10; segment++) {
      final farDepth = math.max(0.0, (segment + phase) * shopLength);
      final nearDepth = (segment + phase + 1) * shopLength;
      if (nearDepth <= 0) continue;
      for (final side in [-1, 1]) {
        final index = (segment - passed + (side == 1 ? 3 : 0)) % shops.length;
        Offset wallPoint(double depth) => Offset(
              w / 2 + side * 1.78 * w * (0.045 + 0.24 * depth * depth),
              horizon + (h - horizon) * depth * depth,
            );
        double wallScale(double depth) => 0.07 + depth * depth * h / 350;
        // Both walls face inward toward the street, not toward the camera.
        // Reverse endpoint order on the left to keep shop lettering readable.
        final startDepth = side == -1 ? nearDepth : farDepth;
        final endDepth = side == -1 ? farDepth : nearDepth;
        final start = wallPoint(startDepth);
        final end = wallPoint(endDepth);
        final startScale = wallScale(startDepth);
        final endScale = wallScale(endDepth);
        final perspective = startScale / endScale - 1;
        canvas.save();
        canvas.transform(Float64List.fromList([
          ((1 + perspective) * end.dx - start.dx) / 150,
          ((1 + perspective) * end.dy - start.dy) / 150,
          0,
          perspective / 150,
          0,
          startScale,
          0,
          0,
          0,
          0,
          1,
          0,
          start.dx,
          start.dy,
          0,
          1,
        ]));
        const left = 0.0;
        // Clip each unit at its shared boundary so awnings and signs cannot
        // spill across its neighbour. A tiny overlap avoids raster seams.
        canvas.clipRect(const Rect.fromLTWH(-0.1, -230, 150.2, 245));
        final facade = const Rect.fromLTWH(left, -208, 150, 208);
        canvas.drawRect(
            facade,
            paint
              ..shader = LinearGradient(
                colors: [
                  const Color(0xFF485055),
                  index.isEven
                      ? const Color(0xFF222F3E)
                      : const Color(0xFF3C3539)
                ],
              ).createShader(facade));
        paint.shader = null;
        // Roof coping, masonry, air conditioner, and lit apartment windows.
        canvas.drawRect(const Rect.fromLTWH(left - 4, -212, 158, 7),
            paint..color = const Color(0xFF797363));
        for (var row = 0; row < 4; row++) {
          canvas.drawLine(
              Offset(left, -195 + row * 27),
              Offset(left + 150, -195 + row * 27),
              paint
                ..color = Colors.black26
                ..strokeWidth = 1);
        }
        for (var col = 0; col < 3; col++) {
          final window = Rect.fromLTWH(left + 12 + col * 46, -186, 29, 43);
          canvas.drawRect(
              window.inflate(3), paint..color = const Color(0xFF172331));
          canvas.drawRect(
              window,
              paint
                ..color = col == index % 3
                    ? const Color(0xFFD2A562)
                    : const Color(0xFF506060));
          canvas.drawLine(
              window.topCenter,
              window.bottomCenter,
              paint
                ..color = Colors.black54
                ..strokeWidth = 2);
        }
        canvas.drawRect(const Rect.fromLTWH(left + 12, -135, 35, 18),
            paint..color = const Color(0xFF92918A));
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(
              Offset(left + 16, -131 + i * 3),
              Offset(left + 43, -131 + i * 3),
              paint
                ..color = Colors.black45
                ..strokeWidth = 1);
        }
        // Illuminated bilingual shop sign.
        final sign = const Rect.fromLTWH(left + 3, -109, 144, 38);
        final signColor =
            index.isEven ? const Color(0xFF17765E) : const Color(0xFF952F3B);
        canvas.drawRect(
            sign.inflate(4),
            paint
              ..color = signColor.withAlpha(60)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
        paint.maskFilter = null;
        canvas.drawRect(sign, paint..color = signColor);
        lettering(urdu[index], const Rect.fromLTWH(left + 8, -108, 134, 20),
            const Color(0xFFFFE9A9),
            fontSize: 16);
        lettering(shops[index], const Rect.fromLTWH(left + 8, -87, 134, 14),
            Colors.white,
            fontSize: 11);
        canvas.drawRect(const Rect.fromLTWH(left + 8, -70, 134, 70),
            paint..color = const Color(0xFFCC9A5B));
        for (var col = 0; col < 3; col++) {
          canvas.drawRect(Rect.fromLTWH(left + 14 + col * 43, -64, 36, 57),
              paint..color = const Color(0xFF3A342C));
          for (var row = 0; row < 3; row++) {
            canvas.drawRect(
                Rect.fromLTWH(left + 17 + col * 43, -53 + row * 16, 29, 3),
                paint..color = const Color(0xFFB98B53));
            for (var bottle = 0; bottle < 4; bottle++) {
              canvas.drawRect(
                  Rect.fromLTWH(
                      left + 19 + col * 43 + bottle * 7, -61 + row * 16, 4, 8),
                  paint
                    ..color = bottle.isEven
                        ? const Color(0xFF88AB70)
                        : const Color(0xFFDDAE75));
            }
          }
        }
        for (var stripe = 0; stripe < 10; stripe++) {
          canvas.drawRect(
              Rect.fromLTWH(left + stripe * 15, -73, 15, 12),
              paint
                ..color = stripe.isEven ? const Color(0xFFDBCB9A) : signColor);
        }
        // Pakistani green flag with crescent on the upper facade.
        canvas.drawRect(const Rect.fromLTWH(left + 91, -133, 36, 21),
            paint..color = const Color(0xFF08683F));
        canvas.drawRect(const Rect.fromLTWH(left + 91, -133, 7, 21),
            paint..color = Colors.white);
        canvas.drawCircle(
            const Offset(left + 113, -123), 7, paint..color = Colors.white);
        canvas.drawCircle(const Offset(left + 116, -125), 6,
            paint..color = const Color(0xFF08683F));
        canvas.drawRect(const Rect.fromLTWH(left - 6, 0, 162, 8),
            paint..color = const Color(0xFF74746C));
        canvas.restore();
      }
    }
    // Streetlights stand on the pavement independently of the wall planes.
    for (var i = 0; i < 7; i++) {
      final depth = (i / 7 + distance / 160) % 1.2;
      for (final side in [-1, 1]) {
        final base = point(side * 1.68, depth);
        final scale = 0.12 + depth * depth * h / 350;
        final top = base - Offset(0, 153 * scale);
        final light = top - Offset(side * 23 * scale, 0);
        canvas.drawLine(
            base,
            top,
            paint
              ..color = const Color(0xFF859092)
              ..strokeWidth = 3 * scale);
        canvas.drawLine(top, light, paint);
        canvas.drawCircle(
            light,
            15 * scale,
            paint
              ..color = const Color(0x77FFCF7C)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        paint.maskFilter = null;
        canvas.drawOval(
            Rect.fromCenter(
                center: light, width: 17 * scale, height: 5 * scale),
            paint..color = const Color(0xFFFFE7AE));
      }
    }
    void person(Offset foot, double scale, Color color,
        {bool duck = false, bool police = false}) {
      canvas.save();
      canvas.translate(foot.dx, foot.dy);
      canvas.scale(scale);
      canvas.drawOval(
          const Rect.fromLTWH(-18, -3, 36, 9), paint..color = Colors.black38);
      if (duck) canvas.scale(1.2, 0.58);
      final stride = caught ? 0.0 : math.sin(distance * 0.8) * 9;
      final skin = const Color(0xFFB87E57);
      final trousers =
          police ? const Color(0xFFB6A17B) : const Color(0xFF263B53);
      void limb(Offset a, Offset b, Color c, double width) {
        canvas.drawLine(
            a,
            b,
            paint
              ..color = c
              ..strokeWidth = width
              ..strokeCap = StrokeCap.round);
      }

      // Articulated legs, knees and shoes give a human running silhouette.
      for (final side in [-1, 1]) {
        final hip = Offset(side * 7, -35);
        final knee = Offset(side * 9, -19 + side * stride * 0.45);
        final ankle =
            Offset(side * 10 + side * stride * 0.3, -4 + side * stride * 0.4);
        limb(hip, knee, trousers, 10);
        limb(knee, ankle, trousers, 8);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(ankle.dx - 5, ankle.dy - 1, 12, 6),
                const Radius.circular(2)),
            paint..color = const Color(0xFF101620));
        if (!police) {
          limb(Offset(ankle.dx - 4, ankle.dy + 5),
              Offset(ankle.dx + 6, ankle.dy + 5), Colors.white70, 2);
        }
      }
      final body = Path()
        ..moveTo(-16, -69)
        ..quadraticBezierTo(0, -76, 16, -69)
        ..lineTo(12, -37)
        ..quadraticBezierTo(0, -31, -12, -37)
        ..close();
      final shirt = police ? const Color(0xFF303C36) : const Color(0xFFAD5037);
      canvas.drawPath(
          body,
          paint
            ..shader = LinearGradient(colors: [
              shirt,
              police ? const Color(0xFF586154) : const Color(0xFFE28553),
              shirt
            ]).createShader(const Rect.fromLTWH(-16, -72, 32, 40)));
      paint.shader = null;
      limb(const Offset(0, -67), const Offset(0, -39), Colors.black12, 1);
      for (final side in [-1, 1]) {
        final shoulder = Offset(side * 15, -66);
        final elbow = Offset(side * 22, -51 + side * stride * 0.4);
        final hand = Offset(side * 17, -39 - side * stride * 0.6);
        limb(shoulder, elbow, shirt, 9);
        limb(elbow, hand, police ? shirt : skin, 6);
        canvas.drawCircle(hand, 3.5, paint..color = skin);
      }
      canvas.drawRect(const Rect.fromLTWH(-12, -37, 24, 4),
          paint..color = const Color(0xFF211E1C));
      limb(const Offset(0, -75), const Offset(0, -70), skin, 8);
      canvas.drawOval(
          const Rect.fromLTWH(-9, -94, 18, 23), paint..color = skin);
      canvas.drawCircle(const Offset(-9, -82), 2.5, paint);
      canvas.drawCircle(const Offset(9, -82), 2.5, paint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-9, -95, 18, 15), const Radius.circular(6)),
          paint..color = const Color(0xFF201C1B));
      if (police) {
        canvas.drawOval(const Rect.fromLTWH(-12, -98, 24, 10),
            paint..color = const Color(0xFF1A2825));
        limb(const Offset(-10, -91), const Offset(10, -91),
            const Color(0xFF66715E), 3);
        for (final x in [-11.0, 11.0]) {
          limb(Offset(x - 3, -68), Offset(x + 3, -68), const Color(0xFFBFA56A),
              3);
        }
        lettering('POLICE', const Rect.fromLTWH(-13, -62, 26, 12), Colors.white,
            fontSize: 8);
        canvas.drawRect(const Rect.fromLTWH(10, -39, 7, 12),
            paint..color = const Color(0xFF161F24));
        limb(const Offset(-14, -37), const Offset(-19, -19),
            const Color(0xFF141B22), 3);
      } else {
        // Small sling bag and seam highlights, seen from behind.
        limb(const Offset(10, -69), const Offset(-9, -40),
            const Color(0xFF312D29), 4);
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -57, 18, 21),
                const Radius.circular(4)),
            paint..color = const Color(0xFF575A43));
        limb(const Offset(-7, -49), const Offset(3, -49),
            const Color(0xFFA6A17A), 1);
      }
      canvas.restore();
    }

    final objects = items
        .where((item) => item.depth >= 0 && item.depth <= 1.15)
        .toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));
    for (final item in objects) {
      final p = point((item.lane - 1).toDouble(), item.depth);
      final scale = 0.2 + item.depth * item.depth * h / 340;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.scale(scale);
      if (item.kind == _Kind.coin) {
        canvas.drawCircle(
            const Offset(0, -24), 12, paint..color = Colors.amber);
        canvas.drawCircle(
            const Offset(0, -24),
            8,
            paint
              ..color = const Color(0xFFFFE69A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        paint.style = PaintingStyle.fill;
      } else if (item.kind == _Kind.hurdle) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-35, -28, 70, 28),
                const Radius.circular(3)),
            paint..color = Colors.deepOrange);
        for (var i = 0; i < 4; i++) {
          canvas.drawRect(Rect.fromLTWH(-30 + i * 18, -23, 9, 8),
              paint..color = Colors.amber.shade100);
        }
      } else if (item.kind == _Kind.overhead) {
        canvas.drawRect(const Rect.fromLTWH(-40, -83, 7, 83),
            paint..color = Colors.pinkAccent);
        canvas.drawRect(const Rect.fromLTWH(33, -83, 7, 83), paint);
        canvas.drawRect(const Rect.fromLTWH(-40, -83, 80, 43), paint);
        canvas.drawLine(
            const Offset(-27, -60),
            const Offset(27, -60),
            paint
              ..color = Colors.white
              ..strokeWidth = 5);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-40, -112, 80, 112),
                const Radius.circular(12)),
            paint..color = const Color(0xFF168B69));
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-31, -96, 62, 38),
                const Radius.circular(5)),
            paint..color = const Color(0xFF102D47));
        canvas.drawRect(const Rect.fromLTWH(-36, -43, 72, 8),
            paint..color = Colors.white70);
        lettering(
            'KARACHI', const Rect.fromLTWH(-30, -109, 60, 12), Colors.amber,
            fontSize: 9);
        lettering(
            'CITY BUS', const Rect.fromLTWH(-30, -54, 60, 10), Colors.white,
            fontSize: 8);
        canvas.drawRect(
            const Rect.fromLTWH(-13, -12, 26, 7), paint..color = Colors.amber);
        for (final x in [-25.0, 25.0]) {
          canvas.drawCircle(
              Offset(x, -22), 6, paint..color = Colors.amber.shade100);
        }
      }
      canvas.restore();
    }
    final runner = point((lane - 1).toDouble(), 0.88);
    final lift =
        jump > 0 ? math.sin((1 - jump / 0.9) * math.pi) * h * 0.22 : 0.0;
    person(runner - Offset(0, lift), h / 360, const Color(0xFFFF6944),
        duck: sliding);
    final officer = point((lane - 1).toDouble(), caught ? 0.92 : 0.98);
    person(officer + Offset(caught ? 25 : -35, 0), h / 390,
        const Color(0xFF3974CE),
        police: true);
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) => true;
}
