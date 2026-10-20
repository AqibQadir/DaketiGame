import 'package:daketi_phase1_modular/features/game/presentation/widgets/winner_note_rain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('winner celebration uses angled artwork and finishes',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: WinnerNoteRain())));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(WinnerNoteRain));
      for (var i = 1; i <= 12; i++) {
        await precacheImage(
            ResizeImage(AssetImage('assets/images/winner_cards/$i.png'),
                width: 192),
            context);
      }
    });
    await tester.pump(const Duration(seconds: 2));
    final cards = tester.widgetList<Image>(find.byType(Image));
    expect(cards, isNotEmpty);
    for (final card in cards) {
      expect(card.width, lessThan(90));
    }
    await tester.pump(const Duration(seconds: 8));
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('reduced motion suppresses celebration', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: WinnerNoteRain(),
    )));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(Image), findsNothing);
    expect(
        find.descendant(
            of: find.byType(WinnerNoteRain),
            matching: find.byType(AnimatedBuilder)),
        findsNothing);
  });
}
