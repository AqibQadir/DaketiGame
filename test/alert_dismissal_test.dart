import 'package:daketi_phase1_modular/core/widgets/game_alert.dart';
import 'package:daketi_phase1_modular/core/widgets/game_styled_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('outside tap dismisses a notice and cancels a confirmation',
      (tester) async {
    bool? confirmed;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return Scaffold(
          body: Column(children: [
        TextButton(
          onPressed: () => showGameAlert(context, 'Example notice'),
          child: const Text('Notice'),
        ),
        TextButton(
          onPressed: () async {
            confirmed = await showGameConfirmation(context,
                title: 'CONFIRM', message: 'Proceed?');
          },
          child: const Text('Confirm'),
        ),
      ]));
    })));
    await tester.tap(find.text('Notice'));
    await tester.pumpAndSettle();
    expect(find.byType(GameStyledDialog), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(GameStyledDialog), findsNothing);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(GameStyledDialog), findsNothing);
    expect(confirmed, isFalse);
  });
}
