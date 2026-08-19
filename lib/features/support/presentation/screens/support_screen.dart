import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_button.dart';
import '../widgets/support_page_shell.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) => SupportPageShell(
        title: 'Support',
        width: 440,
        height: 260,
        showMenu: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GameButton(
              text: 'Contact us',
              width: 190,
              onTap: () => Navigator.pushNamed(context, AppRoutes.contactUs),
            ),
            const SizedBox(height: 18),
            GameButton(
              text: 'Report an issue',
              width: 190,
              onTap: () => Navigator.pushNamed(context, AppRoutes.reportIssue),
            ),
            const SizedBox(height: 18),
            GameButton(
              text: 'FAQs',
              width: 190,
              onTap: () => Navigator.pushNamed(context, AppRoutes.faqs),
            ),
          ],
        ),
      );
}
