import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../tables/presentation/widgets/table_top_bar.dart';
import '../widgets/support_page_shell.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const entries = [
    (
      'Are the card shuffles and game outcomes rigged or fixed?',
      'No. Daketi uses the game service to shuffle and resolve every match consistently for all players.',
    ),
    (
      'The app is freezing or lagging. What should I do?',
      'Check your connection, close background apps, and restart Daketi. Contact support if the problem continues.',
    ),
    (
      'Are my personal details and payment information secure?',
      'Daketi only uses the information required to operate your account and purchases. Never share your password.',
    ),
    (
      'What happens if I lose my internet connection mid-game?',
      'The app attempts to reconnect you to the active match. Your seat may time out if the connection is unavailable for too long.',
    ),
  ];

  @override
  Widget build(BuildContext context) => SupportPageShell(
        title: "FAQ's",
        width: 620,
        height: 245,
        topRight: const TableTopBar(),
        child: ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              dense: true,
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.panelBorder),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.orange),
              ),
              collapsedBackgroundColor: const Color(0xC334322F),
              backgroundColor: const Color(0xD41B1917),
              title: Text(
                entries[index].$1.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              children: [
                Text(
                  entries[index].$2,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
