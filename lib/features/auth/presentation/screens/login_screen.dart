import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/daketi_logo.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/game_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (_) => false,
    );
  }

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
            Positioned(
              right: 18,
              top: 18,
              child: GameIconButton(
                icon: Icons.menu,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.settings,
                  );
                },
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DaketiLogo(
                    type: DaketiLogoType.whiteOrange,
                    width: 300,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameTextField(
                        hint: 'Email',
                        controller: usernameController,
                      ),
                      const SizedBox(width: 14),
                      GameTextField(
                        hint: 'Password',
                        obscureText: true,
                        controller: passwordController,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  GameButton(
                    text: 'Login',
                    onTap: submit,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: Row(
                children: [
                  GameIconButton(
                    icon: Icons.settings,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.settings,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.support_agent,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.support,
                      );
                    },
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 18,
              bottom: 18,
              child: Row(
                children: [
                  GameIconButton(
                    icon: Icons.facebook,
                    onTap: null,
                  ),
                  SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.camera_alt,
                    onTap: null,
                  ),
                  SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.play_arrow,
                    onTap: null,
                  ),
                  SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.music_note,
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
