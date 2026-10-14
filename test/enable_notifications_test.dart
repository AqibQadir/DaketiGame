import 'dart:async';
import 'package:daketi_phase1_modular/core/services/push_notification_service.dart';
import 'package:daketi_phase1_modular/core/widgets/enable_notifications_button.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'api_guide_integration_test.dart'
    show MemoryAuthStorage, jsonResponse, user;

class TestPush extends PushNotificationService {
  TestPush(super.api, {this.available = true});
  final bool available;
  final result = Completer<bool>();
  String? bound;
  int requests = 0;
  @override
  bool get isAvailable => available;
  @override
  Future<void> bindAccount(String? token) async {
    bound = token;
  }

  @override
  Future<bool> enableNotifications() {
    requests++;
    return result.future;
  }
}

void main() {
  for (final available in [true, false]) {
    testWidgets(
        'notification control handles available=$available and duplicate taps',
        (tester) async {
      final api = AuthRestClient(
          baseUrl: 'https://example.test',
          client: MockClient((_) async =>
              jsonResponse({'success': true, 'user': user, 'stats': {}})));
      final push = TestPush(api, available: available);
      addTearDown(api.dispose);
      addTearDown(push.dispose);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authRestClientProvider.overrideWithValue(api),
            authTokenStorageProvider.overrideWithValue(MemoryAuthStorage()),
            pushNotificationServiceProvider.overrideWithValue(push),
          ],
          child: const MaterialApp(
              home: Scaffold(body: EnableNotificationsButton()))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable notifications'));
      await tester.pump();
      if (available) {
        expect(push.bound, 'jwt');
        expect(push.requests, 1);
        expect(
            tester.widget<TextButton>(find.byType(TextButton).first).onPressed,
            isNull);
        push.result.complete(true);
        await tester.pumpAndSettle();
        expect(find.text('NOTIFICATIONS ENABLED.'), findsOneWidget);
      } else {
        await tester.pumpAndSettle();
        expect(push.requests, 0);
        expect(find.text('NOTIFICATIONS ARE NOT AVAILABLE IN THIS BUILD YET.'),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
