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
}
