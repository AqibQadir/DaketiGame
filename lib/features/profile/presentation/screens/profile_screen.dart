import '../../../../core/widgets/game_styled_dialog.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_dialog_title.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../../core/widgets/game_viewport.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool editMenuOpen = false;

  String _number(int value) => value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');

  Widget buildStatRow(String label, String value) => Container(
        height: 28,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 17),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8000),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF261A10),
                      fontSize: 14,
                      fontWeight: FontWeight.w700))),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF261A10),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    void edit() {
      setState(() => editMenuOpen = false);
      if (user == null) {
        _message(context, 'Sign in to edit your profile.');
      } else {
        _editProfile(context, ref);
      }
    }

    Widget logout({bool red = false}) {
      final button = GameButton(
          backgroundAsset: AppAssets.actionButtonBrush,
          text: 'LOGOUT',
          width: red ? 119 : 95,
          fontSize: 15,
          onTap: () => _logout(context, ref));
      if (!red) return button;
      return Stack(alignment: Alignment.center, children: [
        ColorFiltered(
            colorFilter:
                const ColorFilter.mode(Color(0xFFC71912), BlendMode.srcIn),
            child: Image.asset(AppAssets.actionButtonBrush,
                width: 119, height: 32, fit: BoxFit.fill)),
        SizedBox(
            width: 119,
            height: 32,
            child: TextButton(
                onPressed: () => _logout(context, ref),
                child: const Text('LOGOUT',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Dirty Brush',
                        fontSize: 16,
                        height: 1)))),
      ]);
    }

    return Scaffold(
        body: GameBackground(
      overlayOpacity: .20,
      child: GameViewport(
          child: Stack(children: [
        const Positioned(
            left: 23,
            top: 24,
            child: Row(children: [
              Text('PROFILE',
                  style: TextStyle(
                      fontFamily: 'Dirty Brush',
                      color: Color(0xFFD0CFCA),
                      fontSize: 23)),
            ])),
        Positioned(
            right: 32,
            top: 32,
            child: GameIconButton(
                icon: Icons.menu,
                onTap: () => Navigator.pushNamed(context, AppRoutes.menu))),
        Positioned(
            left: 32,
            bottom: 32,
            child: Column(children: [
              GameIconButton(
                  icon: Icons.headset_mic,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.support)),
              const SizedBox(height: 11),
              GameIconButton(
                  icon: Icons.settings,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.settings)),
            ])),
        Positioned(
            left: 192,
            top: 57,
            width: 467,
            height: 272,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      border:
                          Border.all(color: const Color(0xFF77746A), width: .8),
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0x882B2923),
                            Color(0xA6100B05),
                            Color(0xB3140803)
                          ]),
                    ))))),
        Positioned(
            left: 237,
            top: 90,
            width: 112,
            height: 112,
            child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF58483C),
                    border: Border.all(color: const Color(0xFF8E8173))),
                child: ClipOval(
                    child: ColoredBox(
                        color: const Color(0xFFC8C8C8),
                        child: Image.asset(AppAssets.playerAvatar,
                            fit: BoxFit.cover))))),
        Positioned(
            left: 218,
            top: 214,
            width: 154,
            child: Column(children: [
              SizedBox(
                  height: 20,
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(user?.name.toUpperCase() ?? 'GUEST PLAYER',
                          style: const TextStyle(
                              color: Color(0xFFFF8000),
                              fontFamily: 'Dirty Brush',
                              fontSize: 20,
                              height: 1)))),
              const SizedBox(height: 2),
              Text(user?.email ?? 'Not signed in',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFFAAA59E), fontSize: 10)),
              const SizedBox(height: 8),
              const Text('REGIONAL',
                  style: TextStyle(
                      fontFamily: 'Dirty Brush',
                      fontSize: 22,
                      color: Color(0xFFFF8000))),
            ])),
        Positioned(
            left: 393,
            top: 108,
            width: 223,
            child: Column(children: [
              buildStatRow('Worth', '—'),
              buildStatRow('Total Wins', _number(auth.stats.gamesWon)),
              buildStatRow('Matches Played', _number(auth.stats.gamesPlayed)),
              buildStatRow('Level', '—'),
              buildStatRow('Position', '—'),
              const SizedBox(height: 6),
              if (editMenuOpen) logout(red: true)
            ])),
        Positioned(
            left: 602,
            top: 65,
            width: 38,
            height: 32,
            child: IconButton(
                tooltip: 'Profile options',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz,
                    color: Color(0xFFD77505), size: 29),
                onPressed: () => setState(() => editMenuOpen = !editMenuOpen))),
        if (editMenuOpen)
          Positioned(
              left: 618,
              top: 89,
              width: 78,
              height: 40,
              child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFF8B766B)),
                    gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF84412C),
                          Color(0xFF200A05),
                          Color(0xFF090909)
                        ]),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 9)
                    ],
                  ),
                  child: TextButton(
                      onPressed: edit,
                      child: const Text('EDIT',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Dirty Brush',
                              fontSize: 18))))),
      ])),
    ));
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    final name = TextEditingController(text: user.name);
    final dob = TextEditingController(text: user.dateOfBirth ?? '');
    final save = await showDialog<bool>(
        context: context,
        builder: (context) => GameStyledDialog(
              scrollable: true,
              title: const GameDialogTitle('EDIT PROFILE'),
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
                    onPressed: () => _accountAction(context, ref, 'password'),
                    child: const Text('Change password')),
                TextButton(
                    onPressed: () => _accountAction(context, ref, 'verify'),
                    child: const Text('Resend verification')),
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
        builder: (context) => GameStyledDialog(
              scrollable: true,
              title: const GameDialogTitle('CHANGE PASSWORD'),
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

  void _message(BuildContext context, String value) =>
      showGameAlert(context, value);
}
