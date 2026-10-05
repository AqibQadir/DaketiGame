/// Only accept account actions from our HTTPS host (or the app's own scheme).
/// Tokens stay in memory and are never logged or persisted as route names.
class AccountLink {
  const AccountLink({this.referralCode, this.resetToken, this.verifyToken});
  final String? referralCode, resetToken, verifyToken;
  static AccountLink? parse(Uri uri) {
    if (!((uri.scheme == 'https' && uri.host == 'game.daketi.pk') ||
        (uri.scheme == 'daketi' && uri.host == 'account'))) {
      return null;
    }
    String? value(String key) {
      final v = uri.queryParameters[key]?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    final reset = value('resetToken'),
        verify = value('verifyToken'),
        referral = value('ref');
    if (reset == null && verify == null && referral == null) return null;
    if (reset != null && verify != null) return null;
    return AccountLink(
        referralCode: referral, resetToken: reset, verifyToken: verify);
  }
}
