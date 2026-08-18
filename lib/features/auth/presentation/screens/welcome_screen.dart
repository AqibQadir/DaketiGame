import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/daketi_logo.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_icon_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: Stack(
          children: [
            Positioned(
              top: 18,
              right: 18,
              child: GameIconButton(
                icon: Icons.menu,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.settings,
                  );
                },
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DaketiLogo(),
                  const SizedBox(height: 28),
                  GameButton(
                    text: 'Play',
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.authChoice,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  GameButton(
                    text: 'Play as guest',
                    width: 180,
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.home,
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              bottom: 18,
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
            const Positioned(
              right: 18,
              bottom: 18,
              child: Row(
                children: [
                  GameIconButton(
                    icon: Icons.facebook,
                    onTap: null,
                  ),
                  SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.camera_alt,
                    onTap: null,
                  ),
                  SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.play_arrow,
                    onTap: null,
                  ),
                  SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.music_note,
                    onTap: null,
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
