import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/multiplayer_screen.dart';
import 'package:daketi_phase1_modular/features/friends/presentation/friends_screen.dart';
import 'package:daketi_phase1_modular/features/wallet/domain/starting_balance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'profile_setup_gate_test.dart' show FakeAuth;

void main() {
  for (final signedIn in [false, true]) {
    test('starting balance for signedIn=$signedIn', () {
      final container = ProviderContainer(overrides: [
        authControllerProvider.overrideWith((ref) => FakeAuth(
            AuthState(token: signedIn ? 'test' : null, isRestoring: false))),
      ]);
      addTearDown(container.dispose);
      final balance = container.read(startingBalanceProvider);
      expect(balance.coins, signedIn ? 500 : 200);
      expect(balance.rupees, signedIn ? 10 : 0);
    });
  }
  for (final screen in [const MultiplayerScreen(), const FriendsScreen()]) {
    testWidgets('guest cannot access ${screen.runtimeType}', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authControllerProvider.overrideWith(
            (ref) => FakeAuth(const AuthState(isRestoring: false))),
      ], child: MaterialApp(home: screen)));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'Sign up to create or join custom rooms, add friends, and send friend requests.'),
          findsOneWidget);
      expect(find.text('CREATE ROOM'), findsNothing);
      expect(find.text('MY FRIENDS (2)'), findsNothing);
      await tester.tap(find.text('NOT NOW'));
      await tester.pumpAndSettle();
      expect(find.text('An account is needed to play with friends.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
