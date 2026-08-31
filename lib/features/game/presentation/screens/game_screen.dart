import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/services/game_sound_service.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../domain/models/daketi_game.dart';
import '../../domain/models/game_action.dart';
import '../../domain/models/game_card.dart';
import '../../domain/models/game_player.dart';
import '../controllers/game_controller.dart';
import '../widgets/fanned_card_hand.dart';

// Gameplay palette sampled from the approved table reference.
const _gold = Color(0xFFC58B43);
const _darkGold = Color(0xFF533718);
const _cream = Color(0xFFE4C58D);
const _panelBlack = Color(0xFF11130F);
const _panelGreen = Color(0xFF1B291E);
const _turnDurationSeconds = 20;

class _PlayerIdentity {
  const _PlayerIdentity(this.name, this.avatarAsset);

  final String name;
  final String avatarAsset;
}

const _pakistaniBotRoster = <_PlayerIdentity>[
  _PlayerIdentity('Hamza Malik', AppAssets.playerHamza),
  _PlayerIdentity('Ayesha Khan', AppAssets.playerAyesha),
  _PlayerIdentity('Bilal Ahmed', AppAssets.playerBilal),
  _PlayerIdentity('Mahnoor Fatima', AppAssets.playerMahnoor),
  _PlayerIdentity('Saad Qureshi', AppAssets.playerSaad),
];

int _stableIdentitySeed(String value) {
  var hash = 17;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 37 + codeUnit) & 0x7fffffff;
  }
  return hash;
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? selectedCardId;
  String? chatMessage;
  Timer? chatTimer;
  bool isSubmitting = false;
  bool isHandlingTimeout = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GameSoundService.shuffle();
    });
  }

  @override
  void dispose() {
    chatTimer?.cancel();
    super.dispose();
  }

  Future<void> sendChatMessage(String message) async {
    final value = message.trim();
    if (value.isEmpty) return;
    final sent =
        await ref.read(gameControllerProvider.notifier).sendChatMessage(value);
    if (!sent && mounted) {
      _message(ref.read(gameControllerProvider).error ?? 'Message not sent.');
    }
  }

  Future<void> openChatHistory() => showDialog<void>(
        context: context,
        builder: (_) => _ChatHistoryDialog(onSend: sendChatMessage),
      );

  Future<void> selectCard(GameCard card) async {
    final state = ref.read(gameControllerProvider);
    if (!state.isCurrentPlayersTurn || isSubmitting) return;
    HapticFeedback.selectionClick();
    GameSoundService.cardSelected();
    final isAlreadySelected = selectedCardId == card.id;
    setState(() => selectedCardId = isAlreadySelected ? null : card.id);
    if (isAlreadySelected) return;
    await ref.read(gameControllerProvider.notifier).loadAvailableActions();
    if (mounted && ref.read(gameControllerProvider).error != null) {
      _message(ref.read(gameControllerProvider).error!);
    }
  }

  Future<void> perform(GameAction action) async {
    setState(() => isSubmitting = true);
    final ok =
        await ref.read(gameControllerProvider.notifier).performAction(action);
    if (!mounted) return;
    setState(() {
      isSubmitting = false;
      selectedCardId = null;
    });
    if (!ok) {
      GameSoundService.invalidMove();
      _message(
          ref.read(gameControllerProvider).error ?? 'The move was rejected.');
    } else {
      switch (action.type) {
        case GameActionType.captureTable:
        case GameActionType.extendStack:
          GameSoundService.specialCard();
          break;
        case GameActionType.stealOpponent:
          GameSoundService.challenge();
          break;
        case GameActionType.discard:
          GameSoundService.cardSlap();
          break;
        case GameActionType.unknown:
          GameSoundService.goodMove();
          break;
      }
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> handleTurnTimeout() async {
    if (isHandlingTimeout || isSubmitting) return;
    setState(() => isHandlingTimeout = true);
    GameSoundService.invalidMove();
    HapticFeedback.heavyImpact();
    final ok =
        await ref.read(gameControllerProvider.notifier).handleTurnTimeout();
    if (!mounted) return;
    setState(() => isHandlingTimeout = false);
    if (!ok) {
      _message(
        ref.read(gameControllerProvider).error ??
            'Could not advance the expired turn.',
      );
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> leaveMatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xF2181411),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _gold),
        ),
        title: const Text(
          'LEAVE MATCH?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Dirty Brush',
            color: _cream,
            fontSize: 23,
          ),
        ),
        content: const Text(
          'Are you sure you want to leave the match?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9B211A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('LEAVE MATCH'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider, (previous, next) {
      if (previous?.winner == null && next.winner != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.results);
      }
      if (previous?.connectionStatus != next.connectionStatus &&
          next.connectionStatus == GameConnectionStatus.disconnected) {
        _message('Connection lost. Reconnecting…');
      }
      final wasMyTurn = previous?.isCurrentPlayersTurn ?? false;
      if (!wasMyTurn && next.isCurrentPlayersTurn) {
        GameSoundService.yourTurn();
        HapticFeedback.mediumImpact();
      }
    });
    final session = ref.watch(gameControllerProvider);
    ref.listen(gameControllerProvider.select((value) => value.chatMessages),
        (previous, next) {
      if (next.isEmpty || next.length == previous?.length) return;
      final latest = next.last;
      chatTimer?.cancel();
      setState(() => chatMessage = '${latest.senderName}: ${latest.message}');
      chatTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => chatMessage = null);
      });
    });
    final game = session.game;
    final player = game?.playerById(session.playerId);
    if (selectedCardId != null &&
        !(player?.hand.any((card) => card.id == selectedCardId) ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => selectedCardId = null);
      });
    }
    final actions = session.availableActions
        .where((action) => action.cardId == selectedCardId)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.tableBackground,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          const ColoredBox(color: Color(0x18000000)),
          Center(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 844,
                height: 390,
                child: game == null
                    ? const Center(child: CircularProgressIndicator())
                    : _Board(
                        session: session,
                        game: game,
                        player: player,
                        selected: selectedCardId,
                        actions: actions,
                        submitting: isSubmitting,
                        chatMessage: chatMessage,
                        onCard: selectCard,
                        onAction: perform,
                        onChat: sendChatMessage,
                        onOpenChat: openChatHistory,
                        onTurnTimeout: handleTurnTimeout,
                        onExit: leaveMatch,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board(
      {required this.session,
      required this.game,
      required this.player,
      required this.selected,
      required this.actions,
      required this.submitting,
      required this.chatMessage,
      required this.onCard,
      required this.onAction,
      required this.onChat,
      required this.onOpenChat,
      required this.onTurnTimeout,
      required this.onExit});
  final GameSessionState session;
  final DaketiGame game;
  final GamePlayer? player;
  final String? selected;
  final List<GameAction> actions;
  final bool submitting;
  final String? chatMessage;
  final ValueChanged<GameCard> onCard;
  final ValueChanged<GameAction> onAction;
  final ValueChanged<String> onChat;
  final VoidCallback onOpenChat;
  final VoidCallback onTurnTimeout;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    // Rotate the server's player list around the local player so the visual
    // seats always follow the same clockwise turn order. The next player is
    // seated on the left, followed by top-center and then the right seat.
    final localPlayerIndex =
        game.players.indexWhere((p) => p.id == session.playerId);
    final opponents = localPlayerIndex < 0
        ? game.players.where((p) => p.id != session.playerId).toList()
        : List<GamePlayer>.generate(
            game.players.length - 1,
            (index) => game
                .players[(localPlayerIndex + index + 1) % game.players.length],
          );
    final GamePlayer? topOpponent = opponents.length == 1
        ? opponents[0]
        : opponents.length >= 2
            ? opponents[1]
            : null;
    final GamePlayer? leftOpponent =
        opponents.length >= 2 ? opponents[0] : null;
    final GamePlayer? rightOpponent =
        opponents.length >= 3 ? opponents[2] : null;
    final isTwoPlayerMatch = opponents.length == 1;
    final isThreePlayerMatch = opponents.length == 2;
    final identitySeed = _stableIdentitySeed(session.gameId ?? game.gameId);
    final identityStep = 1 + (identitySeed ~/ 5) % 4;
    _PlayerIdentity? identityFor(GamePlayer? opponent, int seatIndex) {
      if (opponent == null || !opponent.isAi) return null;
      final rosterIndex = (identitySeed + seatIndex * identityStep) %
          _pakistaniBotRoster.length;
      return _pakistaniBotRoster[rosterIndex];
    }

    final topIdentity = identityFor(topOpponent, 0);
    final leftIdentity = identityFor(leftOpponent, 1);
    final rightIdentity = identityFor(rightOpponent, 2);
    final reducedPlayerScale = isTwoPlayerMatch
        ? 1.18
        : isThreePlayerMatch
            ? 1.10
            : 1.0;
    return Stack(children: [
      const Positioned.fill(
          child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: RadialGradient(
                      radius: 1.05,
                      colors: [Colors.transparent, Color(0xB0000000)],
                      stops: [.42, 1])))),
      Positioned(
          left: 8, top: 5, child: GameCloseButton(size: 58, onTap: onExit)),
      Positioned(
          left: 70,
          top: 12,
          child: _Square(
              icon: Icons.group,
              label: '${game.players.length}/${game.maxPlayers}')),
      Positioned(
          left: 13,
          top: 65,
          child: _Room(room: session.gameId ?? game.gameId, round: game.round)),
      const Positioned(right: 13, top: 12, child: _Square(icon: Icons.menu)),
      const Positioned(
          right: 13, top: 66, child: _Square(icon: Icons.headset_mic)),
      const Positioned(
          right: 13, top: 118, child: _Square(icon: Icons.settings)),
      if (topOpponent != null)
        Positioned(
            left: isTwoPlayerMatch ? 277 : 287,
            top: isTwoPlayerMatch ? 18 : 4,
            child: Transform.scale(
              scale: reducedPlayerScale,
              alignment: Alignment.topCenter,
              child: _Seat(
                player: topOpponent,
                identity: topIdentity,
                place: 0,
                isActive: game.currentPlayerId == topOpponent.id,
                game: game,
                timerRevision: session.turnTimerRevision,
              ),
            )),
      if (topOpponent?.topCard != null)
        Positioned(
            left: isTwoPlayerMatch ? 300 : 310,
            top: isTwoPlayerMatch ? 36 : 22,
            child: _CapturePile(
                card: topOpponent!.topCard!, count: topOpponent.stackCount)),
      if (leftOpponent != null)
        Positioned(
            // With two opponents, reserve the upper-left for room details and
            // place this whole seat in the clear lane above match chat.
            left: isThreePlayerMatch ? 42 : 37,
            top: isThreePlayerMatch ? 214 : 151,
            child: Transform.scale(
              scale: reducedPlayerScale,
              alignment: Alignment.topLeft,
              child: _Seat(
                player: leftOpponent,
                identity: leftIdentity,
                place: 1,
                isActive: game.currentPlayerId == leftOpponent.id,
                game: game,
                timerRevision: session.turnTimerRevision,
              ),
            )),
      if (leftOpponent?.topCard != null)
        Positioned(
            // In a three-player game, center the captured stack above Player
            // 2's profile. Their hidden hand remains in its usual right lane.
            left: isThreePlayerMatch ? 66 : 59,
            top: isThreePlayerMatch ? 128 : 246,
            child: _CapturePile(
                card: leftOpponent!.topCard!, count: leftOpponent.stackCount)),
      if (rightOpponent != null)
        Positioned(
            // In a four-player match, move Player 3 toward the outer rail so
            // their hidden hand has clear breathing room from the draw deck.
            right: isThreePlayerMatch ? 82 : 22,
            top: isThreePlayerMatch ? 58 : 151,
            child: Transform.scale(
              scale: reducedPlayerScale,
              alignment: Alignment.topRight,
              child: _Seat(
                player: rightOpponent,
                identity: rightIdentity,
                place: 2,
                isActive: game.currentPlayerId == rightOpponent.id,
                game: game,
                timerRevision: session.turnTimerRevision,
              ),
            )),
      if (rightOpponent?.topCard != null)
        Positioned(
            right: 59,
            top: 246,
            child: _CapturePile(
                card: rightOpponent!.topCard!,
                count: rightOpponent.stackCount)),
      Positioned(
          left: 220,
          right: 220,
          top: 137,
          height: 116,
          child: Transform.scale(
            scale: isTwoPlayerMatch
                ? 1.12
                : isThreePlayerMatch
                    ? 1.06
                    : 1,
            child: _TableCards(cards: game.table, deck: game.deckCount),
          )),
      Positioned(
          left: 492,
          top: 105,
          child: _TurnLabel(isLocalTurn: session.isCurrentPlayersTurn)),
      Positioned(
          // Keep the radial hand in its own lane to the right of the local
          // medallion. The shared fan pivot must never sit behind the avatar.
          left: 350,
          right: 95,
          bottom: 12,
          height: 133,
          child: Transform.scale(
            scale: isTwoPlayerMatch
                ? 1.10
                : isThreePlayerMatch
                    ? 1.05
                    : 1,
            alignment: Alignment.bottomCenter,
            child: _Hand(
                cards: player?.hand ?? const [],
                selected: selected,
                enabled: session.isCurrentPlayersTurn && !submitting,
                onTap: onCard),
          )),
      if (player?.topCard != null)
        Positioned(
            left: isTwoPlayerMatch ? 300 : 310,
            bottom: 5,
            child: _CapturePile(
                card: player!.topCard!, count: player!.stackCount)),
      Positioned(
          left: isTwoPlayerMatch ? 359 : 369,
          bottom: 2,
          child: _Medallion(
            player: player,
            fallbackName: session.playerName ?? 'YOU',
            isActive: session.isCurrentPlayersTurn,
            isLocal: true,
            game: game,
            timerRevision: session.turnTimerRevision,
            onTimeout: onTurnTimeout,
          )),
      if (chatMessage != null)
        Positioned(
          left: 205,
          bottom: 54,
          child: _ChatBubble(chatMessage!),
        ),
      Positioned(
          left: 4,
          bottom: 12,
          child: _Chat(onSend: onChat, onOpenHistory: onOpenChat)),
      if (selected != null)
        Positioned(
            right: 13,
            bottom: 12,
            child: _Actions(
                actions: actions, loading: submitting, onTap: onAction)),
      if (session.activity != null)
        Positioned(
            left: 152,
            top: 18,
            width: 190,
            child: _Activity(session.activity!)),
    ]);
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(6)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: _panelBlack,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: _gold, width: 1.2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black87, blurRadius: 7, offset: Offset(0, 3))
          ]),
      child: Container(
          padding: padding,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_panelGreen, Color(0xFF121812)]),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _darkGold)),
          child: child));
}

class _Square extends StatelessWidget {
  const _Square({required this.icon, this.label});
  final IconData icon;
  final String? label;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: label == null ? 48 : 76,
      height: 45,
      child: _Panel(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: _cream, size: 23),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(label!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14))
            ]
          ])));
}

class _Room extends StatelessWidget {
  const _Room({required this.room, required this.round});
  final String room;
  final int round;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 70,
      child: _Panel(
          child: Column(children: [
        const Text('TABLE ID', style: TextStyle(fontSize: 8, color: _cream)),
        Text(room.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9)),
        const Divider(height: 8, color: _darkGold),
        Text('ROUND $round', style: const TextStyle(fontSize: 8, color: _cream))
      ])));
}

class _Seat extends StatelessWidget {
  const _Seat({
    required this.player,
    required this.identity,
    required this.place,
    required this.isActive,
    required this.game,
    required this.timerRevision,
  });
  final GamePlayer player;
  final _PlayerIdentity? identity;
  final int place;
  final bool isActive;
  final DaketiGame game;
  final int timerRevision;
  @override
  Widget build(BuildContext context) {
    final side = place != 0;
    return SizedBox(
        width: side ? 150 : 270,
        height: side ? 108 : 98,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
              left: place == 0
                  ? 82
                  : side && place == 1
                      ? 0
                      : null,
              right: side && place == 2 ? 0 : null,
              top: side ? 2 : 0,
              child: _Medallion(
                player: player,
                displayName: identity?.name,
                avatarAsset: identity?.avatarAsset,
                isActive: isActive,
                isLocal: false,
                game: game,
                timerRevision: timerRevision,
              )),
          Positioned(
              left: place == 1
                  ? 95
                  : place == 2
                      ? -45
                      : 160,
              top: side ? 42 : 5,
              child: _Fan(player.handCount.clamp(0, 5))),
        ]));
  }
}

class _Medallion extends StatefulWidget {
  const _Medallion({
    required this.player,
    required this.isActive,
    required this.isLocal,
    required this.game,
    required this.timerRevision,
    this.fallbackName = 'Player',
    this.displayName,
    this.avatarAsset,
    this.onTimeout,
  });

  final GamePlayer? player;
  final bool isActive;
  final bool isLocal;
  final DaketiGame game;
  final int timerRevision;
  final String fallbackName;
  final String? displayName;
  final String? avatarAsset;
  final VoidCallback? onTimeout;

  @override
  State<_Medallion> createState() => _MedallionState();
}

class _MedallionState extends State<_Medallion> {
  Timer? timer;
  late int fallbackStart;
  late int remaining;
  int? lastAlert;
  bool timeoutSent = false;
  bool useFallbackStart = false;

  @override
  void initState() {
    super.initState();
    fallbackStart = DateTime.now().millisecondsSinceEpoch;
    remaining = calculateRemaining();
    timer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => updateCountdown(),
    );
  }

  int calculateRemaining() {
    final raw = widget.game.turnStartTime;
    final started = raw == null || useFallbackStart
        ? fallbackStart
        : raw < 100000000000
            ? raw * 1000
            : raw;
    return (_turnDurationSeconds -
            (DateTime.now().millisecondsSinceEpoch - started) ~/ 1000)
        .clamp(0, _turnDurationSeconds);
  }

  void updateCountdown() {
    final next = calculateRemaining();
    if (next == remaining) return;
    if (mounted) setState(() => remaining = next);
    if (widget.isActive && widget.isLocal && next == 0 && !timeoutSent) {
      timeoutSent = true;
      widget.onTimeout?.call();
      return;
    }
    if (!widget.isActive ||
        !widget.isLocal ||
        next <= 0 ||
        next > 5 ||
        lastAlert == next) {
      return;
    }
    lastAlert = next;
    if (next == 5) {
      GameSoundService.timerWarning();
      HapticFeedback.lightImpact();
    } else if (next == 1) {
      GameSoundService.timerTick();
      HapticFeedback.heavyImpact();
    } else {
      GameSoundService.timerTick();
      HapticFeedback.lightImpact();
    }
  }

  @override
  void didUpdateWidget(covariant _Medallion oldWidget) {
    super.didUpdateWidget(oldWidget);
    final turnChanged =
        oldWidget.game.currentPlayerId != widget.game.currentPlayerId ||
            oldWidget.game.turnStartTime != widget.game.turnStartTime;
    final moveAccepted = oldWidget.timerRevision != widget.timerRevision;
    if (turnChanged || moveAccepted) {
      fallbackStart = DateTime.now().millisecondsSinceEpoch;
      useFallbackStart = moveAccepted && !turnChanged;
      lastAlert = null;
      timeoutSent = false;
      remaining = calculateRemaining();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    const limit = _turnDurationSeconds;
    final progress = (remaining / limit).clamp(0.0, 1.0);
    final ringColor = remaining <= 5
        ? const Color(0xFFE53E36)
        : remaining <= 10
            ? const Color(0xFFF2C94C)
            : const Color(0xFF35C96F);
    return SizedBox(
        width: 96,
        height: 110,
        child: Stack(alignment: Alignment.topCenter, children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(alignment: Alignment.center, children: [
              if (widget.isActive)
                SizedBox.expand(
                  child: CustomPaint(
                    painter: _TurnTimerRingPainter(
                      progress: progress,
                      color: ringColor,
                    ),
                  ),
                ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF695B35), _panelBlack],
                  ),
                  border: Border.all(color: _gold, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isActive
                          ? ringColor.withValues(alpha: .5)
                          : Colors.black87,
                      blurRadius: widget.isActive ? 10 : 7,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    widget.avatarAsset ?? AppAssets.playerAvatar,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ]),
          ),
          Positioned(
              // Keep the badge below the avatar so the complete circular
              // turn-timer remains visible.
              top: 62,
              child: SizedBox(
                  width: 94,
                  child: _Badge(
                    name: widget.displayName ??
                        player?.name ??
                        widget.fallbackName,
                    score: player?.score ?? 0,
                  ))),
        ]));
  }
}

class _TurnTimerRingPainter extends CustomPainter {
  const _TurnTimerRingPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x733B2B19)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Zero radians is the avatar's right edge. A negative sweep makes the
    // countdown travel from right to left around the profile.
    canvas.drawArc(
      bounds,
      0,
      -2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TurnTimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.name, required this.score});
  final String name;
  final int score;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 94,
      child: _Panel(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Column(children: [
            Text(name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$score',
                  style: const TextStyle(fontSize: 8, color: _cream)),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8A236),
                  boxShadow: [BoxShadow(color: _gold, blurRadius: 2)],
                ),
              ),
            ])
          ])));
}

class _Fan extends StatelessWidget {
  const _Fan(this.count);
  final int count;
  @override
  Widget build(BuildContext context) {
    // Opponent cards are deliberately a little larger than before while
    // retaining enough overlap to keep their name and score unobstructed.
    const cardWidth = 38.0;
    const cardHeight = 55.0;
    const overlapStep = 12.0;
    final rowWidth = count == 0 ? 0.0 : cardWidth + (count - 1) * overlapStep;
    final start = (100 - rowWidth) / 2;
    final center = (count - 1) / 2;
    return SizedBox(
        width: 100,
        height: 62,
        child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(count, (i) {
              final distance = i - center;
              return Positioned(
                  left: start + i * overlapStep,
                  bottom: 0,
                  child: Transform.rotate(
                    angle: distance * .14,
                    alignment: Alignment.bottomCenter,
                    child: const _Card(
                      GameCard(id: 'hidden', value: '', suit: ''),
                      cardWidth,
                      cardHeight,
                    ),
                  ));
            })));
  }
}

class _TableCards extends StatelessWidget {
  const _TableCards({required this.cards, required this.deck});
  final List<GameCard> cards;
  final int deck;
  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 72,
            top: 2,
            bottom: 2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 340),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: LayoutBuilder(
                key: ValueKey(cards.map((card) => card.id).join('|')),
                builder: (context, constraints) {
                  const cardsPerRow = 5;
                  const cardWidth = 47.0;
                  const cardHeight = 67.0;
                  const horizontalStep = 54.0;
                  final rowCount = (cards.length / cardsPerRow).ceil();
                  final verticalStep = rowCount <= 1
                      ? 0.0
                      : ((constraints.maxHeight - cardHeight) / (rowCount - 1))
                          .clamp(14.0, 28.0);
                  final firstRowCount = cards.length.clamp(0, cardsPerRow);
                  final firstRowWidth = firstRowCount == 0
                      ? 0.0
                      : cardWidth + (firstRowCount - 1) * horizontalStep;
                  final baseLeft = (constraints.maxWidth - firstRowWidth) / 2;
                  final paintOrder = List<int>.generate(cards.length, (i) => i)
                    ..sort((a, b) {
                      final rowA = a ~/ cardsPerRow;
                      final rowB = b ~/ cardsPerRow;
                      final rowComparison = rowA.compareTo(rowB);
                      return rowComparison != 0
                          ? rowComparison
                          : a.compareTo(b);
                    });

                  return Stack(
                    clipBehavior: Clip.none,
                    children: paintOrder.map((index) {
                      final row = index ~/ cardsPerRow;
                      final column = index % cardsPerRow;
                      // Each additional row sits above the row before it.
                      // Its first card begins halfway between the first two
                      // cards, matching the requested overlapping pile.
                      final stagger = row.isOdd ? horizontalStep / 2 : 0.0;
                      return Positioned(
                        left: baseLeft + column * horizontalStep + stagger,
                        top: row * verticalStep,
                        child: _Card(cards[index], cardWidth, cardHeight),
                      );
                    }).toList(growable: false),
                  );
                },
              ),
            ),
          ),
          if (deck > 0)
            Positioned(
              right: 8,
              top: 7,
              child: Stack(children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 4),
                  child: _Card(
                    GameCard(id: 'hidden', value: '', suit: ''),
                    47,
                    67,
                  ),
                ),
                const _Card(
                  GameCard(id: 'hidden', value: '', suit: ''),
                  47,
                  67,
                ),
                Positioned(
                  right: 3,
                  bottom: 2,
                  child: Text('$deck', style: const TextStyle(fontSize: 7)),
                ),
              ]),
            ),
        ],
      );
}

class _CapturePile extends StatelessWidget {
  const _CapturePile({required this.card, required this.count});

  final GameCard card;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
      label:
          'Captured stack, $count cards, top card ${card.value} of ${card.suit}',
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${card.id}-$count'),
        tween: Tween(begin: .78, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        ),
        child: SizedBox(
          width: 57,
          height: 82,
          child: Stack(clipBehavior: Clip.none, children: [
            if (count > 2)
              Positioned(
                  left: 5,
                  top: 5,
                  child: Opacity(opacity: .75, child: _Card(card, 47, 67))),
            if (count > 1)
              Positioned(
                  left: 2,
                  top: 2,
                  child: Opacity(opacity: .88, child: _Card(card, 47, 67))),
            Positioned(left: 0, top: 0, child: _Card(card, 47, 67)),
            Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xED11130F),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _gold)),
                    child: Text('$count',
                        style: const TextStyle(
                            color: _cream,
                            fontSize: 7,
                            fontWeight: FontWeight.w900))))
          ]),
        ),
      ));
}

class _Hand extends StatelessWidget {
  const _Hand(
      {required this.cards,
      required this.selected,
      required this.enabled,
      required this.onTap});
  final List<GameCard> cards;
  final String? selected;
  final bool enabled;
  final ValueChanged<GameCard> onTap;

  int rank(GameCard card) => switch (card.value.toUpperCase()) {
        'A' => 14,
        'K' => 13,
        'Q' => 12,
        'J' => 11,
        'T' => 10,
        _ => int.tryParse(card.value) ?? 0,
      };

  @override
  Widget build(BuildContext context) {
    final orderedCards = List<GameCard>.of(cards)
      ..sort((a, b) {
        final valueOrder = rank(a).compareTo(rank(b));
        if (valueOrder != 0) return valueOrder;
        return a.suit.compareTo(b.suit);
      });
    return FannedCardHand(
      cards: orderedCards,
      selectedCardId: selected,
      enabled: enabled,
      onCardTap: onTap,
      cardBuilder: (context, card, active) =>
          _Card(card, 61, 91, selected: active),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.card, this.width, this.height, {this.selected = false});
  final GameCard card;
  final double width;
  final double height;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    // Every card occupies the same measured box. This keeps face-up cards,
    // card backs, rows, fans and capture piles aligned without overflow.
    final displayWidth = width;
    final displayHeight = height;
    return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: displayWidth,
        height: displayHeight,
        decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: selected
                    ? const Color(0xFFFFC75D)
                    : const Color(0xFF59401D),
                width: selected ? 2 : 1),
            boxShadow: [
              const BoxShadow(
                  color: Colors.black87, blurRadius: 5, offset: Offset(2, 3)),
              if (selected)
                const BoxShadow(color: Color(0xFFD99638), blurRadius: 10)
            ]),
        child: card.isHidden
            ? ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  AppAssets.cardBack,
                  width: displayWidth,
                  height: displayHeight,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  _cardAsset(card),
                  width: displayWidth,
                  height: displayHeight,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ));
  }
}

String _cardAsset(GameCard card) {
  final suit = switch (card.suit) {
    'C' => 'Clubs',
    'D' => 'Diamonds',
    'H' => 'Hearts',
    'S' => 'Spades',
    _ => 'Spades',
  };
  final value = switch (card.value) {
    'A' => 'Ace',
    'K' when card.suit == 'S' => 'KIng',
    'K' => 'King',
    'Q' => 'Queen',
    'J' => 'Jack',
    'T' => '10',
    _ => card.value,
  };
  return 'assets/images/cards/style01/$suit/$value.png';
}

class _Chat extends StatefulWidget {
  const _Chat({required this.onSend, required this.onOpenHistory});
  final ValueChanged<String> onSend;
  final VoidCallback onOpenHistory;

  @override
  State<_Chat> createState() => _ChatState();
}

class _ChatState extends State<_Chat> {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void send() {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    widget.onSend(value);
    controller.clear();
    focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 145,
      height: 36,
      child: _Panel(
          padding: const EdgeInsets.only(left: 9, right: 5),
          child: Row(children: [
            InkWell(
              onTap: widget.onOpenHistory,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.chat_bubble, size: 16, color: _cream),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => send(),
                maxLength: 80,
                style: const TextStyle(fontSize: 8, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(fontSize: 8, color: Colors.white60),
                  counterText: '',
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            InkWell(
              onTap: send,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.send, size: 16, color: Color(0xFF6ACA73)),
              ),
            )
          ])));
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 90, maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xF21B1814),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 8)],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 9, height: 1.3),
        ),
      );
}

class _ChatHistoryDialog extends ConsumerStatefulWidget {
  const _ChatHistoryDialog({required this.onSend});

  final ValueChanged<String> onSend;

  @override
  ConsumerState<_ChatHistoryDialog> createState() => _ChatHistoryDialogState();
}

class _ChatHistoryDialogState extends ConsumerState<_ChatHistoryDialog> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void send() {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    widget.onSend(value);
    controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(
      gameControllerProvider.select((state) => state.chatMessages),
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        height: 320,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xF5161310),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 24),
          ],
        ),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.forum, color: _cream, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'MATCH CHAT',
                style: TextStyle(
                  fontFamily: 'Dirty Brush',
                  fontSize: 22,
                  color: _cream,
                ),
              ),
            ),
            IconButton(
              onPressed: Navigator.of(context).pop,
              icon: const Icon(Icons.close, color: Colors.white70),
            ),
          ]),
          const Divider(color: _darkGold),
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Start the conversation.',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final entry = messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.senderName.toUpperCase(),
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xB52B251F),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                entry.message,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 42,
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              color: const Color(0xE00C0B09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _darkGold),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 80,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => send(),
                  style: const TextStyle(fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: 'Type a message…',
                    counterText: '',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: send,
                icon: const Icon(Icons.send, color: Color(0xFF6ACA73)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(
      {required this.actions, required this.loading, required this.onTap});
  final List<GameAction> actions;
  final bool loading;
  final ValueChanged<GameAction> onTap;
  String label(GameAction a) => switch (a.type) {
        GameActionType.captureTable => 'TAKE MATCHING CARDS',
        GameActionType.stealOpponent => "STEAL OPPONENT'S CARD",
        GameActionType.extendStack => 'ADD CARD TO OWN DECK',
        GameActionType.discard => 'PLAY CARD, END TURN',
        GameActionType.unknown => 'MOVE'
      };
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
          width: 124,
          height: 40,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (actions.isEmpty) {
      return const SizedBox(
          width: 124,
          height: 40,
          child: Center(
              child: Text('LOADING MOVES…', style: TextStyle(fontSize: 8))));
    }
    return SizedBox(
      width: 190,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: actions
            .map((action) => Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: _BrushActionButton(
                    label: label(action),
                    onTap: () => onTap(action),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _BrushActionButton extends StatelessWidget {
  const _BrushActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 150 / 34,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppAssets.actionButtonBrush,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Dirty Brush',
                            fontSize: 15,
                            height: 1,
                            shadows: [
                              Shadow(
                                color: Color(0x66000000),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _TurnLabel extends StatelessWidget {
  const _TurnLabel({required this.isLocalTurn});
  final bool isLocalTurn;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xD9000000),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _darkGold),
        ),
        child: Text(
          isLocalTurn ? 'YOUR TURN' : 'OPPONENT TURN',
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: _cream,
          ),
        ),
      );
}

class _Activity extends StatelessWidget {
  const _Activity(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xE6291B0C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 7)]),
      child: Text(text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Color(0xFFFFC75D),
              fontSize: 8,
              fontWeight: FontWeight.w800)));
}
