import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/daketi_logo.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/game_text_field.dart';

class GuestNameScreen extends StatefulWidget {
  const GuestNameScreen({super.key});

  @override
  State<GuestNameScreen> createState() => _GuestNameScreenState();
}

class _GuestNameScreenState extends State<GuestNameScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void continueToOpponents() {
    final name = controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a temporary username.')),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.guestOpponents,
      arguments: name,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GameBackground(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 844,
                height: 390,
                child: Stack(children: [
                  Positioned(
                    left: 18,
                    top: 18,
                    child: GameCloseButton(
                      size: 54,
                      onTap: Navigator.of(context).pop,
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 18,
                    child: GameIconButton(
                      icon: Icons.menu,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.menu),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DaketiLogo(
                          type: DaketiLogoType.whiteOrange,
                          width: 315,
                        ),
                        const SizedBox(height: 21),
                        GameTextField(
                          hint: 'Temporary username',
                          controller: controller,
                        ),
                        const SizedBox(height: 23),
                        GameButton(
                          text: 'Play',
                          width: 180,
                          onTap: continueToOpponents,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 18,
                    child: Row(children: [
                      GameIconButton(
                        icon: Icons.settings,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.settings),
                      ),
                      const SizedBox(width: 8),
                      GameIconButton(
                        icon: Icons.support_agent,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.support),
                      ),
                    ]),
                  ),
                  const Positioned(
                    right: 18,
                    bottom: 18,
                    child: Row(children: [
                      GameIconButton(icon: Icons.facebook, onTap: null),
                      SizedBox(width: 8),
                      GameIconButton(icon: Icons.camera_alt, onTap: null),
                      SizedBox(width: 8),
                      GameIconButton(icon: Icons.play_arrow, onTap: null),
                      SizedBox(width: 8),
                      GameIconButton(icon: Icons.music_note, onTap: null),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
