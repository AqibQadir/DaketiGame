import 'package:daketi_phase1_modular/features/home/presentation/screens/home_screen.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:daketi_phase1_modular/features/home/presentation/controllers/online_players_provider.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'profile_setup_gate_test.dart' show FakeAuth;

void main() {
  testWidgets(
      'Home gives city cards full width without guest or shop shortcuts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
        overrides: [
          onlinePlayersProvider.overrideWith((ref) async => 42),
          authControllerProvider.overrideWith(
              (ref) => FakeAuth(const AuthState(isRestoring: false))),
        ],
        child: MaterialApp(home: const HomeScreen(), routes: {
          AppRoutes.signup: (_) => const Scaffold(body: Text('SIGNUP OPEN'))
        })));
    await tester.pumpAndSettle();
    expect(find.text('GUEST PLAY'), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byIcon(Icons.workspace_premium), findsNothing);
    expect(find.text('42 players online'), findsOneWidget);
    expect(find.text('PLAY WITH FRIENDS'), findsNothing);
    expect(find.byIcon(Icons.groups), findsOneWidget);
    expect(find.byIcon(Icons.storefront), findsNothing);
    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('city-pages'))).width, 844);
    expect(find.text('LAHORE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.groups));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Sign up to create or join custom rooms, add friends, and send friend requests.'),
        findsOneWidget);
    expect(find.text('Rs 0'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    await tester.tap(find.text('SIGN UP'));
    await tester.pumpAndSettle();
    expect(find.text('SIGNUP OPEN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
