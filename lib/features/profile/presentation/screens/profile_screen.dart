import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget buildStatRow(String label, String value) {
    return Container(
      height: 29,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: const BoxDecoration(color: Color(0xFFFF8000)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF261A10),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF261A10),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    return Scaffold(
      body: GameBackground(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: 844,
              height: 390,
              child: Stack(
                children: [
                  Positioned(
                    left: 30,
                    top: 28,
                    child: GameCloseButton(
                      size: 54,
                      onTap: Navigator.of(context).pop,
                    ),
                  ),
                  Positioned(
                    right: 30,
                    top: 30,
                    child: GameIconButton(
                      icon: Icons.menu,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.settings);
                      },
                    ),
                  ),
                  Positioned(
                    left: 30,
                    bottom: 31,
                    child: Column(
                      children: [
                        GameIconButton(
                          icon: Icons.support_agent,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.support);
                          },
                        ),
                        const SizedBox(height: 10),
                        GameIconButton(
                          icon: Icons.settings,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.settings);
                          },
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 199,
                    top: 59,
                    child: GlassPanel(
                      width: 483,
                      height: 281,
                      padding: const EdgeInsets.fromLTRB(38, 34, 42, 28),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 145,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Color(0xFFD9D9D9),
                                  child: Icon(
                                    Icons.person,
                                    size: 66,
                                    color: Color(0xFF3C352C),
                                  ),
                                ),
                                const SizedBox(height: 11),
                                Text(
                                  user?.name.toUpperCase() ?? 'GUEST PLAYER',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.orange,
                                    fontFamily: 'Dirty Brush',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user?.email ?? 'Not signed in',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  user == null
                                      ? 'GUEST'
                                      : (user.emailVerified
                                          ? 'VERIFIED'
                                          : 'UNVERIFIED'),
                                  style: const TextStyle(
                                    color: AppColors.orange,
                                    fontFamily: 'Dirty Brush',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildStatRow(
                                    'Total Score', '${auth.stats.totalScore}'),
                                buildStatRow(
                                    'Total Wins', '${auth.stats.gamesWon}'),
                                buildStatRow('Matches Played',
                                    '${auth.stats.gamesPlayed}'),
                                if (user != null)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton(
                                          style: _compactButtonStyle,
                                          onPressed: () =>
                                              _editProfile(context, ref),
                                          child: const Text('EDIT')),
                                      TextButton(
                                          style: _compactButtonStyle,
                                          onPressed: () => Navigator.pushNamed(
                                              context, AppRoutes.gameHistory),
                                          child: const Text('HISTORY')),
                                      TextButton(
                                        style: _compactButtonStyle,
                                        onPressed: () => _logout(context, ref),
                                        child: const Text('LOG OUT'),
                                      ),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                          minHeight: 28,
                                        ),
                                        onSelected: (value) =>
                                            _accountAction(context, ref, value),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                              value: 'password',
                                              child: Text('Change password')),
                                          PopupMenuItem(
                                              value: 'verify',
                                              child:
                                                  Text('Resend verification')),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    final name = TextEditingController(text: user.name);
    final dob = TextEditingController(text: user.dateOfBirth ?? '');
    final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('EDIT PROFILE'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: dob,
                    decoration: const InputDecoration(
                        labelText: 'Date of birth (YYYY-MM-DD)')),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'))
              ],
            ));
    if (save == true) {
      final ok = await ref.read(authControllerProvider.notifier).updateProfile(
          name: name.text.trim(),
          dateOfBirth: dob.text.trim().isEmpty ? null : dob.text.trim());
      if (context.mounted && !ok) {
        _message(context,
            ref.read(authControllerProvider).error ?? 'Update failed.');
      }
    }
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      name.dispose();
      dob.dispose();
    });
  }

  Future<void> _accountAction(
      BuildContext context, WidgetRef ref, String value) async {
    if (value == 'verify') {
      try {
        final message = await ref
            .read(authControllerProvider.notifier)
            .resendVerification();
        if (context.mounted) _message(context, message);
      } catch (error) {
        if (context.mounted) _message(context, error.toString());
      }
      return;
    }
    final current = TextEditingController();
    final next = TextEditingController();
    final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('CHANGE PASSWORD'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: current,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Current password')),
                TextField(
                    controller: next,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'New password'))
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Update'))
              ],
            ));
    if (save == true) {
      try {
        final message = await ref
            .read(authControllerProvider.notifier)
            .changePassword(current.text, next.text);
        if (context.mounted) _message(context, message);
      } catch (error) {
        if (context.mounted) _message(context, error.toString());
      }
    }
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      current.dispose();
      next.dispose();
    });
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await ref.read(authControllerProvider.notifier).logout();
    navigator.pushNamedAndRemoveUntil(
      AppRoutes.welcome,
      (_) => false,
    );
  }

  static final ButtonStyle _compactButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
  );

  void _message(BuildContext context, String value) =>
      showGameAlert(context, value);
}
