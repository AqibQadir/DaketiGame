import 'package:daketi_phase1_modular/core/widgets/game_viewport.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/daketi_game.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/game_screen.dart';
import 'package:daketi_phase1_modular/features/game/presentation/widgets/bike_daketi_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multiplayer_game_flow_test.dart' show FlowController;

class StealController extends FlowController {
  StealController(this.count) : super(count: count, resumed: true) {
    update(stolen: false);
  }
  final int count;
  String get actor => count == 2 ? 'p0' : 'p${3 % count}';

  void update({required bool stolen}) {
    state = state.copyWith(game: DaketiGame.fromJson({
      'gameId': '0093',
      'status': 'playing',
      'currentPlayerId': actor,
      'deckCount': 20,
      'table': ['3H'],
      'players': List.generate(count, (i) => {
        'id': 'p$i',
        'name': 'Human $i',
        'hand': i == 1 ? ['2D'] : ['hidden'],
        'handCount': 1,
        'stack': (stolen ? 'p$i' == actor : i == 1) ? ['KH'] : [],
        'topCard': (stolen ? 'p$i' == actor : i == 1) ? 'KH' : null,
        'stackCount': (stolen ? 'p$i' == actor : i == 1) ? 1 : 0,
      }),
    }));
  }
}

void main() {
  for (final count in [2, 3, 4]) {
    testWidgets('top thief animation connects visible stacks with $count players',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 736));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = StealController(count);
      await tester.pumpWidget(ProviderScope(
        overrides: [gameControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: GameScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      Finder capturedCard() => find.byWidgetPredicate((w) =>
          w is Image && w.image is AssetImage &&
          (w.image as AssetImage).assetName.endsWith('/Hearts/King.png'));
      final source = tester.getCenter(capturedCard());
      controller.update(stolen: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final overlay = tester.widget<BikeDaketiOverlay>(find.byType(BikeDaketiOverlay));
      final canvas = tester.renderObject<RenderBox>(find.byKey(GameViewport.canvasKey));
      expect((canvas.localToGlobal(overlay.source) - source).distance, lessThan(1));
      // The flying card is not yet displayed at 500ms, leaving only the
      // recipient's real captured card to compare with the destination.
      final destination = tester.getCenter(capturedCard());
      expect((canvas.localToGlobal(overlay.destination) - destination).distance,
          lessThan(1));
      expect(overlay.isLocalVictim, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
