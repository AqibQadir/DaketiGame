import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'game_icon_button.dart';

/// Shared navigation placement on the 844 × 390 page canvas.
class GameNavigationFooter extends StatelessWidget {
  const GameNavigationFooter({super.key});
  @override
  Widget build(BuildContext context) => Positioned(
        left: 18,
        bottom: 18,
        child: Row(children: [
          GameIconButton(
              icon: Icons.settings,
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings)),
          const SizedBox(width: 8),
          GameIconButton(
              icon: Icons.support_agent,
              onTap: () => Navigator.pushNamed(context, AppRoutes.support)),
        ]),
      );
}
