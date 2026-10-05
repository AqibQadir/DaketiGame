import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/game/data/game_api_exception.dart';
import 'package:daketi_phase1_modular/features/game/data/game_socket_service.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/daketi_game.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/game_action.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';

import 'api_guide_integration_test.dart'
    show MemoryAuthStorage, jsonResponse, user;
import 'game_recovery_test.dart'
    show RecoveryRest, RecoverySocket, MemoryStorage, snapshot;

class DelayedSocket extends RecoverySocket {
  Completer<Map<String, dynamic>>? pendingJoin;
  Completer<Map<String, dynamic>>? pendingAction;
  int moves = 0;
  Completer<Map<String, dynamic>>? pendingActions;

  @override
  Future<Map<String, dynamic>> getActions(String gameId) =>
      pendingActions?.future ?? super.getActions(gameId);

  @override
  Future<Map<String, dynamic>> joinGame(
      {required String gameId,
      required String playerName,
      String? token,
      String? reconnectToken}) {
    if (pendingJoin != null) return pendingJoin!.future;
    return super.joinGame(
        gameId: gameId,
        playerName: playerName,
        token: token,
        reconnectToken: reconnectToken);
  }

  @override
  Future<Map<String, dynamic>> performAction(
      String event, Map<String, dynamic> payload) {
    moves++;
    return pendingAction?.future ?? super.performAction(event, payload);
  }
}

void main() {
  group('game session isolation', () {
    late DelayedSocket socket;
    late RecoveryRest rest;
    late MemoryStorage storage;
    late GameController controller;
    setUp(() {
      socket = DelayedSocket();
      rest = RecoveryRest();
      storage = MemoryStorage();
      controller = GameController(
          restClient: rest,
          socketService: socket,
          previousGameStorage: storage);
    });
    tearDown(() {
      controller.dispose();
      socket.dispose();
      rest.dispose();
    });
    Future<bool> join() =>
        controller.joinExistingGame(gameId: '0093', playerName: 'Player');
    const discard = GameAction(type: GameActionType.discard, cardId: '2D');

    test('logout/reset while joining cannot restore an abandoned session',
        () async {
      socket.pendingJoin = Completer();
      final pending = join();
      await Future<void>.delayed(Duration.zero);
      controller.resetSession();
      socket.pendingJoin!.complete({
        'playerId': 'p0',
        'gameState': snapshot(),
        'reconnectToken': 'secret'
      });
      expect(await pending, isFalse);
      expect(controller.state.gameId, isNull);
      expect(controller.state.playerId, isNull);
      expect(storage.saved, isNull);
    });

    test('a late action failure cannot overwrite a new session', () async {
      await join();
      socket.pendingAction = Completer();
      final moving = controller.performAction(discard);
      controller.resetSession();
      await join();
      socket.pendingAction!
          .completeError(const GameApiException('Old failure'));
      expect(await moving, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.gameId, '0093');
    });

    test('an old timeout cannot play a card in a newly joined game', () async {
      await join();
      socket.pendingActions = Completer();
      final timeout = controller.handleTurnTimeout();
      controller.resetSession();
      await join();
      socket.pendingActions!.complete({
        'actions': [
          {'type': 'discard', 'cardId': '2D'}
        ]
      });
      expect(await timeout, isFalse);
      expect(socket.moves, 0);
      expect(controller.state.error, isNull);
    });

    test('duplicate taps emit exactly one mutation', () async {
      await join();
      socket.pendingAction = Completer();
      final first = controller.performAction(discard);
      expect(await controller.performAction(discard), isFalse);
      expect(socket.moves, 1);
      socket.pendingAction!.complete({
        'gameState': {...snapshot(), 'currentPlayerId': 'p1'}
      });
      expect(await first, isTrue);
    });

    test('game_over wins over an older action acknowledgement', () async {
      await join();
      socket.pendingAction = Completer();
      final moving = controller.performAction(discard);
      socket.updates.add(GameSocketEvent('game_over', {
        'winner': 'p0',
        'scores': [
          {'id': 'p0', 'score': 52}
        ],
        'gameState': {...snapshot(status: 'finished'), 'winner': 'p0'}
      }));
      socket.pendingAction!.complete({'gameState': snapshot()});
      await moving;
      expect(controller.state.game?.status, DaketiGameStatus.finished);
      expect(controller.state.winner, 'p0');
      expect(await controller.performAction(discard), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(storage.saved, isNull);
    });

    test('old room events after logout are ignored, even without a gameId',
        () async {
      await join();
      controller.resetSession();
      socket.updates.add(const GameSocketEvent('game_over', {
        'winner': 'p0',
        'scores': [
          {'id': 'p0', 'score': 10}
        ]
      }));
      expect(controller.state.winner, isNull);
      expect(controller.state.scores, isEmpty);
    });

    test(
        'stale AI snapshot losing the reclaimed identity triggers seat recovery',
        () async {
      await join();
      socket.playerId = 'new-socket';
      socket.reclaimed = true;
      expect(await controller.resumePreviousGame(), isTrue);
      final priorJoins = socket.joins;
      socket.updates.add(GameSocketEvent(
          'ai_action', {'action': 'discard', 'gameState': snapshot()}));
      await Future<void>.delayed(Duration.zero);
      expect(socket.joins, priorJoins + 1);
      expect(socket.receivedReconnectToken, 'seat-secret');
      expect(controller.state.playerId, 'new-socket');
      expect(controller.state.game?.playerById('new-socket'), isNotNull);
    });

    test('manually entering the previous room code reuses its seat token',
        () async {
      await join();
      controller.resetSession();
      await join();
      expect(socket.receivedReconnectToken, 'seat-secret');
    });
  });

  test('pending email verification error cannot resurrect a logged-out account',
      () async {
    final verification = Completer<http.Response>();
    final api = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async => r.url.path.endsWith('verify-email')
            ? verification.future
            : jsonResponse({'success': true, 'user': user, 'stats': {}})));
    final controller =
        AuthController(client: api, storage: MemoryAuthStorage());
    addTearDown(() {
      controller.dispose();
      api.dispose();
    });
    await Future<void>.delayed(Duration.zero);
    final pending = controller.verifyEmail('email-token');
    await controller.logout();
    verification.complete(
        jsonResponse({'success': false, 'error': 'Expired link'}, 400));
    expect(await pending, isFalse);
    expect(controller.state.isAuthenticated, isFalse);
    expect(controller.state.user, isNull);
  });

  test('logout ends access immediately and cleanup cannot erase a later login',
      () async {
    final cleanup = Completer<void>();
    final storage = MemoryAuthStorage();
    final api = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async => jsonResponse(
            {'success': true, 'token': 'new-jwt', 'user': user, 'stats': {}})));
    final controller = AuthController(
        client: api, storage: storage, beforeLogout: (_) => cleanup.future);
    addTearDown(() {
      controller.dispose();
      api.dispose();
    });
    await Future<void>.delayed(Duration.zero);
    final logout = controller.logout();
    expect(controller.state.isAuthenticated, isFalse);
    expect(await controller.refreshSession(), isFalse);
    expect(
        await controller.login(email: 'ali@example.com', password: 'password1'),
        isTrue);
    cleanup.complete();
    await logout;
    expect(controller.state.token, 'new-jwt');
    expect(storage.token, 'new-jwt');
  });

  test('an old authenticated 401 cannot expire a newly logged-in account',
      () async {
    final verification = Completer<http.Response>();
    final api = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async {
          if (r.url.path.endsWith('resend-verification')) {
            return verification.future;
          }
          return jsonResponse(
              {'success': true, 'token': 'new-jwt', 'user': user, 'stats': {}});
        }));
    final controller =
        AuthController(client: api, storage: MemoryAuthStorage());
    addTearDown(() {
      controller.dispose();
      api.dispose();
    });
    await Future<void>.delayed(Duration.zero);
    final pending = controller.resendVerification();
    final assertion = expectLater(pending, throwsA(isA<GameApiException>()));
    await controller.logout();
    await controller.login(email: 'ali@example.com', password: 'password1');
    verification
        .complete(jsonResponse({'success': false, 'error': 'Expired'}, 401));
    await assertion;
    expect(controller.state.token, 'new-jwt');
  });
}
