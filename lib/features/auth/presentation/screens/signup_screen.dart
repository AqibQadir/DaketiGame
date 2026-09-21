import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/game_text_field.dart';
import '../controllers/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
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

  Future<void> submit() async {
    if (ref.read(authControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim().toLowerCase();
    if (passwordController.text != confirmPasswordController.text) {
      showGameAlert(context, 'Passwords do not match.');
      return;
    }
    final success = await ref.read(authControllerProvider.notifier).signup(
          name: usernameController.text.trim(),
          email: email,
          password: passwordController.text,
        );
    if (!mounted) return;
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home,
          (route) => route.settings.name == AppRoutes.welcome);
      return;
    }
    showGameAlert(
      context,
      ref.read(authControllerProvider).error ?? 'Unable to sign up.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final loading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  const Text('SIGN UP',
                      style:
                          TextStyle(fontFamily: 'Dirty Brush', fontSize: 30)),
                  const SizedBox(height: 14),
                  AnimatedSlide(
                    offset: Offset(0, keyboardOpen ? -.55 : 0),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Column(children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameTextField(
                            hint: 'Email',
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
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
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                          const SizedBox(width: 14),
                          GameTextField(
                            hint: 'Re-enter password',
                            obscureText: true,
                            controller: confirmPasswordController,
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      GameButton(
                        text: loading ? 'Please wait…' : 'Signup',
                        onTap: loading ? null : submit,
                      ),
                    ]),
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
