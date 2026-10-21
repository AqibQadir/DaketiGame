import 'package:daketi_phase1_modular/core/widgets/game_button.dart';
import 'dart:async';
import 'dart:convert';
import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_token_storage.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/access/presentation/waitlist_screen.dart';
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
  testWidgets('failed login offers recovery and sends the entered email once',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var resetRequests = 0;
    final response = Completer<http.Response>();
    const result =
        "If that email is registered, we've sent password reset instructions.";
    final client = AuthRestClient(
      baseUrl: 'https://game.daketi.pk',
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
              jsonEncode(
                  {'success': false, 'error': 'Invalid email or password'}),
              401);
        }
        expect(request.url.path, '/api/auth/forgot-password');
        expect(jsonDecode(request.body), {'email': 'tester@example.com'});
        resetRequests++;
        return response.future;
      }),
    );
    addTearDown(client.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRestClientProvider.overrideWithValue(client),
        authTokenStorageProvider.overrideWithValue(_Storage()),
      ],
      child: MaterialApp(
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRouter.onGenerateRoute),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Tester@Example.com');
    await tester.enterText(find.byType(TextField).last, 'wrong-password');
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.text('CONTINUE'), findsOneWidget);
    await tester.tap(find.text('FORGOT PASSWORD'));
    await tester.pumpAndSettle();
    expect(find.text('tester@example.com'), findsOneWidget);
    final sendButton = find.widgetWithText(GameButton, 'SEND RESET LINK');
    final continueButton = find.widgetWithText(GameButton, 'CONTINUE');
    expect(tester.getSize(sendButton), tester.getSize(continueButton));
    await tester.tap(find.byTooltip('Close dialog'));
    await tester.pumpAndSettle();
    expect(find.text('SEND RESET LINK'), findsNothing);
    Future<void> reopenRecovery() async {
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FORGOT PASSWORD'));
      await tester.pumpAndSettle();
    }

    await reopenRecovery();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('SEND RESET LINK'), findsNothing);
    await reopenRecovery();
    await tester.tap(find.text('SEND RESET LINK'));
    await tester.pump();
    await tester.tap(find.text('SEND RESET LINK'));
    await tester.pump();
    expect(resetRequests, 1);
    response.complete(
        http.Response(jsonEncode({'success': true, 'message': result}), 200));
    await tester.pumpAndSettle();
    expect(find.text(result), findsOneWidget);
    expect(find.text('SEND RESET LINK'), findsNothing);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
  });

  for (final signup in [false, true]) {
    testWidgets(
        '${signup ? "signup" : "login"} shows progress and opens waiting list on success',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final response = Completer<http.Response>();
      final storage = _Storage();
      final client = AuthRestClient(
          baseUrl: 'https://game.daketi.pk',
          client: MockClient((request) {
            if (request.url.path == '/api/auth/me') {
              return Future.value(http.Response(
                  jsonEncode({
                    'success': true,
                    'user': {
                      'id': '1',
                      'name': 'Tester',
                      'email': 'tester@example.com',
                    },
                    'stats': {}
                  }),
                  200));
            }
            if (request.url.path == '/api/referrals/me') {
              return Future.value(http.Response(
                  jsonEncode({'success': true, 'referrals': []}), 200));
            }
            if (request.url.path.startsWith('/api/waitlist/')) {
              return Future.value(http.Response(
                  jsonEncode({
                    'success': true,
                    'waitlist': {
                      'status': 'waiting',
                      'canPlay': false,
                      'position': 12,
                      'totalWaiting': 100,
                    }
                  }),
                  200));
            }
            expect(request.url.path,
                signup ? '/api/auth/signup' : '/api/auth/login');
            final body = jsonDecode(request.body) as Map;
            expect(body['email'], 'tester@example.com');
            expect(body['password'], 'valid-password');
            if (signup) expect(body['name'], 'Player');
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
      await tester.enterText(fields.at(1), 'valid-password');
      await tester.tap(find.text(signup ? 'SIGN UP' : 'LOGIN').last);
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
      expect(find.byType(WaitlistScreen), findsOneWidget);
      expect(storage.token, 'test-jwt');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      client.dispose();
    });
  }
}
