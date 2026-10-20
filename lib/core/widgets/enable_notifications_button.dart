import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/push_notification_service.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'game_alert.dart';
import 'game_button.dart';

/// Available both before invitation and after the account gains play access.
class EnableNotificationsButton extends ConsumerStatefulWidget {
  const EnableNotificationsButton({super.key});

  @override
  ConsumerState<EnableNotificationsButton> createState() =>
      _EnableNotificationsButtonState();
}

class _EnableNotificationsButtonState
    extends ConsumerState<EnableNotificationsButton> {
  bool _busy = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    String message;
    try {
      final service = ref.read(pushNotificationServiceProvider);
      if (!service.isAvailable) {
        message = 'Notifications are not available in this build yet.';
      } else {
        // Bind explicitly: this button also works outside the app root listener.
        await service.bindAccount(ref.read(authControllerProvider).token);
        final ok = await service.enableNotifications();
        message = ok
            ? 'Notifications enabled.'
            : 'Notifications could not be enabled. Check notification permission in your phone settings, then try again.';
      }
    } catch (_) {
      message =
          'Unable to enable notifications. Check your connection and try again.';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await showGameAlert(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authControllerProvider).isAuthenticated;
    return GameButton(
      text: 'Enable notifications',
      width: 195,
      fontSize: 15,
      icon: Icons.notifications_active_outlined,
      isLoading: _busy,
      onTap: signedIn && !_busy ? _enable : null,
    );
  }
}
