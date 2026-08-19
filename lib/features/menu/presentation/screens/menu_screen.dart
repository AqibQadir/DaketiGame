import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../support/presentation/widgets/support_page_shell.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) => SupportPageShell(
        title: 'Menu',
        width: 440,
        height: 260,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GameButton(
              text: 'General settings',
              width: 225,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.generalSettings),
            ),
            const SizedBox(height: 24),
            GameButton(
              text: 'Leaderboard',
              width: 225,
              onTap: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
            ),
          ],
        ),
      );
}
