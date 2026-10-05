import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../widgets/facebook_login_button.dart';
import '../../../../core/widgets/daketi_logo.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 18,
              child: GameCloseButton(
                onTap: () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    navigator.pushReplacementNamed(AppRoutes.welcome);
                  }
                },
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DaketiLogo(
                    type: DaketiLogoType.whiteOrange,
                    width: 240,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameButton(
                        text: 'Login',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.login,
                          );
                        },
                      ),
                      const SizedBox(width: 18),
                      GameButton(
                        text: 'Signup',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.signup,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const FacebookLoginButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
