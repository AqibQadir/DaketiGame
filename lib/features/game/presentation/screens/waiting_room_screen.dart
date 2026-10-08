import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/game_sound_service.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../domain/models/daketi_game.dart';
import '../controllers/game_controller.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  bool _openingGame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openGameIfStarted(ref.read(gameControllerProvider));
    });
  }

  void _openGameIfStarted(GameSessionState session) {
    final status = session.game?.status;
    if (_openingGame ||
        !mounted ||
        (status != DaketiGameStatus.playing &&
            status != DaketiGameStatus.finished)) {
      return;
    }
    _openingGame = true;
    if (status == DaketiGameStatus.playing) GameSoundService.matchFound();
    Navigator.pushNamedAndRemoveUntil(
        context,
        status == DaketiGameStatus.finished
            ? AppRoutes.results
            : AppRoutes.game,
        (route) =>
            route.settings.name == AppRoutes.tables ||
            route.settings.name == AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider, (previous, next) {
      final previousCount = previous?.game?.players.length ?? 0;
      final nextCount = next.game?.players.length ?? 0;
      if (previous != null && nextCount > previousCount) {
        GameSoundService.playerJoined();
      }
      _openGameIfStarted(next);
    });
    final session = ref.watch(gameControllerProvider);
    final game = session.game;
    final currentPlayer = game?.playerById(session.playerId);
    final isReady = currentPlayer?.isReady ?? false;
    final playerCount = game?.players.length ?? 0;
    final capacity = game?.maxPlayers ?? 0;
    final isFull = capacity > 0 && playerCount == capacity;
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 20,
                top: 18,
                child: GameCloseButton(onTap: Navigator.of(context).pop),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(64, 12, 64, 12),
                  child: GlassPanel(
                    width: 530,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PRIVATE TEAM ROOM',
                          style: TextStyle(
                              fontFamily: 'Dirty Brush', fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SHARE THIS CODE WITH YOUR TEAM',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: session.gameId ?? ''),
                            );
                            showGameAlert(context, 'Room code copied');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xD9201914),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.orange),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  session.gameId ?? '----',
                                  style: const TextStyle(
                                    color: AppColors.orange,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 7,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.copy_rounded,
                                  color: AppColors.cream,
                                  size: 19,
                                ),
                              ],
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
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: AppColors.tileBorder,
                                  child: Text(
                                    player.name.isEmpty
                                        ? '?'
                                        : player.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    player.id == session.playerId
                                        ? '${player.name}  (YOU)'
                                        : player.name,
                                  ),
                                ),
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
                          '$playerCount/$capacity TEAM MEMBERS',
                          style: TextStyle(
                            color: isFull ? AppColors.green : AppColors.orange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFull
                              ? 'Everyone must tap Ready. The game starts automatically.'
                              : 'Waiting for ${capacity - playerCount} more teammate${capacity - playerCount == 1 ? '' : 's'}…',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GameButton(
                          isLoading: session.isLoading,
                          text: isReady ? 'Waiting…' : 'Ready',
                          width: 180,
                          backgroundTint:
                              isReady ? const Color(0xFFFFD54F) : null,
                          onTap: session.isLoading ||
                                  isReady ||
                                  game?.status != DaketiGameStatus.waiting ||
                                  currentPlayer == null ||
                                  session.connectionStatus !=
                                      GameConnectionStatus.connected
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  ref
                                      .read(gameControllerProvider.notifier)
                                      .sendReady();
                                },
                        ),
                        if (session.error != null) ...[
                          const SizedBox(height: 8),
                          Text(session.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.orange, fontSize: 12)),
                        ],
                        if (session.connectionStatus !=
                            GameConnectionStatus.connected) ...[
                          const SizedBox(height: 8),
                          const Text('Connection lost. Reconnecting…',
                              style: TextStyle(
                                  color: AppColors.orange, fontSize: 12)),
                        ],
                        if (isReady) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'READY — WAITING FOR THE REST OF YOUR TEAM',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
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
