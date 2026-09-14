import 'dart:convert';

import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/game/data/game_api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const user = {
    'id': 'user-1',
    'name': 'Aqib',
    'email': 'aqib@example.com',
    'emailVerified': false,
    'role': 'user',
    'dateOfBirth': null,
    'createdAt': '2026-09-12T08:00:00.000Z',
  };

  test('signup sends the documented payload and parses the session', () async {
    late Map<String, dynamic> requestBody;
    final client = AuthRestClient(
      baseUrl: 'https://game.daketi.pk',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/signup');
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'success': true, 'token': 'jwt', 'user': user}),
          201,
        );
      }),
    );

    final result = await client.signup(
      name: 'Aqib',
      email: 'aqib@example.com',
      password: 'password123',
    );

    expect(requestBody, {
      'name': 'Aqib',
      'email': 'aqib@example.com',
      'password': 'password123',
    });
    expect(result.token, 'jwt');
    expect(result.user.name, 'Aqib');
  });

  test('login preserves the backend error message', () async {
    final client = AuthRestClient(
      baseUrl: 'https://game.daketi.pk',
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'success': false,
              'error': 'Invalid email or password',
            }),
            401,
          )),
    );

    expect(
      () => client.login(email: 'bad@example.com', password: 'wrongpass'),
      throwsA(
        isA<GameApiException>().having(
          (error) => error.message,
          'message',
          'Invalid email or password',
        ),
      ),
    );
  });

  test('getMe sends the stored token as a bearer token', () async {
    final client = AuthRestClient(
      baseUrl: 'https://game.daketi.pk',
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/me');
        expect(request.headers['authorization'], 'Bearer jwt');
        return http.Response(
          jsonEncode({
            'success': true,
            'user': user,
            'stats': {'games_played': 2, 'games_won': 1, 'total_score': 30}
          }),
          200,
        );
      }),
    );

    final result = await client.getMe('jwt');
    expect(result.user.email, 'aqib@example.com');
    expect(result.stats.gamesPlayed, 2);
  });

  test('history parses the documented mixed-case payload', () async {
    final client = AuthRestClient(
      baseUrl: 'https://game.daketi.pk',
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/me/history');
        expect(request.headers['authorization'], 'Bearer jwt');
        return http.Response(
            jsonEncode({
              'success': true,
              'history': [
                {
                  'game_id': '0472',
                  'player_name': 'Aqib',
                  'score': 42,
                  'is_winner': true,
                  'max_players': 4,
                  'played_at': '2026-09-11T18:04:22.118Z',
                  'opponents': [
                    {
                      'name': 'Bot',
                      'type': 'ai',
                      'score': 20,
                      'isWinner': false
                    }
                  ]
                }
              ]
            }),
            200);
      }),
    );
    final history = await client.getHistory('jwt');
    expect(history.single.gameId, '0472');
    expect(history.single.opponents.single.isWinner, false);
  });

  test('profile update always sends name and dateOfBirth', () async {
    final client = AuthRestClient(
      baseUrl: 'https://game.daketi.pk',
      client: MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.headers['authorization'], 'Bearer jwt');
        expect(jsonDecode(request.body),
            {'name': 'New Name', 'dateOfBirth': '1990-05-15'});
        return http.Response(
            jsonEncode({
              'success': true,
              'user': {...user, 'name': 'New Name', 'dateOfBirth': '1990-05-15'}
            }),
            200);
      }),
    );
    final updated = await client.updateProfile(
        token: 'jwt', name: 'New Name', dateOfBirth: '1990-05-15');
    expect(updated.name, 'New Name');
  });

  test('rate-limit errors preserve message and reset header', () async {
    final client = AuthRestClient(
      baseUrl: 'https://game.daketi.pk',
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'success': false,
              'error': 'Too many requests - please try again later'
            }),
            429,
            headers: {'ratelimit-reset': '60'},
          )),
    );
    expect(
      () => client.forgotPassword('aqib@example.com'),
      throwsA(isA<GameApiException>()
          .having((error) => error.statusCode, 'status', 429)
          .having((error) => error.message, 'message', contains('60'))),
    );
  });
}
