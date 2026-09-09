import 'package:daketi_phase1_modular/features/game/presentation/widgets/bike_daketi_overlay.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/game_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bike Daketi shows the steal stamp and completes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              BikeDaketiOverlay(
                source: const Offset(700, 180),
                destination: const Offset(400, 330),
                cardCount: 3,
                cards: [
                  GameCard.fromId('7H'),
                  GameCard.fromId('QS'),
                  GameCard.fromId('AC'),
                ],
                onComplete: () => completed = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('DAKETI!'), findsOneWidget);
    expect(find.text('3 CARDS STOLEN · MAAL GAYA!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 700));
    expect(completed, isTrue);
    await tester.binding.setSurfaceSize(null);
  });
}
