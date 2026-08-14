import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../domain/models/daketi_game.dart';
import '../controllers/game_controller.dart';

class WaitingRoomScreen extends ConsumerWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(gameControllerProvider, (previous, next) {
      if (previous?.game?.status != DaketiGameStatus.playing &&
          next.game?.status == DaketiGameStatus.playing) {
        Navigator.pushReplacementNamed(context, AppRoutes.game);
      }
    });
    final session = ref.watch(gameControllerProvider);
    final game = session.game;
    return Scaffold(
      body: GameBackground(
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 18,
              child: GameCloseButton(onTap: Navigator.of(context).pop),
            ),
            Center(
              child: GlassPanel(
                width: 530,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'WAITING ROOM',
                      style: TextStyle(fontFamily: 'Dirty Brush', fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: session.gameId ?? ''),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room code copied')),
                        );
                      },
                      child: Text(
                        'ROOM ${session.gameId ?? '----'}  ·  TAP TO COPY',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final player in game?.players ?? const [])
                      Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tile,
                          border: Border.all(color: AppColors.tileBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(player.name)),
                            Text(
                              player.isReady ? 'READY' : 'NOT READY',
                              style: TextStyle(
                                color: player.isReady
                                    ? AppColors.green
                                    : AppColors.orange,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      '${game?.players.length ?? 0}/${game?.maxPlayers ?? 0} PLAYERS',
                    ),
                    const SizedBox(height: 14),
                    GameButton(
                      text: 'Ready',
                      width: 180,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref.read(gameControllerProvider.notifier).sendReady();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
