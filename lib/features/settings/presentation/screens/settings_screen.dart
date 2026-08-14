import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool music = true;
  bool media = false;
  bool vibration = false;
  bool notification = true;
  String language = 'English';

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
                    GameButton(
                      text: 'Tutorial',
                      width: 190,
                      onTap: () {},
                    ),
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
                                  });
                                },
                              ),
                              toggleRow(
                                label: 'Media',
                                value: media,
                                onChanged: (value) {
                                  setState(() {
                                    media = value;
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'LANGUAGE',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        DropdownButton<String>(
                          value: language,
                          dropdownColor: Colors.black,
                          items: const [
                            DropdownMenuItem(
                              value: 'English',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'Urdu',
                              child: Text('Urdu'),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value == null) return;

                            setState(() {
                              language = value;
                            });
                          },
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
