import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/routes/app_router.dart';
import '../core/widgets/looping_video_background.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/access/presentation/access_controller.dart';
import '../core/services/account_links.dart';
import '../core/services/push_notification_service.dart';
import '../features/game/presentation/controllers/game_controller.dart';

class DaketiApp extends ConsumerStatefulWidget {
  const DaketiApp({super.key});

  @override
  ConsumerState<DaketiApp> createState() => _DaketiAppState();
}

class _DaketiAppState extends ConsumerState<DaketiApp>
    with WidgetsBindingObserver {
  final navigatorKey = GlobalKey<NavigatorState>();
  bool hadAuthenticatedSession = false;
  StreamSubscription<Uri>? _links;
  StreamSubscription<Map<String, String>>? _push;
  Uri? _pendingLink;
  Map<String, String>? _pendingPush;
  Uri? _lastLink;
  String? _currentRoute;
  late final NavigatorObserver _observer = _NavigationObserver((name) {
    _currentRoute = name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingLink();
      if (mounted &&
          _currentRoute != AppRoutes.splash &&
          _currentRoute != AppRoutes.terms &&
          _pendingPush != null) {
        final payload = _pendingPush!;
        _pendingPush = null;
        unawaited(_onPush(payload));
      }
    });
  });

  Future<void> _setupLinks() async {
    try {
      final links = AppLinks();
      _links = links.uriLinkStream.listen(_receiveLink, onError: (_) {});
      final uri = await links.getInitialLink();
      if (uri != null && mounted) _receiveLink(uri);
    } catch (_) {/* Unsupported desktop/test host. */}
  }

  void _receiveLink(Uri uri) {
    if (!mounted || AccountLink.parse(uri) == null || _lastLink == uri) return;
    _lastLink = uri;
    _pendingLink = uri;
    _openPendingLink();
  }

  void _openPendingLink() {
    if (!mounted ||
        _pendingLink == null ||
        _currentRoute == null ||
        _currentRoute == AppRoutes.splash ||
        _currentRoute == AppRoutes.terms ||
        _currentRoute == AppRoutes.game ||
        ref.read(authControllerProvider).isRestoring) {
      return;
    }
    final uri = _pendingLink!;
    final action = AccountLink.parse(uri)!;
    _pendingLink = null;
    if (action.resetToken != null || action.verifyToken != null) {
      navigatorKey.currentState
          ?.pushNamed(AppRoutes.accountLink, arguments: uri);
    } else if (action.referralCode != null) {
      ref.read(pendingReferralProvider.notifier).state = action.referralCode;
      if (!ref.read(authControllerProvider).isAuthenticated) {
        navigatorKey.currentState?.pushNamed(AppRoutes.signup);
      }
    }
  }

  Future<void> _onPush(Map<String, String> payload) async {
    if (!mounted || !ref.read(authControllerProvider).isAuthenticated) return;
    if (_currentRoute == null ||
        _currentRoute == AppRoutes.splash ||
        _currentRoute == AppRoutes.terms) {
      _pendingPush = payload;
      return;
    }
    final access = ref.read(accessControllerProvider.notifier);
    switch (payload['type']) {
      case 'play_unlocked':
      case 'waitlist_status':
        await access.refresh();
        break;
      case 'referral_credited':
        await access.refresh();
        await access.loadReferrals();
        break;
      case 'app_live':
        await access.refresh();
        break;
      default:
        return;
    }
    if (!mounted || payload['opened'] != 'true') return;
    // Never interrupt an active match just because a notification was tapped.
    if (_currentRoute == AppRoutes.game) return;
    navigatorKey.currentState?.pushNamed(
        payload['type'] == 'app_live' ? AppRoutes.home : AppRoutes.waitlist);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_setupLinks());
    _push = ref
        .read(pushNotificationServiceProvider)
        .events
        .listen((payload) => unawaited(_onPush(payload)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _links?.cancel();
    _push?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResume());
    }
  }

  Future<void> _onResume() async {
    if (!ref.read(authControllerProvider).isAuthenticated) return;
    final valid =
        await ref.read(authControllerProvider.notifier).refreshSession();
    if (!mounted || !valid) return;
    await ref.read(accessControllerProvider.notifier).refresh();
    if (mounted) {
      await ref
          .read(pushNotificationServiceProvider)
          .bindAccount(ref.read(authControllerProvider).token);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) hadAuthenticatedSession = true;
      if (previous?.token != next.token) {
        unawaited(
            ref.read(pushNotificationServiceProvider).bindAccount(next.token));
        if (previous?.token != null) {
          ref.read(gameControllerProvider.notifier).resetSession();
        }
      }
      if (!next.isRestoring) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingLink());
      }
      if (hadAuthenticatedSession &&
          previous?.isAuthenticated == true &&
          !next.isAuthenticated &&
          next.error != null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (_) => false,
        );
      }
    });
    return MaterialApp(
      builder: (context, child) => PersistentBackgroundScope(
        child: Stack(fit: StackFit.expand, children: [
          const LoopingVideoBackground(),
          if (child != null) child,
        ]),
      ),
      navigatorKey: navigatorKey,
      navigatorObservers: [_observer],
      debugShowCheckedModeBanner: false,
      title: 'Daketi',
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class _NavigationObserver extends NavigatorObserver {
  _NavigationObserver(this.onChange);
  final void Function(String?) onChange;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange(route.settings.name);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange(previousRoute?.settings.name);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onChange(newRoute?.settings.name);
}
