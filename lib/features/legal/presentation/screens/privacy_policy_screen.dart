import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import 'legal_content_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalContentScreen(
      title: 'Privacy Policy',
      subtitle:
          'A clear overview of the information used to operate your Daketi experience.',
      sections: const [
        LegalSection(
          'Information We Use',
          'Daketi may process profile details, account identifiers, game progress, match statistics, device information, and purchase history needed to provide the service.',
        ),
        LegalSection(
          'How It Helps',
          'Information is used to run multiplayer matches, save progress, deliver purchases, protect fair play, provide support, and improve performance and reliability.',
        ),
        LegalSection(
          'Sharing & Security',
          'Information should only be shared with service providers when required to operate Daketi, comply with law, or protect players. Reasonable safeguards should be used to prevent unauthorized access.',
        ),
        LegalSection(
          'Your Choices',
          'Depending on your location, you may request access, correction, or deletion of eligible personal information through the official Daketi support channel.',
        ),
      ],
      buttonText: 'Accept',
      onContinue: () =>
          Navigator.pushReplacementNamed(context, AppRoutes.welcome),
    );
  }
}
