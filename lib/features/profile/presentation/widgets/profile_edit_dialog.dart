import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/game_dialog_title.dart';
import '../../../../core/widgets/game_styled_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileEditDialog extends ConsumerStatefulWidget {
  const ProfileEditDialog({super.key});

  @override
  ConsumerState<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends ConsumerState<ProfileEditDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dob;
  final _email = TextEditingController();
  late final String _userId;
  late final bool _needsEmail;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user!;
    _userId = user.id;
    _needsEmail = user.needsEmail;
    _name = TextEditingController(text: user.name);
    _dob = TextEditingController(text: user.dateOfBirth ?? '');
  }

  String? _validateDate(String? input) {
    final text = input?.trim() ?? '';
    if (text.isEmpty) return null;
    final date = DateTime.tryParse(text);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
        date == null ||
        date.toIso8601String().substring(0, 10) != text) {
      return 'Enter a valid date as YYYY-MM-DD.';
    }
    final now = DateTime.now();
    final latest = DateTime(now.year - 13, now.month, now.day);
    if (date.isAfter(latest)) return 'You must be at least 13 years old.';
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 13, now.month, now.day);
    final parsed = DateTime.tryParse(_dob.text);
    final first = DateTime(1900);
    final initial = parsed == null || parsed.isAfter(latest)
        ? latest
        : parsed.isBefore(first)
            ? first
            : parsed;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: latest,
    );
    if (selected != null && mounted) {
      _dob.text = selected.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (ref.read(authControllerProvider).user?.id != _userId) {
      setState(() =>
          _error = 'Your account changed. Close this form and try again.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final email = _email.text.trim();
    final ok = await ref.read(authControllerProvider.notifier).updateProfile(
          name: _name.text.trim(),
          dateOfBirth: _dob.text.trim().isEmpty ? null : _dob.text.trim(),
          email: _needsEmail && email.isNotEmpty ? email : null,
        );
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    setState(() => _saving = false);
    if (!ok) {
      setState(() =>
          _error = auth.error ?? 'Unable to save your profile. Try again.');
      return;
    }
    if (_needsEmail && email.isNotEmpty && auth.user?.email != email) {
      setState(() => _error =
          'Your name and date of birth were saved, but your email was not updated. Please contact support.');
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: GameStyledDialog(
          title: const GameDialogTitle('EDIT PROFILE'),
          content: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _name,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name.'
                    : null,
              ),
              if (_needsEmail)
                TextFormField(
                  controller: _email,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Add email address'),
                  validator: (value) => value != null &&
                          value.trim().isNotEmpty &&
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value.trim())
                      ? 'Enter a valid email address.'
                      : null,
                ),
              TextFormField(
                controller: _dob,
                enabled: !_saving,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'Date of birth (YYYY-MM-DD)',
                  helperText: 'Optional. Clear to remove.',
                  suffixIcon: IconButton(
                    tooltip: 'Choose date of birth',
                    onPressed: _saving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today),
                  ),
                ),
                validator: _validateDate,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.orangeAccent)),
              ],
              if (_saving) ...[
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ],
            ]),
          ),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save')),
          ],
        ),
      );
}
