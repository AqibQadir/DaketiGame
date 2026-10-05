import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/backend_config.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../access/presentation/access_controller.dart';
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
    accountIdLoader: () => ref.read(authControllerProvider).user?.id,
    sessionValidator: () =>
        ref.read(authControllerProvider.notifier).refreshSession(),
    eligibilityValidator: () =>
        ref.read(accessControllerProvider.notifier).checkEligibility(),
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
    String? Function()? accountIdLoader,
    Future<bool> Function()? sessionValidator,
    Future<bool> Function()? eligibilityValidator,
    Future<void> Function()? onGameCompleted,
  })  : _previousGameStorage = previousGameStorage,
        _restClient = restClient,
        _socketService = socketService,
        _tokenLoader = tokenLoader ?? _noToken,
        _accountIdLoader = accountIdLoader,
        _sessionValidator = sessionValidator,
        _eligibilityValidator = eligibilityValidator,
        _onGameCompleted = onGameCompleted,
        super(const GameSessionState()) {
    _eventsSubscription = _socketService.events.listen(_handleSocketEvent);
    unawaited(_restorePreviousGame());
  }

  final PreviousGameStorage? _previousGameStorage;
  final GameRestClient _restClient;
  Future<void>? _rejoinOperation;
  String? _reconnectToken;
  bool _resuming = false;
  final GameSocketService _socketService;
  final Future<String?> Function() _tokenLoader;
  final String? Function()? _accountIdLoader;
  final Future<bool> Function()? _sessionValidator;
  final Future<bool> Function()? _eligibilityValidator;
  final Future<void> Function()? _onGameCompleted;
  late final StreamSubscription<GameSocketEvent> _eventsSubscription;
  Timer? _reconnectTimer;
  int _rejoinAttempts = 0;
  int _roomStateRevision = 0;
  int _sessionRevision = 0;
  bool _actionInFlight = false;
  Future<void>? _storageChanges;

  bool _isSession(int revision) => mounted && revision == _sessionRevision;

  Future<void> _changeStorage(Future<void> Function() change) {
    final operation = _storageChanges == null
        ? Future<void>.sync(change)
        : _storageChanges!.then((_) => change());
    _storageChanges = operation.catchError((Object _) {});
    return operation;
  }

  int _beginGame({required String playerName, required bool multiplayer}) {
    resetSession();
    state = state.copyWith(
        isLoading: true, playerName: playerName, isMultiplayer: multiplayer);
    return _sessionRevision;
  }

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
    final revision = _sessionRevision;
    final token = await _tokenLoader();
    if (!_isSession(revision) ||
        state.gameId != gameId ||
        state.game?.status == DaketiGameStatus.finished ||
        state.winner != null) {
      return;
    }
    final previous = PreviousGame(
        gameId: gameId,
        playerId: playerId,
        playerName: name,
        isMultiplayer: state.isMultiplayer,
        ownerToken: token,
        ownerAccountId: _accountIdLoader?.call(),
        reconnectToken: _reconnectToken);
    state = state.copyWith(previousGame: previous);
    try {
      await _changeStorage(() async {
        await _previousGameStorage?.write(previous);
      });
    } catch (_) {}
  }

  Future<void> _forgetPreviousGame() async {
    _reconnectToken = null;
    state = state.copyWith(previousGame: null);
    try {
      await _changeStorage(() async {
        await _previousGameStorage?.clear();
      });
    } catch (_) {}
  }

  Future<bool> resumePreviousGame() async {
    final previous = state.previousGame;
    if (previous == null || state.isLoading) return false;
    final session = ++_sessionRevision;
    _reconnectTimer?.cancel();
    _resuming = true;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentToken = await _validatedTokenForGame();
      if (!_isSession(session)) return false;
      final accountMatches = previous.ownerAccountId != null
          ? currentToken != null &&
              _accountIdLoader?.call() == previous.ownerAccountId
          : currentToken == previous.ownerToken;
      if (!accountMatches) {
        throw const GameApiException(
            'Sign in with the account used for this game to rejoin.');
      }
      final game = await _restClient.getGame(previous.gameId);
      if (!_isSession(session)) return false;
      if (game.status == DaketiGameStatus.finished) {
        await _forgetPreviousGame();
        throw const GameApiException(
            'Your previous game has finished. You can start a new game.');
      }
      await _ensureConnected();
      if (!_isSession(session)) return false;
      state = state.copyWith(gameId: previous.gameId);
      final revision = _roomStateRevision;
      final response = await _socketService.joinGame(
          gameId: previous.gameId,
          playerName: previous.playerName,
          token: currentToken,
          reconnectToken: previous.reconnectToken);
      if (!_isSession(session)) return false;
      final restored = _gameFrom(response['gameState']);
      if (restored == null ||
          restored.gameId != previous.gameId ||
          (response['reclaimed'] != true &&
              response['playerId']?.toString() != previous.playerId)) {
        throw const GameApiException(
            'The server could not restore your original seat. Please try again.');
      }
      state = state.copyWith(
          isMultiplayer: previous.isMultiplayer,
          isResumedGame: true,
          gameId: previous.gameId,
          playerName: previous.playerName,
          playerId: response['playerId']?.toString(),
          game: revision == _roomStateRevision
              ? restored
              : state.game ?? restored,
          isLoading: false,
          recoveryFailed: false,
          error: null,
          availableActions: const [],
          winner: state.winner ?? restored.winner,
          scores: const [],
          activity: 'Rejoined your game');
      _reconnectToken =
          response['reconnectToken']?.toString() ?? previous.reconnectToken;
      await _rememberGame();
      await loadAvailableActions();
      return _isSession(session);
    } catch (error) {
      if (!_isSession(session)) return false;
      if (error is GameApiException && error.statusCode == 404) {
        await _forgetPreviousGame();
      }
      if (mounted) _setError(error);
      return false;
    } finally {
      if (_isSession(session)) _resuming = false;
    }
  }

  Future<bool> createSoloGame({
    required String playerName,
    int aiCount = 1,
    String difficulty = 'master',
  }) async {
    if (state.isLoading) return false;
    final session = _beginGame(playerName: playerName, multiplayer: false);
    state = state.copyWith(lastAiCount: aiCount, lastDifficulty: difficulty);
    try {
      final token = await _validatedTokenForGame();
      if (!_isSession(session)) return false;
      final created = await _restClient.createSoloGame(
          playerName: playerName, aiCount: aiCount, difficulty: difficulty);
      if (!_isSession(session)) return false;
      state = state.copyWith(gameId: created.gameId, game: created.game);
      return await _joinRoom(session, created.gameId, playerName, token);
    } catch (error) {
      if (_isSession(session)) _setError(error);
      return false;
    }
  }

  Future<bool> createMultiplayerRoom({
    required String playerName,
    int maxPlayers = 4,
  }) async {
    if (state.isLoading) return false;
    final session = _beginGame(playerName: playerName, multiplayer: true);
    try {
      final token = await _validatedTokenForGame();
      if (!_isSession(session)) return false;
      final created = await _restClient.createMultiplayerRoom(
          playerName: playerName, maxPlayers: maxPlayers);
      if (!_isSession(session)) return false;
      state = state.copyWith(gameId: created.gameId, game: created.game);
      return await _joinRoom(session, created.gameId, playerName, token);
    } catch (error) {
      if (_isSession(session)) _setError(error);
      return false;
    }
  }

  Future<bool> joinExistingGame({
    required String gameId,
    required String playerName,
    bool preserveLoading = false,
  }) async {
    if (state.isLoading) return false;
    if (!RegExp(r'^\d{4}$').hasMatch(gameId)) {
      _setError(const GameApiException('Enter the four-digit room code.'));
      return false;
    }
    final session = _beginGame(playerName: playerName, multiplayer: true);
    state = state.copyWith(gameId: gameId);
    try {
      final token = await _validatedTokenForGame();
      if (!_isSession(session)) return false;
      final previous = state.previousGame;
      final ownsSavedSeat = previous != null &&
          previous.gameId == gameId &&
          (previous.ownerAccountId != null
              ? token != null &&
                  _accountIdLoader?.call() == previous.ownerAccountId
              : previous.ownerToken == token);
      return await _joinRoom(session, gameId, playerName, token,
          reconnectToken: ownsSavedSeat ? previous.reconnectToken : null);
    } catch (error) {
      if (_isSession(session)) _setError(error);
      return false;
    }
  }

  Future<bool> _joinRoom(
      int session, String gameId, String playerName, String? token,
      {String? reconnectToken}) async {
    await _ensureConnected();
    if (!_isSession(session)) return false;
    final revision = _roomStateRevision;
    final response = await _socketService.joinGame(
        gameId: gameId,
        playerName: playerName,
        token: token,
        reconnectToken: reconnectToken);
    if (!_isSession(session)) return false;
    final snapshot = _gameFrom(response['gameState']);
    final playerId = response['playerId']?.toString();
    if (snapshot == null ||
        snapshot.gameId != gameId ||
        snapshot.playerById(playerId) == null) {
      throw const GameApiException(
          'The server could not confirm your game seat.');
    }
    final game =
        revision == _roomStateRevision ? snapshot : state.game ?? snapshot;
    state = state.copyWith(
        isLoading: false,
        playerId: playerId,
        game: game,
        winner: game.winner ?? state.winner,
        isResumedGame: response['reclaimed'] == true);
    _reconnectToken = response['reconnectToken']?.toString();
    await _rememberGame();
    return _isSession(session);
  }

  Future<void> sendReady() async {
    final session = _sessionRevision;
    final gameId = state.gameId;
    final player = state.game?.playerById(state.playerId);
    if (gameId == null ||
        state.isLoading ||
        player == null ||
        player.isReady ||
        state.game?.status != DaketiGameStatus.waiting) {
      return;
    }
    final revision = _roomStateRevision;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _socketService.playerReady(gameId);
      if (!_isSession(session) || state.gameId != gameId) return;
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
      if (_isSession(session) && state.gameId == gameId) _setError(error);
    }
  }

  Future<bool> sendChatMessage(String message) async {
    final session = _sessionRevision;
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
      if (!_isSession(session)) return false;
      state = state.copyWith(error: null);
      return true;
    } catch (error) {
      if (_isSession(session)) _setError(error, loading: false);
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
    _sessionRevision++;
    _roomStateRevision++;
    _actionInFlight = false;
    _resuming = false;
    _rejoinOperation = null;
    _socketService.disconnect();
    _reconnectTimer?.cancel();
    _rejoinAttempts = 0;
    _reconnectToken = null;
    state = GameSessionState(
        previousGame: state.previousGame,
        lastAiCount: state.lastAiCount,
        lastDifficulty: state.lastDifficulty);
  }

  Future<Map<String, dynamic>> _getActionsRecovering(String gameId) async {
    final session = _sessionRevision;
    try {
      return await _socketService.getActions(gameId);
    } on GameApiException catch (error) {
      if (!_isSession(session)) rethrow;
      if (error.code != 'NOT_IN_GAME') rethrow;
      await _attemptRejoin();
      if (!_isSession(session) ||
          state.gameId != gameId ||
          state.recoveryFailed) {
        rethrow;
      }
      return _socketService.getActions(gameId);
    }
  }

  Future<void> loadAvailableActions() async {
    final session = _sessionRevision;
    final gameId = state.gameId;
    if (gameId == null || !state.isCurrentPlayersTurn) return;
    final revision = _roomStateRevision;
    try {
      final response = await _getActionsRecovering(gameId);
      if (!_isSession(session) ||
          state.gameId != gameId ||
          !state.isCurrentPlayersTurn ||
          revision != _roomStateRevision) {
        return;
      }
      final actions = (response['actions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GameAction.fromJson)
          .toList(growable: false);
      state = state.copyWith(availableActions: actions, error: null);
    } catch (error) {
      if (_isSession(session)) _setError(error, loading: false);
    }
  }

  Future<bool> performAction(GameAction action) async {
    if (_actionInFlight ||
        !state.isCurrentPlayersTurn ||
        state.recoveryFailed ||
        state.winner != null ||
        state.game?.status != DaketiGameStatus.playing) {
      return false;
    }
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
    final session = _sessionRevision;
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
        final response = await _getActionsRecovering(gameId);
        if (!_isSession(session) || state.gameId != gameId) return false;
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
        if (_isSession(session)) _setError(error, loading: false);
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
    final session = _sessionRevision;
    if (_socketService.isConnected) {
      state = state.copyWith(connectionStatus: GameConnectionStatus.connected);
      return;
    }
    state = state.copyWith(connectionStatus: GameConnectionStatus.connecting);
    await _socketService.connect();
    if (_isSession(session)) {
      state = state.copyWith(connectionStatus: GameConnectionStatus.connected);
    }
  }

  Future<String?> _validatedTokenForGame() async {
    final token = await _tokenLoader();
    if (token == null || token.isEmpty) return null;
    final validator = _sessionValidator;
    if (validator == null || await validator()) {
      if (_eligibilityValidator != null && !await _eligibilityValidator()) {
        throw const GameApiException(
            'Your play access is not unlocked yet. Open the waiting list from Home.',
            code: 'PLAY_LOCKED');
      }
      return token;
    }
    throw const GameApiException(
      'Your account session could not be verified. Please log in again or check your connection.',
    );
  }

  Future<bool> _runAction(
    Future<Map<String, dynamic>> Function() operation,
  ) async {
    final gameId = state.gameId;
    final session = _sessionRevision;
    final revision = _roomStateRevision;
    _actionInFlight = true;
    try {
      final response = await operation();
      if (!_isSession(session) || state.gameId != gameId) return false;
      state = state.copyWith(
        game: revision == _roomStateRevision
            ? _gameFrom(response['gameState']) ?? state.game
            : state.game,
        availableActions: const [],
        error: null,
      );
      return true;
    } catch (error) {
      if (_isSession(session)) _setError(error, loading: false);
      return false;
    } finally {
      if (_isSession(session)) _actionInFlight = false;
    }
  }

  void _handleSocketEvent(GameSocketEvent event) {
    if (!mounted) return;
    if (event.name == 'connected') {
      _reconnectTimer?.cancel();
      state = state.copyWith(
        connectionStatus: GameConnectionStatus.connected,
        disconnectedPlayer: null,
      );
      // The initial connection belongs to the explicit join/create request.
      // Rejoining it concurrently can create/reset a player's room entry.
      if (state.playerId != null && state.winner == null && !_resuming) {
        unawaited(_attemptRejoin());
      }
      return;
    }
    if (event.name == 'disconnected') {
      state = state.copyWith(
        connectionStatus: GameConnectionStatus.disconnected,
        activity: 'Connection lost. Reconnecting…',
        availableActions: const [],
      );
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDeadline, () {
        if (!_socketService.isConnected && state.gameId != null) {
          _endUnrecoverableSession();
        }
      });
      return;
    }
    if (state.gameId == null) return;
    final eventGameId = event.data['gameId']?.toString() ??
        (event.data['gameState'] is Map
            ? event.data['gameState']['gameId']?.toString()
            : null);
    if (eventGameId != null && eventGameId != state.gameId) return;
    if (event.name == 'game_over') {
      _roomStateRevision++;
      _reconnectTimer?.cancel();
      unawaited(_forgetPreviousGame());
      final rawScores = event.data['scores'] as List<dynamic>? ?? const [];
      state = state.copyWith(
        game: _gameFrom(event.data['gameState']) ?? state.game,
        winner: event.data['winner']?.toString() ??
            _gameFrom(event.data['gameState'])?.winner,
        availableActions: const [],
        isLoading: false,
        scores: rawScores
            .whereType<Map>()
            .map((score) => score.map(
                  (key, value) => MapEntry(key.toString(), value),
                ))
            .toList(growable: false),
      );
      final refreshAccount = _onGameCompleted;
      if (refreshAccount != null) {
        unawaited(refreshAccount().catchError((Object _) {}));
      }
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
    } else if (event.name == 'player_reconnected') {
      state = state.copyWith(
        availableActions: const [],
        disconnectedPlayer: null,
        activity: '${event.data['playerName'] ?? 'Player'} reconnected',
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
      // A delayed server AI snapshot can still contain the socket ID from
      // before a reclaim. Never adopt that ID or a hidden hand as our seat.
      // Re-authenticate the seat instead, using the same recovery contract.
      if (state.playerId != null &&
          game.playerById(state.playerId) == null &&
          game.status != DaketiGameStatus.finished &&
          _reconnectToken != null &&
          !_resuming &&
          !state.isLoading &&
          !state.recoveryFailed) {
        unawaited(_attemptRejoin());
      }
    }
  }

  Future<void> _attemptRejoin() {
    if (_rejoinOperation != null) return _rejoinOperation!;
    final session = _sessionRevision;
    return _rejoinOperation = _rejoin().whenComplete(() {
      if (_isSession(session)) _rejoinOperation = null;
    });
  }

  Future<void> _rejoin() async {
    final session = _sessionRevision;
    final gameId = state.gameId;
    final playerName = state.playerName;
    if (gameId == null ||
        playerName == null ||
        state.game == null ||
        state.winner != null) {
      return;
    }
    try {
      final token = await _validatedTokenForGame();
      if (!_isSession(session)) return;
      final revision = _roomStateRevision;
      final response = await _socketService.joinGame(
        gameId: gameId,
        playerName: playerName,
        token: token,
        reconnectToken: _reconnectToken ?? state.previousGame?.reconnectToken,
      );
      if (!_isSession(session) || state.gameId != gameId) return;
      if (response['reclaimed'] != true &&
          response['playerId']?.toString() != state.playerId) {
        throw const GameApiException(
            'The server could not restore your original seat.');
      }
      final restored = _gameFrom(response['gameState']);
      if (restored == null ||
          restored.gameId != gameId ||
          restored.playerById(response['playerId']?.toString()) == null) {
        throw const GameApiException(
            'The server could not confirm your game seat.');
      }
      state = state.copyWith(
        isLoading: false,
        playerId: response['playerId']?.toString() ?? state.playerId,
        game: revision == _roomStateRevision ? restored : state.game,
        winner: state.winner ?? restored.winner,
        activity: 'Reconnected to room $gameId',
        availableActions: const [],
        error: null,
        recoveryFailed: false,
      );
      _reconnectToken =
          response['reconnectToken']?.toString() ?? _reconnectToken;
      await _rememberGame();
      _rejoinAttempts = 0;
    } catch (error) {
      if (!_isSession(session) || state.gameId != gameId) return;
      _rejoinAttempts += 1;
      try {
        await _restClient.getGame(gameId);
        if (!_isSession(session) || state.gameId != gameId) return;
        state = state.copyWith(
          activity: 'Restoring connection to room $gameId…',
          error: null,
        );
      } catch (_) {
        if (_isSession(session)) _endUnrecoverableSession();
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
    if (!mounted) return;
    final message = error is GameApiException
        ? error.message
        : 'Something went wrong while connecting to the game.';
    state = state.copyWith(isLoading: loading, error: message);
  }

  void clearError() => state = state.copyWith(error: null);

  @override
  void dispose() {
    _sessionRevision++;
    _reconnectTimer?.cancel();
    _eventsSubscription.cancel();
    super.dispose();
  }
}

Future<String?> _noToken() async => null;
