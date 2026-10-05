import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:daketi_phase1_modular/features/game/data/game_api_exception.dart';
import 'package:daketi_phase1_modular/features/game/data/game_socket_service.dart';

// A minimal local Engine.IO/Socket.io peer exercises the real client transport.
// It does not simulate game rules: those remain server-owned.
void main() {
  late HttpServer server;
  late GameSocketService client;
  final peers = <WebSocket>[];
  late void Function(WebSocket, String, List<dynamic>) onEvent;
  setUp(() async {
    peers.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      expect(request.uri.queryParameters['transport'], 'websocket');
      final ws = await WebSocketTransformer.upgrade(request);
      peers.add(ws);
      ws.add('0${jsonEncode({
            'sid': 'engine-${peers.length}',
            'upgrades': [],
            'pingInterval': 25000,
            'pingTimeout': 20000
          })}');
      ws.listen((packet) {
        final text = packet as String;
        if (text == '40') {
          ws.add('40${jsonEncode({'sid': 'player-${peers.length}'})}');
        } else if (text.startsWith('42')) {
          final index = text.indexOf('[');
          onEvent(ws, text.substring(2, index),
              jsonDecode(text.substring(index)) as List);
        }
      });
    });
    client = GameSocketService(serverUrl: 'http://127.0.0.1:${server.port}');
  });
  tearDown(() async {
    client.dispose();
    for (final ws in peers) {
      await ws.close();
    }
    await server.close(force: true);
  });

  test('real WebSocket join sends account and seat credentials and parses ack',
      () async {
    onEvent = (ws, id, event) {
      expect(event.first, 'join_game');
      expect(event[1], {
        'gameId': '0042',
        'playerName': 'Ali',
        'token': 'account-jwt',
        'reconnectToken': 'seat-secret'
      });
      ws.add('43$id${jsonEncode([
            {
              'success': true,
              'playerId': 'player-1',
              'reclaimed': true,
              'reconnectToken': 'seat-secret'
            }
          ])}');
    };
    await client.connect();
    final response = await client.joinGame(
        gameId: '0042',
        playerName: 'Ali',
        token: 'account-jwt',
        reconnectToken: 'seat-secret');
    expect(response['reclaimed'], isTrue);
  });

  test('malformed acknowledgements fail instead of reporting a successful move',
      () async {
    onEvent = (ws, id, event) => ws.add('43$id[null]');
    await client.connect();
    await expectLater(
        client.getActions('0042'),
        throwsA(isA<GameApiException>().having(
            (e) => e.message, 'message', contains('invalid acknowledgement'))));
  });

  test(
      'disconnect immediately fails pending actions and can open a fresh transport',
      () async {
    final received = Completer<void>();
    onEvent = (ws, id, event) {
      received.complete();
    };
    await client.connect();
    final pending = client
        .performAction('discard_card', {'gameId': '0042', 'cardId': '2H'});
    final assertion = expectLater(pending, throwsA(isA<GameApiException>()));
    await received.future;
    client.disconnect();
    await assertion;
    expect(client.isConnected, isFalse);
    await client.connect();
    expect(client.isConnected, isTrue);
    expect(peers.length, 2);
  });

  test('structured NOT_IN_GAME code survives the transport', () async {
    onEvent = (ws, id, event) => ws.add('43$id${jsonEncode([
              {
                'success': false,
                'code': 'NOT_IN_GAME',
                'error': 'Rejoin required'
              }
            ])}');
    await client.connect();
    await expectLater(
        client.getActions('0042'),
        throwsA(isA<GameApiException>()
            .having((e) => e.code, 'code', 'NOT_IN_GAME')));
  });
}
