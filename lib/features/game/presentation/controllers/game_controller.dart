import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/backend_config.dart';
import '../../data/game_api_exception.dart';
import '../../data/game_rest_client.dart';
import '../../data/game_socket_service.dart';
import '../../domain/models/daketi_game.dart';
import '../../domain/models/game_action.dart';

enum GameConnectionStatus { disconnected, connecting, connected }

class RoomChatMessage {
  const RoomChatMessage({
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.sentAt,
  });

  final String? senderId;
  final String senderName;
  final String message;
  final DateTime sentAt;

  factory RoomChatMessage.fromJson(Map<String, dynamic> json) =>
      RoomChatMessage(
        senderId: (json['playerId'] ?? json['senderId'])?.toString(),
        senderName:
            (json['playerName'] ?? json['senderName'] ?? 'Player').toString(),
        message: (json['message'] ?? '').toString(),
        sentAt: DateTime.tryParse((json['sentAt'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class GameSessionState {
  const GameSessionState({
    this.connectionStatus = GameConnectionStatus.disconnected,
    this.isLoading = false,
    this.gameId,
    this.playerId,
    this.playerName,
    this.game,
    this.availableActions = const [],
    this.error,
    this.winner,
    this.scores = const [],
    this.activity,
    this.disconnectedPlayer,
    this.lastAiCount = 1,
    this.chatMessages = const [],
    this.turnTimerRevision = 0,
  });

  final GameConnectionStatus connectionStatus;
  final bool isLoading;
  final String? gameId;
  final String? playerId;
  final String? playerName;
  final DaketiGame? game;
  final List<GameAction> availableActions;
  final String? error;
  final String? winner;
  final List<Map<String, dynamic>> scores;
  final String? activity;
  final String? disconnectedPlayer;
  final int lastAiCount;
  final List<RoomChatMessage> chatMessages;
  final int turnTimerRevision;

  bool get isCurrentPlayersTurn =>
      game?.currentPlayerId != null && game?.currentPlayerId == playerId;

  GameSessionState copyWith({
    GameConnectionStatus? connectionStatus,
    bool? isLoading,
    Object? gameId = _unchanged,
    Object? playerId = _unchanged,
    Object? playerName = _unchanged,
    Object? game = _unchanged,
    List<GameAction>? availableActions,
    Object? error = _unchanged,
    Object? winner = _unchanged,
    List<Map<String, dynamic>>? scores,
    Object? activity = _unchanged,
    Object? disconnectedPlayer = _unchanged,
    int? lastAiCount,
    List<RoomChatMessage>? chatMessages,
    int? turnTimerRevision,
  }) {
    return GameSessionState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isLoading: isLoading ?? this.isLoading,
      gameId: gameId == _unchanged ? this.gameId : gameId as String?,
      playerId: playerId == _unchanged ? this.playerId : playerId as String?,
      playerName:
          playerName == _unchanged ? this.playerName : playerName as String?,
      game: game == _unchanged ? this.game : game as DaketiGame?,
      availableActions: availableActions ?? this.availableActions,
      error: error == _unchanged ? this.error : error as String?,
      winner: winner == _unchanged ? this.winner : winner as String?,
      scores: scores ?? this.scores,
      activity: activity == _unchanged ? this.activity : activity as String?,
      disconnectedPlayer: disconnectedPlayer == _unchanged
          ? this.disconnectedPlayer
          : disconnectedPlayer as String?,
      lastAiCount: lastAiCount ?? this.lastAiCount,
      chatMessages: chatMessages ?? this.chatMessages,
      turnTimerRevision: turnTimerRevision ?? this.turnTimerRevision,
    );
  }
}

const Object _unchanged = Object();

final gameRestClientProvider = Provider<GameRestClient>((ref) {
  final client = GameRestClient(baseUrl: BackendConfig.serverUrl);
  ref.onDispose(client.dispose);
  return client;
});

final gameSocketServiceProvider = Provider<GameSocketService>((ref) {
  final service = GameSocketService(serverUrl: BackendConfig.serverUrl);
  ref.onDispose(service.dispose);
  return service;
});

final gameControllerProvider =
    StateNotifierProvider<GameController, GameSessionState>((ref) {
  return GameController(
    restClient: ref.watch(gameRestClientProvider),
    socketService: ref.watch(gameSocketServiceProvider),
  );
});

class GameController extends StateNotifier<GameSessionState> {
  GameController({
    required GameRestClient restClient,
    required GameSocketService socketService,
  })  : _restClient = restClient,
        _socketService = socketService,
        super(const GameSessionState()) {
    _eventsSubscription = _socketService.events.listen(_handleSocketEvent);
  }

  final GameRestClient _restClient;
  final GameSocketService _socketService;
  late final StreamSubscription<GameSocketEvent> _eventsSubscription;

  Future<bool> createSoloGame({
    required String playerName,
    int aiCount = 1,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      playerName: playerName,
      lastAiCount: aiCount,
      winner: null,
      scores: const [],
    );
    try {
      await _ensureConnected();
      final created = await _restClient.createSoloGame(
        playerName: playerName,
        aiCount: aiCount,
      );
      state = state.copyWith(gameId: created.gameId, game: created.game);
      final response = await _socketService.joinGame(
        gameId: created.gameId,
        playerName: playerName,
      );
      state = state.copyWith(
        isLoading: false,
        playerId: response['playerId']?.toString(),
        game: _gameFrom(response['gameState']) ?? state.game,
      );
      return true;
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<bool> createMultiplayerRoom({
    required String playerName,
    int maxPlayers = 4,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      playerName: playerName,
      winner: null,
      scores: const [],
      chatMessages: const [],
      activity: null,
    );
    try {
      await _ensureConnected();
      final created = await _restClient.createMultiplayerRoom(
        playerName: playerName,
        maxPlayers: maxPlayers,
      );
      state = state.copyWith(gameId: created.gameId, game: created.game);
      return await joinExistingGame(
        gameId: created.gameId,
        playerName: playerName,
        preserveLoading: true,
      );
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<bool> joinExistingGame({
    required String gameId,
    required String playerName,
    bool preserveLoading = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      gameId: gameId,
      playerName: playerName,
      winner: null,
      scores: const [],
      chatMessages: const [],
      activity: null,
    );
    try {
      await _ensureConnected();
      final response = await _socketService.joinGame(
        gameId: gameId,
        playerName: playerName,
      );
      state = state.copyWith(
        isLoading: false,
        playerId: response['playerId']?.toString(),
        game: _gameFrom(response['gameState']),
      );
      return true;
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<void> sendReady() async {
    final gameId = state.gameId;
    if (gameId == null) return;
    await _runAction(() => _socketService.playerReady(gameId));
  }

  Future<bool> sendChatMessage(String message) async {
    final gameId = state.gameId;
    final value = message.trim();
    if (gameId == null || value.isEmpty) return false;
    if (value.length > 200) {
      state =
          state.copyWith(error: 'Messages can contain up to 200 characters.');
      return false;
    }
    try {
      await _socketService.sendChatMessage(gameId: gameId, message: value);
      state = state.copyWith(error: null);
      return true;
    } catch (error) {
      _setError(error, loading: false);
      return false;
    }
  }

  Future<bool> replaySolo() {
    return createSoloGame(
      playerName: state.playerName ?? 'Player',
      aiCount: state.lastAiCount,
    );
  }

  void resetSession() {
    state = GameSessionState(connectionStatus: state.connectionStatus);
  }

  Future<void> loadAvailableActions() async {
    final gameId = state.gameId;
    if (gameId == null || !state.isCurrentPlayersTurn) return;
    try {
      final response = await _socketService.getActions(gameId);
      final actions = (response['actions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GameAction.fromJson)
          .toList(growable: false);
      state = state.copyWith(availableActions: actions, error: null);
    } catch (error) {
      _setError(error, loading: false);
    }
  }

  Future<bool> performAction(GameAction action) async {
    final gameId = state.gameId;
    if (gameId == null) return false;
    final event = switch (action.type) {
      GameActionType.captureTable => 'capture_table',
      GameActionType.stealOpponent => 'steal_opponent',
      GameActionType.extendStack => 'extend_stack',
      GameActionType.discard => 'discard_card',
      GameActionType.unknown => '',
    };
    if (event.isEmpty) return false;
    final payload = <String, dynamic>{
      'gameId': gameId,
      'cardId': action.cardId,
      if (action.targetPlayerId != null)
        'targetPlayerId': action.targetPlayerId,
    };
    return _runAction(() => _socketService.performAction(event, payload));
  }

  Future<bool> handleTurnTimeout() async {
    if (!state.isCurrentPlayersTurn || state.gameId == null) return true;

    state = state.copyWith(activity: 'TIME OVER');
    await Future<void>.delayed(const Duration(milliseconds: 650));

    // The API has no timeout event. Use only server-approved actions and keep
    // the room authoritative: prefer a discard because it ends the turn.
    for (var step = 0; step < 12 && state.isCurrentPlayersTurn; step++) {
      final gameId = state.gameId;
      if (gameId == null) return false;
      try {
        final response = await _socketService.getActions(gameId);
        final actions = (response['actions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(GameAction.fromJson)
            .toList(growable: false);
        if (actions.isEmpty) {
          state = state.copyWith(
            error: 'Time expired, but the server returned no legal move.',
          );
          return false;
        }
        final action = actions.firstWhere(
          (item) => item.type == GameActionType.discard,
          orElse: () => actions.first,
        );
        state = state.copyWith(
          activity: 'TIME OVER · AUTO ${_actionLabel(action)}',
        );
        await Future<void>.delayed(const Duration(milliseconds: 650));
        final ended = action.type == GameActionType.discard;
        if (!await performAction(action)) return false;
        if (ended) return true;
      } catch (error) {
        _setError(error, loading: false);
        return false;
      }
    }
    return !state.isCurrentPlayersTurn;
  }

  String _actionLabel(GameAction action) => switch (action.type) {
        GameActionType.captureTable => 'CAPTURE ${action.cardId}',
        GameActionType.stealOpponent => 'STEAL WITH ${action.cardId}',
        GameActionType.extendStack => 'EXTEND WITH ${action.cardId}',
        GameActionType.discard => 'DISCARD ${action.cardId}',
        GameActionType.unknown => 'MOVE ${action.cardId}',
      };

  Future<void> _ensureConnected() async {
    if (_socketService.isConnected) return;
    state = state.copyWith(connectionStatus: GameConnectionStatus.connecting);
    await _socketService.connect();
    state = state.copyWith(connectionStatus: GameConnectionStatus.connected);
  }

  Future<bool> _runAction(
    Future<Map<String, dynamic>> Function() operation,
  ) async {
    try {
      final response = await operation();
      state = state.copyWith(
        game: _gameFrom(response['gameState']) ?? state.game,
        availableActions: const [],
        error: null,
      );
      return true;
    } catch (error) {
      _setError(error, loading: false);
      return false;
    }
  }

  void _handleSocketEvent(GameSocketEvent event) {
    if (event.name == 'connected') {
      state = state.copyWith(
        connectionStatus: GameConnectionStatus.connected,
        disconnectedPlayer: null,
      );
      _attemptRejoin();
      return;
    }
    if (event.name == 'disconnected') {
      state = state.copyWith(
        connectionStatus: GameConnectionStatus.disconnected,
        activity: 'Connection lost. Reconnecting…',
      );
      return;
    }
    if (event.name == 'game_over') {
      final rawScores = event.data['scores'] as List<dynamic>? ?? const [];
      state = state.copyWith(
        game: _gameFrom(event.data['gameState']) ?? state.game,
        winner: event.data['winner']?.toString(),
        scores: rawScores
            .whereType<Map>()
            .map((score) => score.map(
                  (key, value) => MapEntry(key.toString(), value),
                ))
            .toList(growable: false),
      );
      return;
    }
    if (event.name == 'chat_message') {
      final message = RoomChatMessage.fromJson(event.data);
      if (message.message.isNotEmpty) {
        state = state.copyWith(chatMessages: [...state.chatMessages, message]);
      }
      return;
    }
    if (event.name == 'chat_history') {
      final rawMessages = event.data['messages'] as List<dynamic>? ?? const [];
      state = state.copyWith(
        chatMessages: rawMessages
            .whereType<Map>()
            .map((item) => RoomChatMessage.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ))
            .where((item) => item.message.isNotEmpty)
            .toList(growable: false),
      );
      return;
    }
    if (event.name == 'ai_action') {
      final action = event.data['action']?.toString().replaceAll('_', ' ');
      final card = event.data['cardId']?.toString();
      state = state.copyWith(
        activity: 'AI ${action ?? 'moved'}${card == null ? '' : ' · $card'}',
        turnTimerRevision: state.turnTimerRevision + 1,
      );
    } else if (event.name == 'action_performed') {
      final action = event.data['type']?.toString().replaceAll('_', ' ');
      state = state.copyWith(
        activity: 'Action: ${action ?? 'performed'}',
        turnTimerRevision: state.turnTimerRevision + 1,
      );
    } else if (event.name == 'turn_started') {
      state = state.copyWith(
        activity: null,
        turnTimerRevision: state.turnTimerRevision + 1,
      );
    } else if (event.name == 'player_joined') {
      state = state.copyWith(
        activity: '${event.data['playerName'] ?? 'Player'} joined',
      );
    } else if (event.name == 'player_disconnected') {
      final name = event.data['playerName']?.toString() ?? 'Player';
      state = state.copyWith(
        disconnectedPlayer: name,
        activity: '$name disconnected',
      );
    }
    final game = _gameFrom(event.data['gameState']);
    if (game != null) {
      state = state.copyWith(game: game, availableActions: const []);
    }
  }

  Future<void> _attemptRejoin() async {
    final gameId = state.gameId;
    final playerName = state.playerName;
    if (gameId == null || playerName == null || state.game == null) return;
    try {
      final response = await _socketService.joinGame(
        gameId: gameId,
        playerName: playerName,
      );
      state = state.copyWith(
        playerId: response['playerId']?.toString() ?? state.playerId,
        game: _gameFrom(response['gameState']) ?? state.game,
        activity: 'Reconnected to room $gameId',
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        error: 'Connected, but the server could not restore your seat.',
      );
    }
  }

  DaketiGame? _gameFrom(Object? value) {
    if (value is! Map) return null;
    final map = value.map((key, value) => MapEntry(key.toString(), value));
    return DaketiGame.fromJson(map);
  }

  void _setError(Object error, {bool loading = false}) {
    final message = error is GameApiException
        ? error.message
        : 'Something went wrong while connecting to the game.';
    state = state.copyWith(isLoading: loading, error: message);
  }

  void clearError() => state = state.copyWith(error: null);

  @override
  void dispose() {
    _eventsSubscription.cancel();
    super.dispose();
  }
}
