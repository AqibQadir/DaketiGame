import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'access_controller.dart';

/// All authenticated lobby entry points respect the server's access decision.
class LaunchAccessGate extends ConsumerWidget {
  const LaunchAccessGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth.isRestoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isAuthenticated) return child;
    final access = ref.watch(accessControllerProvider);
    if (access.waitlist?.canPlay == true) return child;
    if (access.waitlist == null && access.error == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pushReplacementNamed(context, AppRoutes.waitlist);
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
