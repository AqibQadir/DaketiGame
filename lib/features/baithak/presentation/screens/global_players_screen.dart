import 'package:flutter/material.dart';
import '../../../friends/presentation/friends_screen.dart';

class GlobalPlayersScreen extends StatelessWidget {
  const GlobalPlayersScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const FriendsScreen(initialTab: FriendsTab.find);
}
