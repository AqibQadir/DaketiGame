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
    final scores = session.scores.isNotEmpty
        ? session.scores
        : (session.game?.players
                .map((player) => {
                      'id': player.id,
                      'name': player.name,
                      'score': player.score,
                    })
                .toList() ??
            const <Map<String, dynamic>>[]);
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
                ...scores.map(
                  (score) => ListTile(
                    dense: true,
                    title: Text(score['name']?.toString() ?? 'Player'),
                    trailing: Text(
                      '${score['score'] ?? 0} PTS',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
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
