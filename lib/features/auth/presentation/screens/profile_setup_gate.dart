import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../controllers/auth_controller.dart';

/// Every authenticated entry to the lobby checks profile setup, including restore.
class ProfileSetupGate extends ConsumerStatefulWidget {
  const ProfileSetupGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<ProfileSetupGate> createState() => _ProfileSetupGateState();
}

class _ProfileSetupGateState extends ConsumerState<ProfileSetupGate> {
  final name = TextEditingController();
  DateTime? birthday;
  String? gender;
  String? accountId;
  bool checking = true, complete = false, saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(check);
  }

  Future<void> check() async {
    try {
      var auth = ref.read(authControllerProvider);
      if (!auth.isAuthenticated) {
        if (mounted) {
          setState(() {
            complete = true;
            checking = false;
          });
        }
        return;
      }
      final refreshed =
          await ref.read(authControllerProvider.notifier).refreshSession();
      if (!mounted) return;
      auth = ref.read(authControllerProvider);
      if (!refreshed || auth.user == null) {
        setState(() {
          checking = false;
          error = 'Unable to load your profile. Please retry.';
        });
        return;
      }
      final user = auth.user!;
      accountId = user.id;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final hasName = user.name.trim().isNotEmpty && user.name != 'Player';
      name.text = hasName ? user.name : '';
      birthday = DateTime.tryParse(user.dateOfBirth ?? '');
      gender = prefs.getString('profile_gender_${user.id}');
      setState(() {
        complete = prefs.getBool('profile_complete_${user.id}') == true ||
            (hasName && (birthday != null || auth.stats.gamesPlayed > 0));
        checking = false;
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          checking = false;
          error = 'Unable to load your profile. Please retry.';
        });
      }
    }
  }

  Future<void> save() async {
    if (saving) return;
    if (name.text.trim().isEmpty || birthday == null || gender == null) {
      setState(() => error = 'Enter your name, date of birth and gender.');
      return;
    }
    if (ref.read(authControllerProvider).user?.id != accountId) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final ok = await ref.read(authControllerProvider.notifier).updateProfile(
          name: name.text.trim(),
          dateOfBirth: birthday!.toIso8601String().substring(0, 10));
      if (!mounted) return;
      if (!ok) throw Exception('save');
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || ref.read(authControllerProvider).user?.id != accountId) {
        return;
      }
      if (!await prefs.setString('profile_gender_$accountId', gender!) ||
          !await prefs.setBool('profile_complete_$accountId', true)) {
        throw Exception('storage');
      }
      if (mounted) setState(() => complete = true);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Unable to save your profile. Please retry.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (complete) return widget.child;
    return Scaffold(
        body: GameBackground(
            child: SafeArea(
                child: Center(
      child: checking
          ? const CircularProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                  width: 440,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('YOUR PROFILE',
                        style:
                            TextStyle(fontFamily: 'Dirty Brush', fontSize: 28)),
                    const SizedBox(height: 12),
                    if (accountId != null) ...[
                      const CircleAvatar(
                          radius: 24, child: Icon(Icons.person, size: 32)),
                      const SizedBox(height: 12),
                      TextField(
                          controller: name,
                          maxLength: 24,
                          decoration: const InputDecoration(
                              labelText: 'User name', counterText: '')),
                      Row(children: [
                        Expanded(
                            child: TextButton(
                                onPressed: saving
                                    ? null
                                    : () async {
                                        final now = DateTime.now();
                                        final latest = DateTime(
                                            now.year - 13, now.month, now.day);
                                        final selected = await showDatePicker(
                                            context: context,
                                            initialDate: birthday != null &&
                                                    !birthday!
                                                        .isAfter(latest) &&
                                                    birthday!.year >= 1900
                                                ? birthday!
                                                : latest,
                                            firstDate: DateTime(1900),
                                            lastDate: latest);
                                        if (selected != null && mounted) {
                                          setState(() => birthday = selected);
                                        }
                                      },
                                child: Text(birthday == null
                                    ? 'Date of birth'
                                    : birthday!
                                        .toIso8601String()
                                        .substring(0, 10)))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: gender,
                                decoration:
                                    const InputDecoration(labelText: 'Gender'),
                                items: [
                                  'Male',
                                  'Female',
                                  'Other',
                                  'Prefer not to say'
                                ]
                                    .map((g) => DropdownMenuItem(
                                        value: g, child: Text(g)))
                                    .toList(),
                                onChanged: saving
                                    ? null
                                    : (value) =>
                                        setState(() => gender = value))),
                      ]),
                    ],
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(error!,
                              style: const TextStyle(color: Colors.orange))),
                    const SizedBox(height: 12),
                    GameButton(
                        isLoading: saving,
                        text: accountId == null ? 'Retry' : 'Continue',
                        onTap: saving
                            ? null
                            : accountId == null
                                ? check
                                : save),
                  ])),
            ),
    ))));
  }
}
