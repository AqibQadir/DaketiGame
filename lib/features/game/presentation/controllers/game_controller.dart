import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/backend_config.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/game_api_exception.dart';
import '../../data/game_rest_client.dart';
import '../../data/previous_game_storage.dart';
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
    this.lastDifficulty = 'master',
    this.chatMessages = const [],
    this.turnTimerRevision = 0,
    this.recoveryFailed = false,
    this.previousGame,
    this.isMultiplayer = false,
    this.isResumedGame = false,
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
  final String lastDifficulty;
  final List<RoomChatMessage> chatMessages;
  final int turnTimerRevision;
  final bool recoveryFailed;
  final PreviousGame? previousGame;
  final bool isMultiplayer;
  final bool isResumedGame;

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
    String? lastDifficulty,
    List<RoomChatMessage>? chatMessages,
    int? turnTimerRevision,
    bool? recoveryFailed,
    Object? previousGame = _unchanged,
    bool? isMultiplayer,
    bool? isResumedGame,
  }) {
    return GameSessionState(
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      isResumedGame: isResumedGame ?? this.isResumedGame,
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
      lastDifficulty: lastDifficulty ?? this.lastDifficulty,
      chatMessages: chatMessages ?? this.chatMessages,
      turnTimerRevision: turnTimerRevision ?? this.turnTimerRevision,
      recoveryFailed: recoveryFailed ?? this.recoveryFailed,
      previousGame: previousGame == _unchanged
          ? this.previousGame
          : previousGame as PreviousGame?,
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
    previousGameStorage: PreviousGameStorage(),
    restClient: ref.watch(gameRestClientProvider),
    socketService: ref.watch(gameSocketServiceProvider),
    tokenLoader: ref.watch(authTokenStorageProvider).read,
    sessionValidator: () =>
        ref.read(authControllerProvider.notifier).refreshSession(),
    onGameCompleted: () =>
        ref.read(authControllerProvider.notifier).refreshSession(),
  );
});

class GameController extends StateNotifier<GameSessionState> {
  GameController({
    PreviousGameStorage? previousGameStorage,
    required GameRestClient restClient,
    required GameSocketService socketService,
    Future<String?> Function()? tokenLoader,
    Future<bool> Function()? sessionValidator,
    Future<void> Function()? onGameCompleted,
  })  : _previousGameStorage = previousGameStorage,
        _restClient = restClient,
        _socketService = socketService,
        _tokenLoader = tokenLoader ?? _noToken,
        _sessionValidator = sessionValidator,
        _onGameCompleted = onGameCompleted,
        super(const GameSessionState()) {
    _eventsSubscription = _socketService.events.listen(_handleSocketEvent);
    unawaited(_restorePreviousGame());
  }

  final PreviousGameStorage? _previousGameStorage;
  final GameRestClient _restClient;
  bool _rejoining = false;
  bool _resuming = false;
  final GameSocketService _socketService;
  final Future<String?> Function() _tokenLoader;
  final Future<bool> Function()? _sessionValidator;
  final Future<void> Function()? _onGameCompleted;
  late final StreamSubscription<GameSocketEvent> _eventsSubscription;
  Timer? _reconnectTimer;
  int _rejoinAttempts = 0;
  int _roomStateRevision = 0;

  static const _reconnectDeadline = Duration(seconds: 15);

  Future<void> _restorePreviousGame() async {
    try {
      final previous = await _previousGameStorage?.read();
      if (mounted && state.gameId == null && state.previousGame == null) {
        state = state.copyWith(previousGame: previous);
      }
    } catch (_) {
      // A storage failure must not prevent playing.
    }
  }

  Future<void> _rememberGame() async {
    final gameId = state.gameId;
    final playerId = state.playerId;
    final name = state.playerName;
    if (gameId == null || playerId == null || name == null) return;
    final token = await _tokenLoader();
    if (!mounted || state.gameId != gameId) return;
    final previous = PreviousGame(
        gameId: gameId,
        playerId: playerId,
        playerName: name,
        isMultiplayer: state.isMultiplayer,
        ownerToken: token);
    state = state.copyWith(previousGame: previous);
    try {
      await _previousGameStorage?.write(previous);
    } catch (_) {}
  }

  Future<void> _forgetPreviousGame() async {
    state = state.copyWith(previousGame: null);
    try {
      await _previousGameStorage?.clear();
    } catch (_) {}
  }

  Future<bool> resumePreviousGame() async {
    final previous = state.previousGame;
    if (previous == null || state.isLoading) return false;
    _reconnectTimer?.cancel();
    _resuming = true;
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (await _tokenLoader() != previous.ownerToken) {
        throw const GameApiException(
            'Sign in with the account used for this game to rejoin.');
      }
      final game = await _restClient.getGame(previous.gameId);
      if (game.status == DaketiGameStatus.finished) {
        await _forgetPreviousGame();
        throw const GameApiException(
            'Your previous game has finished. You can start a new game.');
      }
      await _ensureConnected();
      final response = await _socketService.joinGame(
          gameId: previous.gameId,
          playerName: previous.playerName,
          token: await _validatedTokenForGame());
      if (!mounted) return false;
      final restored = _gameFrom(response['gameState']);
      if (restored == null ||
          restored.gameId != previous.gameId ||
          response['playerId']?.toString() != previous.playerId) {
        throw const GameApiException(
            'The server could not restore your original seat. Please try again.');
      }
      state = state.copyWith(
          isMultiplayer: previous.isMultiplayer,
          isResumedGame: true,
          gameId: previous.gameId,
          playerName: previous.playerName,
          playerId: previous.playerId,
          game: restored,
          isLoading: false,
          recoveryFailed: false,
          error: null,
          availableActions: const [],
          winner: restored.winner,
          scores: const [],
          activity: 'Rejoined your game');
      return true;
    } catch (error) {
      if (error is GameApiException && error.statusCode == 404) {
        await _forgetPreviousGame();
      }
      if (mounted) _setError(error);
      return false;
    } finally {
      _resuming = false;
    }
  }

  Future<bool> createSoloGame({
    required String playerName,
    int aiCount = 1,
    String difficulty = 'master',
  }) async {
    state = state.copyWith(
      isResumedGame: false,
      isMultiplayer: false,
      isLoading: true,
      error: null,
      playerId: null,
      recoveryFailed: false,
      playerName: playerName,
      lastAiCount: aiCount,
      lastDifficulty: difficulty,
      winner: null,
      scores: const [],
    );
    try {
      await _ensureConnected();
      final authToken = await _validatedTokenForGame();
      final created = await _restClient.createSoloGame(
        playerName: playerName,
        aiCount: aiCount,
        difficulty: difficulty,
      );
      state = state.copyWith(gameId: created.gameId, game: created.game);
      final response = await _socketService.joinGame(
        gameId: created.gameId,
        playerName: playerName,
        token: authToken,
      );
      state = state.copyWith(
        isLoading: false,
        playerId: response['playerId']?.toString(),
        game: _gameFrom(response['gameState']) ?? state.game,
      );
      await _rememberGame();
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
      isResumedGame: false,
      isMultiplayer: true,
      isLoading: true,
      error: null,
      playerId: null,
      recoveryFailed: false,
      playerName: playerName,
      winner: null,
      scores: const [],
      chatMessages: const [],
      activity: null,
    );
    try {
      await _ensureConnected();
      await _validatedTokenForGame();
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
      isResumedGame: false,
      isMultiplayer: true,
      isLoading: true,
      error: null,
      gameId: gameId,
      game: null,
      playerId: null,
      recoveryFailed: false,
      playerName: playerName,
      winner: null,
      scores: const [],
      chatMessages: const [],
      activity: null,
    );
    try {
      await _ensureConnected();
      final revision = _roomStateRevision;
      final response = await _socketService.joinGame(
        gameId: gameId,
        playerName: playerName,
        token: await _validatedTokenForGame(),
      );
      final joinedGame = revision == _roomStateRevision
          ? _gameFrom(response['gameState'])
          : state.game;
      state = state.copyWith(
        winner: joinedGame?.winner,
        isLoading: false,
        playerId: response['playerId']?.toString(),
        game: joinedGame,
      );
      await _rememberGame();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<void> sendReady() async {
    final gameId = state.gameId;
    final player = state.game?.playerById(state.playerId);
    if (gameId == null ||
        state.isLoading ||
        player == null ||
        state.game?.status != DaketiGameStatus.waiting) {
      return;
    }
    final revision = _roomStateRevision;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response =
          await _socketService.playerReady(gameId, isReady: !player.isReady);
      if (!mounted || state.gameId != gameId) return;
      // Broadcasts can precede the acknowledgement, including game_started.
      // Never replace their newer state with the request's waiting snapshot.
      state = state.copyWith(
        isLoading: false,
        game: revision == _roomStateRevision
            ? _gameFrom(response['gameState']) ?? state.game
            : state.game,
        error: null,
      );
    } catch (error) {
      if (mounted && state.gameId == gameId) _setError(error);
    }
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
      difficulty: state.lastDifficulty,
    );
  }

  void resetSession() {
    _reconnectTimer?.cancel();
    _rejoinAttempts = 0;
    state = GameSessionState(
        connectionStatus: state.connectionStatus,
        previousGame: state.previousGame);
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
    final completed =
        await _runAction(() => _socketService.performAction(event, payload));
    if (completed) {
      // A successful move must always receive a fresh turn allowance. Socket
      // events still reset remote/AI turns, while this guarantees that local
      // moves reset immediately even if an action event is delayed or omitted.
      state = state.copyWith(
        turnTimerRevision: state.turnTimerRevision + 1,
      );
    }
    return completed;
  }

  Future<bool> handleTurnTimeout({String? selectedCardId}) async {
    if (!state.isCurrentPlayersTurn || state.gameId == null) return true;
    if (!_socketService.isConnected || state.recoveryFailed) return false;

    state = state.copyWith(activity: 'TIME OVER');

    // The API has no timeout event. Use only server-approved actions and keep
    // the room authoritative. When a discard is available, always put the
    // lowest-ranked card on the table and end the expired turn.
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
        final discardActions = actions
            .where((item) => item.type == GameActionType.discard)
            .toList(growable: false);
        final action = discardActions.isEmpty
            ? actions.first
            : discardActions.reduce((lowest, candidate) =>
                _cardRank(candidate.cardId) < _cardRank(lowest.cardId)
                    ? candidate
                    : lowest);
        state = state.copyWith(
          activity: 'TIME OVER · AUTO ${_actionLabel(action)}',
        );
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

  int _cardRank(String cardId) {
    if (cardId.isEmpty) return 99;
    return switch (cardId[0].toUpperCase()) {
      'A' => 14,
      'K' => 13,
      'Q' => 12,
      'J' => 11,
      'T' => 10,
      final value => int.tryParse(value) ?? 99,
    };
  }

  Future<void> _ensureConnected() async {
    if (_socketService.isConnected) return;
    state = state.copyWith(connectionStatus: GameConnectionStatus.connecting);
    await _socketService.connect();
    state = state.copyWith(connectionStatus: GameConnectionStatus.connected);
  }

  Future<String?> _validatedTokenForGame() async {
    final token = await _tokenLoader();
    if (token == null || token.isEmpty) return null;
    final validator = _sessionValidator;
    if (validator == null || await validator()) return token;
    throw const GameApiException(
      'Your account session could not be verified. Please log in again or check your connection.',
    );
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
      _reconnectTimer?.cancel();
      state = state.copyWith(
        connectionStatus: GameConnectionStatus.connected,
        disconnectedPlayer: null,
      );
      // The initial connection belongs to the explicit join/create request.
      // Rejoining it concurrently can create/reset a player's room entry.
      if (state.playerId != null && !_resuming) unawaited(_attemptRejoin());
      return;
    }
    if (event.name == 'disconnected') {
      state = state.copyWith(
        connectionStatus: GameConnectionStatus.disconnected,
        activity: 'Connection lost. Reconnecting…',
      );
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDeadline, () {
        if (!_socketService.isConnected && state.gameId != null) {
          _endUnrecoverableSession();
        }
      });
      return;
    }
    final eventGameId = event.data['gameId']?.toString() ??
        (event.data['gameState'] is Map
            ? event.data['gameState']['gameId']?.toString()
            : null);
    if (eventGameId != null && eventGameId != state.gameId) return;
    if (event.name == 'game_over') {
      unawaited(_forgetPreviousGame());
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
      final refreshAccount = _onGameCompleted;
      if (refreshAccount != null) unawaited(refreshAccount());
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
    if (game != null && game.gameId == state.gameId) {
      _roomStateRevision++;
      state = state.copyWith(game: game, availableActions: const []);
    }
  }

  Future<void> _attemptRejoin() async {
    final gameId = state.gameId;
    final playerName = state.playerName;
    if (gameId == null ||
        playerName == null ||
        state.game == null ||
        _rejoining) {
      return;
    }
    _rejoining = true;
    try {
      final response = await _socketService.joinGame(
        gameId: gameId,
        playerName: playerName,
        token: await _validatedTokenForGame(),
      );
      if (!mounted || state.gameId != gameId) return;
      if (response['playerId']?.toString() != state.playerId) {
        throw const GameApiException(
            'The server could not restore your original seat.');
      }
      state = state.copyWith(
        isLoading: false,
        playerId: response['playerId']?.toString() ?? state.playerId,
        game: _gameFrom(response['gameState']) ?? state.game,
        activity: 'Reconnected to room $gameId',
        error: null,
        recoveryFailed: false,
      );
      _rejoinAttempts = 0;
    } catch (error) {
      if (!mounted || state.gameId != gameId) return;
      _rejoinAttempts += 1;
      try {
        final recoveredGame = await _restClient.getGame(gameId);
        if (!mounted || state.gameId != gameId) return;
        state = state.copyWith(
          game: recoveredGame,
          activity: 'Restoring connection to room $gameId…',
          error: null,
        );
      } catch (_) {
        _endUnrecoverableSession();
        return;
      }
      if (_rejoinAttempts >= 3) {
        _endUnrecoverableSession();
        return;
      }
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(
        const Duration(seconds: 2),
        () => unawaited(_attemptRejoin()),
      );
    } finally {
      _rejoining = false;
    }
  }

  void _endUnrecoverableSession() {
    _reconnectTimer?.cancel();
    _rejoinAttempts = 0;
    state = state.copyWith(
      isLoading: false,
      availableActions: const [],
      connectionStatus: _socketService.isConnected
          ? GameConnectionStatus.connected
          : GameConnectionStatus.disconnected,
      recoveryFailed: true,
      error: 'Connection lost. Use Join previous game to try again.',
    );
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
    _reconnectTimer?.cancel();
    _eventsSubscription.cancel();
    super.dispose();
  }
}

Future<String?> _noToken() async => null;
