import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/backend_config.dart';
import '../../../../core/services/facebook_sign_in_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../game/data/game_api_exception.dart';
import '../../data/auth_rest_client.dart';
import '../../data/auth_token_storage.dart';
import '../../domain/auth_user.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isRestoring = true,
    this.token,
    this.user,
    this.stats = const AuthStats(),
    this.history = const [],
    this.error,
    this.errorStatusCode,
  });

  final bool isLoading;
  final bool isRestoring;
  final String? token;
  final AuthUser? user;
  final AuthStats stats;
  final List<GameHistoryEntry> history;
  final String? error;
  final int? errorStatusCode;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
}

final authRestClientProvider = Provider<AuthRestClient>((ref) {
  final client = AuthRestClient(baseUrl: BackendConfig.serverUrl);
  ref.onDispose(client.dispose);
  return client;
});

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    client: ref.watch(authRestClientProvider),
    storage: ref.watch(authTokenStorageProvider),
    beforeLogout: (token) =>
        ref.read(pushNotificationServiceProvider).unregister(token),
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRestClient client,
    required AuthTokenStorage storage,
    Future<void> Function(String?)? beforeLogout,
  })  : _client = client,
        _storage = storage,
        _beforeLogout = beforeLogout,
        super(const AuthState()) {
    restoreSession();
  }

  final AuthRestClient _client;
  final AuthTokenStorage _storage;
  final Future<void> Function(String?)? _beforeLogout;
  int _authRevision = 0;
  Future<void>? _storageChanges;

  Future<void> _changeStorage(Future<void> Function() change) {
    final operation = _storageChanges == null
        ? Future<void>.sync(change)
        : _storageChanges!.then((_) => change());
    _storageChanges = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> restoreSession() async {
    final revision = _authRevision;
    String? token;
    try {
      token = await _storage.read();
      if (!mounted || revision != _authRevision) return;
      if (token == null || token.isEmpty) {
        state = const AuthState(isRestoring: false);
        return;
      }
      final result = await _client.getMe(token);
      if (!mounted || revision != _authRevision) return;
      state = AuthState(
        isRestoring: false,
        token: token,
        user: result.user,
        stats: result.stats,
      );
    } on GameApiException catch (error) {
      if (!mounted || revision != _authRevision) return;
      if (error.statusCode == 401 || error.statusCode == 404) {
        await _expireSession('Your session has expired. Please log in again.');
      } else {
        // Keep a previously issued token through temporary connectivity
        // failures. It will be validated again when the app resumes.
        state = AuthState(
          isRestoring: false,
          token: token,
          error: error.message,
        );
      }
    } catch (_) {
      if (!mounted || revision != _authRevision) return;
      state = AuthState(
          isRestoring: false,
          token: token,
          error: token == null
              ? null
              : 'Unable to verify your session. Please check your connection.');
    }
  }

  Future<bool> login({required String email, required String password}) =>
      _authenticate(() => _client.login(email: email, password: password));

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) =>
      _authenticate(() => _client.signup(
          name: name,
          email: email,
          password: password,
          referralCode: referralCode));

  Future<bool> facebookLogin({String? referralCode}) => _authenticate(() async {
        final service = FacebookSignInService();
        var accessToken = await service.signIn();
        if (accessToken == null) {
          throw const GameApiException('Facebook sign-in cancelled.');
        }
        try {
          return await _client.facebookLogin(accessToken,
              referralCode: referralCode);
        } on GameApiException catch (error) {
          if (error.statusCode != 401) rethrow;
          await service.logout();
          accessToken = await service.signIn();
          if (accessToken == null) {
            throw const GameApiException('Facebook sign-in cancelled.');
          }
          return _client.facebookLogin(accessToken, referralCode: referralCode);
        }
      });

  Future<void> expireSession() =>
      _expireSession('Your session has expired. Please log in again.');

  Future<bool> _authenticate(Future<AuthResult> Function() request) async {
    if (state.isLoading) return false;
    final revision = ++_authRevision;
    final previous = state;
    state = AuthState(
      isLoading: true,
      isRestoring: false,
      token: state.token,
      user: state.user,
    );
    try {
      final result = await request();
      if (!mounted || revision != _authRevision) return false;
      await _changeStorage(() => _storage.write(result.token));
      if (!mounted || revision != _authRevision) return false;
      state = AuthState(
        isRestoring: false,
        token: result.token,
        user: result.user,
      );
      return true;
    } catch (error) {
      if (!mounted || revision != _authRevision) return false;
      state = AuthState(
        token: previous.token,
        user: previous.user,
        stats: previous.stats,
        history: previous.history,
        isRestoring: false,
        errorStatusCode: error is GameApiException ? error.statusCode : null,
        error: error is GameApiException
            ? error.message
            : error is TimeoutException
                ? 'The server did not respond within 15 seconds. Please try again.'
                : error is PlatformException
                    ? 'Your account was accepted, but this device could not save the secure session. Please restart the app and try again.'
                    : 'Unable to reach the login server. Check your connection and try again.',
      );
      return false;
    }
  }

  Future<void> logout() => _endSession();

  Future<bool> refreshSession() async {
    final revision = _authRevision;
    final token = state.token;
    if (!mounted || revision != _authRevision) return false;
    if (token == null || token.isEmpty) return false;
    final previous = state;
    try {
      final result = await _client.getMe(token);
      if (!mounted || revision != _authRevision) return false;
      state = AuthState(
        isRestoring: false,
        token: token,
        user: result.user,
        stats: result.stats,
        history: state.history,
      );
      return true;
    } on GameApiException catch (error) {
      if (!mounted || revision != _authRevision) return false;
      if (_endsSession(error)) {
        await _expireSession(error.message);
      } else {
        state = AuthState(
          isRestoring: false,
          token: token,
          user: previous.user,
          stats: previous.stats,
          history: previous.history,
          error: error.message,
        );
      }
      return false;
    } catch (_) {
      if (!mounted || revision != _authRevision) return false;
      state = AuthState(
        isRestoring: false,
        token: token,
        user: previous.user,
        stats: previous.stats,
        history: previous.history,
        error: 'Unable to connect to the server.',
      );
      return false;
    }
  }

  Future<bool> loadHistory() async {
    final token = state.token;
    if (token == null) return false;
    return _authenticated(() async {
      final results = await Future.wait<Object>([
        _client.getMe(token),
        _client.getHistory(token),
      ]);
      if (!mounted || state.token != token) return;
      final current = results[0] as CurrentUserResult;
      final history = results[1] as List<GameHistoryEntry>;
      state = AuthState(
        isRestoring: false,
        token: token,
        user: current.user,
        stats: current.stats,
        history: history,
      );
    });
  }

  Future<bool> updateProfile(
      {required String name, String? dateOfBirth, String? email}) async {
    final token = state.token;
    if (token == null) return false;
    return _authenticated(() async {
      final user = await _client.updateProfile(
        token: token,
        name: name,
        dateOfBirth: dateOfBirth,
        email: email,
      );
      if (!mounted || state.token != token) return;
      state = AuthState(
        isRestoring: false,
        token: token,
        user: user,
        stats: state.stats,
        history: state.history,
      );
    });
  }

  Future<String> changePassword(String currentPassword, String newPassword) =>
      _withToken(
          (token) => _client.changePassword(
              token: token,
              currentPassword: currentPassword,
              newPassword: newPassword),
          validateUnauthorized: true);

  Future<String> resendVerification() => _withToken(_client.resendVerification);

  Future<String> forgotPassword(String email) =>
      _client.forgotPassword(email.trim());

  Future<String> resetPassword(String resetToken, String newPassword) =>
      _client.resetPassword(token: resetToken, newPassword: newPassword);

  Future<bool> verifyEmail(String verificationToken) async {
    final revision = _authRevision;
    final previous = state;
    try {
      await _client.verifyEmail(verificationToken);
      if (!mounted || revision != _authRevision) return false;
      if (state.isAuthenticated) await refreshSession();
      return true;
    } catch (error) {
      if (!mounted || revision != _authRevision) return false;
      state = AuthState(
        isRestoring: false,
        token: previous.token,
        user: previous.user,
        stats: previous.stats,
        history: previous.history,
        error: error is GameApiException
            ? error.message
            : 'Unable to verify your email. Check your connection and retry.',
      );
      return false;
    }
  }

  Future<String> _withToken(Future<String> Function(String) request,
      {bool validateUnauthorized = false}) async {
    final revision = _authRevision;
    final token = state.token;
    if (token == null) throw const GameApiException('Please log in first.');
    try {
      return await request(token);
    } on GameApiException catch (error) {
      if (!mounted || revision != _authRevision) rethrow;
      if (_endsSession(error)) {
        if (validateUnauthorized && error.statusCode == 401) {
          // Password mismatch is also a 401; verify the session independently.
          try {
            await _client.getMe(token);
          } on GameApiException catch (check) {
            if (mounted && revision == _authRevision && _endsSession(check)) {
              await _expireSession(check.message);
            }
          } catch (_) {/* Retain session when verification is unavailable. */}
        } else {
          await _expireSession(error.message);
        }
      }
      rethrow;
    }
  }

  Future<bool> _authenticated(Future<void> Function() request) async {
    final revision = _authRevision;
    final previous = state;
    state = AuthState(
      isLoading: true,
      isRestoring: false,
      token: state.token,
      user: state.user,
      stats: state.stats,
      history: state.history,
    );
    try {
      await request();
      return mounted && revision == _authRevision;
    } on GameApiException catch (error) {
      if (!mounted || revision != _authRevision) return false;
      if (_endsSession(error)) {
        await _expireSession(error.message);
      } else {
        state = AuthState(
          isRestoring: false,
          token: previous.token,
          user: previous.user,
          stats: previous.stats,
          history: previous.history,
          error: error.message,
        );
      }
      return false;
    } catch (_) {
      if (!mounted || revision != _authRevision) return false;
      state = AuthState(
        isRestoring: false,
        token: previous.token,
        user: previous.user,
        stats: previous.stats,
        history: previous.history,
        error: 'Unable to connect to the server.',
      );
      return false;
    }
  }

  bool _endsSession(GameApiException error) =>
      error.statusCode == 401 || error.statusCode == 404;

  Future<void> _expireSession(String message) => _endSession(message: message);

  Future<void> _endSession({String? message}) async {
    _authRevision++;
    final token = state.token;
    // End access immediately, even when unregistering a device is offline.
    // Queue storage deletion before another login can save its new token.
    final clearing = _changeStorage(_storage.clear);
    final cleanup = Future<void>.sync(() async {
      try {
        await _beforeLogout?.call(token);
      } catch (_) {}
    });
    if (mounted) state = AuthState(isRestoring: false, error: message);
    await Future.wait([clearing, cleanup]);
  }
}
