import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../controllers/game_controller.dart';

class MultiplayerScreen extends ConsumerStatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  ConsumerState<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends ConsumerState<MultiplayerScreen> {
  final nameController = TextEditingController(text: 'Player');
  final codeController = TextEditingController();
  int maxPlayers = 4;

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<void> createRoom() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final success = await ref
        .read(gameControllerProvider.notifier)
        .createMultiplayerRoom(playerName: name, maxPlayers: maxPlayers);
    if (mounted) _finish(success);
  }

  Future<void> joinRoom() async {
    final name = nameController.text.trim();
    final code = codeController.text.trim();
    if (name.isEmpty || !RegExp(r'^\d{4}$').hasMatch(code)) {
      _message('Enter your name and a four-digit room code.');
      return;
    }
    final success = await ref
        .read(gameControllerProvider.notifier)
        .joinExistingGame(gameId: code, playerName: name);
    if (mounted) _finish(success);
  }

  void _finish(bool success) {
    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.waitingRoom);
    } else {
      _message(
        ref.read(gameControllerProvider).error ?? 'Unable to join the room.',
      );
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(gameControllerProvider).isLoading;
    return Scaffold(
      body: GameBackground(
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 18,
              child: GameCloseButton(onTap: Navigator.of(context).pop),
            ),
            Center(
              child: GlassPanel(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PRIVATE TEAM ROOM',
                      style: TextStyle(
                        fontFamily: 'Dirty Brush',
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Create a private table and share its 4-digit code, or join a teammate’s room.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      maxLength: 24,
                      decoration:
                          const InputDecoration(labelText: 'Player name'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: maxPlayers,
                            decoration:
                                const InputDecoration(labelText: 'Room size'),
                            items: const [
                              DropdownMenuItem(
                                  value: 2, child: Text('2 team members')),
                              DropdownMenuItem(
                                  value: 3, child: Text('3 team members')),
                              DropdownMenuItem(
                                  value: 4, child: Text('4 team members')),
                            ],
                            onChanged: (value) {
                              setState(() => maxPlayers = value ?? 4);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        GameButton(
                          text: loading ? 'Please wait' : 'Create room',
                          width: 170,
                          onTap: loading ? () {} : createRoom,
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('OR JOIN YOUR TEAM WITH A CODE'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: const InputDecoration(
                                labelText: '4-digit code'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GameButton(
                          text: loading ? 'Please wait' : 'Join room',
                          width: 170,
                          onTap: loading ? () {} : joinRoom,
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
