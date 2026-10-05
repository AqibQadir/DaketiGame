import 'package:daketi_phase1_modular/features/game/domain/models/daketi_game.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/game_screen.dart';
import 'package:daketi_phase1_modular/features/game/presentation/widgets/bike_daketi_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multiplayer_game_flow_test.dart' show FlowController;

class TimerController extends FlowController {
  TimerController() : super(count: 2, resumed: true);

  void move({required String actor, required bool stolen}) {
    state = state.copyWith(
      turnTimerRevision: state.turnTimerRevision + 1,
      game: DaketiGame.fromJson({
        'gameId': '0093',
        'status': 'playing',
        'currentPlayerId': actor,
        'turnStartTime': DateTime.now().millisecondsSinceEpoch - 60000,
        'deckCount': 20,
        'table': ['3H', '4D'],
        'players': [
          {
            'id': 'p0',
            'handCount': 2,
            'stack': stolen ? ['KH'] : [],
            'stackCount': stolen ? 1 : 0
          },
          {
            'id': 'p1',
            'hand': ['2D'],
            'handCount': 1,
            'stack': stolen ? [] : ['KH'],
            'stackCount': stolen ? 0 : 1
          },
        ],
      }),
    );
  }
}

double ringProgress(WidgetTester tester) {
  final paint = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .firstWhere(
          (w) => w.painter.runtimeType.toString() == '_TurnTimerRingPainter');
  return (paint.painter as dynamic).progress as double;
}

void main() {
  testWidgets(
      'moves reset stale timestamps and stealing holds zero until complete',
      (tester) async {
    final controller = TimerController();
    await tester.pumpWidget(ProviderScope(
      overrides: [gameControllerProvider.overrideWith((ref) => controller)],
      child: const MaterialApp(home: GameScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 1));

    controller.move(actor: 'p0', stolen: false);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(ringProgress(tester), greaterThan(.95));

    controller.move(actor: 'p0', stolen: true);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(BikeDaketiOverlay), findsOneWidget);
    expect(ringProgress(tester), 0);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(ringProgress(tester), 0);
    expect(controller.timeoutCalls, 0);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(BikeDaketiOverlay), findsNothing);
    expect(ringProgress(tester), greaterThan(.95));

    controller.move(actor: 'p1', stolen: true);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(ringProgress(tester), greaterThan(.95));
    expect(controller.timeoutCalls, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
