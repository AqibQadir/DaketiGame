import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/game_icon_button.dart';
import '../../../game/presentation/controllers/game_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget buildCounter({
    required IconData icon,
    required String value,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.tileBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.orange,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                left: 16,
                top: 12,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE0CDB9),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF4D3324),
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE FULL NAME',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'PERSONAL',
                          style: TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                left: 310,
                right: 90,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildCounter(
                      icon: Icons.shopping_cart,
                      value: 'BUY COINS',
                    ),
                    const SizedBox(width: 10),
                    buildCounter(
                      icon: Icons.monetization_on,
                      value: '125,000',
                    ),
                    const SizedBox(width: 10),
                    buildCounter(
                      icon: Icons.account_balance_wallet,
                      value: '125,000',
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: 12,
                child: GameIconButton(
                  icon: Icons.menu,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.settings,
                    );
                  },
                ),
              ),
              Positioned(
                left: 18,
                top: 88,
                child: Column(
                  children: [
                    GameIconButton(
                      icon: Icons.emoji_events,
                      label: 'Missions',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.sideQuests);
                      },
                    ),
                    const SizedBox(height: 14),
                    GameIconButton(
                      icon: Icons.calendar_month,
                      label: 'Daily',
                      badge: '2',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 18,
                top: 88,
                child: Column(
                  children: [
                    GameIconButton(
                      icon: Icons.home_work_outlined,
                      label: 'Clan',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.baithak);
                      },
                    ),
                    const SizedBox(height: 14),
                    GameIconButton(
                      icon: Icons.storefront,
                      label: 'Shop',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.dukan);
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                bottom: 16,
                child: Row(
                  children: [
                    GameIconButton(
                      icon: Icons.settings,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.settings,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GameIconButton(
                      icon: Icons.person,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.profile,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GameIconButton(
                      icon: Icons.support_agent,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.support,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 18,
                bottom: 16,
                child: Row(
                  children: [
                    GameIconButton(
                      icon: Icons.groups,
                      label: 'Teams',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.tables);
                      },
                    ),
                    const SizedBox(width: 12),
                    GameIconButton(
                      icon: Icons.workspace_premium,
                      label: 'Ranking',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GameButton(
                    text: session.isLoading ? 'Connecting' : 'Start game',
                    width: 180,
                    onTap: session.isLoading
                        ? () {}
                        : () async {
                            final setup = await showDialog<_SoloSetup>(
                              context: context,
                              builder: (_) => const _SoloSetupDialog(),
                            );
                            if (setup == null || !context.mounted) return;
                            final success = await ref
                                .read(gameControllerProvider.notifier)
                                .createSoloGame(
                                  playerName: setup.playerName,
                                  aiCount: setup.aiCount,
                                );
                            if (!context.mounted) return;
                            if (success) {
                              Navigator.pushNamed(context, AppRoutes.game);
                            } else {
                              final message =
                                  ref.read(gameControllerProvider).error ??
                                      'Unable to start the game.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoloSetup {
  const _SoloSetup(this.playerName, this.aiCount);

  final String playerName;
  final int aiCount;
}

class _SoloSetupDialog extends StatefulWidget {
  const _SoloSetupDialog();

  @override
  State<_SoloSetupDialog> createState() => _SoloSetupDialogState();
}

class _SoloSetupDialogState extends State<_SoloSetupDialog> {
  final TextEditingController nameController =
      TextEditingController(text: 'Player');
  int aiCount = 1;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xEE181411),
      title: const Text('START SOLO GAME'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            maxLength: 24,
            decoration: const InputDecoration(labelText: 'Player name'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: aiCount,
            decoration: const InputDecoration(labelText: 'AI opponents'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 opponent')),
              DropdownMenuItem(value: 2, child: Text('2 opponents')),
              DropdownMenuItem(value: 3, child: Text('3 opponents')),
            ],
            onChanged: (value) => setState(() => aiCount = value ?? 1),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(_SoloSetup(name, aiCount));
          },
          child: const Text('CREATE'),
        ),
      ],
    );
  }
}
