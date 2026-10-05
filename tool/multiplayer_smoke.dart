// Explicit live QA: creates one two-player guest room and plays it to completion.
// Run: dart run tool/multiplayer_smoke.dart [https://server]
import 'dart:async';
import 'dart:io';
import 'package:daketi_phase1_modular/features/game/data/game_rest_client.dart';
import 'package:daketi_phase1_modular/features/game/data/game_socket_service.dart';

Future<void> main(List<String> args) async {
  final baseUrl = args.firstOrNull ?? 'https://game.daketi.pk';
  final rest = GameRestClient(baseUrl: baseUrl);
  final sockets =
      List.generate(2, (_) => GameSocketService(serverUrl: baseUrl));
  final subscriptions = <StreamSubscription<GameSocketEvent>>[];
  final states = List.generate(2, (_) => <String, dynamic>{});
  final revisions = [0, 0];
  final ids = <String>[];
  var finished = false;
  try {
    for (var i = 0; i < 2; i++) {
      final index = i;
      subscriptions.add(sockets[i].events.listen((event) {
        if (event.data['gameState'] is Map) {
          states[index] =
              Map<String, dynamic>.from(event.data['gameState'] as Map);
          revisions[index]++;
        }
        if (event.name == 'game_over') finished = true;
      }));
      await sockets[i].connect();
    }
    final created = await rest.createMultiplayerRoom(
        playerName: 'Daketi QA One', maxPlayers: 2);
    for (var i = 0; i < 2; i++) {
      final response = await sockets[i]
          .joinGame(gameId: created.gameId, playerName: 'Daketi QA ${i + 1}');
      ids.add(response['playerId'] as String);
      states[i] = Map<String, dynamic>.from(response['gameState'] as Map);
    }
    stdout.writeln('PASS two guest seats joined room ${created.gameId}');
    await sockets[0].playerReady(created.gameId);
    await sockets[0].performAction(
        'player_ready', {'gameId': created.gameId, 'isReady': false});
    // Fetch a personalized snapshot with the existing socket/seat.
    final readyCheck = await sockets[0]
        .joinGame(gameId: created.gameId, playerName: 'Daketi QA 1');
    final players = (readyCheck['gameState'] as Map)['players'] as List;
    final unreadySupported =
        players.firstWhere((p) => p['id'] == ids[0])['isReady'] == false;
    stdout.writeln('Ready/Unready extension supported: $unreadySupported');
    await sockets[0].playerReady(created.gameId);
    await sockets[1].playerReady(created.gameId);
    stdout.writeln('PASS all-ready starts multiplayer');
    final deadline = DateTime.now().add(const Duration(minutes: 4));
    var moves = 0;
    final actionTypes = <String>{};
    while (!finished) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Multiplayer match');
      }
      final current = states[0]['currentPlayerId'];
      final index = ids.indexOf(current?.toString() ?? '');
      if (index < 0) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }
      final legal = await sockets[index].getActions(created.gameId);
      final actions = (legal['actions'] as List).cast<Map>();
      if (actions.isEmpty) {
        throw StateError('No legal move for the current player');
      }
      final action = actions.firstWhere((a) => a['type'] != 'discard',
          orElse: () => actions.first);
      final revision = revisions[index];
      final type = action['type'] as String;
      actionTypes.add(type);
      final response = await sockets[index]
          .performAction(type == 'discard' ? 'discard_card' : type, {
        'gameId': created.gameId,
        'cardId': action['cardId'],
        if (action['targetPlayerId'] != null)
          'targetPlayerId': action['targetPlayerId'],
      });
      if (revision == revisions[index] && response['gameState'] is Map) {
        states[index] = Map<String, dynamic>.from(response['gameState'] as Map);
      }
      moves++;
      if (moves % 10 == 0) stdout.writeln('Progress: $moves moves');
    }
    stdout.writeln(
        'PASS completed multiplayer ($moves moves; ${actionTypes.join(', ')})');
  } catch (error) {
    stderr.writeln('FAIL ${error.runtimeType}: $error');
    exitCode = 1;
  } finally {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    for (final socket in sockets) {
      socket.dispose();
    }
    rest.dispose();
  }
}
