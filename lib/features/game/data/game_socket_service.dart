import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'game_api_exception.dart';

class GameSocketEvent {
  const GameSocketEvent(this.name, this.data);

  final String name;
  final Map<String, dynamic> data;
}

class GameSocketService {
  GameSocketService({required this.serverUrl});

  final String serverUrl;
  final StreamController<GameSocketEvent> _events =
      StreamController<GameSocketEvent>.broadcast();
  io.Socket? _socket;
  Completer<void>? _connectionCompleter;

  Stream<GameSocketEvent> get events => _events.stream;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (isConnected) return;
    if (_connectionCompleter != null) return _connectionCompleter!.future;

    final completer = Completer<void>();
    _connectionCompleter = completer;
    final socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
    });
    _socket = socket;

    socket.onConnect((_) {
      if (!completer.isCompleted) completer.complete();
      _events.add(const GameSocketEvent('connected', {}));
    });
    socket.onConnectError((error) {
      if (!completer.isCompleted) {
        completer.completeError(
          GameApiException('Unable to connect to the game server: $error'),
        );
      }
    });
    socket.onDisconnect((reason) {
      _events.add(GameSocketEvent('disconnected', {'reason': reason}));
    });

    for (final name in const [
      'game_started',
      'player_joined',
      'player_ready',
      'turn_started',
      'action_performed',
      'turn_ended',
      'ai_action',
      'game_over',
      'player_disconnected',
      'chat_message',
      'chat_history',
    ]) {
      socket.on(name, (data) => _events.add(GameSocketEvent(name, _map(data))));
    }
    socket.connect();

    try {
      await completer.future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const GameApiException('The game server connection timed out.');
    } finally {
      _connectionCompleter = null;
    }
  }

  Future<Map<String, dynamic>> joinGame({
    required String gameId,
    required String playerName,
  }) {
    return _emitWithAck('join_game', {
      'gameId': gameId,
      'playerName': playerName,
    });
  }

  Future<Map<String, dynamic>> playerReady(String gameId) {
    return _emitWithAck('player_ready', {'gameId': gameId});
  }

  Future<Map<String, dynamic>> getActions(String gameId) {
    return _emitWithAck('get_actions', {'gameId': gameId});
  }

  Future<Map<String, dynamic>> performAction(
    String event,
    Map<String, dynamic> payload,
  ) {
    return _emitWithAck(event, payload);
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String gameId,
    required String message,
  }) {
    return _emitWithAck('send_chat_message', {
      'gameId': gameId,
      'message': message,
    });
  }

  Future<Map<String, dynamic>> _emitWithAck(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw const GameApiException('Not connected to the game server.');
    }
    final completer = Completer<Map<String, dynamic>>();
    socket.emitWithAck(
      event,
      payload,
      ack: (data) {
        final response = _map(data);
        if (response['success'] == false) {
          completer.completeError(
            GameApiException(response['error']?.toString() ?? 'Action failed.'),
          );
        } else {
          completer.complete(response);
        }
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw GameApiException('$event timed out.'),
    );
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  void dispose() {
    _socket?.dispose();
    _events.close();
  }
}
