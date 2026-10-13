import 'package:flutter/material.dart';
import '../../../../core/services/audio_settings.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool music = AudioSettings.music.value;
  bool media = AudioSettings.media.value;
  bool vibration = false;
  bool notification = true;

  Widget toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.green,
          inactiveThumbColor: AppColors.red,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: Stack(
          children: [
            Positioned(
              left: 18,
              top: 18,
              child: GameCloseButton(
                onTap: Navigator.of(context).pop,
              ),
            ),
            Center(
              child: GlassPanel(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('SETTINGS',
                        style: TextStyle(
                            fontFamily: 'Dirty Brush',
                            fontSize: 27,
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              toggleRow(
                                label: 'Music',
                                value: music,
                                onChanged: (value) {
                                  setState(() {
                                    music = value;
                                    AudioSettings.setMusic(value);
                                  });
                                },
                              ),
                              toggleRow(
                                label: 'Media',
                                value: media,
                                onChanged: (value) {
                                  setState(() {
                                    media = value;
                                    AudioSettings.setMedia(value);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              toggleRow(
                                label: 'Vibration',
                                value: vibration,
                                onChanged: (value) {
                                  setState(() {
                                    vibration = value;
                                  });
                                },
                              ),
                              toggleRow(
                                label: 'Notification',
                                value: notification,
                                onChanged: (value) {
                                  setState(() {
                                    notification = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
