import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';

class BaithakScreen extends StatelessWidget {
  const BaithakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        overlayOpacity: .18,
        child: Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 844,
              height: 390,
              child: Stack(
                children: [
                  Positioned(
                    left: 28,
                    top: 25,
                    child: Row(
                      children: [
                        GameCloseButton(
                          size: 40,
                          onTap: Navigator.of(context).pop,
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'BAITHAK',
                          style: TextStyle(
                            fontFamily: 'Dirty Brush',
                            fontSize: 24,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 36,
                    top: 28,
                    child: Row(
                      children: [
                        _TopCounter(
                          icon: Icons.monetization_on,
                          text: 'Buy Coins',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.dukan);
                          },
                        ),
                        const SizedBox(width: 20),
                        const _TopCounter(
                          icon: Icons.stars_rounded,
                          text: '125,000',
                          showAdd: true,
                        ),
                        const SizedBox(width: 20),
                        const _TopCounter(
                          icon: Icons.handshake,
                          text: '25,000',
                          showAdd: true,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 42,
                    top: 100,
                    child: Row(
                      children: [
                        _ModeCard(
                          title: 'MY CLAN',
                          subtitle: 'MAKE YOUR OWN CLAN',
                          buttonText: 'CREATE ROOM',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.multiplayer,
                          ),
                        ),
                        const SizedBox(width: 18),
                        _ModeCard(
                          title: 'GLOBAL',
                          subtitle: 'PAIRS RANDOMLY WITH\nPLAYER',
                          buttonText: 'CREATE ROOM',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.globalPlayers,
                            );
                          },
                        ),
                        const SizedBox(width: 18),
                        _ModeCard(
                          title: 'CHAT LOBBY',
                          subtitle: 'CHAT WITH PEOPLE ACROSS\nTHE GLOBE',
                          buttonText: 'ENTER LOBBY',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.chatLobby,
                          ),
                        ),
                        const SizedBox(width: 18),
                        _ModeCard(
                          title: 'CHAT WITH AI',
                          subtitle: 'PRACTICE WITH AI',
                          buttonText: 'PLAY',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.personalChat,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 15,
                    top: 197,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 34,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    bottom: 25,
                    child: Row(
                      children: [
                        GameIconButton(
                          icon: Icons.settings,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.settings);
                          },
                        ),
                        const SizedBox(width: 10),
                        GameIconButton(
                          icon: Icons.person,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.profile);
                          },
                        ),
                        const SizedBox(width: 10),
                        GameIconButton(
                          icon: Icons.support_agent,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.support);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopCounter extends StatelessWidget {
  const _TopCounter({
    required this.icon,
    required this.text,
    this.showAdd = false,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final bool showAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 29,
        padding: EdgeInsets.only(left: 9, right: showAdd ? 4 : 11),
        decoration: BoxDecoration(
          color: const Color(0xE4443020),
          border: Border.all(color: AppColors.tileBorder),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.orange),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            if (showAdd) ...[
              const SizedBox(width: 9),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                color: AppColors.orange,
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      height: 220,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xB5080808),
        border: Border.all(color: Colors.white38, width: 1.2),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black87, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.chaiHotelBackground,
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              color: Colors.black.withValues(alpha: .46),
              colorBlendMode: BlendMode.darken,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Dirty Brush',
                      fontSize: 22,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 30,
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  GameButton(
                    text: buttonText,
                    width: 126,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
