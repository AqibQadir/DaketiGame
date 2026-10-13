import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/daketi_logo.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'access_controller.dart';

class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key});
  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  bool _sharing = false;
  Timer? _refreshTimer;
  static const orange = Color(0xFFFF8509);

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refresh());
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_refresh());
      }
    });
  }

  Future<void> _refresh() async {
    final controller = ref.read(accessControllerProvider.notifier);
    await controller.refresh(join: true);
    if (mounted) await controller.loadReferrals();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
    super.dispose();
  }

  Future<void> _share(BuildContext buttonContext, String link) async {
    if (_sharing || link.isEmpty) return;
    setState(() => _sharing = true);
    try {
      final box = buttonContext.findRenderObject() as RenderBox;
      await SharePlus.instance.share(ShareParams(
        text: 'Join me on Daketi! Sign up with my invitation: $link',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      ));
      if (mounted) await _refresh();
    } catch (_) {
      if (mounted) {
        showGameAlert(
            context, 'Unable to open sharing. Use Copy link instead.');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(accessControllerProvider);
    final data = state.waitlist;
    // Temporary launch display, derived from verified server referrals.
    // This is not a wallet balance or a repeated award on each login/share.
    final points = 200 + (data?.referralCount ?? 0) * 100;
    ref.listen(accessControllerProvider, (previous, next) {
      if (next.waitlist?.canPlay == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.home, (_) => false);
          }
        });
      }
    });
    return Scaffold(
      body: GameBackground(
        variant: 1,
        overlayOpacity: .56,
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: 430, minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .logout();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, AppRoutes.login, (_) => false);
                                }
                              },
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text('Back to login'),
                            ),
                            IconButton(
                                tooltip: 'Refresh',
                                onPressed: state.loading ? null : _refresh,
                                icon: const Icon(Icons.refresh,
                                    color: Colors.white60)),
                          ]),
                      const SizedBox(height: 12),
                      const DaketiLogo(width: 260, height: 100),
                      const SizedBox(height: 30),
                      if (!auth.isAuthenticated) ...[
                        const Text('Sign in to join the waiting list.'),
                        GameButton(
                            text: 'Login',
                            onTap: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.login)),
                      ] else ...[
                        const Text('HURRAH!!',
                            style: TextStyle(
                                fontSize: 24, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 4),
                        Text(
                            data?.canPlay == true
                                ? 'YOU ARE IN!'
                                : data?.position != null
                                    ? '#${data!.position}'
                                    : 'WELCOME',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: orange,
                                fontSize: 66,
                                height: 1.1)),
                        Text(
                            data?.canPlay == true
                                ? 'YOUR ACCESS IS UNLOCKED'
                                : data?.status == 'invited'
                                    ? 'YOUR INVITATION IS HERE'
                                    : 'YOU ARE ON A WAITING LIST',
                            style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.white70)),
                        if (data?.position != null)
                          Text(
                              '#${data!.position} · ${data.totalWaiting} waiting',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 20),
                        const Text('POINTS EARNED',
                            style: TextStyle(
                                fontSize: 18, fontStyle: FontStyle.italic)),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.monetization_on_outlined,
                                  size: 40, color: orange),
                              const SizedBox(width: 12),
                              Text('$points',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 60,
                                      color: orange)),
                            ]),
                        const Text('+200 login bonus',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 14),
                        Builder(
                            builder: (buttonContext) => GameButton(
                                text: 'Share to friend',
                                width: 250,
                                isLoading: _sharing,
                                onTap: _sharing ||
                                        (data?.referralLink.isEmpty ?? true)
                                    ? null
                                    : () => _share(
                                        buttonContext, data!.referralLink))),
                        const SizedBox(height: 10),
                        const Text('Invite friends',
                            style: TextStyle(color: orange, fontSize: 16)),
                        const SizedBox(height: 5),
                        const Text(
                            'Get +100 points for each friend who signs up\nand verifies their email.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.5)),
                        if (auth.user?.needsEmail == true)
                          TextButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, AppRoutes.profile),
                              child: const Text(
                                  'Add your email in Profile to verify referrals')),
                        if (data != null) ...[
                          const SizedBox(height: 14),
                          SelectableText('Your code: ${data.referralCode}',
                              style: const TextStyle(color: Colors.white70)),
                          Text(
                              '${data.referralCount} verified referrals · ${data.pendingReferralCount} pending',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          TextButton(
                              onPressed: data.referralLink.isEmpty
                                  ? null
                                  : () async {
                                      await Clipboard.setData(ClipboardData(
                                          text: data.referralLink));
                                      if (context.mounted) {
                                        showGameAlert(
                                            context, 'Invitation link copied.');
                                      }
                                    },
                              child: const Text('Copy link',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontFamily: 'Roboto'))),
                        ],
                        if (state.loading)
                          const Padding(
                              padding: EdgeInsets.all(8),
                              child: LinearProgressIndicator(color: orange)),
                        if (state.error != null)
                          Text(state.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.amber)),
                        if (data?.canPlay == true)
                          GameButton(
                              text: 'Home',
                              onTap: () => Navigator.pushNamedAndRemoveUntil(
                                  context, AppRoutes.home, (_) => false)),
                        const SizedBox(height: 14),
                        const Text('FOLLOW US FOR UPDATES',
                            style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.white60)),
                        const SizedBox(height: 12),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _social('Instagram', Icons.camera_alt_outlined,
                                  'https://instagram.com/daketi.pk'),
                              _social('TikTok', Icons.music_note_rounded,
                                  'https://tiktok.com/@daketi.pk'),
                              _social('X', null, 'https://x.com/daketipk'),
                            ]),
                        if (PushNotificationService.enabled)
                          TextButton.icon(
                              icon: const Icon(
                                  Icons.notifications_active_outlined),
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
                                            : 'Notifications are not ready. Please try again.');
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    showGameAlert(context,
                                        'Unable to enable notifications. Please try again.');
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
                            child: const Text('Sign out',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontFamily: 'Roboto'))),
                      ],
                    ]),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _openSocial(String url) async {
    try {
      if (await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Present a useful fallback when no browser can open the account.
    }
    if (mounted) {
      showGameAlert(context, 'Unable to open this account. Please visit $url');
    }
  }

  Widget _social(String name, IconData? icon, String url) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Tooltip(
          message: name,
          child: Semantics(
            button: true,
            label: 'Follow Daketi on $name',
            child: Material(
              color: const Color(0x993D3B37),
              child: InkWell(
                onTap: () => _openSocial(url),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.white30)),
                  child: icon != null
                      ? Icon(icon, color: const Color(0xFFEDB270), size: 30)
                      : const Text('𝕏',
                          style: TextStyle(
                              color: Color(0xFFEDB270), fontSize: 30)),
                ),
              ),
            ),
          ),
        ),
      );
}
