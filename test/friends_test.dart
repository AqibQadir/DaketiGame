import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'profile_setup_gate_test.dart' show FakeAuth;
import 'package:daketi_phase1_modular/features/friends/domain/friends_controller.dart';
import 'package:daketi_phase1_modular/features/friends/presentation/friends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requests have valid transitions and cannot create duplicate friends',
      () {
    final controller = FriendsController();
    addTearDown(controller.dispose);
    Friendship relation(String id) =>
        controller.state.firstWhere((p) => p.id == id).relationship;
    controller.add('DK1005');
    controller.add('DK1005');
    expect(relation('DK1005'), Friendship.outgoing);
    controller.accept('DK1005');
    expect(relation('DK1005'), Friendship.outgoing);
    controller.cancel('DK1005');
    expect(relation('DK1005'), Friendship.none);
    controller.accept('DK1003');
    controller.accept('DK1003');
    expect(relation('DK1003'), Friendship.friend);
    expect(controller.state.length, 8);
    controller.remove('DK1003');
    expect(relation('DK1003'), Friendship.none);
    controller.decline('DK1004');
    expect(relation('DK1004'), Friendship.none);
  });

  testWidgets('search, add, cancel, accept and remove demo friends',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = FriendsController();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        friendsProvider.overrideWith((ref) => controller),
        authControllerProvider.overrideWith((ref) =>
            FakeAuth(const AuthState(token: 'test', isRestoring: false)))
      ],
      child: const MaterialApp(home: FriendsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('MY FRIENDS (2)'), findsOneWidget);
    await tester.tap(find.text('FIND FRIENDS'));
    await tester.enterText(find.byType(TextField), '  #dk1005  ');
    await tester.pumpAndSettle();
    expect(find.text('Saad Qureshi'), findsOneWidget);
    await tester.tap(find.text('ADD FRIEND'));
    await tester.pumpAndSettle();
    expect(find.text('Request sent'), findsOneWidget);
    expect(find.text('ADD FRIEND'), findsNothing);
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(find.text('ADD FRIEND'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'does not exist');
    await tester.pumpAndSettle();
    expect(find.text('No players found'), findsOneWidget);
    await tester.tap(find.text('REQUESTS (2)'));
    await tester.pumpAndSettle();
    final bilal = find.byKey(const ValueKey('DK1003'));
    await tester.tap(find.descendant(of: bilal, matching: find.text('ACCEPT')));
    await tester.pumpAndSettle();
    expect(find.text('MY FRIENDS (3)'), findsOneWidget);
    expect(find.text('REQUESTS (1)'), findsOneWidget);
    await tester.tap(find.text('MY FRIENDS (3)'));
    await tester.enterText(find.byType(TextField), 'bilal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bilal Ahmed'));
    await tester.pumpAndSettle();
    expect(find.text('PLAYER PROFILE'), findsOneWidget);
    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REMOVE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(find.text('MY FRIENDS (3)'), findsOneWidget);
    await tester.tap(find.text('REMOVE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REMOVE').last);
    await tester.pumpAndSettle();
    expect(find.text('MY FRIENDS (2)'), findsOneWidget);
    expect(find.text('No players found'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
