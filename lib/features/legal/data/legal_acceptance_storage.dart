import 'package:shared_preferences/shared_preferences.dart';

class LegalAcceptanceStorage {
  // Increment this suffix whenever users must accept materially updated terms.
  static const _acceptanceKey = 'legal_terms_accepted_v1';

  Future<bool> isAccepted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_acceptanceKey) ?? false;
  }

  Future<void> markAccepted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_acceptanceKey, true);
  }
}
