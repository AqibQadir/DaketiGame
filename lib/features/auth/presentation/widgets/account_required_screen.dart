import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_styled_dialog.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';

Future<void> showFriendsSignupAlert(BuildContext context) async {
  final signup = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => GameStyledDialog(
          title: const Text('PLAY WITH FRIENDS'),
          content: const Text(
              'Sign up to create or join custom rooms, add friends, and send friend requests.'),
          actions: [
            GameButton(
              text: 'Not now',
              backgroundTint: const Color(0xFFFFC928),
              width: 120,
              fontSize: 16,
              onTap: () => Navigator.pop(dialogContext, false),
            ),
            GameButton(
              text: 'Sign up',
              backgroundTint: const Color(0xFFFFC928),
              width: 120,
              fontSize: 16,
              onTap: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      ) ??
      false;
  if (signup && context.mounted) {
    await Navigator.pushNamed(context, AppRoutes.signup);
  }
}

/// Direct route entry is blocked as well as the Home shortcut.
class AccountRequiredScreen extends StatefulWidget {
  const AccountRequiredScreen({super.key});
  @override
  State<AccountRequiredScreen> createState() => _AccountRequiredScreenState();
}

class _AccountRequiredScreenState extends State<AccountRequiredScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showFriendsSignupAlert(context);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: GameBackground(
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.people_outline,
              color: Colors.orangeAccent, size: 42),
          const SizedBox(height: 12),
          const Text('An account is needed to play with friends.',
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          GameButton(
              text: 'Sign up',
              backgroundTint: const Color(0xFFFFC928),
              onTap: () => Navigator.pushNamed(context, AppRoutes.signup)),
          const SizedBox(height: 10),
          GameButton(
              text: 'Back',
              backgroundTint: const Color(0xFFFFC928),
              onTap: () => Navigator.maybePop(context)),
        ])),
      ));
}
