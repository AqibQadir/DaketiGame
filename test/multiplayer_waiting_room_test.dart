import 'dart:async';

import 'package:daketi_phase1_modular/core/widgets/game_button.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/game/data/game_api_exception.dart';
import 'package:daketi_phase1_modular/features/game/data/game_rest_client.dart';
import 'package:daketi_phase1_modular/features/game/data/game_socket_service.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/daketi_game.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/waiting_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> room(
        {int count = 2, bool ready = false, String status = 'waiting'}) =>
    {
      'gameId': '0093',
      'status': status,
      'maxPlayers': count,
      'players': List.generate(
          count,
          (i) => {
                'id': 'p$i',
                'name': 'Player $i',
                'type': 'human',
                'isReady': i == 0 && ready,
                'isConnected': true,
              }),
    };

class RoomSocket extends GameSocketService {
  RoomSocket() : super(serverUrl: 'http://localhost');
  final updates = StreamController<GameSocketEvent>.broadcast(sync: true);
  int joins = 0;
  int readyCalls = 0;
  final readyValues = <bool>[];
  bool connected = false;
  int count = 2;
  Completer<Map<String, dynamic>>? pendingReady;
  Completer<Map<String, dynamic>>? pendingJoin;
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
      String? token,
      String? reconnectToken}) async {
    joins++;
    if (pendingJoin != null) return pendingJoin!.future;
    return {'success': true, 'playerId': 'p0', 'gameState': room(count: count)};
  }

  @override
  Future<Map<String, dynamic>> playerReady(String gameId) {
    expect(gameId, '0093');
    readyCalls++;
    readyValues.add(true);
    return (pendingReady = Completer<Map<String, dynamic>>()).future;
  }

  void update(String event, Map<String, dynamic> game) =>
      updates.add(GameSocketEvent(event, {'gameState': game}));
  @override
  void dispose() {
    updates.close();
    super.dispose();
  }
}

void main() {
  late RoomSocket socket;
  late GameRestClient rest;
  late GameController controller;
  setUp(() {
    socket = RoomSocket();
    rest = GameRestClient(baseUrl: 'http://localhost');
    controller = GameController(restClient: rest, socketService: socket);
  });
  tearDown(() {
    controller.dispose();
    socket.dispose();
    rest.dispose();
  });
  Future<void> join() async {
    expect(
        await controller.joinExistingGame(
            gameId: '0093', playerName: 'Player 0'),
        isTrue);
  }

  test('initial connect joins once and preserves zero-padded code', () async {
    await join();
    expect(socket.joins, 1);
    expect(controller.state.gameId, '0093');
  });

  test('explicit join after connection loss does not join twice', () async {
    await join();
    socket.connected = false;
    await join();
    expect(socket.joins, 2);
  });

  test('reconnection during Ready still rejoins the room', () async {
    await join();
    final pending = controller.sendReady();
    socket.updates.add(const GameSocketEvent('disconnected', {}));
    await socket.connect();
    await Future<void>.delayed(Duration.zero);
    expect(socket.joins, 2);
    socket.pendingReady!.complete({'success': true});
    await pending;
  });

  test('late ready acknowledgement cannot undo game_started', () async {
    await join();
    final pending = controller.sendReady();
    await controller.sendReady();
    expect(socket.readyCalls, 1);
    socket.update('game_started', room(ready: true, status: 'playing'));
    socket.pendingReady!.complete({'success': true, 'gameState': room()});
    await pending;
    expect(controller.state.game!.status, DaketiGameStatus.playing);
    expect(controller.state.game!.playerById('p0')!.isReady, isTrue);
    expect(controller.state.isLoading, isFalse);
  });

  test('player joining preserves server readiness; ready errors allow retry',
      () async {
    await join();
    socket.update('player_ready', room(ready: true));
    socket.update('player_joined', room(count: 3, ready: true));
    expect(controller.state.game!.playerById('p0')!.isReady, isTrue);
    socket.update('player_ready', room());
    final pending = controller.sendReady();
    socket.pendingReady!.completeError(const GameApiException('Please retry'));
    await pending;
    expect(controller.state.error, 'Please retry');
    expect(controller.state.isLoading, isFalse);
    final retry = controller.sendReady();
    socket.update('player_ready', room(ready: true));
    socket.pendingReady!.complete({'success': true});
    await retry;
    expect(controller.state.error, isNull);
    expect(controller.state.game!.playerById('p0')!.isReady, isTrue);
  });

  test('late join acknowledgement cannot undo a started room', () async {
    socket.pendingJoin = Completer<Map<String, dynamic>>();
    final joining =
        controller.joinExistingGame(gameId: '0093', playerName: 'Player 0');
    await Future<void>.delayed(Duration.zero);
    socket.update('game_started', room(status: 'playing'));
    socket.pendingJoin!.complete({'playerId': 'p0', 'gameState': room()});
    expect(await joining, isTrue);
    expect(controller.state.game!.status, DaketiGameStatus.playing);
    expect(controller.state.isMultiplayer, isTrue);
  });

  testWidgets('already started room opens the game on first frame',
      (tester) async {
    await join();
    socket.update('game_started', room(status: 'playing'));
    await tester.pumpWidget(ProviderScope(
      overrides: [gameControllerProvider.overrideWith((ref) => controller)],
      child: MaterialApp(home: const WaitingRoomScreen(), routes: {
        AppRoutes.game: (_) => const Scaffold(body: Text('Game opened')),
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Game opened'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller = GameController(restClient: rest, socketService: socket);
  });

  testWidgets(
      'Ready waits for other players without offering unsupported Unready',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await join();
    await tester.pumpWidget(ProviderScope(
      overrides: [gameControllerProvider.overrideWith((ref) => controller)],
      child: const MaterialApp(home: WaitingRoomScreen()),
    ));
    await tester.pumpAndSettle();
    final button = find.byType(GameButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(socket.readyValues, [true]);
    expect(tester.widget<GameButton>(button).onTap, isNull);
    socket.pendingReady!
        .complete({'success': true, 'gameState': room(ready: true)});
    await tester.pumpAndSettle();
    expect(tester.widget<GameButton>(button).text, 'Waiting…');
    expect(tester.widget<GameButton>(button).onTap, isNull);
    await controller.sendReady();
    expect(socket.readyCalls, 1);
    expect(controller.state.game!.playerById('p0')!.isReady, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller = GameController(restClient: rest, socketService: socket);
  });

  for (final count in [2, 3, 4]) {
    testWidgets(
        '$count-player room Ready is reachable on short landscape screen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      socket.count = count;
      await join();
      await tester.pumpWidget(ProviderScope(
        overrides: [gameControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          home: const WaitingRoomScreen(),
          routes: {
            AppRoutes.game: (_) => const Scaffold(body: Text('Game opened'))
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final button = find.byType(GameButton);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      expect(socket.readyCalls, 1);
      socket.pendingReady!
          .completeError(const GameApiException('Ready failed. Try again.'));
      await tester.pumpAndSettle();
      expect(find.text('Ready failed. Try again.'), findsOneWidget);
      expect(tester.widget<GameButton>(button).onTap, isNotNull);
      expect(tester.takeException(), isNull);
      final retry = controller.sendReady();
      socket.update(
          'game_started', room(count: count, ready: true, status: 'playing'));
      socket.pendingReady!
          .complete({'success': true, 'gameState': room(count: count)});
      await retry;
      await tester.pumpAndSettle();
      expect(find.text('Game opened'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // ProviderScope owns the controller once mounted.
      await tester.pumpWidget(const SizedBox());
      controller = GameController(restClient: rest, socketService: socket);
    });
  }
}
