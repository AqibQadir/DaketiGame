import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../support/presentation/widgets/support_page_shell.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => SupportPageShell(
        title: 'General Settings',
        width: 470,
        height: 245,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _AccountRow('Username', 'Dakait 420'),
            const _AccountRow('Email', 'dakait-420@gmail.com'),
            const _AccountRow('Phone', '+92 300 000 000'),
            const _AccountRow('Password', '••••••••'),
            const SizedBox(height: 15),
            GameButton(
              text: 'Logout',
              width: 120,
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.welcome,
                (_) => false,
              ),
            ),
          ],
        ),
      );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
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
