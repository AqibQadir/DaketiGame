import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../domain/models/game_action.dart';
import '../../domain/models/game_card.dart';
import '../../domain/models/daketi_game.dart';
import '../controllers/game_controller.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? selectedCardId;
  bool isSubmitting = false;

  List<GameAction> actionsFor(GameSessionState session) {
    return session.availableActions
        .where((action) => action.cardId == selectedCardId)
        .toList(growable: false);
  }

  Future<void> selectCard(GameCard card) async {
    final session = ref.read(gameControllerProvider);
    if (!session.isCurrentPlayersTurn || isSubmitting) return;
    HapticFeedback.selectionClick();
    setState(() => selectedCardId = card.id);
    await ref.read(gameControllerProvider.notifier).loadAvailableActions();
    if (!mounted) return;
    final updated = ref.read(gameControllerProvider);
    if (updated.error != null) _showMessage(updated.error!);
  }

  Future<void> perform(GameAction action) async {
    setState(() => isSubmitting = true);
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    final success =
        await ref.read(gameControllerProvider.notifier).performAction(action);
    if (!mounted) return;
    setState(() {
      isSubmitting = false;
      selectedCardId = null;
    });
    if (!success) {
      _showMessage(
        ref.read(gameControllerProvider).error ?? 'The move was rejected.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider, (previous, next) {
      if (previous?.winner == null && next.winner != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.results);
      }
      if (previous?.connectionStatus != next.connectionStatus &&
          next.connectionStatus == GameConnectionStatus.disconnected) {
        _showMessage('Connection lost. Reconnecting…');
      }
      if (previous?.disconnectedPlayer != next.disconnectedPlayer &&
          next.disconnectedPlayer != null) {
        _showMessage('${next.disconnectedPlayer} disconnected');
      }
    });
    final session = ref.watch(gameControllerProvider);
    final game = session.game;
    final player = game?.playerById(session.playerId);
    final selectedActions = actionsFor(session);

    if (selectedCardId != null &&
        !(player?.hand.any((card) => card.id == selectedCardId) ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => selectedCardId = null);
      });
    }

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 844,
                height: 390,
                child: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 16,
                      child: GameCloseButton(
                        size: 50,
                        onTap: Navigator.of(context).pop,
                      ),
                    ),
                    Positioned(
                      top: 17,
                      left: 82,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ROOM ${session.gameId ?? '----'}',
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            session.isCurrentPlayersTurn
                                ? 'YOUR TURN · TAP A CARD'
                                : 'WAITING FOR OPPONENT',
                            style: const TextStyle(fontSize: 10),
                          ),
                          if (game != null) _TurnTimer(game: game),
                        ],
                      ),
                    ),
                    if (game == null)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      Positioned(
                        top: 16,
                        left: 260,
                        right: 24,
                        height: 58,
                        child: Row(
                          children: game.players
                              .where((item) => item.id != session.playerId)
                              .map(
                                (opponent) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _PlayerChip(
                                      name: opponent.name,
                                      cards: opponent.handCount,
                                      score: opponent.score,
                                      topCard: opponent.topCard,
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                      Positioned(
                        left: 150,
                        right: 150,
                        top: 86,
                        height: 185,
                        child: _PokerTable(
                          deckCount: game.deckCount,
                          cards: game.table,
                        ),
                      ),
                      Positioned(
                        left: 225,
                        right: 225,
                        bottom: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${player?.name ?? session.playerName ?? 'PLAYER'} · '
                              'SCORE ${player?.score ?? 0}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: (player?.hand ?? const <GameCard>[])
                                  .map(
                                    (card) => _CardTile(
                                      card: card,
                                      selected: selectedCardId == card.id,
                                      enabled: session.isCurrentPlayersTurn &&
                                          !isSubmitting,
                                      onTap: () => selectCard(card),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                        ),
                      ),
                      if (selectedCardId != null)
                        Positioned(
                          left: 22,
                          bottom: 23,
                          width: 190,
                          child: isSubmitting
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : selectedActions.isEmpty
                                  ? const Text(
                                      'LOADING LEGAL MOVES…',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 10),
                                    )
                                  : Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 6,
                                      runSpacing: 5,
                                      children: selectedActions
                                          .map(
                                            (action) => _ActionButton(
                                              action: action,
                                              onTap: () => perform(action),
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                        ),
                      if (game.protectedValues.isNotEmpty)
                        Positioned(
                          right: 24,
                          top: 82,
                          child: _ProtectedValues(
                            values: game.protectedValues,
                          ),
                        ),
                      if (session.activity != null)
                        Positioned(
                          left: 260,
                          right: 260,
                          top: 76,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              key: ValueKey(session.activity),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xC9000000),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                session.activity!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnTimer extends StatelessWidget {
  const _TurnTimer({required this.game});

  final DaketiGame game;

  @override
  Widget build(BuildContext context) {
    final rawStart = game.turnStartTime;
    final startMillis = rawStart == null
        ? DateTime.now().millisecondsSinceEpoch
        : rawStart < 100000000000
            ? rawStart * 1000
            : rawStart;
    final elapsed = DateTime.now().millisecondsSinceEpoch - startMillis;
    final initial = (game.turnTimeLimit - elapsed ~/ 1000)
        .clamp(0, game.turnTimeLimit)
        .toDouble();
    return TweenAnimationBuilder<double>(
      key: ValueKey('${game.currentPlayerId}-${game.turnStartTime}'),
      tween: Tween(begin: initial, end: 0),
      duration: Duration(seconds: initial.ceil()),
      builder: (context, value, _) {
        final warning = value <= 8;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 12,
              color: warning ? Colors.redAccent : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              '${value.ceil()}s',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: warning ? Colors.redAccent : Colors.white70,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProtectedValues extends StatelessWidget {
  const _ProtectedValues({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xD9181411),
        border: Border.all(color: AppColors.tileBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 12, color: AppColors.orange),
          const SizedBox(width: 5),
          Text(
            'PROTECTED  ${values.join(' · ')}',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final GameAction action;
  final VoidCallback onTap;

  String get label => switch (action.type) {
        GameActionType.captureTable => 'CAPTURE',
        GameActionType.stealOpponent => 'STEAL',
        GameActionType.extendStack => 'EXTEND STACK',
        GameActionType.discard => 'DISCARD · END TURN',
        GameActionType.unknown => 'UNKNOWN',
      };

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.name,
    required this.cards,
    required this.score,
    required this.topCard,
  });

  final String name;
  final int cards;
  final int score;
  final GameCard? topCard;

  @override
  Widget build(BuildContext context) {
    final stack = topCard == null
        ? 'NO STACK'
        : 'TOP ${topCard!.value}${topCard!.suitSymbol}';
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xED37291F), Color(0xE8171210)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: AppColors.tileBorder),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            '$cards CARDS  ·  $score PTS  ·  $stack',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _PokerTable extends StatelessWidget {
  const _PokerTable({required this.deckCount, required this.cards});

  final int deckCount;
  final List<GameCard> cards;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(95),
        gradient: const LinearGradient(
          colors: [Color(0xFF9B5A27), Color(0xFF3B1D0D), Color(0xFFB16B31)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD99A59), width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xD9000000),
            blurRadius: 18,
            spreadRadius: 2,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(88),
          gradient: const RadialGradient(
            colors: [Color(0xFF315C43), Color(0xFF193626), Color(0xFF0B1B12)],
            radius: .95,
          ),
          border: Border.all(color: const Color(0xFFDFB276), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0xB3000000),
              blurRadius: 12,
              spreadRadius: 4,
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 15,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xB8000000),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0x8877B58A)),
                  ),
                  child: Text(
                    'TABLE  ·  DECK $deckCount',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 30,
              right: 30,
              top: 57,
              bottom: 20,
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 9,
                  runSpacing: 7,
                  children: cards
                      .map((card) => _CardTile(card: card))
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    this.selected = false,
    this.enabled = false,
    this.onTap,
  });

  final GameCard card;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = card.isRed ? const Color(0xFFE52B3E) : Colors.black;
    final displayValue = card.value == 'T' ? '10' : card.value;

    return AnimatedScale(
      scale: selected ? 1.13 : 1,
      duration: const Duration(milliseconds: 140),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 46,
          height: 62,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: card.isHidden
                ? const LinearGradient(
                    colors: [Color(0xFF4A2D1E), Color(0xFF20140F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF1EFEA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? Colors.cyanAccent : const Color(0xFF272727),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0xA6000000),
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
              if (selected)
                const BoxShadow(color: Colors.cyanAccent, blurRadius: 10),
            ],
          ),
          child: card.isHidden
              ? const _CardBack()
              : Stack(
                  children: [
                    Positioned(
                      left: 4,
                      top: 3,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayValue,
                            style: TextStyle(
                              color: cardColor,
                              fontFamily: 'Georgia',
                              fontSize: displayValue == '10' ? 12 : 15,
                              height: .85,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            card.suitSymbol,
                            style: TextStyle(
                              color: cardColor,
                              fontFamily: 'Georgia',
                              fontSize: 11,
                              height: .9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Text(
                          card.suitSymbol,
                          style: TextStyle(
                            color: cardColor,
                            fontFamily: 'Georgia',
                            fontSize: 28,
                            height: 1,
                            shadows: const [
                              Shadow(
                                color: Colors.black12,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFB64E17),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFFFFB35B)),
        ),
        child: const Center(
          child: Icon(
            Icons.diamond_outlined,
            color: Color(0xFFFFD28A),
            size: 22,
          ),
        ),
      ),
    );
  }
}
