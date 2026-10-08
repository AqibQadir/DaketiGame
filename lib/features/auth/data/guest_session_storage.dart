import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GuestSessionStorage {
  static const key = 'daketi_guest_session';
  static const duration = Duration(days: 30);

  Future<String?> read({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final name = (data['name'] as String).trim();
      final expires = DateTime.parse(data['expires'] as String);
      if (name.isNotEmpty && (now ?? DateTime.now()).isBefore(expires)) {
        return name;
      }
    } catch (_) {/* Invalid stored sessions are discarded. */}
    await prefs.remove(key);
    return null;
  }

  Future<void> save(String name, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
        key,
        jsonEncode({
          'name': name.trim(),
          'expires':
              (now ?? DateTime.now()).add(duration).toUtc().toIso8601String(),
        }));
    if (!saved) throw StateError('Unable to save guest session');
  }
}
