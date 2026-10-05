import 'dart:async';
import 'dart:convert';

import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_token_storage.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/profile/presentation/widgets/account_options_dialog.dart';
import 'package:daketi_phase1_modular/features/profile/presentation/widgets/profile_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends AuthTokenStorage {
  @override
  Future<String?> read() async => 'account-token';
}

Map<String, dynamic> user({String name = 'Player', bool password = true}) => {
      'id': '1',
      'name': name,
      'email': 'player@example.com',
      'emailVerified': false,
      'hasPassword': password,
      'facebookLinked': !password,
      'dateOfBirth': '1990-05-15',
    };

Future<AuthController> openDialog(WidgetTester tester, Widget dialog,
    Future<http.Response> Function(http.Request) handler,
    {bool password = true}) async {
  final client = AuthRestClient(
    baseUrl: 'https://game.daketi.pk',
    client: MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/api/auth/me') {
        return http.Response(
            jsonEncode({
              'success': true,
              'user': user(password: password),
              'stats': {}
            }),
            200);
      }
      return handler(request);
    }),
  );
  final controller = AuthController(client: client, storage: _Storage());
  addTearDown(() {
    client.dispose();
  });
  await tester.pumpWidget(ProviderScope(
    overrides: [authControllerProvider.overrideWith((ref) => controller)],
    child: MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => dialog),
                    child: const Text('Open'),
                  ),
                ))),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
}

void main() {
  testWidgets('profile validates fields, retains rejected edits, saves once',
      (tester) async {
    var calls = 0;
    final accepted = Completer<http.Response>();
    final controller = await openDialog(
      tester,
      const ProfileEditDialog(),
      (request) async {
        calls++;
        expect(request.method, 'PATCH');
        expect(request.headers['authorization'], 'Bearer account-token');
        expect(jsonDecode(request.body), {
          'name': 'Updated Player',
          'dateOfBirth': '1990-05-15',
        });
        if (calls == 1) {
          return http.Response(
              jsonEncode({'success': false, 'error': 'Please try again later'}),
              429);
        }
        return accepted.future;
      },
    );
    await tester.enterText(find.byType(TextFormField).first, ' ');
    await tapText(tester, 'SAVE');
    await tester.pumpAndSettle();
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(find.byType(TextFormField).first, 'Updated Player');
    await tester.enterText(find.byType(TextFormField).last, '1990-02-31');
    await tapText(tester, 'SAVE');
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid date as YYYY-MM-DD.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(find.byType(TextFormField).last, '1990-05-15');
    await tapText(tester, 'SAVE');
    await tester.pumpAndSettle();
    expect(find.text('Please try again later'), findsOneWidget);
    expect(find.text('Updated Player'), findsOneWidget);
    await tapText(tester, 'SAVE');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tapText(tester, 'SAVING…');
    expect(calls, 2);
    accepted.complete(http.Response(
        jsonEncode({'success': true, 'user': user(name: 'Updated Player')}),
        200));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditDialog), findsNothing);
    expect(controller.state.user?.name, 'Updated Player');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'password mismatch does not submit; valid password waits and clears',
      (tester) async {
    var calls = 0;
    final accepted = Completer<http.Response>();
    await openDialog(tester, const AccountOptionsDialog(), (request) async {
      calls++;
      expect(request.url.path, '/api/auth/change-password');
      expect(jsonDecode(request.body),
          {'currentPassword': 'old-password', 'newPassword': 'new-password'});
      return accepted.future;
    });
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'old-password');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.enterText(fields.at(2), 'mismatch');
    await tapText(tester, 'Update password');
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(fields.at(2), 'new-password');
    await tapText(tester, 'Update password');
    await tester.pump();
    expect(calls, 1);
    await tapText(tester, 'Update password');
    expect(calls, 1);
    accepted.complete(http.Response(
        jsonEncode({'success': true, 'message': 'Password updated'}), 200));
    await tester.pumpAndSettle();
    expect(find.text('Password updated'), findsOneWidget);
    for (final field in tester.widgetList<TextFormField>(fields)) {
      expect(field.controller!.text, isEmpty);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Facebook-only account can request a password setup email',
      (tester) async {
    var sent = false;
    await openDialog(tester, const AccountOptionsDialog(), (request) async {
      expect(request.url.path, '/api/auth/forgot-password');
      expect(jsonDecode(request.body), {'email': 'player@example.com'});
      sent = true;
      return http.Response(
          jsonEncode({
            'success': true,
            'message':
                'If that email is registered, reset instructions were sent.'
          }),
          200);
    }, password: false);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Facebook connected'), findsOneWidget);
    await tapText(tester, 'Set a password by email');
    await tester.pumpAndSettle();
    expect(sent, isTrue);
    expect(
        find.text('If that email is registered, reset instructions were sent.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
