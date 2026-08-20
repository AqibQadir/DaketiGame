import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/game_button.dart';
import '../../domain/models/daketi_game.dart';
import '../../domain/models/game_action.dart';
import '../../domain/models/game_card.dart';
import '../../domain/models/game_player.dart';
import '../controllers/game_controller.dart';

// Gameplay palette sampled from the approved table reference.
const _gold = Color(0xFFC58B43);
const _darkGold = Color(0xFF533718);
const _cream = Color(0xFFE4C58D);
const _panelBlack = Color(0xFF11130F);
const _panelGreen = Color(0xFF1B291E);
const _feltEdge = Color(0xFF3E2A16);

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? selectedCardId;
  bool isSubmitting = false;

  Future<void> selectCard(GameCard card) async {
    final state = ref.read(gameControllerProvider);
    if (!state.isCurrentPlayersTurn || isSubmitting) return;
    HapticFeedback.selectionClick();
    setState(() => selectedCardId = card.id);
    await ref.read(gameControllerProvider.notifier).loadAvailableActions();
    if (mounted && ref.read(gameControllerProvider).error != null) {
      _message(ref.read(gameControllerProvider).error!);
    }
  }

  Future<void> perform(GameAction action) async {
    setState(() => isSubmitting = true);
    HapticFeedback.mediumImpact();
    final ok =
        await ref.read(gameControllerProvider.notifier).performAction(action);
    if (!mounted) return;
    setState(() {
      isSubmitting = false;
      selectedCardId = null;
    });
    if (!ok) {
      _message(
          ref.read(gameControllerProvider).error ?? 'The move was rejected.');
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
    });
    final session = ref.watch(gameControllerProvider);
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
          SafeArea(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
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
                          onCard: selectCard,
                          onAction: perform,
                          onExit: leaveMatch,
                        ),
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
      required this.onCard,
      required this.onAction,
      required this.onExit});
  final GameSessionState session;
  final DaketiGame game;
  final GamePlayer? player;
  final String? selected;
  final List<GameAction> actions;
  final bool submitting;
  final ValueChanged<GameCard> onCard;
  final ValueChanged<GameAction> onAction;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final opponents =
        game.players.where((p) => p.id != session.playerId).toList();
    return Stack(children: [
      const Positioned.fill(
          child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: RadialGradient(
                      radius: 1.05,
                      colors: [Colors.transparent, Color(0xB0000000)],
                      stops: [.42, 1])))),
      Positioned(
          left: 13,
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
      if (opponents.isNotEmpty)
        Positioned(
            left: 287, top: 4, child: _Seat(player: opponents[0], place: 0)),
      if (opponents.isNotEmpty && opponents[0].topCard != null)
        Positioned(
            left: 226,
            top: 92,
            child: _CapturePile(
                card: opponents[0].topCard!, count: opponents[0].stackCount)),
      if (opponents.length > 1)
        Positioned(
            left: 37, top: 151, child: _Seat(player: opponents[1], place: 1)),
      if (opponents.length > 1 && opponents[1].topCard != null)
        Positioned(
            left: 116,
            top: 251,
            child: _CapturePile(
                card: opponents[1].topCard!, count: opponents[1].stackCount)),
      if (opponents.length > 2)
        Positioned(
            right: 37, top: 151, child: _Seat(player: opponents[2], place: 2)),
      if (opponents.length > 2 && opponents[2].topCard != null)
        Positioned(
            right: 116,
            top: 251,
            child: _CapturePile(
                card: opponents[2].topCard!, count: opponents[2].stackCount)),
      Positioned(
          left: 220,
          right: 220,
          top: 151,
          height: 78,
          child: _TableCards(cards: game.table, deck: game.deckCount)),
      Positioned(
          left: 355, top: 100, child: _Turn(session: session, game: game)),
      if (game.protectedValues.isNotEmpty)
        Positioned(
            left: 349, top: 130, child: _Protected(game.protectedValues)),
      Positioned(
          left: 225,
          right: 225,
          bottom: 3,
          height: 133,
          child: _Hand(
              cards: player?.hand ?? const [],
              selected: selected,
              enabled: session.isCurrentPlayersTurn && !submitting,
              onTap: onCard)),
      if (player?.topCard != null)
        Positioned(
            left: 178,
            bottom: 25,
            child: _CapturePile(
                card: player!.topCard!, count: player!.stackCount)),
      Positioned(
          left: 225,
          bottom: 11,
          child: _Badge(
              name: player?.name ?? session.playerName ?? 'YOU',
              score: player?.score ?? 0)),
      Positioned(
          left: 13,
          bottom: 55,
          child: GameButton(text: 'Leave match', width: 145, onTap: onExit)),
      const Positioned(left: 13, bottom: 12, child: _Chat()),
      if (selected != null)
        Positioned(
            right: 13,
            bottom: 12,
            child: _Actions(
                actions: actions, loading: submitting, onTap: onAction)),
      if (session.activity != null)
        Positioned(
            left: 320,
            right: 320,
            top: 128,
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
  const _Seat({required this.player, required this.place});
  final GamePlayer player;
  final int place;
  @override
  Widget build(BuildContext context) {
    final side = place != 0;
    return SizedBox(
        width: side ? 150 : 270,
        height: side ? 108 : 98,
        child: Stack(children: [
          Positioned(
              left: place == 0
                  ? 82
                  : side && place == 1
                      ? 0
                      : null,
              right: side && place == 2 ? 0 : null,
              top: side ? 2 : 0,
              child: _Medallion(player)),
          Positioned(
              left: place == 1
                  ? 60
                  : place == 2
                      ? 0
                      : 160,
              top: side ? 42 : 5,
              child: _Fan(player.handCount.clamp(0, 5))),
        ]));
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion(this.player);
  final GamePlayer player;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 96,
      height: 96,
      child: Stack(alignment: Alignment.topCenter, children: [
        Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                    colors: [Color(0xFF4D4329), _panelBlack]),
                border: Border.all(color: _gold, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 7)
                ]),
            child: ClipOval(
                child: Image.asset(
              AppAssets.playerAvatar,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ))),
        Positioned(
            top: 48,
            child: SizedBox(
                width: 94,
                child: _Badge(name: player.name, score: player.score))),
      ]));
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
            Text('$score  ●',
                style: const TextStyle(fontSize: 8, color: _cream))
          ])));
}

class _Fan extends StatelessWidget {
  const _Fan(this.count);
  final int count;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 100,
      height: 62,
      child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(count, (i) {
            final d = i - (count - 1) / 2;
            return Positioned(
                left: 32 + d * 12,
                top: d.abs() * 2,
                child: Transform.rotate(
                    angle: d * .12,
                    alignment: Alignment.bottomCenter,
                    child: const _Card(
                        GameCard(id: 'hidden', value: '', suit: ''), 35, 51)));
          })));
}

class _TableCards extends StatelessWidget {
  const _TableCards({required this.cards, required this.deck});
  final List<GameCard> cards;
  final int deck;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Flexible(
            child: Wrap(
                spacing: 7,
                alignment: WrapAlignment.center,
                children: cards.take(5).map((c) => _Card(c, 43, 61)).toList())),
        if (deck > 0) ...[
          const SizedBox(width: 14),
          Stack(children: [
            const Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child:
                    _Card(GameCard(id: 'hidden', value: '', suit: ''), 43, 61)),
            const _Card(GameCard(id: 'hidden', value: '', suit: ''), 43, 61),
            Positioned(
                right: 3,
                bottom: 2,
                child: Text('$deck', style: const TextStyle(fontSize: 7)))
          ])
        ]
      ]);
}

class _CapturePile extends StatelessWidget {
  const _CapturePile({required this.card, required this.count});

  final GameCard card;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
      label:
          'Captured stack, $count cards, top card ${card.value} of ${card.suit}',
      child: SizedBox(
          width: 52,
          height: 75,
          child: Stack(clipBehavior: Clip.none, children: [
            if (count > 2)
              Positioned(
                  left: 5,
                  top: 5,
                  child: Opacity(opacity: .75, child: _Card(card, 43, 61))),
            if (count > 1)
              Positioned(
                  left: 2,
                  top: 2,
                  child: Opacity(opacity: .88, child: _Card(card, 43, 61))),
            Positioned(left: 0, top: 0, child: _Card(card, 43, 61)),
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
          ])));
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
  @override
  Widget build(BuildContext context) {
    final center = (cards.length - 1) / 2;
    return Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: List.generate(cards.length, (i) {
          final d = i - center;
          final active = cards[i].id == selected;
          return Positioned(
              left: 108 + d * 38,
              bottom: 1 + (center - d.abs()) * 2 + (active ? 13 : 0),
              child: Transform.rotate(
                  angle: d * .055,
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                      onTap: enabled ? () => onTap(cards[i]) : null,
                      child: _Card(cards[i], 61, 91, selected: active))));
        }));
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
    final displayWidth = card.isHidden ? width : width * 1.10;
    final displayHeight = card.isHidden ? height : height * 1.10;
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

class _Chat extends StatelessWidget {
  const _Chat();
  @override
  Widget build(BuildContext context) => const SizedBox(
      width: 154,
      height: 36,
      child: _Panel(
          padding: EdgeInsets.symmetric(horizontal: 9),
          child: Row(children: [
            Icon(Icons.chat_bubble, size: 16, color: _cream),
            SizedBox(width: 8),
            Expanded(
                child: Text('Type a message…',
                    style: TextStyle(fontSize: 8, color: Colors.white60))),
            Icon(Icons.send, size: 15, color: Color(0xFF6ACA73))
          ])));
}

class _Actions extends StatelessWidget {
  const _Actions(
      {required this.actions, required this.loading, required this.onTap});
  final List<GameAction> actions;
  final bool loading;
  final ValueChanged<GameAction> onTap;
  String label(GameAction a) => switch (a.type) {
        GameActionType.captureTable => 'CAPTURE',
        GameActionType.stealOpponent => 'STEAL',
        GameActionType.extendStack => 'EXTEND',
        GameActionType.discard => 'DISCARD',
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
    return Wrap(
        spacing: 4,
        children: actions
            .map((a) => FilledButton(
                onPressed: () => onTap(a),
                style: FilledButton.styleFrom(
                    backgroundColor: _feltEdge,
                    foregroundColor: _cream,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    side: const BorderSide(color: _gold)),
                child: Text(label(a),
                    style: const TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w900))))
            .toList());
  }
}

class _Turn extends StatelessWidget {
  const _Turn({required this.session, required this.game});
  final GameSessionState session;
  final DaketiGame game;
  @override
  Widget build(BuildContext context) {
    final raw = game.turnStartTime;
    final millis = raw == null
        ? DateTime.now().millisecondsSinceEpoch
        : raw < 100000000000
            ? raw * 1000
            : raw;
    final initial = (game.turnTimeLimit -
            (DateTime.now().millisecondsSinceEpoch - millis) ~/ 1000)
        .clamp(0, game.turnTimeLimit)
        .toDouble();
    return Column(children: [
      Text(session.isCurrentPlayersTurn ? 'YOUR TURN' : 'OPPONENT TURN',
          style: const TextStyle(
              fontSize: 8, fontWeight: FontWeight.w900, color: _cream)),
      TweenAnimationBuilder<double>(
          key: ValueKey('${game.currentPlayerId}-${game.turnStartTime}'),
          tween: Tween(begin: initial, end: 0),
          duration: Duration(seconds: initial.ceil()),
          builder: (_, value, __) => Row(children: [
                Icon(Icons.timer_outlined,
                    size: 10,
                    color: value <= 8 ? Colors.redAccent : Colors.white70),
                Text(' ${value.ceil()}s',
                    style: TextStyle(
                        fontSize: 8,
                        color: value <= 8 ? Colors.redAccent : Colors.white70))
              ]))
    ]);
  }
}

class _Protected extends StatelessWidget {
  const _Protected(this.values);
  final List<String> values;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xE011130F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _darkGold)),
      child: Text('🔒 ${values.join(' · ')}',
          style: const TextStyle(fontSize: 7, color: _cream)));
}

class _Activity extends StatelessWidget {
  const _Activity(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xDD000000),
          borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 7)));
}
