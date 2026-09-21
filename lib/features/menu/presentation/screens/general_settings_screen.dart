import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../support/presentation/widgets/support_page_shell.dart';

class GeneralSettingsScreen extends ConsumerWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SupportPageShell(
        title: 'Account Settings',
        width: 470,
        height: 245,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AccountRow('Username',
                ref.watch(authControllerProvider).user?.name ?? 'Guest'),
            _AccountRow(
                'Email',
                ref.watch(authControllerProvider).user?.email ??
                    'Not signed in'),
            const _AccountRow('Password', '••••••••'),
            const SizedBox(height: 15),
            GameButton(
              text: 'Logout',
              width: 120,
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.welcome, (_) => false);
              },
            ),
          ],
        ),
      );
}

class _AccountRow extends ConsumerWidget {
  const _AccountRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
        ]),
      );
}
