import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSettings {
  AudioSettings._();
  static final music = ValueNotifier<bool>(true);
  static final musicVolume = ValueNotifier<double>(1);
  static double get effectiveMusicVolume => music.value ? musicVolume.value : 0;
  static final media = ValueNotifier<bool>(true);
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    music.value = prefs.getBool('audio_music') ?? true;
    media.value = prefs.getBool('audio_media') ?? true;
    musicVolume.value =
        (prefs.getDouble('audio_music_volume') ?? 1).clamp(0.0, 1.0);
  }

  static Future<void> setMusic(bool enabled) async {
    music.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_music', enabled);
  }

  static Future<void> setMusicVolume(double value) async {
    final volume = value.clamp(0.0, 1.0);
    musicVolume.value = volume;
    music.value = volume > 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_music_volume', volume);
    await prefs.setBool('audio_music', volume > 0);
  }

  static Future<void> setMedia(bool enabled) async {
    media.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_media', enabled);
  }
}
