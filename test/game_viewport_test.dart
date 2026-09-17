import 'package:daketi_phase1_modular/core/widgets/game_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'game canvas fills available display without a second safe-area inset',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const cases = <({String name, Size size, EdgeInsets safePadding})>[
      (name: 'iPhone SE', size: Size(667, 375), safePadding: EdgeInsets.zero),
      (
        name: 'iPhone 8 Plus',
        size: Size(736, 414),
        safePadding: EdgeInsets.zero
      ),
      (
        name: 'modern iPhone',
        size: Size(852, 393),
        safePadding: EdgeInsets.only(left: 47, right: 47),
      ),
      (
        name: 'large iPhone',
        size: Size(932, 430),
        safePadding: EdgeInsets.only(left: 59, right: 59),
      ),
      (
        name: 'compact Android',
        size: Size(640, 360),
        safePadding: EdgeInsets.zero
      ),
      (
        name: 'standard Android',
        size: Size(800, 360),
        safePadding: EdgeInsets.zero
      ),
      (
        name: 'Android camera cutout',
        size: Size(915, 412),
        safePadding: EdgeInsets.only(left: 28),
      ),
      (name: 'foldable', size: Size(842, 674), safePadding: EdgeInsets.zero),
      (name: 'tablet', size: Size(1024, 768), safePadding: EdgeInsets.zero),
      (name: 'reference', size: Size(844, 390), safePadding: EdgeInsets.zero),
    ];

    for (final device in cases) {
      await tester.binding.setSurfaceSize(device.size);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: device.size,
                padding: device.safePadding,
                viewPadding: device.safePadding,
              ),
              child: const GameViewport(
                child: ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ),
      );

      final canvas = tester.getRect(find.byKey(GameViewport.canvasKey));
      final screenBounds = Offset.zero & device.size;
      expect(canvas.left, greaterThanOrEqualTo(-.001),
          reason: '${device.name}: left edge');
      expect(canvas.top, greaterThanOrEqualTo(-.001),
          reason: '${device.name}: top edge');
      expect(canvas.right, lessThanOrEqualTo(screenBounds.right + .001),
          reason: '${device.name}: right edge');
      expect(canvas.bottom, lessThanOrEqualTo(screenBounds.bottom + .001),
          reason: '${device.name}: bottom edge');
      expect(
        (canvas.width - device.size.width).abs() < .01 ||
            (canvas.height - device.size.height).abs() < .01,
        isTrue,
        reason:
            '${device.name}: board must reach at least one full display axis',
      );
      expect(canvas.width / canvas.height, closeTo(844 / 390, .001),
          reason: '${device.name}: aspect ratio');
    }
  });
}
