import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_icon_button.dart';
import 'table_top_bar.dart';

class TablePageShell extends StatelessWidget {
  const TablePageShell({
    super.key,
    required this.title,
    required this.child,
    required this.categories,
  });

  final String title;
  final Widget child;
  final Widget categories;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        overlayOpacity: .19,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 844,
              height: 390,
              child: Stack(
                children: [
                  Positioned(
                    left: 26,
                    top: 24,
                    child: InkWell(
                      onTap: Navigator.of(context).pop,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new,
                            size: 29,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Dirty Brush',
                              fontSize: 22,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(right: 31, top: 23, child: TableTopBar()),
                  Positioned(left: 39, right: 49, top: 77, child: child),
                  Positioned(
                    left: 27,
                    bottom: 22,
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
                  Positioned(
                      left: 205, right: 30, bottom: 31, child: categories),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
