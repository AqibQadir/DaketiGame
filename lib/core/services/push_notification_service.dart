import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_rest_client.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref.watch(authRestClientProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Opt-in until the real Firebase project configuration is supplied. No fake
/// credentials, startup network dependency, or change to game availability.
class PushNotificationService {
  PushNotificationService(this.api);
  final AuthRestClient api;
  static const enabled = bool.fromEnvironment('FIREBASE_ENABLED');
  final _events = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get events => _events.stream;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  String? _accountToken, _deviceToken;
  Future<void>? _initializing;
  bool _ready = false, _disposed = false;

  Future<void> _initialize() =>
      _initializing ??= _setup().whenComplete(() => _initializing = null);
  Future<void> _setup() async {
    if (_ready || !enabled || _disposed) return;
    if (Firebase.apps.isEmpty) {
      const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
      if (apiKey.isEmpty) {
        await Firebase.initializeApp(); // Native GoogleService configuration.
      } else {
        await Firebase.initializeApp(
            options: const FirebaseOptions(
          apiKey: apiKey,
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
          iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
        ));
      }
    }
    if (_disposed) return;
    _subscriptions
        .add(FirebaseMessaging.instance.onTokenRefresh.listen((value) {
      _deviceToken = value;
      unawaited(_registerSafely());
    }));
    _subscriptions.add(FirebaseMessaging.onMessage
        .listen((message) => _dispatch(message, opened: false)));
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp
        .listen((message) => _dispatch(message, opened: true)));
    _ready = true;
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _dispatch(initial, opened: true);
  }

  void _dispatch(RemoteMessage message, {required bool opened}) {
    if (_disposed) return;
    _events.add({
      ...message.data.map((k, v) => MapEntry(k, v.toString())),
      'opened': '$opened'
    });
  }

  Future<void> bindAccount(String? token) async {
    _accountToken = token;
    if (token == null || !enabled) return;
    try {
      await _initialize();
      if (_disposed || _accountToken != token) return;
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      // Permission is requested by the explicit Enable notifications button.
      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        return;
      }
      await _fetchAndRegister();
    } catch (_) {
      // Retry on resume. Push availability never blocks login or gameplay.
    }
  }

  Future<bool> enableNotifications() async {
    if (!enabled || _accountToken == null) return false;
    await _initialize();
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return false;
    }
    return _fetchAndRegister();
  }

  Future<bool> _fetchAndRegister() async {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        await FirebaseMessaging.instance.getAPNSToken() == null) {
      return false;
    }
    _deviceToken = await FirebaseMessaging.instance.getToken(
        vapidKey:
            kIsWeb ? const String.fromEnvironment('FIREBASE_VAPID_KEY') : null);
    return _register();
  }

  Future<void> _registerSafely() async {
    try {
      await _register();
    } catch (_) {/* Retried on resume. */}
  }

  Future<bool> _register() async {
    final token = _accountToken, device = _deviceToken;
    if (token == null || device == null || _disposed) return false;
    await api.request('POST', '/api/devices', token: token, body: {
      'token': device,
      'platform': kIsWeb
          ? 'web'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
    });
    // An in-flight registration may finish after logout. Undo it for that user.
    if (_accountToken != token) {
      await api.request('DELETE', '/api/devices',
          token: token, body: {'token': device});
      return false;
    }
    return true;
  }

  Future<void> unregister(String? accountToken) async {
    _accountToken = null;
    if (!enabled || !_ready) return;
    final device = _deviceToken;
    try {
      if (accountToken != null && device != null) {
        await api.request('DELETE', '/api/devices',
            token: accountToken, body: {'token': device});
      }
    } finally {
      // Invalidate delivery even if the backend is unreachable at logout.
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
      _deviceToken = null;
    }
  }

  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_events.close());
  }
}
