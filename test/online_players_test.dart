import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:daketi_phase1_modular/features/game/data/game_rest_client.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';
import 'package:daketi_phase1_modular/features/home/presentation/controllers/online_players_provider.dart';

void main() {
  for (final count in [17, 0, -1]) {
    test('online count uses real stats and rejects invalid value $count',
        () async {
      final api = GameRestClient(
          baseUrl: 'https://example.test',
          client: MockClient((request) async {
            expect(request.url.path, '/api/stats');
            return http.Response(
                '{"success":true,"stats":{"connectedPlayers":$count}}', 200);
          }));
      final container = ProviderContainer(
          overrides: [gameRestClientProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
      addTearDown(api.dispose);
      final subscription = container.listen(onlinePlayersProvider, (_, __) {});
      addTearDown(subscription.close);
      if (count < 0) {
        await expectLater(container.read(onlinePlayersProvider.future),
            throwsFormatException);
      } else {
        expect(await container.read(onlinePlayersProvider.future), count);
      }
    });
  }
}
