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
  double musicVolume = AudioSettings.effectiveMusicVolume;
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
                              Row(children: [
                                const Icon(Icons.music_note, size: 19),
                                const SizedBox(width: 6),
                                const Expanded(
                                    child: Text('MUSIC',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic))),
                                Text('${(musicVolume * 100).round()}%'),
                              ]),
                              Slider(
                                value: musicVolume,
                                activeColor: AppColors.green,
                                label: '${(musicVolume * 100).round()}%',
                                semanticFormatterCallback: (value) =>
                                    'Music volume ${(value * 100).round()} percent',
                                onChanged: (value) {
                                  setState(() => musicVolume = value);
                                  AudioSettings.setMusicVolume(value);
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
