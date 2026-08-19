import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/game_button.dart';
import '../widgets/support_page_shell.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => SupportPageShell(
        title: 'Contact Us',
        width: 440,
        height: 260,
        showMenu: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GameButton(
              text: 'Email us',
              width: 180,
              onTap: () async {
                await Clipboard.setData(
                  const ClipboardData(text: 'support@daketi.com'),
                );
                if (context.mounted) {
                  _show(context, 'Support email copied');
                }
              },
            ),
            const SizedBox(height: 18),
            GameButton(
              text: 'WA support',
              width: 180,
              onTap: () => _show(context, 'WhatsApp support coming soon'),
            ),
            const SizedBox(height: 18),
            GameButton(
              text: 'Call support',
              width: 180,
              onTap: () => _show(context, 'Call support coming soon'),
            ),
          ],
        ),
      );
}
