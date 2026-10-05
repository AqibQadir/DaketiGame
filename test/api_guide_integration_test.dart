import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_token_storage.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/game/data/game_api_exception.dart';
import 'package:daketi_phase1_modular/features/access/presentation/access_controller.dart';
import 'package:daketi_phase1_modular/features/access/data/access_models.dart';
import 'package:daketi_phase1_modular/core/services/account_links.dart';

class MemoryAuthStorage extends AuthTokenStorage {
  String? token = 'jwt';
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

http.Response jsonResponse(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);
const user = {'id': 'account-1', 'name': 'Ali', 'email': 'ali@example.com'};
void main() {
  test(
      'signup passes optional referral; Facebook accepts nullable email and sign-in flags',
      () async {
    final requests = <http.Request>[];
    final client = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async {
          requests.add(r);
          return jsonResponse({
            'success': true,
            'token': 'jwt',
            'user': {
              ...user,
              'email': null,
              'facebookLinked': true,
              'hasPassword': false
            }
          });
        }));
    addTearDown(client.dispose);
    await client.signup(
        name: 'Ali',
        email: 'ali@example.com',
        password: 'password1',
        referralCode: ' abc23456 ');
    expect(jsonDecode(requests.first.body)['referralCode'], 'abc23456');
    final result = await client.facebookLogin('facebook-access-token');
    expect(requests.last.url.path, '/api/auth/facebook');
    expect(
        jsonDecode(requests.last.body)['accessToken'], 'facebook-access-token');
    expect(result.user.needsEmail, isTrue);
    expect(result.user.hasPassword, isFalse);
    expect(result.user.facebookLinked, isTrue);
  });
  test(
      'device deletion sends authenticated JSON and public referral checks omit auth',
      () async {
    final requests = <http.Request>[];
    final client = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async {
          requests.add(r);
          return jsonResponse({'success': true});
        }));
    addTearDown(client.dispose);
    await client.request('POST', '/api/devices',
        token: 'jwt', body: {'token': 'fcm', 'platform': 'ios'});
    await client.request('DELETE', '/api/devices',
        token: 'jwt', body: {'token': 'fcm'});
    await client.validateReferral('abCD2345');
    expect(requests[1].method, 'DELETE');
    expect(requests[1].headers['Authorization'], 'Bearer jwt');
    expect(jsonDecode(requests[1].body), {'token': 'fcm'});
    expect(requests[2].headers['Authorization'], isNull);
    expect(requests[2].url.path, '/api/referrals/validate/abCD2345');
  });
  test(
      'launch flow joins once, refreshes authoritative status and checks canPlay',
      () async {
    final paths = <String>[];
    final client = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async {
          paths.add('${r.method} ${r.url.path}');
          if (r.url.path == '/api/play/eligibility') {
            return jsonResponse(
                {'success': true, 'status': 'invited', 'canPlay': false});
          }
          return jsonResponse({
            'success': true,
            'waitlist': {
              'status': 'invited',
              'position': 12,
              'canPlay': false,
              'referralCount': 2,
              'pendingReferralCount': 3
            }
          });
        }));
    final controller =
        AccessController(client, 'jwt', onUnauthorized: () async {});
    addTearDown(() {
      controller.dispose();
      client.dispose();
    });
    await controller.refresh();
    expect(paths.first, 'POST /api/waitlist/join');
    expect(paths.where((p) => p.startsWith('POST')).length, 1);
    expect(controller.state.waitlist?.position, isNull);
    expect(controller.state.waitlist?.pendingReferralCount, 3);
    expect(await controller.checkEligibility(), isFalse);
    await controller.refresh();
    expect(controller.state.waitlist?.canPlay, isFalse);
  });
  test('canPlay is authoritative even for an unfamiliar status', () {
    final value = WaitlistStatus.fromJson(
        {'status': 'future_status', 'canPlay': true, 'position': 4});
    expect(value.canPlay, isTrue);
    expect(value.position, isNull);
  });
  test(
      'expired launch session invokes expiration; network failure never grants access',
      () async {
    var expired = 0;
    final client = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async =>
            jsonResponse({'success': false, 'error': 'Expired'}, 401)));
    final controller =
        AccessController(client, 'jwt', onUnauthorized: () async {
      expired++;
    });
    addTearDown(() {
      controller.dispose();
      client.dispose();
    });
    await controller.refresh();
    expect(expired, 1);
    expect(controller.state.waitlist, isNull);
    expect(controller.state.error, 'Expired');
  });
  test('wrong current password does not clear a valid account session',
      () async {
    final client = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async {
          if (r.url.path.endsWith('change-password')) {
            return jsonResponse(
                {'success': false, 'error': 'Current password is incorrect'},
                401);
          }
          return jsonResponse({'success': true, 'user': user, 'stats': {}});
        }));
    final storage = MemoryAuthStorage();
    final controller = AuthController(client: client, storage: storage);
    addTearDown(() {
      controller.dispose();
      client.dispose();
    });
    await Future<void>.delayed(Duration.zero);
    await expectLater(controller.changePassword('wrong', 'new-password'),
        throwsA(isA<GameApiException>()));
    expect(controller.state.isAuthenticated, isTrue);
    expect(storage.token, 'jwt');
  });
  test('in-flight account refresh cannot resurrect a logged-out session',
      () async {
    final response = Completer<http.Response>();
    var count = 0;
    final client = AuthRestClient(
        baseUrl: 'https://example.test',
        client: MockClient((r) async {
          count++;
          if (count > 1) return response.future;
          return jsonResponse({'success': true, 'user': user, 'stats': {}});
        }));
    final storage = MemoryAuthStorage();
    final controller = AuthController(client: client, storage: storage);
    addTearDown(() {
      controller.dispose();
      client.dispose();
    });
    await Future<void>.delayed(Duration.zero);
    final refreshing = controller.refreshSession();
    await Future<void>.delayed(Duration.zero);
    await controller.logout();
    response
        .complete(jsonResponse({'success': true, 'user': user, 'stats': {}}));
    expect(await refreshing, isFalse);
    expect(controller.state.isAuthenticated, isFalse);
    expect(storage.token, isNull);
  });
  test('account link parser accepts only supported trusted origins and actions',
      () {
    expect(
        AccountLink.parse(Uri.parse('https://game.daketi.pk/?ref=ABCD2345'))
            ?.referralCode,
        'ABCD2345');
    expect(
        AccountLink.parse(Uri.parse('daketi://account?resetToken=secret'))
            ?.resetToken,
        'secret');
    expect(AccountLink.parse(Uri.parse('https://evil.test/?resetToken=secret')),
        isNull);
    expect(
        AccountLink.parse(Uri.parse('https://game.daketi.pk.evil.test/?ref=a')),
        isNull);
    expect(
        AccountLink.parse(Uri.parse('http://game.daketi.pk/?ref=a')), isNull);
    expect(
        AccountLink.parse(
            Uri.parse('https://game.daketi.pk/?verifyToken=a&resetToken=b')),
        isNull);
  });
}
