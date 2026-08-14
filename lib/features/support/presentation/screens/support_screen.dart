import 'package:flutter/material.dart';

import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: Stack(
          children: [
            Positioned(
              left: 18,
              top: 18,
              child: GameCloseButton(
                onTap: Navigator.of(context).pop,
              ),
            ),
            Center(
              child: GlassPanel(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GameButton(
                      text: 'Contact us',
                      width: 190,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    GameButton(
                      text: 'Report',
                      width: 190,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    GameButton(
                      text: 'FAQ',
                      width: 190,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
