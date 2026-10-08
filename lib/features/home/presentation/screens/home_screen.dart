import '../../../../core/widgets/game_viewport.dart';
import '../../../../core/widgets/game_navigation_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../access/presentation/access_controller.dart';
import '../../../access/presentation/waitlist_screen.dart';
import '../../../auth/presentation/controllers/guest_name_provider.dart';
import '../../../tables/presentation/widgets/city_table_cards.dart';
import '../../../game/presentation/controllers/game_controller.dart';
import '../../../game/domain/models/daketi_game.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Object? promptedGame;

  Future<void> offerRecentGame() async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final join = await showGameConfirmation(
      context,
      title: 'BACK TO THE TABLE?',
      message: 'You have a recent match. Would you like to join it again?',
      confirmText: 'Join',
    );
    if (!mounted || !join) return;
    final resumed =
        await ref.read(gameControllerProvider.notifier).resumePreviousGame();
    if (!mounted) return;
    if (!resumed) {
      showGameAlert(
          context,
          ref.read(gameControllerProvider).error ??
              'Unable to rejoin. Please try again.');
      return;
    }
    final game = ref.read(gameControllerProvider).game;
    Navigator.pushNamed(
        context,
        game?.status == DaketiGameStatus.waiting
            ? AppRoutes.waitingRoom
            : AppRoutes.game);
  }

  Widget buildCounter({
    required IconData icon,
    required String value,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.tileBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.orange,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth.isAuthenticated &&
        ref.watch(accessControllerProvider).waitlist?.canPlay != true) {
      return const WaitlistScreen();
    }
    final user = auth.user;
    final session = ref.watch(gameControllerProvider);
    if (session.previousGame != null && promptedGame != session.previousGame) {
      promptedGame = session.previousGame;
      WidgetsBinding.instance.addPostFrameCallback((_) => offerRecentGame());
    }
    final guestName = ref.watch(guestNameProvider)?.trim();
    final hasGuestIdentity = guestName != null && guestName.isNotEmpty;
    return Scaffold(
      body: GameBackground(
        child: GameViewport(
            child: Stack(
          children: [
            if (auth.isAuthenticated)
              Positioned(
                  right: 75,
                  bottom: 14,
                  child: TextButton.icon(
                      icon: const Icon(Icons.group_add),
                      label: const Text('Invite friends'),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.waitlist))),
            Positioned(
              left: 16,
              top: 12,
              child: Semantics(
                button: true,
                label: 'Open profile',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFE0CDB9),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF4D3324),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name.toUpperCase() ??
                                (hasGuestIdentity
                                    ? guestName.toUpperCase()
                                    : 'GUEST PLAYER'),
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            user == null ? 'GUEST' : 'PERSONAL',
                            style: const TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 310,
              right: 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildCounter(
                    icon: Icons.shopping_cart,
                    value: 'BUY COINS',
                  ),
                  const SizedBox(width: 10),
                  buildCounter(
                    icon: Icons.monetization_on,
                    value: auth.isAuthenticated
                        ? auth.stats.totalScore.toString().replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]},')
                        : '—',
                  ),
                  const SizedBox(width: 10),
                  buildCounter(
                    icon: Icons.account_balance_wallet,
                    value: '—',
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              top: 12,
              child: GameIconButton(
                icon: Icons.menu,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.menu,
                  );
                },
              ),
            ),
            Positioned(
              left: 18,
              top: 88,
              child: Column(
                children: [
                  GameIconButton(
                    icon: Icons.emoji_events,
                    label: 'Missions',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.sideQuests);
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              top: 88,
              child: Column(
                children: [
                  GameIconButton(
                    icon: Icons.storefront,
                    label: 'Shop',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.dukan);
                    },
                  ),
                ],
              ),
            ),
            const GameNavigationFooter(),
            Positioned(
              right: 18,
              bottom: 8,
              child: Row(
                children: [
                  GameIconButton(
                    icon: Icons.groups,
                    label: 'Teams',
                    onTap: () {
                      if (auth.isAuthenticated && user == null) {
                        ref
                            .read(authControllerProvider.notifier)
                            .refreshSession();
                        showGameAlert(
                          context,
                          'Loading your profile. Try again.',
                        );
                        return;
                      }
                      Navigator.pushNamed(
                        context,
                        AppRoutes.multiplayer,
                        arguments: user?.name ?? '',
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  GameIconButton(
                    icon: Icons.workspace_premium,
                    label: 'Ranking',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.leaderboard,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 84,
              right: 84,
              top: 72,
              bottom: 66,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 712,
                    height: 245,
                    child: CityTableCards(),
                  ),
                ),
              ),
            ),
            if (!auth.isAuthenticated)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: GameButton(
                    text: 'Guest play',
                    width: 150,
                    onTap: () => Navigator.pushNamed(
                      context,
                      hasGuestIdentity
                          ? AppRoutes.guestOpponents
                          : AppRoutes.guestName,
                      arguments: guestName,
                    ),
                  ),
                ),
              ),
          ],
        )),
      ),
    );
  }
}
