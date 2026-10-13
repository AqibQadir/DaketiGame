import 'package:daketi_phase1_modular/features/game/presentation/widgets/winner_note_rain.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/core/routes/game_popup_route.dart';
import 'package:daketi_phase1_modular/features/game/data/game_rest_client.dart';
import 'package:daketi_phase1_modular/features/game/data/game_socket_service.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/game_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class ResultsController extends GameController {
  ResultsController(bool tied, {bool won = false})
      : super(
          restClient: GameRestClient(baseUrl: 'http://localhost'),
          socketService: GameSocketService(serverUrl: 'http://localhost'),
        ) {
    state =
        GameSessionState(playerId: 'b', winner: tied ? 'draw' : won ? 'b' : 'a', scores: [
      {'id': 'a', 'name': 'Ayesha Khan', 'score': 125},
      {'id': 'b', 'name': 'Local player', 'score': tied ? 125 : 120},
      {'id': 'c', 'name': 'Hamza Malik', 'score': 80},
      {'id': 'd', 'name': 'Mahnoor Fatima', 'score': 30},
    ]);
  }
}

void main() {
  testWidgets('winner gets note rain and close returns home', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
      overrides: [gameControllerProvider.overrideWith((ref) => ResultsController(false, won: true))],
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: Text('Old game')),
        routes: {AppRoutes.home: (_) => const Scaffold(body: Text('Home destination'))}),
    ));
    nav.currentState!.push(GamePopupRoute<void>(
      settings: const RouteSettings(name: AppRoutes.results), child: const GameResultsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(WinnerNoteRain), findsOneWidget);
    await tester.tap(find.byTooltip('Close popup'));
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
    expect(nav.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(844, 390),
    const Size(667, 375),
    const Size(956, 440)
  ]) {
    for (final tied in [false, true]) {
      testWidgets('four results fit $size, tied=$tied', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final nav = GlobalKey<NavigatorState>();
        await tester.pumpWidget(ProviderScope(
          overrides: [
            gameControllerProvider
                .overrideWith((ref) => ResultsController(tied))
          ],
          child: MaterialApp(navigatorKey: nav, home: const Scaffold()),
        ));
        nav.currentState!.push(GamePopupRoute<void>(
            settings: const RouteSettings(name: '/results'),
            child: const GameResultsScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Manifest lookup is case-sensitive even on macOS test filesystems.
        final assets = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets();
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          if (image.image case final AssetImage asset) {
            expect(assets, contains(asset.assetName));
          }
        }
        for (final label in ['REPLAY', 'HOME']) {
          expect(find.text(label).hitTestable(), findsOneWidget);
          final rect = tester.getRect(find.text(label));
          expect(rect.bottom, lessThan(size.height));
        }
        if (tied) expect(find.text('1'), findsNWidgets(2));
      });
    }
  }
}
