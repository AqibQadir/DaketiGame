import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../features/game/data/game_api_exception.dart';

class FacebookSignInService {
  static const enabled = bool.fromEnvironment('FACEBOOK_ENABLED');
  Future<String?> signIn() async {
    if (!enabled) {
      throw const GameApiException('Facebook sign-in is not available yet.');
    }
    final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginTracking: LoginTracking.enabled);
    if (result.status == LoginStatus.cancelled) return null;
    final token = result.accessToken;
    if (result.status != LoginStatus.success || token == null) {
      throw const GameApiException(
          'Facebook sign-in could not finish. Please try again.');
    }
    // The documented backend accepts Graph API access tokens, not iOS Limited
    // Login JWTs. Do not send an unsupported token as if it were a usable login.
    if (token.type == AccessTokenType.limited) {
      throw const GameApiException(
          'Facebook sign-in is not available on this device yet. Please sign in with email for now.');
    }
    return token.tokenString;
  }

  Future<void> logout() => FacebookAuth.instance.logOut();
}
