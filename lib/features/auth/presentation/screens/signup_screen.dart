import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/daketi_logo.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/game_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameTextField(
                        hint: 'Email',
                        controller: emailController,
                      ),
                      const SizedBox(width: 14),
                      GameTextField(
                        hint: 'Username',
                        controller: usernameController,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameTextField(
                        hint: 'Password',
                        obscureText: true,
                        controller: passwordController,
                      ),
                      const SizedBox(width: 14),
                      GameTextField(
                        hint: 'Re-enter password',
                        obscureText: true,
                        controller: confirmPasswordController,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GameButton(
                    text: 'Signup',
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
            Positioned(
              right: 18,
              bottom: 18,
              child: Row(
                children: [
                  GameIconButton(
                    icon: Icons.facebook,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.camera_alt,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.play_arrow,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  GameIconButton(
                    icon: Icons.music_note,
                    onTap: () {},
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
