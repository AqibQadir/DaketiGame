import '../../../../core/widgets/game_navigation_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/daketi_logo.dart';
import '../../../../core/widgets/game_styled_dialog.dart';
import '../../../../core/widgets/game_dialog_title.dart';
import '../controllers/auth_controller.dart';
import '../../../access/presentation/access_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final referralController = TextEditingController();
  bool _validating = false;
  @override
  void initState() {
    super.initState();
    referralController.text = ref.read(pendingReferralProvider) ?? '';
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    referralController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (ref.read(authControllerProvider).isLoading || _validating) return;
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim().toLowerCase();
    if (!email.contains('@') || passwordController.text.length < 8) {
      showGameAlert(context,
          'Enter a valid email and a password of at least 8 characters.');
      return;
    }
    if (referralController.text.trim().isNotEmpty) {
      setState(() => _validating = true);
      try {
        await ref
            .read(authRestClientProvider)
            .validateReferral(referralController.text);
      } catch (error) {
        if (mounted) showGameAlert(context, error.toString());
        return;
      } finally {
        if (mounted) setState(() => _validating = false);
      }
      if (!mounted) return;
    }
    final success = await ref.read(authControllerProvider.notifier).signup(
          // The existing signup API requires a name; collect the real name next.
          name: 'Player',
          email: email,
          password: passwordController.text,
          referralCode: referralController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      ref.read(pendingReferralProvider.notifier).state = null;
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
    final loading = ref.watch(authControllerProvider).isLoading || _validating;
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
                          right: 18,
                          top: 18,
                          child: GameCloseButton(
                            onTap: Navigator.of(context).pop,
                          ),
                        ),
                        Positioned(
                          top: 36,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const DaketiLogo(width: 320, height: 120),
                              const SizedBox(height: 20),
                              AnimatedSlide(
                                offset: Offset(0, keyboardOpen ? -.55 : 0),
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: Column(children: [
                                  Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _signupField(
                                            hint: 'Email',
                                            controller: emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            autofillHints: const [
                                              AutofillHints.email
                                            ]),
                                        const SizedBox(width: 36),
                                        _signupField(
                                            hint: 'Password',
                                            controller: passwordController,
                                            obscureText: true,
                                            autofillHints: const [
                                              AutofillHints.newPassword
                                            ]),
                                      ]),
                                  const SizedBox(height: 16),
                                  Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                            width: 170,
                                            height: 40,
                                            child: GameButton(
                                                isLoading: loading,
                                                text: 'Sign Up',
                                                width: 170,
                                                onTap: submit)),
                                        const SizedBox(width: 18),
                                        TextButton(
                                          onPressed:
                                              loading ? null : _editReferral,
                                          child: Text(referralController.text
                                                  .trim()
                                                  .isEmpty
                                              ? 'Have an invitation code?'
                                              : 'Invitation code added'),
                                        ),
                                      ]),
                                ]),
                              ),
                            ],
                          ),
                        ),
                        const GameNavigationFooter(),
                      ],
                    )))),
      ),
    );
  }

  Widget _signupField({
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

  Future<void> _editReferral() async {
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => GameStyledDialog(
              title: const GameDialogTitle('INVITATION CODE'),
              content: TextField(
                  controller: referralController,
                  decoration: const InputDecoration(
                      hintText: 'Referral code (optional)')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Done'))
              ],
            ));
    if (mounted) setState(() {});
  }
}
