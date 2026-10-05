import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/game_dialog_title.dart';
import '../../../../core/widgets/game_styled_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../game/data/game_api_exception.dart';

class AccountOptionsDialog extends ConsumerStatefulWidget {
  const AccountOptionsDialog({super.key});

  @override
  ConsumerState<AccountOptionsDialog> createState() =>
      _AccountOptionsDialogState();
}

class _AccountOptionsDialogState extends ConsumerState<AccountOptionsDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _message;
  late final String? _userId = ref.read(authControllerProvider).user?.id;

  Future<void> _run(Future<String> Function() action,
      {bool password = false}) async {
    if (_busy || (password && !_form.currentState!.validate())) return;
    if (ref.read(authControllerProvider).user?.id != _userId) {
      setState(() =>
          _message = 'Your account changed. Close this form and try again.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final message = await action();
      if (!mounted) return;
      if (password) {
        _current.clear();
        _next.clear();
        _confirm.clear();
      }
      setState(() => _message = message);
    } catch (error) {
      if (mounted) {
        setState(() => _message = error is GameApiException
            ? error.message
            : 'Unable to reach the server. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final controller = ref.read(authControllerProvider.notifier);
    return PopScope(
      canPop: !_busy,
      child: GameStyledDialog(
        title: const GameDialogTitle('ACCOUNT OPTIONS'),
        content: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(user?.email.isNotEmpty == true
                ? user!.email
                : 'No email added'),
            Text(user?.emailVerified == true
                ? 'Email verified'
                : 'Email not verified'),
            if (user?.facebookLinked == true) const Text('Facebook connected'),
            if (user?.needsEmail == true)
              const Text(
                  'Add an email in Edit Profile to receive account emails.'),
            if (user != null && !user.needsEmail && !user.emailVerified)
              TextButton(
                onPressed:
                    _busy ? null : () => _run(controller.resendVerification),
                child: const Text('Resend verification'),
              ),
            if (user?.hasPassword == true) ...[
              TextFormField(
                controller: _current,
                enabled: !_busy,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current password'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your current password.'
                    : null,
              ),
              TextFormField(
                controller: _next,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) => value == null || value.length < 8
                    ? 'Use at least 8 characters.'
                    : null,
              ),
              TextFormField(
                controller: _confirm,
                enabled: !_busy,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm new password'),
                validator: (value) =>
                    value != _next.text ? 'Passwords do not match.' : null,
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                          () => controller.changePassword(
                              _current.text, _next.text),
                          password: true,
                        ),
                child: const Text('Update password'),
              ),
            ],
            if (user != null && !user.needsEmail)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => controller.forgotPassword(user.email)),
                child: Text(user.hasPassword
                    ? 'Send password reset email'
                    : 'Set a password by email'),
              ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!,
                  style: const TextStyle(color: Colors.orangeAccent)),
            ],
            if (_busy)
              const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator()),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
