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
import '../widgets/bike_daketi_overlay.dart';
import '../widgets/fanned_card_hand.dart';
import '../widgets/opening_deal_overlay.dart';

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

class _StealAnimation {
  const _StealAnimation({
    required this.id,
    required this.targetPlayerId,
    required this.cardCount,
    required this.cards,
  });

  final int id;
  final String targetPlayerId;
  final int cardCount;
  final List<GameCard> cards;
}

class _DrawDeal {
  const _DrawDeal({
    required this.playerId,
    required this.destination,
    required this.card,
  });

  final String playerId;
  final Offset destination;
  final GameCard card;
}

class _DrawAnimation {
  const _DrawAnimation({required this.id, required this.deals});

  final int id;
  final List<_DrawDeal> deals;
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
  String? noticeMessage;
  Timer? noticeTimer;
  bool isSubmitting = false;
  bool isHandlingTimeout = false;
  bool isLeavingDisconnectedGame = false;
  _StealAnimation? stealAnimation;
  int stealAnimationId = 0;
  _DrawAnimation? drawAnimation;
  int drawAnimationId = 0;
  int openingDealPhase = 0;

  List<_DrawDeal> _drawDealsFor(
    GameSessionState previous,
    GameSessionState next,
  ) {
    final oldGame = previous.game;
    final newGame = next.game;
    if (oldGame == null ||
        newGame == null ||
        openingDealPhase < 2 ||
        newGame.deckCount >= oldGame.deckCount) {
      return const [];
    }
    final localId = next.playerId;
    final localIndex = newGame.players.indexWhere((item) => item.id == localId);
    if (localIndex < 0) return const [];
    final opponents = List<GamePlayer>.generate(
      newGame.players.length - 1,
      (index) =>
          newGame.players[(localIndex + index + 1) % newGame.players.length],
    );
    Offset destinationFor(String playerId) {
      if (playerId == localId) return const Offset(560, 330);
      final index = opponents.indexWhere((item) => item.id == playerId);
      if (opponents.length == 1) return const Offset(515, 70);
      if (opponents.length == 2) {
        return index == 0 ? const Offset(126, 212) : const Offset(515, 70);
      }
      return switch (index) {
        0 => const Offset(126, 212),
        1 => const Offset(515, 70),
        _ => const Offset(700, 212),
      };
    }

    final deals = <_DrawDeal>[];
    for (final newPlayer in newGame.players) {
      final oldPlayer = oldGame.playerById(newPlayer.id);
      if (oldPlayer == null) continue;
      final increase = newPlayer.handCount - oldPlayer.handCount;
      if (increase <= 0) continue;
      final destination = destinationFor(newPlayer.id);
      if (newPlayer.id == localId) {
        final oldIds = oldPlayer.hand.map((card) => card.id).toSet();
        final added = newPlayer.hand
            .where((card) => !oldIds.contains(card.id))
            .toList(growable: false);
        for (var index = 0; index < increase; index++) {
          deals.add(_DrawDeal(
            playerId: newPlayer.id,
            destination: destination,
            card: index < added.length
                ? added[index]
                : const GameCard(id: 'hidden', value: '', suit: ''),
          ));
        }
      } else {
        for (var index = 0; index < increase; index++) {
          deals.add(_DrawDeal(
            playerId: newPlayer.id,
            destination: destination,
            card: const GameCard(id: 'hidden', value: '', suit: ''),
          ));
        }
      }
    }
    final available = oldGame.deckCount - newGame.deckCount;
    return deals.take(available).toList(growable: false);
  }

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
    noticeTimer?.cancel();
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

  Future<void> showCapturedCards(GamePlayer player) {
    if (player.id != ref.read(gameControllerProvider).playerId) {
      return Future<void>.value();
    }
    final cards = player.stack.isNotEmpty
        ? player.stack
        : player.topCard == null
            ? const <GameCard>[]
            : <GameCard>[player.topCard!];
    final dialogWidth = (cards.length * 55.0 + 40).clamp(220.0, 430.0);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        backgroundColor: Colors.transparent,
        child: Container(
          width: dialogWidth,
          height: 145,
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xF2181411),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 14),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${player.name.toUpperCase()} · CAPTURED SERIES',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Dirty Brush',
                        color: _cream,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.close_rounded,
                        color: _cream,
                        size: 16,
                        shadows: [
                          Shadow(color: Color(0xFFFF8500), blurRadius: 6),
                          Shadow(color: Colors.black, blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Expanded(
                child: cards.isEmpty
                    ? const Center(
                        child: Text(
                          'NO CAPTURED CARDS',
                          style: TextStyle(fontSize: 9),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final card in cards) ...[
                              _Card(card, 47, 67),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    final targetBeforeMove = action.targetPlayerId == null
        ? null
        : ref
            .read(gameControllerProvider)
            .game
            ?.playerById(action.targetPlayerId);
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
          GameSoundService.daketiRide();
          setState(() {
            stealAnimation = _StealAnimation(
              id: ++stealAnimationId,
              targetPlayerId: action.targetPlayerId ?? '',
              cardCount: targetBeforeMove?.stackCount.clamp(1, 99) ?? 1,
              cards: targetBeforeMove == null
                  ? const []
                  : targetBeforeMove.stack.isNotEmpty
                      ? List<GameCard>.of(targetBeforeMove.stack)
                      : targetBeforeMove.topCard == null
                          ? const []
                          : [targetBeforeMove.topCard!],
            );
          });
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

  void _message(String text) {
    noticeTimer?.cancel();
    setState(() => noticeMessage = text);
    noticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => noticeMessage = null);
    });
  }

  void returnToOverviewAfterConnectionFailure() {
    if (isLeavingDisconnectedGame || !mounted) return;
    isLeavingDisconnectedGame = true;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (_) => false,
    );
  }

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
          style: TextStyle(color: Colors.white70, fontSize: 14),
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
      if (previous?.recoveryFailed != true && next.recoveryFailed) {
        returnToOverviewAfterConnectionFailure();
      }
      final wasMyTurn = previous?.isCurrentPlayersTurn ?? false;
      if (!wasMyTurn && next.isCurrentPlayersTurn) {
        GameSoundService.yourTurn();
        HapticFeedback.mediumImpact();
      }
      if (previous != null && drawAnimation == null) {
        final deals = _drawDealsFor(previous, next);
        if (deals.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || drawAnimation != null) return;
            setState(() => drawAnimation = _DrawAnimation(
                  id: ++drawAnimationId,
                  deals: deals,
                ));
          });
        }
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
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
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
                        submitting: isSubmitting || drawAnimation != null,
                        chatMessage: chatMessage,
                        onCard: selectCard,
                        onAction: perform,
                        onChat: sendChatMessage,
                        onOpenChat: openChatHistory,
                        onViewCapturedCards: showCapturedCards,
                        onTurnTimeout: handleTurnTimeout,
                        openingDealPhase: openingDealPhase,
                        onHandsDealt: () {
                          if (mounted) setState(() => openingDealPhase = 1);
                        },
                        onTableDealt: () {
                          if (mounted) setState(() => openingDealPhase = 2);
                        },
                        stealAnimation: stealAnimation,
                        onStealAnimationComplete: () {
                          if (mounted) setState(() => stealAnimation = null);
                        },
                        drawAnimation: drawAnimation,
                        onDrawAnimationComplete: () {
                          if (mounted) setState(() => drawAnimation = null);
                        },
                        onExit: leaveMatch,
                      ),
              ),
            ),
          ),
          if (noticeMessage != null)
            Positioned(
              top: 12,
              right: 78,
              child: IgnorePointer(
                child: _CompactNotice(noticeMessage!),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactNotice extends StatelessWidget {
  const _CompactNotice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xF21B1814),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _gold, width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 6),
          ],
        ),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _cream,
            fontSize: 11,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
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
      required this.onViewCapturedCards,
      required this.onTurnTimeout,
      required this.openingDealPhase,
      required this.onHandsDealt,
      required this.onTableDealt,
      required this.stealAnimation,
      required this.onStealAnimationComplete,
      required this.drawAnimation,
      required this.onDrawAnimationComplete,
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
  final ValueChanged<GamePlayer> onViewCapturedCards;
  final VoidCallback onTurnTimeout;
  final int openingDealPhase;
  final VoidCallback onHandsDealt;
  final VoidCallback onTableDealt;
  final _StealAnimation? stealAnimation;
  final VoidCallback onStealAnimationComplete;
  final _DrawAnimation? drawAnimation;
  final VoidCallback onDrawAnimationComplete;
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
    final isFourPlayerMatch = opponents.length >= 3;
    int dealingCountFor(String playerId) =>
        drawAnimation?.deals
            .where((deal) => deal.playerId == playerId)
            .length ??
        0;
    final localDeals = drawAnimation?.deals
            .where((deal) => deal.playerId == session.playerId)
            .toList(growable: false) ??
        const <_DrawDeal>[];
    final dealtCardIds = localDeals
        .where((deal) => !deal.card.isHidden)
        .map((deal) => deal.card.id)
        .toSet();
    var visibleLocalCards = (player?.hand ?? const <GameCard>[])
        .where((card) => !dealtCardIds.contains(card.id))
        .toList(growable: false);
    final unknownLocalDeals =
        localDeals.where((deal) => deal.card.isHidden).length;
    if (unknownLocalDeals > 0 && visibleLocalCards.isNotEmpty) {
      visibleLocalCards = visibleLocalCards
          .take(math.max(0, visibleLocalCards.length - unknownLocalDeals))
          .toList(growable: false);
    }
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
    GameAction? stealActionFor(GamePlayer? opponent) {
      if (opponent == null) return null;
      for (final action in actions) {
        if (action.type == GameActionType.stealOpponent &&
            action.targetPlayerId == opponent.id) {
          return action;
        }
      }
      return null;
    }

    final topStealAction = stealActionFor(topOpponent);
    final leftStealAction = stealActionFor(leftOpponent);
    final rightStealAction = stealActionFor(rightOpponent);
    Offset? stealSourceFor(String targetPlayerId) {
      if (topOpponent?.id == targetPlayerId) {
        return Offset(
          isFourPlayerMatch ? 430 : 515,
          isFourPlayerMatch ? 72 : 70,
        );
      }
      if (leftOpponent?.id == targetPlayerId) {
        return const Offset(145, 275);
      }
      if (rightOpponent?.id == targetPlayerId) {
        return const Offset(680, 185);
      }
      return null;
    }

    GameAction? actionOfType(GameActionType type) {
      for (final action in actions) {
        if (action.type == type) return action;
      }
      return null;
    }

    final captureTableAction = actionOfType(GameActionType.captureTable);
    final extendOwnStackAction = actionOfType(GameActionType.extendStack);
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
            // The supplied frames use two distinct top lanes: centered in a
            // three-seat game and left-of-centre when the right seat is used.
            left: isFourPlayerMatch
                ? 158
                : isTwoPlayerMatch
                    ? 287
                    : 295,
            top: isFourPlayerMatch
                ? 5
                : isTwoPlayerMatch
                    ? 0
                    : 8,
            child: Transform.scale(
              scale: isTwoPlayerMatch ? reducedPlayerScale : 1,
              alignment: Alignment.topCenter,
              child: _Seat(
                player: topOpponent,
                identity: topIdentity,
                place: 0,
                isActive: game.currentPlayerId == topOpponent.id,
                game: game,
                timerRevision: session.turnTimerRevision,
                showHand: openingDealPhase >= 1,
                dealingCardCount: dealingCountFor(topOpponent.id),
                identityScale: isFourPlayerMatch ? 1.08 : 1,
                identityLeft: 70,
                handLeft: isFourPlayerMatch ? 225 : 180,
                handTop: isFourPlayerMatch ? 33 : 37,
              ),
            )),
      if (topOpponent?.topCard != null)
        Positioned(
            // Travel with the shifted profile, leaving the hidden hand in its
            // approved position and using the space opened on the left.
            left: isFourPlayerMatch ? 332 : 315,
            top: isFourPlayerMatch ? 44 : 49,
            child: _CapturePile(
              card: topOpponent!.topCard!,
              count: topOpponent.stackCount,
              stealAction: topStealAction,
              onSteal: onAction,
            )),
      if (leftOpponent != null)
        Positioned(
            left: 67,
            top: 164,
            child: Transform.scale(
              scale: 1,
              alignment: Alignment.topLeft,
              child: _Seat(
                player: leftOpponent,
                identity: leftIdentity,
                place: 1,
                isActive: game.currentPlayerId == leftOpponent.id,
                game: game,
                timerRevision: session.turnTimerRevision,
                showHand: openingDealPhase >= 1,
                dealingCardCount: dealingCountFor(leftOpponent.id),
                handLeft: 30,
                handTop: 92,
              ),
            )),
      if (leftOpponent?.topCard != null)
        Positioned(
            left: 174,
            top: 204,
            child: _CapturePile(
              card: leftOpponent!.topCard!,
              count: leftOpponent.stackCount,
              stealAction: leftStealAction,
              onSteal: onAction,
            )),
      if (rightOpponent != null)
        Positioned(
            right: 108,
            top: 49,
            child: Transform.scale(
              scale: 1,
              alignment: Alignment.topRight,
              child: _Seat(
                player: rightOpponent,
                identity: rightIdentity,
                place: 2,
                isActive: game.currentPlayerId == rightOpponent.id,
                game: game,
                timerRevision: session.turnTimerRevision,
                showHand: openingDealPhase >= 1,
                dealingCardCount: dealingCountFor(rightOpponent.id),
                handLeft: 33,
                handTop: 105,
              ),
            )),
      if (rightOpponent?.topCard != null)
        Positioned(
            right: 69,
            top: 158,
            child: _CapturePile(
              card: rightOpponent!.topCard!,
              count: rightOpponent.stackCount,
              stealAction: rightStealAction,
              onSteal: onAction,
            )),
      if (openingDealPhase >= 1)
        Positioned(
            left: 220,
            right: 220,
            top: 137,
            height: 116,
            child: Transform.scale(
              scale: isTwoPlayerMatch ? 1.12 : 1,
              child: _TableCards(
                cards: game.table,
                deck: game.deckCount,
                captureAction: captureTableAction,
                onCapture: onAction,
                onOpeningComplete: openingDealPhase == 1 ? onTableDealt : null,
              ),
            )),
      if (openingDealPhase >= 2)
        Positioned(
            left: 492,
            top: 105,
            child: _TurnLabel(isLocalTurn: session.isCurrentPlayersTurn)),
      Positioned(
          // Keep the radial hand in its own lane to the right of the local
          // medallion. The shared fan pivot must never sit behind the avatar.
          left: 368,
          right: 77,
          bottom: 12,
          height: 133,
          child: Transform.scale(
            scale: isTwoPlayerMatch
                ? 1.10
                : isThreePlayerMatch
                    ? 1.05
                    : 1,
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              opacity: openingDealPhase >= 1 ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: _Hand(
                  cards: visibleLocalCards,
                  selected: selected,
                  enabled: openingDealPhase >= 2 &&
                      session.isCurrentPlayersTurn &&
                      !submitting,
                  onTap: onCard),
            ),
          )),
      if (player?.topCard != null)
        Positioned(
            left: 294,
            bottom: 10,
            child: _CapturePile(
              card: player!.topCard!,
              count: player!.stackCount,
              primaryAction: extendOwnStackAction,
              onPrimaryAction: onAction,
              onView: () => onViewCapturedCards(player!),
            )),
      Positioned(
          left: 346,
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
      if (openingDealPhase >= 2 &&
          selected != null &&
          (actions.isNotEmpty || submitting))
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
      if (stealAnimation case final animation?)
        BikeDaketiOverlay(
          key: ValueKey(animation.id),
          source: stealSourceFor(animation.targetPlayerId) ??
              const Offset(700, 185),
          destination: const Offset(400, 330),
          cardCount: animation.cardCount,
          cards: animation.cards,
          onComplete: onStealAnimationComplete,
        ),
      if (drawAnimation case final animation?)
        _DeckDrawOverlay(
          key: ValueKey('draw-${animation.id}'),
          source: Offset(
            isTwoPlayerMatch
                ? 613
                : isThreePlayerMatch
                    ? 603
                    : 593,
            176,
          ),
          deals: animation.deals,
          onComplete: onDrawAnimationComplete,
        ),
      if (openingDealPhase == 0)
        OpeningDealOverlay(
          playerCount: game.players.length,
          cardsPerPlayer: player == null
              ? 4
              : math.max(player!.handCount, player!.hand.length).clamp(1, 5),
          onComplete: onHandsDealt,
        ),
    ]);
  }
}

class _DeckDrawOverlay extends StatefulWidget {
  const _DeckDrawOverlay({
    super.key,
    required this.source,
    required this.deals,
    required this.onComplete,
  });

  final Offset source;
  final List<_DrawDeal> deals;
  final VoidCallback onComplete;

  @override
  State<_DeckDrawOverlay> createState() => _DeckDrawOverlayState();
}

class _DeckDrawOverlayState extends State<_DeckDrawOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  int lastSoundIndex = -1;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 180 + widget.deals.length * 470),
    )
      ..addListener(_playDealSound)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      })
      ..forward();
  }

  void _playDealSound() {
    final index = (controller.value * widget.deals.length)
        .floor()
        .clamp(0, widget.deals.length - 1);
    if (index == lastSoundIndex) return;
    lastSoundIndex = index;
    GameSoundService.cardSelected();
  }

  @override
  void dispose() {
    controller
      ..removeListener(_playDealSound)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: AbsorbPointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final scaled = controller.value * widget.deals.length;
              final index = scaled.floor().clamp(0, widget.deals.length - 1);
              final progress = (scaled - index).clamp(0.0, 1.0);
              final travel = Curves.easeInOutCubic.transform(
                (progress / .72).clamp(0.0, 1.0),
              );
              final flip = Curves.easeInOut.transform(
                ((progress - .68) / .30).clamp(0.0, 1.0),
              );
              final deal = widget.deals[index];
              final position =
                  Offset.lerp(widget.source, deal.destination, travel)! +
                      Offset(0, -math.sin(travel * math.pi) * 38);
              final scaleX = math.cos(flip * math.pi).abs().clamp(.06, 1.0);
              final showFace = !deal.card.isHidden && flip >= .5;
              return Stack(
                children: [
                  for (var settledIndex = 0;
                      settledIndex < index;
                      settledIndex++)
                    Positioned(
                      left: widget.deals[settledIndex].destination.dx -
                          24 +
                          widget.deals
                                  .take(settledIndex)
                                  .where((item) =>
                                      item.playerId ==
                                      widget.deals[settledIndex].playerId)
                                  .length *
                              7,
                      top: widget.deals[settledIndex].destination.dy - 34,
                      child: _Card(
                        widget.deals[settledIndex].card,
                        48,
                        69,
                      ),
                    ),
                  Positioned(
                    left: position.dx - 24,
                    top: position.dy - 34,
                    child: Transform.rotate(
                      angle: (1 - travel) * .14,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(scaleX, 1, 1),
                        child: _Card(
                          showFace
                              ? deal.card
                              : const GameCard(
                                  id: 'hidden', value: '', suit: ''),
                          48,
                          69,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
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
    required this.showHand,
    required this.dealingCardCount,
    this.identityScale = 1,
    this.identityLeft,
    this.handLeft,
    this.handTop,
  });
  final GamePlayer player;
  final _PlayerIdentity? identity;
  final int place;
  final bool isActive;
  final DaketiGame game;
  final int timerRevision;
  final bool showHand;
  final int dealingCardCount;
  final double identityScale;
  final double? identityLeft;
  final double? handLeft;
  final double? handTop;
  @override
  Widget build(BuildContext context) {
    final side = place != 0;
    return SizedBox(
        width: side ? 150 : 270,
        height: side ? 108 : 98,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
              left: place == 0
                  ? identityLeft ?? 82
                  : side && place == 1
                      ? 0
                      : null,
              right: side && place == 2 ? 0 : null,
              top: side ? 2 : 0,
              child: Transform.scale(
                scale: identityScale,
                alignment: Alignment.topLeft,
                child: _Medallion(
                  player: player,
                  displayName: identity?.name,
                  avatarAsset: identity?.avatarAsset,
                  isActive: isActive,
                  isLocal: false,
                  game: game,
                  timerRevision: timerRevision,
                ),
              )),
          Positioned(
              left: handLeft ??
                  (place == 1
                      ? 95
                      : place == 2
                          ? -45
                          : 160),
              top: handTop ?? (side ? 42 : 5),
              child: AnimatedOpacity(
                opacity: showHand ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: _Fan(
                  (player.handCount - dealingCardCount).clamp(0, 5),
                ),
              )),
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
    final playerChanged =
        oldWidget.game.currentPlayerId != widget.game.currentPlayerId;
    final serverStartChanged =
        oldWidget.game.turnStartTime != widget.game.turnStartTime;
    final moveAccepted = oldWidget.timerRevision != widget.timerRevision;
    if (playerChanged || serverStartChanged || moveAccepted) {
      fallbackStart = DateTime.now().millisecondsSinceEpoch;
      // Captures, steals and stack extensions can keep the same player active.
      // A successful-move revision must therefore restart that player's timer
      // locally even when the response also contains a changed/stale server
      // timestamp. A real hand-off still follows the next player's server time.
      useFallbackStart = moveAccepted && !playerChanged;
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
              // Leave the complete turn-timer ring visible above the compact
              // identity panel.
              top: 60,
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
    const overlapStep = 9.0;
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
              final centerLift =
                  ((center - distance.abs()) * 5).clamp(0.0, 6.0);
              return Positioned(
                  left: start + i * overlapStep,
                  bottom: centerLift,
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

class _TableCards extends StatefulWidget {
  const _TableCards({
    required this.cards,
    required this.deck,
    this.captureAction,
    this.onCapture,
    this.onOpeningComplete,
  });
  final List<GameCard> cards;
  final int deck;
  final GameAction? captureAction;
  final ValueChanged<GameAction>? onCapture;
  final VoidCallback? onOpeningComplete;

  @override
  State<_TableCards> createState() => _TableCardsState();
}

class _TableCardsState extends State<_TableCards> {
  Timer? openingDealTimer;
  bool openingDeal = true;

  @override
  void initState() {
    super.initState();
    _startOpeningDeal();
  }

  void _startOpeningDeal() {
    openingDealTimer?.cancel();
    openingDeal = true;
    final duration = 520 + widget.cards.length * 145;
    openingDealTimer = Timer(Duration(milliseconds: duration), () {
      if (!mounted) return;
      setState(() => openingDeal = false);
      widget.onOpeningComplete?.call();
    });
  }

  @override
  void dispose() {
    openingDealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 72,
            top: 2,
            bottom: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const cardsPerRow = 5;
                const cardWidth = 47.0;
                const cardHeight = 67.0;
                const horizontalStep = 54.0;
                final rowCount = (widget.cards.length / cardsPerRow).ceil();
                final verticalStep = rowCount <= 1
                    ? 0.0
                    : ((constraints.maxHeight - cardHeight) / (rowCount - 1))
                        .clamp(14.0, 28.0);
                final firstRowCount = widget.cards.length.clamp(0, cardsPerRow);
                final firstRowWidth = firstRowCount == 0
                    ? 0.0
                    : cardWidth + (firstRowCount - 1) * horizontalStep;
                final baseLeft = (constraints.maxWidth - firstRowWidth) / 2;
                final paintOrder = List<int>.generate(
                    widget.cards.length, (i) => i)
                  ..sort((a, b) {
                    final rowA = a ~/ cardsPerRow;
                    final rowB = b ~/ cardsPerRow;
                    final rowComparison = rowA.compareTo(rowB);
                    return rowComparison != 0 ? rowComparison : a.compareTo(b);
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
                    final card = widget.cards[index];
                    return Positioned(
                      key: ValueKey('table-${card.id}'),
                      left: baseLeft + column * horizontalStep + stagger,
                      top: row * verticalStep,
                      child: Semantics(
                        button: widget.captureAction != null,
                        label: widget.captureAction == null
                            ? null
                            : 'Take matching table cards',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.captureAction != null &&
                                  widget.onCapture != null
                              ? () => widget.onCapture!(widget.captureAction!)
                              : null,
                          child: _OpeningTableCard(
                            card: card,
                            index: index,
                            travelX: 220 - column * horizontalStep,
                            animate: openingDeal,
                            width: cardWidth,
                            height: cardHeight,
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                );
              },
            ),
          ),
          if (widget.deck > 0)
            Positioned(
              // Preserve the clear lane between the draw pile and the right
              // opponent's hidden hand shown in the approved frame.
              right: 21,
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
                  child: Text('${widget.deck}',
                      style: const TextStyle(fontSize: 7)),
                ),
              ]),
            ),
        ],
      );
}

class _OpeningTableCard extends StatefulWidget {
  const _OpeningTableCard({
    required this.card,
    required this.index,
    required this.travelX,
    required this.animate,
    required this.width,
    required this.height,
  });

  final GameCard card;
  final int index;
  final double travelX;
  final bool animate;
  final double width;
  final double height;

  @override
  State<_OpeningTableCard> createState() => _OpeningTableCardState();
}

class _OpeningTableCardState extends State<_OpeningTableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animate ? 500 : 230),
    );
    if (widget.animate) {
      Future<void>.delayed(
        Duration(milliseconds: 70 + widget.index * 145),
        () {
          if (mounted) controller.forward();
        },
      );
    } else {
      controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _OpeningTableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate && !widget.animate && !controller.isCompleted) {
      controller.value = 1;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          if (!widget.animate) {
            final arrival = Curves.easeOutBack.transform(controller.value);
            return Opacity(
              opacity: controller.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: .84 + .16 * arrival,
                alignment: Alignment.center,
                child: _Card(widget.card, widget.width, widget.height),
              ),
            );
          }
          final progress = Curves.easeOutCubic.transform(controller.value);
          final flipProgress = Curves.easeInOut.transform(
            ((controller.value - .18) / .82).clamp(0.0, 1.0),
          );
          final scaleX = math.cos(flipProgress * math.pi).abs().clamp(.06, 1.0);
          final faceUp = flipProgress >= .5;
          return Opacity(
            opacity: controller.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(
                widget.travelX * (1 - progress),
                -12 * (1 - progress),
              ),
              child: Transform.rotate(
                angle: (1 - progress) * .10,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(scaleX, 1, 1),
                  child: _Card(
                    faceUp
                        ? widget.card
                        : const GameCard(id: 'hidden', value: '', suit: ''),
                    widget.width,
                    widget.height,
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _CapturePile extends StatelessWidget {
  const _CapturePile({
    required this.card,
    required this.count,
    this.stealAction,
    this.onSteal,
    this.primaryAction,
    this.onPrimaryAction,
    this.onView,
  });

  final GameCard card;
  final int count;
  final GameAction? stealAction;
  final ValueChanged<GameAction>? onSteal;
  final GameAction? primaryAction;
  final ValueChanged<GameAction>? onPrimaryAction;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) => Transform.scale(
        // Captured piles use the compact orange-box footprint from the
        // approved frames, while table and hand cards retain their full size.
        scale: .84,
        alignment: Alignment.topLeft,
        child: Semantics(
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
              child: GestureDetector(
                onTap: stealAction != null && onSteal != null
                    ? () => onSteal!(stealAction!)
                    : primaryAction != null && onPrimaryAction != null
                        ? () => onPrimaryAction!(primaryAction!)
                        : onView,
                child: SizedBox(
                  width: 57,
                  height: 82,
                  child: Stack(clipBehavior: Clip.none, children: [
                    if (count > 2)
                      Positioned(
                          left: 5,
                          top: 5,
                          child: Opacity(
                              opacity: .75, child: _Card(card, 47, 67))),
                    if (count > 1)
                      Positioned(
                          left: 2,
                          top: 2,
                          child: Opacity(
                              opacity: .88, child: _Card(card, 47, 67))),
                    Positioned(left: 0, top: 0, child: _Card(card, 47, 67)),
                    Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xED11130F),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: _gold)),
                            child: Text('$count',
                                style: const TextStyle(
                                    color: _cream,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900)))),
                  ]),
                ),
              ),
            )),
      );
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
      width: 154,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Dirty Brush',
                            fontSize: 12,
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
