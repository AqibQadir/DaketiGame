import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_viewport.dart';
import '../../../../core/widgets/game_icon_button.dart';
import 'table_top_bar.dart';

class TablePageShell extends StatelessWidget {
  const TablePageShell({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        overlayOpacity: .19,
        child: SizedBox.expand(
          child: GameViewport(
            child: SizedBox(
              child: Stack(
                children: [
                  Positioned(
                    left: 26,
                    top: 24,
                    child: Row(children: [
                      IconButton(
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_ios, size: 32),
                        onPressed: () {
                          final navigator = Navigator.of(context);
                          if (navigator.canPop()) {
                            navigator.pop();
                          } else {
                            navigator.pushNamedAndRemoveUntil(
                                AppRoutes.home, (_) => false);
                          }
                        },
                      ),
                      const SizedBox(width: 2),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Dirty Brush',
                          fontSize: 22,
                          height: 1,
                        ),
                      ),
                    ]),
                  ),
                  const Positioned(right: 31, top: 32, child: TableTopBar()),
                  Positioned(left: 42, right: 32, top: 80, child: child),
                  Positioned(
                    left: 32,
                    bottom: 32,
                    child: Row(
                      children: [
                        GameIconButton(
                          icon: Icons.settings,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.settings,
                          ),
                        ),
                        const SizedBox(width: 9),
                        GameIconButton(
                          icon: Icons.person,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.profile,
                          ),
                        ),
                        const SizedBox(width: 9),
                        GameIconButton(
                          icon: Icons.support_agent,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.support,
                          ),
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
