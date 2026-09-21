import 'package:flutter/material.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/guest_name_provider.dart';
import '../widgets/room_code_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_alert.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../controllers/game_controller.dart';

class MultiplayerScreen extends ConsumerStatefulWidget {
  const MultiplayerScreen({
    super.key,
    this.initialPlayerName = '',
  });

  final String initialPlayerName;

  @override
  ConsumerState<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends ConsumerState<MultiplayerScreen> {
  final codeController = TextEditingController();
  int maxPlayers = 4;

  String get playerName => (ref.read(authControllerProvider).user?.name ??
          (widget.initialPlayerName.trim().isNotEmpty
              ? widget.initialPlayerName
              : null) ??
          ref.read(guestNameProvider) ??
          '')
      .trim();

  bool ensureIdentity() {
    if (playerName.isNotEmpty) return true;
    Navigator.pushNamed(context, AppRoutes.guestName);
    return false;
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> createRoom() async {
    if (!ensureIdentity()) return;
    final name = playerName;
    final success = await ref
        .read(gameControllerProvider.notifier)
        .createMultiplayerRoom(playerName: name, maxPlayers: maxPlayers);
    if (mounted) _finish(success);
  }

  Future<void> joinRoom() async {
    if (!ensureIdentity()) return;
    final name = playerName;
    final code = codeController.text.trim();
    if (name.isEmpty || !RegExp(r'^\d{4}$').hasMatch(code)) {
      _message('Enter a four-digit room code.');
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
    showGameAlert(context, value);
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
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 70),
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
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final count in [2, 3, 4])
                                  Semantics(
                                    label: '$count players',
                                    button: true,
                                    selected: maxPlayers == count,
                                    child: InkWell(
                                      onTap: loading
                                          ? null
                                          : () => setState(
                                              () => maxPlayers = count),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 84,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: maxPlayers == count
                                              ? const Color(0x332D1905)
                                              : Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: maxPlayers == count
                                                  ? const Color(0xFFFF8500)
                                                  : Colors.white24,
                                              width:
                                                  maxPlayers == count ? 2 : 1),
                                        ),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: List.generate(
                                                      count,
                                                      (_) => Icon(Icons.person,
                                                          size: 16,
                                                          color: maxPlayers ==
                                                                  count
                                                              ? const Color(
                                                                  0xFFFFAC50)
                                                              : Colors
                                                                  .white60))),
                                              const SizedBox(height: 6),
                                              Text('$count PLAYERS',
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white)),
                                            ]),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GameButton(
                            text: loading ? 'Please wait' : 'Create room',
                            width: 170,
                            onTap: loading ? null : createRoom,
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
                            child: RoomCodeInput(
                                controller: codeController,
                                enabled: !loading,
                                onSubmitted: (_) => joinRoom()),
                          ),
                          const SizedBox(width: 12),
                          GameButton(
                            text: loading ? 'Please wait' : 'Join room',
                            width: 170,
                            onTap: loading ? null : joinRoom,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
