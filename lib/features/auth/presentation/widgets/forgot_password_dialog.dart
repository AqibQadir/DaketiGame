import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_styled_dialog.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key, required this.initialEmail});
  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  late final email = TextEditingController(text: widget.initialEmail);
  bool busy = false;
  bool done = false;
  String? message;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy || done) return;
    final address = email.text.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      setState(() => message = 'Enter a valid email address.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(address);
      if (mounted) {
        setState(() {
          message = result;
          done = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => message = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: true,
        child: GameStyledDialog(
          onClose: () => Navigator.pop(context),
          title: const Text('FORGOT PASSWORD'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!done) ...[
              const Text(
                  'Enter your email to request password reset instructions.'),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email'),
                onSubmitted: (_) => send(),
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!, textAlign: TextAlign.center),
            ],
          ]),
          actions: [
            if (!done)
              GameButton(
                text: 'Send reset link',
                width: 120,
                fontSize: 16,
                isLoading: busy,
                onTap: busy ? null : send,
              ),
            GameButton(
              text: 'Continue',
              width: 120,
              fontSize: 16,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
}
