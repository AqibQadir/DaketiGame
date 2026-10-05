import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/account_links.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../controllers/auth_controller.dart';

class AccountLinkScreen extends ConsumerStatefulWidget {
  const AccountLinkScreen({super.key, required this.uri});
  final Uri uri;
  @override
  ConsumerState<AccountLinkScreen> createState() => _AccountLinkScreenState();
}

class _AccountLinkScreenState extends ConsumerState<AccountLinkScreen> {
  final password = TextEditingController(), confirm = TextEditingController();
  bool busy = false, done = false;
  String? message;
  AccountLink? get link => AccountLink.parse(widget.uri);
  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || done) return;
    final action = link;
    if (action == null) return;
    if (action.resetToken != null &&
        (password.text.length < 8 || password.text != confirm.text)) {
      setState(() =>
          message = 'Use at least 8 characters and make both passwords match.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (action.resetToken != null) {
        final text = await ref
            .read(authControllerProvider.notifier)
            .resetPassword(action.resetToken!, password.text);
        if (mounted) {
          setState(() {
            message = text;
            done = true;
          });
        }
      } else if (action.verifyToken != null) {
        // The link may belong to another account: verification must not replace
        // the identity currently logged in on this shared device.
        await ref.read(authRestClientProvider).verifyEmail(action.verifyToken!);
        if (ref.read(authControllerProvider).isAuthenticated) {
          await ref.read(authControllerProvider.notifier).refreshSession();
        }
        if (mounted) {
          setState(() {
            message = 'Email verified. Your referral can now be credited.';
            done = true;
          });
        }
      }
    } catch (error) {
      if (mounted) setState(() => message = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resetting = link?.resetToken != null;
    return Scaffold(
        body: GameBackground(
            child: SafeArea(
                child: Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(resetting ? 'RESET PASSWORD' : 'VERIFY EMAIL',
                  style:
                      const TextStyle(fontFamily: 'Dirty Brush', fontSize: 30)),
              const SizedBox(height: 12),
              if (link == null) const Text('This account link is invalid.'),
              if (resetting && !done) ...[
                TextField(
                    controller: password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'New password')),
                TextField(
                    controller: confirm,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirm password')),
              ],
              if (!resetting && !done && link != null)
                const Text(
                    'Confirm to verify the email address associated with this link.'),
              if (message != null)
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(message!, textAlign: TextAlign.center)),
              const SizedBox(height: 12),
              if (!done && link != null)
                GameButton(
                    text: busy ? 'Please wait' : 'Confirm',
                    onTap: busy ? null : submit),
              TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          done && resetting
                              ? AppRoutes.login
                              : ref.read(authControllerProvider).isAuthenticated
                                  ? AppRoutes.home
                                  : AppRoutes.welcome,
                          (_) => false),
                  child: Text(done && resetting ? 'Go to login' : 'Continue')),
            ]),
          )),
    ))));
  }
}
