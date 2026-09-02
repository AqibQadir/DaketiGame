import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/glass_panel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget buildStatRow(String label, String value) {
    return Container(
      height: 29,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: const BoxDecoration(color: Color(0xFFFF8000)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF261A10),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF261A10),
              fontSize: 11,
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
        child: Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 844,
              height: 390,
              child: Stack(
                children: [
                  Positioned(
                    left: 30,
                    top: 28,
                    child: GameCloseButton(
                      size: 54,
                      onTap: Navigator.of(context).pop,
                    ),
                  ),
                  Positioned(
                    right: 30,
                    top: 30,
                    child: GameIconButton(
                      icon: Icons.menu,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.settings);
                      },
                    ),
                  ),
                  Positioned(
                    left: 30,
                    bottom: 31,
                    child: Column(
                      children: [
                        GameIconButton(
                          icon: Icons.support_agent,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.support);
                          },
                        ),
                        const SizedBox(height: 10),
                        GameIconButton(
                          icon: Icons.settings,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.settings);
                          },
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 199,
                    top: 59,
                    child: GlassPanel(
                      width: 483,
                      height: 281,
                      padding: const EdgeInsets.fromLTRB(38, 34, 42, 28),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 145,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Color(0xFFD9D9D9),
                                  child: Icon(
                                    Icons.person,
                                    size: 66,
                                    color: Color(0xFF3C352C),
                                  ),
                                ),
                                SizedBox(height: 11),
                                Text(
                                  'THE FULL NAME',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.orange,
                                    fontFamily: 'Dirty Brush',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'The Username',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'REGIONAL',
                                  style: TextStyle(
                                    color: AppColors.orange,
                                    fontFamily: 'Dirty Brush',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildStatRow('Worth', '125,000'),
                                buildStatRow('Total Wins', '100'),
                                buildStatRow('Matches Played', '125,000'),
                                buildStatRow('Level', '25'),
                                buildStatRow('Position', '9th'),
                              ],
                            ),
                          ),
                        ],
                      ),
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
