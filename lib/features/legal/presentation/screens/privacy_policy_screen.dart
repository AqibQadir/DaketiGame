import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import 'legal_content_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalContentScreen(
      title: 'Privacy Policy',
      body:
          'Daketi may store profile details, game progress, purchase history, and gameplay statistics. This is placeholder content and should later be replaced with the final privacy policy.',
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
