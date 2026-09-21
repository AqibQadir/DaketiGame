import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/backend_config.dart';
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
  });

  final bool isLoading;
  final bool isRestoring;
  final String? token;
  final AuthUser? user;
  final AuthStats stats;
  final List<GameHistoryEntry> history;
  final String? error;

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
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRestClient client,
    required AuthTokenStorage storage,
  })  : _client = client,
        _storage = storage,
        super(const AuthState()) {
    restoreSession();
  }

  final AuthRestClient _client;
  final AuthTokenStorage _storage;
  int _authRevision = 0;

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
        await _storage.clear();
        state = const AuthState(isRestoring: false);
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
      state = const AuthState(isRestoring: false);
    }
  }

  Future<bool> login({required String email, required String password}) =>
      _authenticate(() => _client.login(email: email, password: password));

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) =>
      _authenticate(
          () => _client.signup(name: name, email: email, password: password));

  Future<bool> _authenticate(Future<AuthResult> Function() request) async {
    if (state.isLoading) return false;
    _authRevision++;
    state = AuthState(
      isLoading: true,
      isRestoring: false,
      token: state.token,
      user: state.user,
    );
    try {
      final result = await request();
      await _storage.write(result.token);
      state = AuthState(
        isRestoring: false,
        token: result.token,
        user: result.user,
      );
      return true;
    } catch (error) {
      state = AuthState(
        isRestoring: false,
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

  Future<void> logout() async {
    _authRevision++;
    await _storage.clear();
    state = const AuthState(isRestoring: false);
  }

  Future<bool> refreshSession() async {
    final token = state.token ?? await _storage.read();
    if (token == null || token.isEmpty) return false;
    final previous = state;
    try {
      final result = await _client.getMe(token);
      state = AuthState(
        isRestoring: false,
        token: token,
        user: result.user,
        stats: result.stats,
        history: state.history,
      );
      return true;
    } on GameApiException catch (error) {
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
      {required String name, String? dateOfBirth}) async {
    final token = state.token;
    if (token == null) return false;
    return _authenticated(() async {
      final user = await _client.updateProfile(
        token: token,
        name: name,
        dateOfBirth: dateOfBirth,
      );
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
      _withToken((token) => _client.changePassword(
          token: token,
          currentPassword: currentPassword,
          newPassword: newPassword));

  Future<String> resendVerification() => _withToken(_client.resendVerification);

  Future<String> forgotPassword(String email) =>
      _client.forgotPassword(email.trim());

  Future<String> resetPassword(String resetToken, String newPassword) =>
      _client.resetPassword(token: resetToken, newPassword: newPassword);

  Future<bool> verifyEmail(String verificationToken) async {
    final previous = state;
    try {
      final user = await _client.verifyEmail(verificationToken);
      state = AuthState(
        isRestoring: false,
        token: state.token,
        user: user,
        stats: state.stats,
        history: state.history,
      );
      return true;
    } on GameApiException catch (error) {
      state = AuthState(
        isRestoring: false,
        token: previous.token,
        user: previous.user,
        stats: previous.stats,
        history: previous.history,
        error: error.message,
      );
      return false;
    }
  }

  Future<String> _withToken(Future<String> Function(String) request) async {
    final token = state.token;
    if (token == null) throw const GameApiException('Please log in first.');
    try {
      return await request(token);
    } on GameApiException catch (error) {
      if (_endsSession(error)) await _expireSession(error.message);
      rethrow;
    }
  }

  Future<bool> _authenticated(Future<void> Function() request) async {
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
      return true;
    } on GameApiException catch (error) {
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

  Future<void> _expireSession(String message) async {
    await _storage.clear();
    state = AuthState(isRestoring: false, error: message);
  }
}
