import 'package:flutter/material.dart';

import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';

class LegalContentScreen extends StatelessWidget {
  const LegalContentScreen({
    super.key,
    required this.title,
    required this.body,
    required this.buttonText,
    required this.onContinue,
  });

  final String title;
  final String body;
  final String buttonText;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        variant: 1,
        overlayOpacity: 0.40,
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 20,
              child: GameCloseButton(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    onContinue();
                  }
                },
              ),
            ),
            Center(
              child: GlassPanel(
                width: 650,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GameButton(
                      text: buttonText,
                      onTap: onContinue,
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
