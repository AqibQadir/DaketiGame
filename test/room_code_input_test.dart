import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'profile_setup_gate_test.dart' show FakeAuth;
import 'package:daketi_phase1_modular/features/game/presentation/widgets/room_code_input.dart';
import 'package:flutter/material.dart';
import 'package:daketi_phase1_modular/core/widgets/glass_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/multiplayer_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('merged room keeps player buttons, code input and friend search',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [const Size(640, 360), const Size(844, 390)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) =>
                FakeAuth(const AuthState(token: 'test', isRestoring: false)))
          ],
          child: const MaterialApp(
              home: MultiplayerScreen(initialPlayerName: 'Guest'))));
      await tester.pump();
      expect(
          find.descendant(
              of: find.byType(RoomCodeInput), matching: find.byType(TextField)),
          findsOneWidget);
      expect(
          find.widgetWithText(TextField, 'Name or player ID'), findsOneWidget);
      expect(find.text('FRIENDS'), findsOneWidget);
      final halves = find.byType(GlassPanel);
      expect(halves, findsNWidgets(2));
      expect(tester.getRect(halves.first).width,
          closeTo(tester.getRect(halves.last).width, .01));
      expect(find.text('Player name'), findsNothing);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Select room location'), findsOneWidget);
      for (final count in [2, 3, 4]) {
        await tester.ensureVisible(find.text('$count PLAYERS'));
        await tester.tap(find.text('$count PLAYERS'));
        await tester.pump();
      }
      await tester.tap(find.text('REQUESTS (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byKey(const ValueKey('DK1003')),
          matching: find.text('ACCEPT')));
      await tester.pumpAndSettle();
      expect(find.text('MY FRIENDS (3)'), findsOneWidget);
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
