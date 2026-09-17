import 'package:daketi_phase1_modular/features/game/presentation/widgets/opening_deal_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opening deal completes after distributing player cards',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              OpeningDealOverlay(
                playerCount: 2,
                cardsPerPlayer: 4,
                onComplete: () => completed = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('DEALING CARDS…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('staggered deal finishes once and cancels safely when removed',
      (tester) async {
    var completions = 0;
    Widget overlay() => MaterialApp(
          home: Stack(children: [
            OpeningDealOverlay(
              playerCount: 4,
              cardsPerPlayer: 5,
              onComplete: () => completions++,
            )
          ]),
        );
    await tester.pumpWidget(overlay());
    await tester.pump(const Duration(milliseconds: 600));
    expect(completions, 0);
    // Three stationary deck layers plus multiple overlapping card flights.
    expect(find.byType(Image).evaluate().length, greaterThan(4));
    await tester.pump(const Duration(seconds: 2));
    expect(completions, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(overlay());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });
}
