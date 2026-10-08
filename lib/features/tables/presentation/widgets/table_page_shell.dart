import '../../../../core/widgets/game_navigation_footer.dart';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_viewport.dart';
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
                  Positioned(
                      right: 18,
                      top: 18,
                      child: IconButton(
                        tooltip: 'Close tables',
                        icon: const Icon(Icons.close_rounded, size: 28),
                        onPressed: () {
                          final navigator = Navigator.of(context);
                          if (navigator.canPop()) {
                            navigator.pop();
                          } else {
                            navigator.pushNamedAndRemoveUntil(
                                AppRoutes.home, (_) => false);
                          }
                        },
                      )),
                  const Positioned(right: 84, top: 32, child: TableTopBar()),
                  Positioned(
                      left: 42, right: 32, top: 80, bottom: 64, child: child),
                  const GameNavigationFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
