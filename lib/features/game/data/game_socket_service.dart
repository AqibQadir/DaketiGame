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
  final Set<Completer<Map<String, dynamic>>> _pendingRequests = {};
  bool _disposed = false;

  Stream<GameSocketEvent> get events => _events.stream;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_disposed) {
      throw const GameApiException('The game connection is closed.');
    }
    if (isConnected) return;
    if (_connectionCompleter != null) return _connectionCompleter!.future;

    final completer = Completer<void>();
    _connectionCompleter = completer;
    // Dispose a failed/reconnecting transport before explicitly retrying.
    _socket?.dispose();
    final socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'reconnection': true,
    });
    _socket = socket;

    socket.onConnect((_) {
      if (_disposed || _socket != socket) return;
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
      if (_disposed || _socket != socket) return;
      _failPendingRequests();
      _events.add(GameSocketEvent('disconnected', {'reason': reason}));
    });

    for (final name in const [
      'game_started',
      'player_joined',
      'player_reconnected',
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
      socket.on(name, (data) {
        if (!_disposed && _socket == socket) {
          _events.add(GameSocketEvent(name, _map(data)));
        }
      });
    }
    socket.connect();

    try {
      await completer.future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const GameApiException('The game server connection timed out.');
    } finally {
      if (_connectionCompleter == completer) _connectionCompleter = null;
    }
  }

  Future<Map<String, dynamic>> joinGame({
    required String gameId,
    required String playerName,
    String? token,
    String? reconnectToken,
  }) {
    return _emitWithAck('join_game', {
      'gameId': gameId,
      'playerName': playerName,
      if (token != null && token.isNotEmpty) 'token': token,
      if (reconnectToken != null && reconnectToken.isNotEmpty)
        'reconnectToken': reconnectToken,
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
    _pendingRequests.add(completer);
    socket.emitWithAck(
      event,
      payload,
      ack: (data) {
        if (completer.isCompleted) return;
        if (data is! Map || data['success'] is! bool) {
          completer.completeError(const GameApiException(
              'The game server returned an invalid acknowledgement.'));
          return;
        }
        final response = _map(data);
        if (response['success'] == false) {
          completer.completeError(
            GameApiException(response['error']?.toString() ?? 'Action failed.',
                code: response['code']?.toString()),
          );
        } else {
          completer.complete(response);
        }
      },
    );
    try {
      return await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw GameApiException('$event timed out.'),
      );
    } finally {
      _pendingRequests.remove(completer);
    }
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  void _failPendingRequests() {
    for (final request in _pendingRequests.toList()) {
      if (!request.isCompleted) {
        request.completeError(const GameApiException(
            'Connection interrupted. Reconnect before making another move.'));
      }
    }
    _pendingRequests.clear();
  }

  /// A new transport leaves all old rooms; no undocumented leave event needed.
  void disconnect() {
    final socket = _socket;
    _socket = null;
    socket?.dispose();
    _failPendingRequests();
    final connecting = _connectionCompleter;
    _connectionCompleter = null;
    if (connecting != null && !connecting.isCompleted) {
      connecting.completeError(const GameApiException('Connection cancelled.'));
    }
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _events.close();
  }
}
