import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../widgets/baithak_page_shell.dart';
import '../widgets/player_card.dart';

class MyClanScreen extends StatelessWidget {
  const MyClanScreen({super.key});

  @override
  Widget build(BuildContext context) => BaithakPageShell(
        title: 'My Clan',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            4,
            (_) => PlayerCard(
              action: '',
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.personalChat,
              ),
            ),
          ),
        ),
      );
}
