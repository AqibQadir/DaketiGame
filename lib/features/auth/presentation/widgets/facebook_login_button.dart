import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/facebook_sign_in_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../access/presentation/access_controller.dart';
import '../controllers/auth_controller.dart';

class FacebookLoginButton extends ConsumerWidget {
  const FacebookLoginButton({super.key, this.referralCode});
  final String? referralCode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!FacebookSignInService.enabled) return const SizedBox.shrink();
    final auth = ref.watch(authControllerProvider);
    if (auth.errorStatusCode == 503) return const SizedBox.shrink();
    final loading = auth.isLoading;
    return TextButton.icon(
      icon: const Icon(Icons.facebook),
      label: const Text('Continue with Facebook'),
      onPressed: loading
          ? null
          : () async {
              final ok = await ref
                  .read(authControllerProvider.notifier)
                  .facebookLogin(
                      referralCode:
                          referralCode ?? ref.read(pendingReferralProvider));
              if (!context.mounted) return;
              if (ok) {
                ref.read(pendingReferralProvider.notifier).state = null;
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.home, (_) => false);
              } else {
                showGameAlert(
                    context,
                    ref.read(authControllerProvider).error ??
                        'Unable to sign in with Facebook.');
              }
            },
    );
  }
}
