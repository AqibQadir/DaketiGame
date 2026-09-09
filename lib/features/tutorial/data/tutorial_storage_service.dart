import 'package:shared_preferences/shared_preferences.dart';

class TutorialStorageService {
  static const _completionKey = 'game_tutorial_completed_v1';

  Future<bool> isCompleted() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(_completionKey) ?? false;
    } catch (_) {
      // A newly-added platform plugin can be unavailable until the host app is
      // restarted. Never leave the user trapped on the legal screen.
      return false;
    }
  }

  Future<void> markCompleted() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_completionKey, true);
    } catch (_) {
      // Navigation must still complete if local persistence is unavailable.
    }
  }
}
