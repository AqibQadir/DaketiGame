import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../game/data/game_api_exception.dart';
import '../domain/auth_user.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class CurrentUserResult {
  const CurrentUserResult({required this.user, required this.stats});
  final AuthUser user;
  final AuthStats stats;
}

class AuthRestClient {
  AuthRestClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _authResult(response);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _authResult(response);
  }

  Future<CurrentUserResult> getMe(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    return CurrentUserResult(
      user: AuthUser.fromJson(_map(data['user'], 'user')),
      stats: AuthStats.fromJson(_map(data['stats'] ?? const {}, 'stats')),
    );
  }

  Future<List<GameHistoryEntry>> getHistory(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/auth/me/history'),
      headers: _authHeaders(token),
    );
    final data = _decode(response);
    return (data['history'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => GameHistoryEntry.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value))))
        .toList(growable: false);
  }

  Future<AuthUser> updateProfile({
    required String token,
    required String name,
    String? dateOfBirth,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _authHeaders(token, json: true),
      body: jsonEncode({'name': name, 'dateOfBirth': dateOfBirth}),
    );
    return AuthUser.fromJson(_map(_decode(response)['user'], 'user'));
  }

  Future<String> changePassword(
          {required String token,
          required String currentPassword,
          required String newPassword}) =>
      _message(_client.post(Uri.parse('$baseUrl/api/auth/change-password'),
          headers: _authHeaders(token, json: true),
          body: jsonEncode({
            'currentPassword': currentPassword,
            'newPassword': newPassword
          })));

  Future<String> forgotPassword(String email) =>
      _message(_client.post(Uri.parse('$baseUrl/api/auth/forgot-password'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email})));

  Future<String> resetPassword(
          {required String token, required String newPassword}) =>
      _message(_client.post(Uri.parse('$baseUrl/api/auth/reset-password'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'token': token, 'newPassword': newPassword})));

  Future<AuthUser> verifyEmail(String verificationToken) async {
    final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/verify-email'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'token': verificationToken}));
    return AuthUser.fromJson(_map(_decode(response)['user'], 'user'));
  }

  Future<String> resendVerification(String token) =>
      _message(_client.post(Uri.parse('$baseUrl/api/auth/resend-verification'),
          headers: _authHeaders(token)));

  Future<String> _message(Future<http.Response> request) async =>
      (await _decodeFuture(request))['message']?.toString() ?? 'Success';

  Future<Map<String, dynamic>> _decodeFuture(
          Future<http.Response> request) async =>
      _decode(await request);

  Map<String, String> _authHeaders(String token, {bool json = false}) => {
        'Authorization': 'Bearer $token',
        if (json) 'Content-Type': 'application/json',
      };

  AuthResult _authResult(http.Response response) {
    final data = _decode(response);
    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw const GameApiException('The server did not return a login token.');
    }
    return AuthResult(
      token: token,
      user: AuthUser.fromJson(_map(data['user'], 'user')),
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = _map(jsonDecode(response.body), 'response');
    } on FormatException {
      throw GameApiException(
        'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final reset = response.headers['ratelimit-reset'];
      final message = data['error']?.toString() ?? 'Authentication failed.';
      throw GameApiException(
        response.statusCode == 429 && reset != null
            ? '$message Try again after $reset.'
            : message,
        statusCode: response.statusCode,
      );
    }
    if (data['success'] == false) {
      throw GameApiException(data['error']?.toString() ?? 'Request failed.');
    }
    return data;
  }

  Map<String, dynamic> _map(Object? value, String name) {
    if (value is! Map) throw FormatException('$name is not an object');
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  void dispose() => _client.close();
}
