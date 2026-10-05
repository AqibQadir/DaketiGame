import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'access_controller.dart';

class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key});
  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  bool _sharing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(accessControllerProvider.notifier).refresh());
      unawaited(ref.read(accessControllerProvider.notifier).loadReferrals());
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(accessControllerProvider);
    final data = state.waitlist;
    return Scaffold(
        body: GameBackground(
            child: SafeArea(
                child: Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Expanded(
                    child: Text('YOUR DAKETI INVITATION',
                        style: TextStyle(
                            fontFamily: 'Dirty Brush',
                            fontSize: 29,
                            color: Color(0xFFFFB344)))),
                IconButton(
                    tooltip: 'Profile',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.profile),
                    icon: const Icon(Icons.person)),
                IconButton(
                    tooltip: 'Refresh',
                    onPressed: state.loading
                        ? null
                        : () async {
                            await ref
                                .read(accessControllerProvider.notifier)
                                .refresh(
                                    join:
                                        data == null || data.status == 'none');
                            if (mounted) {
                              await ref
                                  .read(accessControllerProvider.notifier)
                                  .loadReferrals();
                            }
                          },
                    icon: const Icon(Icons.refresh)),
              ]),
              if (!auth.isAuthenticated) ...[
                const Text(
                    'Sign in to join the waiting list and invite your friends.'),
                GameButton(
                    text: 'Login',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.login)),
              ] else ...[
                if (state.loading) const LinearProgressIndicator(),
                if (state.error != null)
                  Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(state.error!,
                          style: const TextStyle(color: Colors.amber))),
                if (data != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xED1F1B13),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF907044))),
                    child: Column(children: [
                      Text(
                          data.canPlay
                              ? 'YOU ARE READY TO PLAY'
                              : switch (data.status) {
                                  'waiting' => 'YOU ARE ON THE LIST',
                                  'invited' => 'YOUR INVITATION IS HERE',
                                  _ => 'JOIN THE WAITING LIST',
                                },
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 20)),
                      if (data.position != null)
                        Text('#${data.position} · ${data.totalWaiting} waiting',
                            style: const TextStyle(
                                fontSize: 28, color: Color(0xFFFFB344))),
                      Text(
                          data.canPlay
                              ? 'Your access is unlocked.'
                              : data.status == 'invited'
                                  ? 'You have been invited. We will let you know when play is unlocked.'
                                  : 'Invite friends. Verified referrals move you up the queue.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                          '${data.referralCount} verified referrals · ${data.pendingReferralCount} pending'),
                      if (data.referralCode.isNotEmpty)
                        SelectableText('Your code: ${data.referralCode}',
                            style: const TextStyle(color: Color(0xFFFFB344))),
                      if (data.referralLink.isNotEmpty)
                        Wrap(
                            spacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              Builder(
                                  builder: (buttonContext) => TextButton.icon(
                                      icon: const Icon(Icons.share),
                                      label: const Text('Invite friends'),
                                      onPressed: _sharing
                                          ? null
                                          : () async {
                                              setState(() => _sharing = true);
                                              try {
                                                final box = buttonContext
                                                        .findRenderObject()
                                                    as RenderBox;
                                                await SharePlus.instance.share(
                                                    ShareParams(
                                                        text:
                                                            'Join me on Daketi! ${data.referralLink}',
                                                        sharePositionOrigin:
                                                            box.localToGlobal(
                                                                    Offset
                                                                        .zero) &
                                                                box.size));
                                              } catch (_) {
                                                if (context.mounted) {
                                                  showGameAlert(context,
                                                      'Unable to open sharing. Use Copy link instead.');
                                                }
                                              } finally {
                                                if (mounted) {
                                                  setState(
                                                      () => _sharing = false);
                                                }
                                              }
                                            })),
                              TextButton.icon(
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy link'),
                                  onPressed: () async {
                                    await Clipboard.setData(
                                        ClipboardData(text: data.referralLink));
                                    if (context.mounted) {
                                      showGameAlert(
                                          context, 'Invitation link copied.');
                                    }
                                  }),
                            ]),
                    ]),
                  ),
                if (auth.user?.needsEmail == true)
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'Add an email in Profile to receive account emails and verify your referral.')),
                for (final person in state.referrals)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Expanded(child: Text(person.name)),
                        Text(
                            person.verified
                                ? 'Verified'
                                : 'Awaiting email verification',
                            style: const TextStyle(color: Colors.amber)),
                      ])),
                const SizedBox(height: 10),
                Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (data?.status == 'none')
                        GameButton(
                            text: 'Join list',
                            onTap: state.loading
                                ? null
                                : () => ref
                                    .read(accessControllerProvider.notifier)
                                    .refresh(join: true)),
                      if (data?.canPlay == true)
                        GameButton(
                            text: 'Home',
                            onTap: () => Navigator.pushNamedAndRemoveUntil(
                                context, AppRoutes.home, (_) => false)),
                      if (PushNotificationService.enabled)
                        TextButton.icon(
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Enable notifications'),
                            onPressed: () async {
                              try {
                                final ok = await ref
                                    .read(pushNotificationServiceProvider)
                                    .enableNotifications();
                                if (context.mounted) {
                                  showGameAlert(
                                      context,
                                      ok
                                          ? 'Notifications enabled.'
                                          : 'Notifications are not ready. Check device permissions and try again.');
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  showGameAlert(context,
                                      'Unable to enable notifications. Please try again later.');
                                }
                              }
                            }),
                      TextButton(
                          onPressed: () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .logout();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, AppRoutes.welcome, (_) => false);
                            }
                          },
                          child: const Text('Sign out')),
                    ]),
              ],
            ]),
          )),
    ))));
  }
}
