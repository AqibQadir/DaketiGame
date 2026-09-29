import 'dart:async';

import 'package:daketi_phase1_modular/features/game/data/game_api_exception.dart';
import 'package:daketi_phase1_modular/features/game/data/game_rest_client.dart';
import 'package:daketi_phase1_modular/features/game/data/game_socket_service.dart';
import 'package:daketi_phase1_modular/features/game/data/previous_game_storage.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/daketi_game.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daketi_phase1_modular/features/home/presentation/screens/home_screen.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';

Map<String, dynamic> snapshot({String status = 'playing'}) => {
      'gameId': '0093',
      'status': status,
      'currentPlayerId': 'p0',
      'players': [
        {
          'id': 'p0',
          'name': 'Player',
          'type': 'human',
          'hand': ['KH', '2D', '8C']
        }
      ],
    };

class MemoryStorage extends PreviousGameStorage {
  PreviousGame? saved;
  @override
  Future<PreviousGame?> read() async => saved;
  @override
  Future<void> write(PreviousGame game) async {
    saved = game;
  }

  @override
  Future<void> clear() async {
    saved = null;
  }
}

class RecoveryRest extends GameRestClient {
  RecoveryRest() : super(baseUrl: 'http://localhost');
  String status = 'playing';
  bool offline = false;
  @override
  Future<DaketiGame> getGame(String gameId) async {
    if (offline) throw const GameApiException('Offline');
    return DaketiGame.fromJson(snapshot(status: status));
  }
}

class RecoverySocket extends GameSocketService {
  RecoverySocket() : super(serverUrl: 'http://localhost');
  final updates = StreamController<GameSocketEvent>.broadcast(sync: true);
  bool connected = false;
  int joins = 0;
  String playerId = 'p0';
  String? discarded;
  @override
  Stream<GameSocketEvent> get events => updates.stream;
  @override
  bool get isConnected => connected;
  @override
  Future<void> connect() async {
    connected = true;
    updates.add(const GameSocketEvent('connected', {}));
  }

  @override
  Future<Map<String, dynamic>> joinGame(
      {required String gameId,
      required String playerName,
      String? token}) async {
    joins++;
    return {'playerId': playerId, 'gameState': snapshot()};
  }

  @override
  Future<Map<String, dynamic>> getActions(String gameId) async => {
        'actions': [
          for (final card in ['KH', '2D', '8C'])
            {'type': 'discard', 'cardId': card}
        ],
      };
  @override
  Future<Map<String, dynamic>> performAction(
      String event, Map<String, dynamic> payload) async {
    discarded = payload['cardId'] as String;
    return {
      'gameState': {...snapshot(), 'currentPlayerId': 'p1'}
    };
  }

  @override
  void dispose() {
    updates.close();
    super.dispose();
  }
}

void main() {
  late MemoryStorage storage;
  late RecoveryRest rest;
  late RecoverySocket socket;
  late GameController controller;
  GameController makeController() => GameController(
      restClient: rest, socketService: socket, previousGameStorage: storage);
  setUp(() {
    storage = MemoryStorage();
    rest = RecoveryRest();
    socket = RecoverySocket();
    controller = makeController();
  });
  tearDown(() {
    if (controller.mounted) controller.dispose();
    socket.dispose();
    rest.dispose();
  });
  Future<void> join() async {
    expect(
        await controller.joinExistingGame(gameId: '0093', playerName: 'Player'),
        isTrue);
  }

  test('room survives app restart and rejoins the original seat once',
      () async {
    await join();
    expect(storage.saved?.gameId, '0093');
    controller.dispose();
    socket.connected = false;
    controller = makeController();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.previousGame?.gameId, '0093');
    expect(await controller.resumePreviousGame(), isTrue);
    expect(socket.joins, 2);
    expect(controller.state.playerId, 'p0');
    expect(controller.state.isMultiplayer, isTrue);
    expect(controller.state.isResumedGame, isTrue);
    expect(controller.state.game?.status, DaketiGameStatus.playing);
  });

  testWidgets('long disconnect keeps the room available for retry',
      (tester) async {
    controller.dispose();
    controller = makeController();
    await join();
    socket.connected = false;
    socket.updates.add(const GameSocketEvent('disconnected', {}));
    await tester.pump(const Duration(seconds: 16));
    expect(controller.state.recoveryFailed, isTrue);
    expect(controller.state.gameId, '0093');
    expect(controller.state.previousGame?.gameId, '0093');
    expect(await controller.resumePreviousGame(), isTrue);
    expect(controller.state.recoveryFailed, isFalse);
    expect(socket.joins, 2);
  });

  test('temporary fetch failure preserves retry, finished room clears it',
      () async {
    await join();
    rest.offline = true;
    expect(await controller.resumePreviousGame(), isFalse);
    expect(storage.saved, isNotNull);
    rest.offline = false;
    rest.status = 'finished';
    expect(await controller.resumePreviousGame(), isFalse);
    expect(storage.saved, isNull);
    expect(controller.state.previousGame, isNull);
  });

  test('rejoin refuses a replacement seat', () async {
    await join();
    socket.playerId = 'p9';
    expect(await controller.resumePreviousGame(), isFalse);
    expect(controller.state.error, contains('original seat'));
    expect(controller.state.playerId, 'p0');
    expect(storage.saved, isNotNull);
  });

  test('timeout discards the smallest legal card even with a larger selection',
      () async {
    await join();
    expect(await controller.handleTurnTimeout(selectedCardId: 'KH'), isTrue);
    expect(socket.discarded, '2D');
  });

  testWidgets(
      'Home offers a reachable top-right rejoin into the shared game route',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await join();
    await tester.pumpWidget(ProviderScope(
      overrides: [gameControllerProvider.overrideWith((ref) => controller)],
      child: MaterialApp(home: const HomeScreen(), routes: {
        AppRoutes.game: (_) => const Scaffold(body: Text('Resumed game')),
      }),
    ));
    await tester.pump();
    final button = find.text('JOIN PREVIOUS GAME');
    expect(button, findsOneWidget);
    expect(tester.getCenter(button).dx, greaterThan(600));
    expect(tester.getCenter(button).dy, lessThan(60));
    expect(tester.takeException(), isNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Resumed game'), findsOneWidget);
    expect(socket.joins, 2);
  });

  test('completion clears saved room but another room event cannot clear it',
      () async {
    await join();
    socket.updates.add(const GameSocketEvent('game_over', {'gameId': '9999'}));
    expect(controller.state.previousGame, isNotNull);
    socket.updates.add(GameSocketEvent(
        'game_over', {'gameState': snapshot(status: 'finished')}));
    await Future<void>.delayed(Duration.zero);
    expect(storage.saved, isNull);
    expect(controller.state.previousGame, isNull);
  });
}
