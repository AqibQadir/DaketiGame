import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/daketi_app.dart';
import 'core/services/audio_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioSettings.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(const ProviderScope(child: DaketiApp()));
}
