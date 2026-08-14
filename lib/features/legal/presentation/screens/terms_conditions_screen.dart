import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import 'legal_content_screen.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalContentScreen(
      title: 'Terms & Conditions',
      body:
          'Welcome to Daketi. By continuing, you agree to play fairly, protect your account, and follow the game rules. This is temporary dummy legal content and should later be replaced with the approved final text.',
      buttonText: 'Continue',
      onContinue: () {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.privacy,
        );
      },
    );
  }
}
