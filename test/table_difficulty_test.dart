import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/guest_name_provider.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/screens/guest_opponent_screen.dart';
import 'package:daketi_phase1_modular/features/game/data/game_rest_client.dart';
import 'package:daketi_phase1_modular/features/game/data/game_socket_service.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';
import 'package:daketi_phase1_modular/features/tables/domain/table_match_selection.dart';
import 'package:daketi_phase1_modular/features/tables/domain/table_room.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/screens/table_room_screen.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/widgets/table_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingGameController extends GameController {
  RecordingGameController()
      : super(
          restClient: GameRestClient(baseUrl: 'http://localhost'),
          socketService: GameSocketService(serverUrl: 'http://localhost'),
        );

  String? requestedDifficulty;
  int? requestedOpponents;

  @override
  Future<bool> createSoloGame({
    required String playerName,
    int aiCount = 1,
    String difficulty = 'master',
  }) async {
    requestedDifficulty = difficulty;
    requestedOpponents = aiCount;
    return false;
  }
}

void main() {
  for (final room in TableRoom.values.where((room) => !room.locked)) {
    for (final tier in TableTier.values) {
      testWidgets('${room.name} ${tier.name} chooses AI automatically',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(844, 390));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = RecordingGameController();
        final container = ProviderContainer(overrides: [
          gameControllerProvider.overrideWith((ref) => controller),
        ]);
        addTearDown(container.dispose);
        container.read(guestNameProvider.notifier).state = 'Table player';
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: TableRoomScreen(room: room),
          ),
        ));
        await tester.pumpAndSettle();
        final card = find.byWidgetPredicate(
            (widget) => widget is TableCard && widget.title == tier.title);
        await tester
            .tap(find.descendant(of: card, matching: find.text('ENTER MATCH')));
        await tester.pumpAndSettle();
        if (tier.locked) {
          expect(find.byType(GuestOpponentScreen), findsNothing);
          expect(controller.requestedDifficulty, isNull);
          expect(tester.takeException(), isNull);
          return;
        }
        final setup = tester
            .widget<GuestOpponentScreen>(find.byType(GuestOpponentScreen));
        expect(setup.tableSelection?.room, room);
        expect(setup.tableSelection?.tier, tier);
        expect(find.text('AI DIFFICULTY'), findsNothing);
        expect(find.text('BEGINNER'), findsNothing);
        expect(find.text('MASTER'), findsNothing);
        expect(find.text('CUSTOM'), findsNothing);
        await tester.tap(find.text('3 OPPONENTS'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('PLAY'));
        await tester.pumpAndSettle();
        expect(
            controller.requestedDifficulty,
            room == TableRoom.oldLahore && tier == TableTier.silver
                ? 'beginner'
                : 'master');
        expect(controller.requestedOpponents, 3);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('guest game retains manual difficulty selection', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = RecordingGameController();
    await tester.pumpWidget(ProviderScope(
      overrides: [gameControllerProvider.overrideWith((ref) => controller)],
      child: MaterialApp(
        initialRoute: AppRoutes.guestOpponents,
        onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
            RouteSettings(name: settings.name, arguments: 'Guest tester')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('AI DIFFICULTY'), findsOneWidget);
    expect(find.text('CUSTOM'), findsOneWidget);
    await tester.tap(find.text('BEGINNER'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(controller.requestedDifficulty, 'beginner');
    expect(tester.takeException(), isNull);
  });
}
