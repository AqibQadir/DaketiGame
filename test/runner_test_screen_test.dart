import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daketi_phase1_modular/features/runner/presentation/screens/runner_test_screen.dart';

void main() {
  testWidgets('runner starts, accepts controls, pauses, and resumes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: RunnerTestScreen()));
    expect(find.text('Start run'), findsOneWidget);
    await tester.tap(find.text('Start run'));
    await tester.pump();
    for (final label in ['Left', 'Right', 'Jump']) {
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('RUN PAUSED'), findsOneWidget);
    await tester.tap(find.text('Resume run'));
    await tester.pump();
    expect(find.text('RUN PAUSED'), findsNothing);
    expect(find.text('Slide'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('collision ends a run and restart resets demo progress',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: RunnerTestScreen()));
    await tester.tap(find.text('Start run'));
    await tester.pump();
    // Stay in one lane until an obstacle reaches the runner.
    for (var frame = 0; frame < 2400; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('BUSTED!').evaluate().isNotEmpty) break;
    }
    expect(find.text('BUSTED!'), findsOneWidget);
    await tester.tap(find.text('Run again'));
    await tester.pump();
    expect(find.text('● 0 demo coins'), findsOneWidget);
    expect(find.text('0 m'), findsOneWidget);
    expect(find.text('BUSTED!'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
