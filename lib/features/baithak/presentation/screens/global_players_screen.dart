import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../widgets/baithak_page_shell.dart';
import '../widgets/player_card.dart';

class GlobalPlayersScreen extends StatelessWidget {
  const GlobalPlayersScreen({super.key});

  @override
  Widget build(BuildContext context) => BaithakPageShell(
        title: 'Global',
        child: GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 2.35,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: 8,
          itemBuilder: (_, __) => PlayerCard(
            compact: true,
            action: '',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.personalChat,
            ),
          ),
        ),
      );
}
