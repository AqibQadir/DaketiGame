import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/access/presentation/launch_access_gate.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'api_guide_integration_test.dart'
    show MemoryAuthStorage, jsonResponse, user;

void main() {
  for (final canPlay in [false, true]) {
    testWidgets('restored account opens home only when canPlay=$canPlay',
        (tester) async {
      final api = AuthRestClient(
          baseUrl: 'https://example.test',
          client: MockClient((request) async {
            if (request.url.path == '/api/auth/me') {
              return jsonResponse({'success': true, 'user': user, 'stats': {}});
            }
            return jsonResponse({
              'success': true,
              'waitlist': {
                // Status alone must never unlock the lobby.
                'status': 'invited', 'canPlay': canPlay,
              }
            });
          }));
      addTearDown(api.dispose);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authRestClientProvider.overrideWithValue(api),
            authTokenStorageProvider.overrideWithValue(MemoryAuthStorage()),
          ],
          child: MaterialApp(
              home: const LaunchAccessGate(child: Text('HOME CONTENT')),
              routes: {
                AppRoutes.waitlist: (_) => const Text('WAITING CONTENT'),
              })));
      await tester.pumpAndSettle();
      expect(find.text(canPlay ? 'HOME CONTENT' : 'WAITING CONTENT'),
          findsOneWidget);
      expect(find.text(canPlay ? 'WAITING CONTENT' : 'HOME CONTENT'),
          findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
