import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../controllers/game_controller.dart';

class GameResultsScreen extends ConsumerWidget {
  const GameResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
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
        final aIsWinner = a['id']?.toString() == session.winner;
        final bIsWinner = b['id']?.toString() == session.winner;
        if (aIsWinner != bIsWinner) return aIsWinner ? -1 : 1;
        final aScore = (a['score'] as num?)?.toInt() ?? 0;
        final bScore = (b['score'] as num?)?.toInt() ?? 0;
        final scoreOrder = bScore.compareTo(aScore);
        if (scoreOrder != 0) return scoreOrder;
        return (a['name']?.toString() ?? '')
            .compareTo(b['name']?.toString() ?? '');
      });
    return Scaffold(
      body: GameBackground(
        child: Center(
          child: GlassPanel(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  winnerText,
                  style: const TextStyle(
                    fontFamily: 'Dirty Brush',
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 16),
                ...scores.indexed.map(
                  (rankedScore) {
                    final rank = rankedScore.$1 + 1;
                    final score = rankedScore.$2;
                    final isWinner = score['id']?.toString() == session.winner;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isWinner
                            ? const Color(0xFFFF8A00)
                            : const Color(0xFF30271F),
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      title: Text(score['name']?.toString() ?? 'Player'),
                      subtitle: isWinner
                          ? const Text(
                              'WINNER',
                              style: TextStyle(
                                color: Color(0xFFFFB34D),
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                      trailing: Text(
                        '${score['score'] ?? 0} PTS',
                        style: TextStyle(
                          color: isWinner ? const Color(0xFFFFB34D) : null,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GameButton(
                      text: 'Replay',
                      onTap: () async {
                        final success = await ref
                            .read(gameControllerProvider.notifier)
                            .replaySolo();
                        if (success && context.mounted) {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.game);
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
