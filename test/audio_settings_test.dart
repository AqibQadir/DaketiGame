import 'package:daketi_phase1_modular/core/services/audio_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:daketi_phase1_modular/features/settings/presentation/screens/settings_screen.dart';
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
  test('volume persists, clamps, mutes at zero, and respects the legacy mute',
      () async {
    SharedPreferences.setMockInitialValues({'audio_music': false});
    await AudioSettings.initialize();
    expect(AudioSettings.effectiveMusicVolume, 0);
    await AudioSettings.setMusicVolume(.35);
    AudioSettings.musicVolume.value = 1;
    await AudioSettings.initialize();
    expect(AudioSettings.effectiveMusicVolume, .35);
    await AudioSettings.setMusicVolume(-1);
    expect(AudioSettings.effectiveMusicVolume, 0);
    expect(AudioSettings.music.value, isFalse);
    await AudioSettings.setMusicVolume(2);
    expect(AudioSettings.effectiveMusicVolume, 1);
  });
  testWidgets('settings replaces media with a music slider and retains toggles',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AudioSettings.initialize();
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('MEDIA'), findsNothing);
    expect(find.text('LANGUAGE'), findsNothing);
    expect(find.byType(Switch), findsNWidgets(2));
    final slider = find.byType(Slider);
    await tester.tapAt(tester.getCenter(slider));
    await tester.pumpAndSettle();
    expect(AudioSettings.effectiveMusicVolume, closeTo(.5, .05));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
