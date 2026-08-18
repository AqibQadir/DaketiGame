import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import 'legal_content_screen.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalContentScreen(
      title: 'Terms & Conditions',
      subtitle:
          'Fair play starts with clear rules. Please review before entering the game.',
      sections: const [
        LegalSection(
          'Fair Play',
          'Play honestly and respectfully. Cheating, exploiting bugs, collusion, abusive conduct, or any attempt to gain an unfair advantage may result in restricted access.',
        ),
        LegalSection(
          'Your Account',
          'You are responsible for protecting your login details and for activity performed through your account. Do not share, sell, or transfer account access.',
        ),
        LegalSection(
          'Virtual Items',
          'Coins, XP, tables, rewards, and other in-game items are licensed for use inside Daketi. They have no cash value unless applicable law or an approved feature states otherwise.',
        ),
        LegalSection(
          'Game Availability',
          'Online play may be affected by maintenance, updates, network conditions, or service interruptions. Daketi may update gameplay, balancing, features, and these terms when required.',
        ),
      ],
      buttonText: 'Accept',
      onContinue: () =>
          Navigator.pushReplacementNamed(context, AppRoutes.welcome),
    );
  }
}
