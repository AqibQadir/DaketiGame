import 'package:daketi_phase1_modular/features/auth/presentation/screens/profile_setup_gate.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_token_storage.dart';
import 'package:daketi_phase1_modular/features/auth/domain/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuth extends AuthController {
  FakeAuth(AuthState initial)
      : super(
            client: AuthRestClient(baseUrl: 'http://localhost'),
            storage: AuthTokenStorage()) {
    state = initial;
  }
  @override
  Future<void> restoreSession() async {}
  @override
  Future<bool> refreshSession() async => true;
}

void main() {
  for (final scenario in ['new', 'returning', 'saved', 'guest']) {
    testWidgets('profile gate $scenario', (tester) async {
      SharedPreferences.setMockInitialValues(
          scenario == 'saved' ? {'profile_complete_1': true} : {});
      final auth = FakeAuth(scenario == 'guest'
          ? const AuthState(isRestoring: false)
          : AuthState(
              token: 'token',
              isRestoring: false,
              user: AuthUser(
                  id: '1',
                  name: scenario == 'returning' ? 'Ali' : 'Player',
                  email: 'a@b.com',
                  emailVerified: true,
                  role: 'user',
                  createdAt: null),
              stats: AuthStats(gamesPlayed: scenario == 'returning' ? 3 : 0)));
      await tester.pumpWidget(ProviderScope(
          overrides: [authControllerProvider.overrideWith((ref) => auth)],
          child:
              const MaterialApp(home: ProfileSetupGate(child: Text('LOBBY')))));
      await tester.pumpAndSettle();
      expect(find.text('YOUR PROFILE'),
          scenario == 'new' ? findsOneWidget : findsNothing);
      expect(find.text('LOBBY'),
          scenario == 'new' ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
