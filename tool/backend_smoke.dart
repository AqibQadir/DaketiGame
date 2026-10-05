// Run: dart run tool/backend_smoke.dart [--play-guest] [https://server]
// Default: read-only checks. --play-guest creates and plays one unranked solo
// game and deliberately reconnects once. No accounts, emails or JWTs involved.
import 'dart:async';
import 'dart:io';

import 'package:daketi_phase1_modular/features/game/data/game_rest_client.dart';
import 'package:daketi_phase1_modular/features/game/data/game_socket_service.dart';

Future<void> main(List<String> args) async {
  final baseUrl = args.where((a) => a.startsWith('http')).firstOrNull ??
      'https://game.daketi.pk';
  final rest = GameRestClient(baseUrl: baseUrl);
  final socket = GameSocketService(serverUrl: baseUrl);
  StreamSubscription<GameSocketEvent>? subscription;
  try {
    if (!await rest.healthCheck()) throw StateError('Health check failed');
    stdout.writeln('PASS health');
    final stats = await rest.getServerStats();
    stdout.writeln('PASS stats (${stats.keys.join(', ')})');
    await socket.connect();
    stdout.writeln('PASS WebSocket-only Socket.io connection');
    if (!args.contains('--play-guest')) return;

    var latest = <String, dynamic>{};
    var revision = 0;
    var finished = false;
    var aiSteps = 0;
    subscription = socket.events.listen((event) {
      if (event.data['gameState'] is Map) {
        latest = Map<String, dynamic>.from(event.data['gameState'] as Map);
        revision++;
      }
      if (event.name == 'game_over') finished = true;
      if (event.name == 'ai_action') aiSteps++;
    });
    final created = await rest.createSoloGame(
        playerName: 'Daketi Integration QA',
        aiCount: 1,
        difficulty: 'beginner');
    var joined = await socket.joinGame(
        gameId: created.gameId, playerName: 'Daketi Integration QA');
    var playerId = joined['playerId'] as String;
    final seat = joined['reconnectToken'] as String?;
    if (seat == null || seat.isEmpty) {
      throw StateError('Missing reconnect token');
    }
    latest = Map<String, dynamic>.from(joined['gameState'] as Map);
    stdout.writeln('PASS guest solo join, room ${created.gameId}');
    if (args.contains('--reconnect-during-ai')) {
      // Give the turn to AI before interrupting the transport, to exercise
      // its in-flight snapshot/seat-reclaim race deterministically.
      for (var step = 0;
          step < 12 && latest['currentPlayerId'] == playerId;
          step++) {
        final legal = await socket.getActions(created.gameId);
        final actions = (legal['actions'] as List).cast<Map>();
        final action = actions.firstWhere((a) => a['type'] == 'discard',
            orElse: () => actions.first);
        final before = revision;
        final result = await socket.performAction(
            action['type'] == 'discard'
                ? 'discard_card'
                : action['type'] as String,
            {
              'gameId': created.gameId,
              'cardId': action['cardId'],
              if (action['targetPlayerId'] != null)
                'targetPlayerId': action['targetPlayerId']
            });
        if (before == revision && result['gameState'] is Map) {
          latest = Map<String, dynamic>.from(result['gameState'] as Map);
        }
      }
      stdout.writeln('Testing reclaim during an AI turn');
    }
    socket.disconnect();
    await socket.connect();
    joined = await socket.joinGame(
        gameId: created.gameId,
        playerName: 'Daketi Integration QA',
        reconnectToken: seat);
    if (joined['reclaimed'] != true || joined['playerId'] == playerId) {
      throw StateError('Seat was not reclaimed on a new socket');
    }
    playerId = joined['playerId'] as String;
    latest = Map<String, dynamic>.from(joined['gameState'] as Map);
    stdout.writeln('PASS reconnect token reclaims seat with a new player ID');
    stdout.writeln(
        'State after reclaim: status=${latest['status']}, localTurn=${latest['currentPlayerId'] == playerId}, deck=${latest['deckCount']}');

    final deadline = DateTime.now().add(const Duration(minutes: 4));
    var moves = 0;
    var seatRepairs = 0;
    var lastReport = DateTime.now();
    while (!finished && latest['status'] != 'finished') {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
            'Guest match: status=${latest['status']}, localTurn=${latest['currentPlayerId'] == playerId}, moves=$moves, AI steps=$aiSteps');
      }
      if (DateTime.now().difference(lastReport).inSeconds >= 10) {
        stdout.writeln(
            'Progress: moves=$moves, AI steps=$aiSteps, connected=${socket.isConnected}, localTurn=${latest['currentPlayerId'] == playerId}, deck=${latest['deckCount']}');
        lastReport = DateTime.now();
      }
      if (!(latest['players'] as List).any((p) => p['id'] == playerId)) {
        if (++seatRepairs > 5) {
          throw StateError('Server repeatedly lost the reclaimed seat');
        }
        stdout.writeln(
            'Recovering seat after stale server snapshot ($seatRepairs)');
        joined = await socket.joinGame(
            gameId: created.gameId,
            playerName: 'Daketi Integration QA',
            reconnectToken: seat);
        if (joined['reclaimed'] != true && joined['playerId'] != playerId) {
          throw StateError('Server did not restore the seat');
        }
        playerId = joined['playerId'] as String;
        latest = Map<String, dynamic>.from(joined['gameState'] as Map);
        continue;
      }
      if (latest['currentPlayerId'] != playerId) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }
      final response = await socket.getActions(created.gameId);
      final actions = (response['actions'] as List).cast<Map>();
      if (actions.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }
      final action = actions.firstWhere((a) => a['type'] == 'discard',
          orElse: () => actions.first);
      final before = revision;
      final result = await socket.performAction(
          action['type'] == 'discard'
              ? 'discard_card'
              : action['type'] as String,
          {
            'gameId': created.gameId,
            'cardId': action['cardId'],
            if (action['targetPlayerId'] != null)
              'targetPlayerId': action['targetPlayerId'],
          });
      if (before == revision && result['gameState'] is Map) {
        latest = Map<String, dynamic>.from(result['gameState'] as Map);
      }
      moves++;
    }
    stdout.writeln(
        'PASS completed guest game ($moves human moves, $aiSteps AI steps)');
  } catch (error) {
    // Never print response payloads: seat credentials must remain private.
    stderr.writeln('FAIL ${error.runtimeType}: $error');
    exitCode = 1;
  } finally {
    await subscription?.cancel();
    socket.dispose();
    rest.dispose();
  }
}
