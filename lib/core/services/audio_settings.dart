import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSettings {
  AudioSettings._();
  static final music = ValueNotifier<bool>(true);
  static final media = ValueNotifier<bool>(true);
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    music.value = prefs.getBool('audio_music') ?? true;
    media.value = prefs.getBool('audio_media') ?? true;
  }

  static Future<void> setMusic(bool enabled) async {
    music.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_music', enabled);
  }

  static Future<void> setMedia(bool enabled) async {
    media.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_media', enabled);
  }
}
