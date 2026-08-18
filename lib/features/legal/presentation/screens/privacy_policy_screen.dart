import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import 'legal_content_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalContentScreen(
      title: 'Terms & Conditions & Privacy Policy',
      body:
          'TERMS & CONDITIONS\nWelcome to Daketi. By continuing, you agree to play fairly, protect your account, and follow the game rules. This is temporary content and should later be replaced with the approved final terms.\n\nPRIVACY POLICY\nDaketi may store profile details, game progress, purchase history, and gameplay statistics. This is placeholder content and should later be replaced with the approved final privacy policy.',
      buttonText: 'Accept',
      onContinue: () {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.welcome,
        );
      },
    );
  }
}
