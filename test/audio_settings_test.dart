import 'package:daketi_phase1_modular/core/services/audio_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('music and media switches persist independently across initialization',
      () async {
    SharedPreferences.setMockInitialValues({});
    await AudioSettings.initialize();
    expect(AudioSettings.music.value, isTrue);
    expect(AudioSettings.media.value, isTrue);
    await AudioSettings.setMusic(false);
    await AudioSettings.setMedia(false);
    AudioSettings.music.value = true;
    AudioSettings.media.value = true;
    await AudioSettings.initialize();
    expect(AudioSettings.music.value, isFalse);
    expect(AudioSettings.media.value, isFalse);
    await AudioSettings.setMedia(true);
    await AudioSettings.initialize();
    expect(AudioSettings.music.value, isFalse);
    expect(AudioSettings.media.value, isTrue);
  });
}
