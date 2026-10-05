import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/testing.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/access/presentation/waitlist_screen.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/screens/account_link_screen.dart';
import 'api_guide_integration_test.dart'
    show MemoryAuthStorage, jsonResponse, user;

void main() {
  for (final status in ['waiting', 'invited', 'ready']) {
    testWidgets(
        'waitlist $status fits small landscape and respects eligibility',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(667, 375));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = AuthRestClient(
          baseUrl: 'https://example.test',
          client: MockClient((r) async {
            if (r.url.path == '/api/auth/me') {
              return jsonResponse({'success': true, 'user': user, 'stats': {}});
            }
            if (r.url.path == '/api/referrals/me') {
              return jsonResponse({
                'success': true,
                'referrals': [
                  {'name': 'Sara', 'verified': true},
                  {'name': 'Omar', 'verified': false}
                ]
              });
            }
            return jsonResponse({
              'success': true,
              'waitlist': {
                'status': status,
                'position': 45,
                'totalWaiting': 500,
                'canPlay': status == 'ready',
                'referralCode': 'ABCD2345',
                'referralLink': 'https://game.daketi.pk/?ref=ABCD2345',
                'referralCount': 1,
                'pendingReferralCount': 1,
              }
            });
          }));
      addTearDown(api.dispose);
      await tester.pumpWidget(ProviderScope(overrides: [
        authRestClientProvider.overrideWithValue(api),
        authTokenStorageProvider.overrideWithValue(MemoryAuthStorage()),
      ], child: const MaterialApp(home: WaitlistScreen())));
      await tester.pumpAndSettle();
      expect(find.text('Your code: ABCD2345'), findsOneWidget);
      expect(find.text('Invite friends'), findsOneWidget);
      expect(find.text('1 verified referrals · 1 pending'), findsOneWidget);
      if (status == 'waiting') {
        expect(find.text('#45 · 500 waiting'), findsOneWidget);
      }
      if (status == 'invited') expect(find.text('HOME'), findsNothing);
      if (status == 'ready') expect(find.text('HOME'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
      'reset link validates passwords then submits token and offers login',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var resets = 0;
    final api = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async {
          if (r.url.path == '/api/auth/reset-password') {
            resets++;
            return jsonResponse(
                {'success': true, 'message': 'Password updated'});
          }
          return jsonResponse({'success': true, 'user': user, 'stats': {}});
        }));
    addTearDown(api.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authRestClientProvider.overrideWithValue(api),
          authTokenStorageProvider.overrideWithValue(MemoryAuthStorage())
        ],
        child: MaterialApp(
            home: AccountLinkScreen(
                uri: Uri.parse(
                    'https://game.daketi.pk/?resetToken=reset-secret')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRM'));
    await tester.pump();
    expect(resets, 0);
    await tester.enterText(find.byType(TextField).first, 'new-password');
    await tester.enterText(find.byType(TextField).last, 'new-password');
    tester.testTextInput.hide();
    await tester.tap(find.text('CONFIRM'));
    await tester.pumpAndSettle();
    expect(resets, 1);
    expect(find.text('Go to login'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
