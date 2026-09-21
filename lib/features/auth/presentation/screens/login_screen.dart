import '../../../../core/widgets/game_styled_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_dialog_title.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/daketi_logo.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (ref.read(authControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    final email = usernameController.text.trim().toLowerCase();
    if (email.isEmpty || passwordController.text.isEmpty) {
      showGameAlert(context, 'Enter your email and password.');
      return;
    }
    final success = await ref.read(authControllerProvider.notifier).login(
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
      ref.read(authControllerProvider).error ?? 'Unable to log in.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final loading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GameBackground(
        child: Center(
            child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                    width: 844,
                    height: 390,
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
                                AppRoutes.menu,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 82,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const DaketiLogo(width: 320, height: 120),
                              const SizedBox(height: 32),
                              AnimatedSlide(
                                offset: Offset(0, keyboardOpen ? -.55 : 0),
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: Column(children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _loginField(
                                        hint: 'Email',
                                        controller: usernameController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email
                                        ],
                                      ),
                                      const SizedBox(width: 36),
                                      _loginField(
                                        hint: 'Password',
                                        obscureText: true,
                                        controller: passwordController,
                                        autofillHints: const [
                                          AutofillHints.password
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 25),
                                  if (loading)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    ),
                                  GameButton(
                                    text: loading ? 'Please wait…' : 'Login',
                                    onTap: loading ? null : submit,
                                  ),
                                  TextButton(
                                    onPressed: loading ? null : _forgotPassword,
                                    child: const Text('Forgot password?'),
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
                    )))),
      ),
    );
  }

  Widget _loginField({
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
  }) =>
      SizedBox(
        width: 198,
        height: 34,
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          autocorrect: false,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0x773C3A36),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.white30)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFFFF8500))),
          ),
        ),
      );

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: usernameController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => GameStyledDialog(
        title: const GameDialogTitle('RESET PASSWORD'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Email')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Send')),
        ],
      ),
    );
    if (email == null || email.trim().isEmpty || !mounted) {
      Future<void>.delayed(
        const Duration(milliseconds: 400),
        controller.dispose,
      );
      return;
    }
    try {
      final message =
          await ref.read(authControllerProvider.notifier).forgotPassword(email);
      if (mounted) {
        await showGameAlert(context, message);
      }
    } catch (error) {
      if (mounted) {
        await showGameAlert(context, error.toString());
      }
    } finally {
      controller.dispose();
    }
  }
}
