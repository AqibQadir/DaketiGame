import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class GameHistoryScreen extends ConsumerStatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  ConsumerState<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends ConsumerState<GameHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).loadHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: GameBackground(
        child: Stack(children: [
          Positioned(
            left: 18,
            top: 18,
            child: GameCloseButton(onTap: Navigator.of(context).pop),
          ),
          Positioned(
            right: 18,
            top: 18,
            child: GameIconButton(
              icon: Icons.menu,
              onTap: () => Navigator.pushNamed(context, AppRoutes.menu),
            ),
          ),
          Center(
            child: GlassPanel(
              width: 680,
              height: 310,
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
              child: Column(children: [
                const Text(
                  'GAME HISTORY',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontFamily: 'Dirty Brush',
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _content(auth)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _content(AuthState auth) {
    if (auth.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (auth.error != null && auth.history.isEmpty) {
      return Center(child: Text(auth.error!, textAlign: TextAlign.center));
    }
    if (auth.history.isEmpty) {
      return const Center(child: Text('NO RECORDED GAMES YET'));
    }
    return ListView.separated(
      itemCount: auth.history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (_, index) => _HistoryRow(game: auth.history[index]),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.game});

  final GameHistoryEntry game;

  @override
  Widget build(BuildContext context) {
    final opponents = game.opponents.map((item) => item.name).join(', ');
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xB31A1714),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: game.isWinner ? AppColors.orange : AppColors.panelBorder,
        ),
      ),
      child: Row(children: [
        Container(
          width: 66,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: game.isWinner ? AppColors.orange : const Color(0xFF3A3733),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            game.isWinner ? 'WIN' : 'PLAYED',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ROOM ${game.gameId}  •  ${game.playerName.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                opponents.isEmpty
                    ? '${game.maxPlayers} PLAYERS'
                    : 'VS $opponents',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 9),
              ),
            ],
          ),
        ),
        Text(
          '${game.score}',
          style: const TextStyle(
            color: AppColors.orange,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 4),
        const Text('PTS', style: TextStyle(fontSize: 8, color: Colors.white60)),
      ]),
    );
  }
}
