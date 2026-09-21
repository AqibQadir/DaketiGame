import 'dart:async';
import 'dart:convert';
import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_token_storage.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends AuthTokenStorage {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

void main() {
  for (final signup in [false, true]) {
    testWidgets(
        '${signup ? "signup" : "login"} shows progress and opens rooms on success',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final response = Completer<http.Response>();
      final storage = _Storage();
      final client = AuthRestClient(
          baseUrl: 'https://game.daketi.pk',
          client: MockClient((request) {
            expect(request.url.path,
                signup ? '/api/auth/signup' : '/api/auth/login');
            final body = jsonDecode(request.body) as Map;
            expect(body['email'], 'tester@example.com');
            expect(body['password'], 'valid-password');
            if (signup) expect(body['name'], 'Tester');
            return response.future;
          }));
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authRestClientProvider.overrideWithValue(client),
            authTokenStorageProvider.overrideWithValue(storage),
          ],
          child: MaterialApp(
              navigatorKey: nav,
              initialRoute: AppRoutes.welcome,
              onGenerateRoute: AppRouter.onGenerateRoute)));
      await tester.pumpAndSettle();
      nav.currentState!.pushNamed(signup ? AppRoutes.signup : AppRoutes.login);
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'tester@example.com');
      if (signup) {
        await tester.enterText(fields.at(1), 'Tester');
        await tester.enterText(fields.at(2), 'valid-password');
        await tester.enterText(fields.at(3), 'valid-password');
      } else {
        await tester.enterText(fields.at(1), 'valid-password');
      }
      await tester.tap(find.text(signup ? 'SIGNUP' : 'LOGIN').last);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      response.complete(http.Response(
          jsonEncode({
            'success': true,
            'token': 'test-jwt',
            'user': {
              'id': '1',
              'name': 'Tester',
              'email': 'tester@example.com',
              'emailVerified': false,
              'role': 'user'
            }
          }),
          signup ? 201 : 200));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(storage.token, 'test-jwt');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      client.dispose();
    });
  }
}
