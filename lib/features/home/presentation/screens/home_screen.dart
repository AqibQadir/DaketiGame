import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_icon_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                left: 16,
                top: 12,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE0CDB9),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF4D3324),
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE FULL NAME',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'PERSONAL',
                          style: TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ],
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
                      value: '125,000',
                    ),
                    const SizedBox(width: 10),
                    buildCounter(
                      icon: Icons.account_balance_wallet,
                      value: '125,000',
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
                    const SizedBox(height: 14),
                    const GameIconButton(
                      icon: Icons.calendar_month,
                      label: 'Daily',
                      badge: '2',
                      onTap: null,
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
                      icon: Icons.home_work_outlined,
                      label: 'Clan',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.baithak);
                      },
                    ),
                    const SizedBox(height: 14),
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
              Positioned(
                left: 18,
                bottom: 16,
                child: Row(
                  children: [
                    GameIconButton(
                      icon: Icons.settings,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.settings,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GameIconButton(
                      icon: Icons.person,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.profile,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GameIconButton(
                      icon: Icons.support_agent,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.support,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 18,
                bottom: 16,
                child: Row(
                  children: [
                    GameIconButton(
                      icon: Icons.groups,
                      label: 'Teams',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.multiplayer);
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GameButton(
                    text: 'Start game',
                    width: 180,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.guestName,
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
