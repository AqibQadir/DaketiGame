import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../tables/presentation/widgets/table_top_bar.dart';

class BaithakPageShell extends StatelessWidget {
  const BaithakPageShell({
    super.key,
    required this.title,
    required this.child,
    this.showTopBar = true,
  });
  final String title;
  final Widget child;
  final bool showTopBar;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GameBackground(
          overlayOpacity: .18,
          child: Center(
            child: FittedBox(
              fit: BoxFit.cover,
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
                  if (showTopBar)
                    const Positioned(
                      right: 30,
                      top: 23,
                      child: TableTopBar(),
                    ),
                  Positioned(
                      left: 35, right: 35, top: 78, bottom: 68, child: child),
                  Positioned(
                    left: 27,
                    bottom: 21,
                    child: Row(children: [
                      GameIconButton(
                        icon: Icons.settings,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.settings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GameIconButton(
                        icon: Icons.person,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.profile,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GameIconButton(
                        icon: Icons.support_agent,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.support,
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
