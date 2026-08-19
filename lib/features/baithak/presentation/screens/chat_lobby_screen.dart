import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../widgets/baithak_page_shell.dart';
import '../widgets/player_card.dart';

class ChatLobbyScreen extends StatelessWidget {
  const ChatLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => BaithakPageShell(
        title: 'Chat Lobby',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            4,
            (_) => PlayerCard(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.personalChat,
              ),
            ),
          ),
        ),
      );
}
