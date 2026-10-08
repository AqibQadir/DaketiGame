import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/game_sound_service.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../controllers/game_controller.dart';

const _pakistaniBotNames = <String>[
  'Hamza Malik',
  'Ayesha Khan',
  'Bilal Ahmed',
  'Mahnoor Fatima',
  'Saad Qureshi',
];

int _stableIdentitySeed(String value) {
  var hash = 17;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 37 + codeUnit) & 0x7fffffff;
  }
  return hash;
}

class GameResultsScreen extends ConsumerStatefulWidget {
  const GameResultsScreen({super.key});

  @override
  ConsumerState<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends ConsumerState<GameResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = ref.read(gameControllerProvider);
      if (session.winner == session.playerId) {
        GameSoundService.roundWon();
      } else if (session.winner != 'draw') {
        GameSoundService.gameLost();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameControllerProvider);
    final game = session.game;
    final aiDisplayNames = <String, String>{};
    if (game != null) {
      final seed = _stableIdentitySeed(session.gameId ?? game.gameId);
      final step = 1 + (seed ~/ _pakistaniBotNames.length) % 4;
      final opponents = game.players
          .where((player) => player.id != session.playerId)
          .toList();
      for (final indexedPlayer in opponents.indexed) {
        final player = indexedPlayer.$2;
        if (!player.isAi) continue;
        final rosterIndex =
            (seed + indexedPlayer.$1 * step) % _pakistaniBotNames.length;
        aiDisplayNames[player.id] = _pakistaniBotNames[rosterIndex];
      }
    }
    final winnerText = session.winner == 'draw'
        ? 'DRAW'
        : session.winner == session.playerId
            ? 'YOU WIN'
            : 'GAME OVER';
    final rawScores = session.scores.isNotEmpty
        ? session.scores
        : (session.game?.players
                .map((player) => {
                      'id': player.id,
                      'name': player.name,
                      'score': player.score,
                    })
                .toList() ??
            const <Map<String, dynamic>>[]);
    final scores = List<Map<String, dynamic>>.of(rawScores)
      ..sort((a, b) {
        final aScore = (a['score'] as num?)?.toInt() ?? 0;
        final bScore = (b['score'] as num?)?.toInt() ?? 0;
        final scoreOrder = bScore.compareTo(aScore);
        if (scoreOrder != 0) return scoreOrder;
        return (a['name']?.toString() ?? '')
            .compareTo(b['name']?.toString() ?? '');
      });
    final topScore = scores.isEmpty ? null : scores.first['score'] as num?;
    final tiedAtTop = topScore != null &&
        scores.where((score) => score['score'] == topScore).length > 1;
    final sharedFirst = session.winner == 'draw' && tiedAtTop;
    return Scaffold(
      body: GameBackground(
        overlayOpacity: 0.18,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 760,
                  height: 350,
                  child: Stack(
                    children: [
                      const Positioned(
                          left: 102,
                          top: 115,
                          child: _ResultCard(
                              asset:
                                  'assets/images/cards/style01/Spades/KIng.png',
                              angle: -0.17)),
                      const Positioned(
                          right: 100,
                          top: 108,
                          child: _ResultCard(
                              asset:
                                  'assets/images/cards/style01/Spades/Queen.png',
                              angle: 0.15)),
                      Positioned(
                        left: 158,
                        right: 158,
                        top: 18,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(32, 10, 32, 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xF5232219),
                                Color(0xFA080905),
                                Color(0xF51D190C)
                              ],
                            ),
                            border: Border.all(
                                color: const Color(0xFF79705A), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black87,
                                  blurRadius: 22,
                                  offset: Offset(0, 10)),
                              BoxShadow(
                                  color: Color(0x337E7044),
                                  blurRadius: 5,
                                  spreadRadius: 1),
                            ],
                          ),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Semantics(
                              label: sharedFirst
                                  ? 'DRAW — JOINT FIRST'
                                  : winnerText,
                              child: ExcludeSemantics(
                                  child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                      text: sharedFirst
                                          ? 'DRAW'
                                          : winnerText == 'YOU WIN'
                                              ? 'YOU '
                                              : winnerText == 'DRAW'
                                                  ? 'DRAW'
                                                  : 'GAME ',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  if (!sharedFirst && winnerText != 'DRAW')
                                    TextSpan(
                                        text: winnerText == 'YOU WIN'
                                            ? 'WIN'
                                            : 'OVER',
                                        style: const TextStyle(
                                            color: Color(0xFFFFAC12))),
                                ]),
                                style: const TextStyle(
                                    fontFamily: 'Dirty Brush',
                                    fontSize: 43,
                                    height: 1.15),
                              )),
                            ),
                            if (sharedFirst)
                              const Text('JOINT FIRST',
                                  style: TextStyle(
                                      color: Color(0xFFFFCF74),
                                      fontSize: 10,
                                      letterSpacing: 2)),
                            const SizedBox(height: 10),
                            if (scores.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Waiting for final scores',
                                      style: TextStyle(color: Colors.white70))),
                            ...scores.indexed.map((entry) {
                              final score = entry.$2;
                              final points =
                                  (score['score'] as num?)?.toInt() ?? 0;
                              final rank = 1 +
                                  scores
                                      .where((other) =>
                                          ((other['score'] as num?)?.toInt() ??
                                              0) >
                                          points)
                                      .length;
                              final id = score['id']?.toString();
                              final winner = id == session.winner ||
                                  (sharedFirst && rank == 1);
                              return _ResultRow(
                                name: aiDisplayNames[id] ??
                                    score['name']?.toString() ??
                                    'Player',
                                points: points,
                                rank: rank,
                                winner: winner,
                                local: id == session.playerId,
                                last: entry.$1 == scores.length - 1 && !winner,
                                compact: scores.length > 3,
                              );
                            }),
                          ]),
                        ),
                      ),
                      Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GameButton(
                                isLoading: session.isLoading,
                                text: session.isMultiplayer
                                    ? 'Play again'
                                    : 'Replay',
                                onTap: session.isLoading
                                    ? null
                                    : () async {
                                        if (session.isMultiplayer) {
                                          Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              AppRoutes.multiplayer,
                                              (route) =>
                                                  route.settings.name ==
                                                  AppRoutes.home,
                                              arguments: session.playerName);
                                          return;
                                        }
                                        final success = await ref
                                            .read(
                                                gameControllerProvider.notifier)
                                            .replaySolo();
                                        if (!context.mounted) return;
                                        if (!success) {
                                          showGameAlert(
                                              context,
                                              ref
                                                      .read(
                                                          gameControllerProvider)
                                                      .error ??
                                                  'Unable to start another game.');
                                          return;
                                        }
                                        if (success) {
                                          Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              AppRoutes.game,
                                              (route) =>
                                                  route.settings.name ==
                                                      AppRoutes.tables ||
                                                  route.settings.name ==
                                                      AppRoutes.home);
                                        }
                                      },
                              ),
                              const SizedBox(width: 16),
                              GameButton(
                                text: 'Home',
                                onTap: () {
                                  ref
                                      .read(gameControllerProvider.notifier)
                                      .resetSession();
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.home,
                                    (_) => false,
                                  );
                                },
                              ),
                            ],
                          )),
                      Positioned(
                          right: 18,
                          top: 14,
                          child: GameIconButton(
                              icon: Icons.menu,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.menu))),
                      Positioned(
                          left: 18,
                          bottom: 62,
                          child: GameIconButton(
                              icon: Icons.person,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.profile))),
                      Positioned(
                          left: 18,
                          bottom: 12,
                          child: GameIconButton(
                              icon: Icons.settings,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.settings))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.asset, required this.angle});
  final String asset;
  final double angle;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Transform.rotate(
            angle: angle,
            child: Container(
              width: 100,
              height: 145,
              decoration: const BoxDecoration(boxShadow: [
                BoxShadow(
                    color: Colors.black87, blurRadius: 16, offset: Offset(0, 8))
              ]),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(asset, fit: BoxFit.fill)),
            )),
      );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(
      {required this.name,
      required this.points,
      required this.rank,
      required this.winner,
      required this.local,
      required this.last,
      required this.compact});
  final String name;
  final int points, rank;
  final bool winner, local, last, compact;
  @override
  Widget build(BuildContext context) => Container(
        height: compact ? 36 : 46,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
              colors: winner
                  ? const [Color(0xFF49340E), Color(0xFFBA730D)]
                  : last
                      ? const [Color(0xFF370D0A), Color(0xFF230506)]
                      : const [Color(0xFF332C18), Color(0xFF211B0D)]),
          border: Border.all(
              color: winner ? const Color(0xFFEAA734) : const Color(0xFF655C43),
              width: winner ? 1.4 : 1),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 5, offset: Offset(0, 3))
          ],
        ),
        child: Row(children: [
          SizedBox(
              width: 38,
              child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xFFB7B5A1),
                        backgroundImage: AssetImage(AppAssets.playerAvatar)),
                    Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                            width: 13,
                            height: 13,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: winner
                                    ? const Color(0xFFE7A129)
                                    : const Color(0xFF5C4C32),
                                shape: BoxShape.circle),
                            child: Text('$rank',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold)))),
                    if (winner)
                      const Positioned(
                          top: -11,
                          child: CustomPaint(
                              size: Size(21, 14), painter: _CrownPainter())),
                  ])),
          const SizedBox(width: 9),
          Expanded(
              child: Text(name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'Dirty Brush',
                      color: Colors.white,
                      fontSize: 17))),
          if (local)
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7),
                child: Text('YOU',
                    style: TextStyle(
                        color: Color(0xFFFFD790),
                        fontSize: 8,
                        fontWeight: FontWeight.w900))),
          Text('$points PTS',
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  fontSize: 14)),
        ]),
      );
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(2, 12)
      ..lineTo(0, 3)
      ..lineTo(6, 6)
      ..lineTo(10.5, 0)
      ..lineTo(15, 6)
      ..lineTo(21, 3)
      ..lineTo(19, 12)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFC23C));
    canvas.drawLine(
        const Offset(3, 14),
        const Offset(18, 14),
        Paint()
          ..color = const Color(0xFFFFDA72)
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
