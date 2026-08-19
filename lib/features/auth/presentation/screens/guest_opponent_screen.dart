import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../game/presentation/controllers/game_controller.dart';

class GuestOpponentScreen extends ConsumerStatefulWidget {
  const GuestOpponentScreen({
    super.key,
    required this.playerName,
  });

  final String playerName;

  @override
  ConsumerState<GuestOpponentScreen> createState() =>
      _GuestOpponentScreenState();
}

class _GuestOpponentScreenState extends ConsumerState<GuestOpponentScreen> {
  int opponents = 1;

  Future<void> startGame() async {
    final success = await ref
        .read(gameControllerProvider.notifier)
        .createSoloGame(playerName: widget.playerName, aiCount: opponents);
    if (!mounted) return;
    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.game,
        (route) => route.settings.name == AppRoutes.welcome,
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(gameControllerProvider).error ?? 'Unable to start the game.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(gameControllerProvider).isLoading;
    return Scaffold(
      body: GameBackground(
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 844,
              height: 390,
              child: Stack(children: [
                Positioned(
                  left: 20,
                  top: 18,
                  child: GameCloseButton(
                    size: 54,
                    onTap: Navigator.of(context).pop,
                  ),
                ),
                Center(
                  child: GlassPanel(
                    width: 470,
                    height: 255,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 38,
                      vertical: 26,
                    ),
                    child: Column(children: [
                      const Text(
                        'CHOOSE YOUR OPPONENTS',
                        style: TextStyle(
                          fontFamily: 'Dirty Brush',
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Playing as ${widget.playerName}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final count = index + 1;
                          final selected = opponents == count;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: InkWell(
                              onTap: () => setState(() => opponents = count),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 100,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xAA5A361E)
                                      : const Color(0xA31A1714),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.orange
                                        : AppColors.panelBorder,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      count == 1 ? Icons.person : Icons.groups,
                                      color: selected
                                          ? AppColors.orange
                                          : AppColors.cream,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$count ${count == 1 ? 'OPPONENT' : 'OPPONENTS'}',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      GameButton(
                        text: loading ? 'Starting' : 'Play',
                        width: 155,
                        onTap: loading ? () {} : startGame,
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
