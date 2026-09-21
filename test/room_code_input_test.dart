import 'package:daketi_phase1_modular/features/game/presentation/widgets/room_code_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/multiplayer_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('private room has player buttons and only a code input',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [const Size(640, 360), const Size(844, 390)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const ProviderScope(
          child: MaterialApp(
              home: MultiplayerScreen(initialPlayerName: 'Guest'))));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Player name'), findsNothing);
      for (final count in [2, 3, 4]) {
        await tester.tap(find.text('$count PLAYERS'));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('room code supports paste, leading zeros and deletion',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: SizedBox(width: 270, child: RoomCodeInput(controller: controller)),
    ))));
    await tester.enterText(find.byType(TextField), '0a12345');
    await tester.pump();
    expect(controller.text, '0123');
    for (final digit in ['0', '1', '2', '3']) {
      expect(find.text(digit), findsOneWidget);
    }
    await tester.enterText(find.byType(TextField), '01');
    await tester.pump();
    expect(controller.text, '01');
    expect(find.text('2'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
