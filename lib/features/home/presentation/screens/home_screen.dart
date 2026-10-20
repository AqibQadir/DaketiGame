import '../../../../core/widgets/game_viewport.dart';
import '../../../../core/widgets/game_navigation_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../access/presentation/access_controller.dart';
import '../../../access/presentation/waitlist_screen.dart';
import '../../../auth/presentation/controllers/guest_name_provider.dart';
import '../../../tables/presentation/widgets/city_table_cards.dart';
import '../../../game/presentation/controllers/game_controller.dart';
import '../../../game/domain/models/daketi_game.dart';
import '../controllers/online_players_provider.dart';
import '../../../wallet/domain/starting_balance.dart';
import '../../../auth/presentation/widgets/account_required_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Object? promptedGame;

  Future<void> offerRecentGame() async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final active =
        await ref.read(gameControllerProvider.notifier).hasActivePreviousGame();
    if (!active || !mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
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

  void _openFriends() {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      showFriendsSignupAlert(context);
      return;
    }
    if (auth.isAuthenticated && auth.user == null) {
      ref.read(authControllerProvider.notifier).refreshSession();
      showGameAlert(context, 'Loading your profile. Try again.');
      return;
    }
    Navigator.pushNamed(context, AppRoutes.multiplayer,
        arguments: auth.user?.name ?? '');
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
    final balance = ref.watch(startingBalanceProvider);
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
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            user == null ? 'GUEST' : 'PERSONAL',
                            style: const TextStyle(fontSize: 10),
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
              right: 18,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildCounter(
                    icon: Icons.monetization_on,
                    value: balance.coins.toString(),
                  ),
                  const SizedBox(width: 10),
                  buildCounter(
                    icon: Icons.account_balance_wallet,
                    value: 'Rs ${balance.rupees}',
                  ),
                ],
              ),
            ),
            const GameNavigationFooter(),
            Positioned(
              right: 18,
              bottom: 18,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                GameIconButton(
                    icon: Icons.groups,
                    label: 'Play with friends',
                    showLabel: false,
                    onTap: _openFriends),
              ]),
            ),
            Positioned(
                left: 210,
                right: 210,
                bottom: 22,
                child: Center(child: _OnlinePlayersCount())),
            const Positioned(
              left: 0,
              right: 0,
              top: 72,
              bottom: 66,
              child: CityTableCards(),
            ),
          ],
        )),
      ),
    );
  }
}

class _OnlinePlayersCount extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlinePlayersProvider);
    final text = online.when(
      data: (count) => '$count players online',
      loading: () => 'Checking online players…',
      error: (_, __) => 'Online players unavailable',
    );
    return Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle,
                size: 7,
                color: online.hasValue && !online.hasError
                    ? const Color(0xFF74CE8B)
                    : Colors.white38),
            const SizedBox(width: 7),
            Text(text,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ));
  }
}
