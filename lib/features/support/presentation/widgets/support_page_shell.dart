import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/glass_panel.dart';

class SupportPageShell extends StatelessWidget {
  const SupportPageShell({
    super.key,
    required this.title,
    required this.child,
    this.width = 470,
    this.height,
    this.showMenu = false,
    this.topRight,
  });

  final String title;
  final Widget child;
  final double width;
  final double? height;
  final bool showMenu;
  final Widget? topRight;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GameBackground(
          overlayOpacity: .18,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 844,
                height: 390,
                child: Stack(children: [
                  Positioned(
                    left: 25,
                    top: 23,
                    child: Row(children: [
                      GameCloseButton(
                        size: 38,
                        onTap: Navigator.of(context).pop,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Dirty Brush',
                          fontSize: 21,
                          height: 1,
                        ),
                      ),
                    ]),
                  ),
                  if (showMenu)
                    Positioned(
                      right: 25,
                      top: 23,
                      child: GameIconButton(
                        icon: Icons.menu,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.menu,
                        ),
                      ),
                    ),
                  if (topRight != null)
                    Positioned(right: 29, top: 23, child: topRight!),
                  Center(
                    child: GlassPanel(
                      width: width,
                      height: height,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 25,
                      ),
                      child: child,
                    ),
                  ),
                  Positioned(
                    left: 27,
                    bottom: 24,
                    child: Column(children: [
                      GameIconButton(
                        icon: Icons.person,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.profile,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GameIconButton(
                        icon: Icons.settings,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.settings,
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
