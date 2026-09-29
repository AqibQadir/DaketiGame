import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/guest_name_provider.dart';
import 'package:daketi_phase1_modular/features/game/data/game_rest_client.dart';
import 'package:daketi_phase1_modular/features/game/data/game_socket_service.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/daketi_game.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/game_action.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/game_results_screen.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/game_screen.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/multiplayer_screen.dart';
import 'package:daketi_phase1_modular/features/game/presentation/widgets/fanned_card_hand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FlowController extends GameController {
  FlowController({int count = 4, bool resumed = false, bool expired = false})
      : super(
          restClient: GameRestClient(baseUrl: 'http://localhost'),
          socketService: GameSocketService(serverUrl: 'http://localhost'),
        ) {
    state = GameSessionState(
        isMultiplayer: true,
        isResumedGame: resumed,
        gameId: '0093',
        playerId: 'p1',
        playerName: 'Human 1',
        connectionStatus: GameConnectionStatus.connected,
        game: DaketiGame.fromJson({
          'gameId': '0093',
          'status': 'playing',
          'maxPlayers': count,
          'currentPlayerId': 'p1',
          'deckCount': 20,
          'table': ['3H', '4D'],
          'turnStartTime':
              DateTime.now().millisecondsSinceEpoch - (expired ? 60000 : 0),
          'players': List.generate(
              count,
              (i) => {
                    'id': 'p$i',
                    'name': 'Human $i',
                    'type': 'human',
                    'isConnected': true,
                    'hand': i == 1 ? ['2D', 'KH'] : ['hidden', 'hidden'],
                    'handCount': 2,
                    'stackCount': 0,
                  }),
        }));
  }
  int timeoutCalls = 0;
  @override
  Future<bool> handleTurnTimeout({String? selectedCardId}) async {
    timeoutCalls++;
    return true;
  }

  int soloCalls = 0;
  int? requestedCapacity;
  String? joinedCode;
  @override
  Future<void> loadAvailableActions() async {
    state = state.copyWith(availableActions: [
      for (final type in GameActionType.values
          .where((type) => type != GameActionType.unknown))
        GameAction(
            type: type,
            cardId: 'KH',
            targetPlayerId: type == GameActionType.stealOpponent ? 'p0' : null),
    ]);
  }

  GameAction? performed;
  @override
  Future<bool> performAction(GameAction action) async {
    performed = action;
    return true;
  }

  @override
  Future<bool> createMultiplayerRoom(
      {required String playerName, int maxPlayers = 4}) async {
    requestedCapacity = maxPlayers;
    return true;
  }

  @override
  Future<bool> joinExistingGame(
      {required String gameId,
      required String playerName,
      bool preserveLoading = false}) async {
    joinedCode = gameId;
    return true;
  }

  @override
  Future<bool> replaySolo() async {
    soloCalls++;
    return false;
  }
}

void main() {
  for (final count in [2, 3, 4]) {
    testWidgets('$count humans use the same board, names and opening deal',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = FlowController(count: count);
      await tester.pumpWidget(ProviderScope(
        overrides: [gameControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: GameScreen()),
      ));
      expect(find.text('DEALING CARDS…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('DEALING CARDS…'), findsNothing);
      for (var i = 0; i < count; i++) {
        expect(find.text('HUMAN $i'), findsWidgets);
      }
      final hand = tester.widget<FannedCardHand>(find.byType(FannedCardHand));
      expect(hand.cards.map((card) => card.id), ['2D', 'KH']);
      expect(hand.enabled, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('rejoined board shows the current hand without dealing again',
      (tester) async {
    final controller = FlowController(resumed: true);
    await tester.pumpWidget(ProviderScope(
      overrides: [gameControllerProvider.overrideWith((ref) => controller)],
      child: const MaterialApp(home: GameScreen()),
    ));
    await tester.pump();
    expect(find.text('DEALING CARDS…'), findsNothing);
    expect(tester.widget<FannedCardHand>(find.byType(FannedCardHand)).enabled,
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an already expired turn on rejoin triggers timeout once',
      (tester) async {
    final controller = FlowController(resumed: true, expired: true);
    await tester.pumpWidget(ProviderScope(
      overrides: [gameControllerProvider.overrideWith((ref) => controller)],
      child: const MaterialApp(home: GameScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.timeoutCalls, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final entry in {
    'TAKE MATCHING CARDS': GameActionType.captureTable,
    "STEAL OPPONENT'S CARD": GameActionType.stealOpponent,
    'ADD CARD TO OWN DECK': GameActionType.extendStack,
    'PLAY CARD, END TURN': GameActionType.discard,
  }.entries) {
    testWidgets('multiplayer selected card exposes ${entry.key}',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = FlowController(resumed: true);
      await tester.pumpWidget(ProviderScope(
        overrides: [gameControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: GameScreen()),
      ));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('K of H'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(entry.key));
      await tester.pump();
      expect(controller.performed?.type, entry.value);
      expect(controller.performed?.cardId, 'KH');
      if (entry.value == GameActionType.stealOpponent) {
        expect(controller.performed?.targetPlayerId, 'p0');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'multiplayer play again returns to rooms without creating a solo game',
      (tester) async {
    final controller = FlowController();
    await tester.pumpWidget(ProviderScope(
      overrides: [gameControllerProvider.overrideWith((ref) => controller)],
      child: MaterialApp(home: const GameResultsScreen(), routes: {
        AppRoutes.multiplayer: (_) => const Scaffold(body: Text('Room setup')),
      }),
    ));
    await tester.pump();
    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pumpAndSettle();
    expect(find.text('Room setup'), findsOneWidget);
    expect(controller.soloCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest identity returns to room setup and continues create',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = FlowController();
    final container = ProviderContainer(overrides: [
      gameControllerProvider.overrideWith((ref) => controller),
    ]);
    addTearDown(container.dispose);
    container.read(guestAgeProvider.notifier).state = 25;
    container.read(guestGenderProvider.notifier).state = 'Male';
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          home: const MultiplayerScreen(),
          onGenerateRoute: AppRouter.onGenerateRoute,
          routes: {
            AppRoutes.game: (_) => const Scaffold(body: Text('Game opened'))
          }),
    ));
    await tester.pump();
    await tester.tap(find.text('3 PLAYERS'));
    await tester.tap(find.text('CREATE ROOM'));
    await tester.pumpAndSettle();
    expect(find.text('PLAY AS GUEST'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Guest human');
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(controller.requestedCapacity, 3);
    expect(find.text('Game opened'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
