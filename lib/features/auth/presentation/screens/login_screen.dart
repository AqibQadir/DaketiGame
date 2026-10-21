import '../widgets/forgot_password_dialog.dart';
import '../../../../core/widgets/game_styled_dialog.dart';
import '../../../../core/widgets/game_viewport.dart';
import '../../../../core/widgets/game_navigation_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/daketi_logo.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.showClose = true});

  final bool showClose;

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
    final recover = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => GameStyledDialog(
        title: Text(
            (ref.read(authControllerProvider).error ?? 'Unable to log in.')
                .toUpperCase()),
        actions: [
          GameButton(
            text: 'Forgot Password',
            width: 120,
            fontSize: 16,
            backgroundTint: const Color(0xFFBC201B),
            onTap: () => Navigator.pop(dialogContext, true),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (recover == true && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => ForgotPasswordDialog(initialEmail: email),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GameBackground(
        child: GameViewport(
          child: Stack(children: [
            if (widget.showClose)
              Positioned(
                right: 18,
                top: 18,
                child: GameCloseButton(onTap: Navigator.of(context).pop),
              ),
            const Positioned(
              top: 86,
              left: 0,
              right: 0,
              child: Center(child: DaketiLogo(width: 280, height: 105)),
            ),
            Positioned(
              top: 210,
              left: 176,
              right: 76,
              child: Row(children: [
                _loginField(
                  hint: 'Email',
                  controller: usernameController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(width: 10),
                _loginField(
                  hint: 'Password',
                  obscureText: true,
                  controller: passwordController,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(width: 10),
                GameButton(
                  text: 'Login',
                  width: 150,
                  fontSize: 16,
                  isLoading: loading,
                  onTap: loading ? null : submit,
                ),
              ]),
            ),
            Positioned(
              top: 274,
              left: 0,
              right: 0,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GameButton(
                  text: 'Sign Up',
                  width: 150,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
                ),
                const SizedBox(width: 18),
                GameButton(
                  text: 'Play as Guest',
                  width: 180,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.guestName),
                ),
              ]),
            ),
            const GameNavigationFooter(),
          ]),
        ),
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
        width: 211,
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
}
