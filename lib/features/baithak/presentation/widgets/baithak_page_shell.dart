import '../../../../core/widgets/game_navigation_footer.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_close_button.dart';
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
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
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
                  const GameNavigationFooter(),
                ]),
              ),
            ),
          ),
        ),
      );
}
