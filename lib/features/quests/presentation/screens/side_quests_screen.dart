import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_close_button.dart';

enum _QuestTier { rookie, champion, legend }

class SideQuestsScreen extends StatefulWidget {
  const SideQuestsScreen({super.key});

  @override
  State<SideQuestsScreen> createState() => _SideQuestsScreenState();
}

class _SideQuestsScreenState extends State<SideQuestsScreen> {
  _QuestTier selectedTier = _QuestTier.rookie;

  static const rookieQuests = [
    ('INVITE YOUR THREE FRIENDS', '100'),
    ('MAKE 10 LOGIN STREAKS', '100'),
    ('MAKE YOUR OWN BAITHAK', '100'),
    ('WIN THREE MATCHES', '100'),
    ('PRACTICE WITH OUR BOT', '100'),
    ('DRAW 10 CARDS', '100'),
  ];

  static const championQuests = [
    ('STEAL 2 OPPONENT CARDS', '500'),
    ('CAPTURE 5 CARDS IN A MATCH', '500'),
    ('PROTECT YOUR STACK ONCE', '500'),
    ('WIN WITHOUT USING ASSISTANCE', '500'),
    ('CREATE 3 COMBOS', '500'),
    ('BUILD STACKS 5 TIMES', '500'),
  ];

  static const legendQuests = [
    ('CAPTURE 100 CARDS THIS WEEK', '1000'),
    ('WIN WITHOUT LOSING A STACK', '1000'),
    ('TRIGGER 50 COMBO ACTIONS', '1000'),
    ('STEAL 3 TIMES IN ONE MATCH', '1000'),
    ('FINISH 20 MATCHES', '1000'),
    ('WIN 10 RANKED GAMES', '1000'),
  ];

  List<(String, String)> get quests => switch (selectedTier) {
        _QuestTier.rookie => rookieQuests,
        _QuestTier.champion => championQuests,
        _QuestTier.legend => legendQuests,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        overlayOpacity: .20,
        child: Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 844,
              height: 390,
              child: Stack(
                children: [
                  Positioned(
                    left: 27,
                    top: 25,
                    child: Row(
                      children: [
                        GameCloseButton(
                          size: 38,
                          onTap: Navigator.of(context).pop,
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'SIDE QUEST',
                          style: TextStyle(
                            fontFamily: 'Dirty Brush',
                            fontSize: 22,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 34,
                    top: 24,
                    child: Row(
                      children: [
                        _BalancePill(
                          icon: Icons.monetization_on,
                          label: 'Buy Coins',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.dukan);
                          },
                        ),
                        const SizedBox(width: 14),
                        const _BalancePill(
                          icon: Icons.stars_rounded,
                          label: '125,000',
                          showAdd: true,
                        ),
                        const SizedBox(width: 14),
                        const _BalancePill(
                          icon: Icons.handshake,
                          label: '25,000',
                          showAdd: true,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 39,
                    right: 39,
                    top: 99,
                    child: Container(
                      height: 230,
                      padding: const EdgeInsets.fromLTRB(42, 20, 53, 23),
                      decoration: BoxDecoration(
                        color: const Color(0xDF080706),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 22,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _TierButton(
                                label: 'ROOKIE',
                                selected: selectedTier == _QuestTier.rookie,
                                onTap: () => setState(
                                  () => selectedTier = _QuestTier.rookie,
                                ),
                              ),
                              const SizedBox(width: 26),
                              _TierButton(
                                label: 'CHAMPION',
                                selected: selectedTier == _QuestTier.champion,
                                onTap: () => setState(
                                  () => selectedTier = _QuestTier.champion,
                                ),
                              ),
                              const SizedBox(width: 26),
                              _TierButton(
                                label: 'LEGEND',
                                selected: selectedTier == _QuestTier.legend,
                                onTap: () => setState(
                                  () => selectedTier = _QuestTier.legend,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  right: 17,
                                  child: GridView.builder(
                                    padding: EdgeInsets.zero,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 17,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 9.4,
                                    ),
                                    itemCount: quests.length,
                                    itemBuilder: (context, index) {
                                      final quest = quests[index];
                                      return _QuestRow(
                                        label: quest.$1,
                                        reward: quest.$2,
                                      );
                                    },
                                  ),
                                ),
                                const Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: _QuestScrollBar(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TierButton extends StatelessWidget {
  const _TierButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 89,
        height: 27,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xB9454545) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: selected ? Border.all(color: Colors.white30) : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Dirty Brush',
            fontSize: 14,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.label, required this.reward});

  final String label;
  final String reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 2, 5, 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xC54A4A4A), Color(0xA7161616)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 48),
            height: 23,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF18325),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFBE78)),
            ),
            child: Text(
              reward,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({
    required this.icon,
    required this.label,
    this.showAdd = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool showAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: EdgeInsets.only(left: 8, right: showAdd ? 4 : 10),
        decoration: BoxDecoration(
          color: const Color(0xDB46311F),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.tileBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.orange),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            if (showAdd) ...[
              const SizedBox(width: 7),
              Container(
                width: 21,
                height: 21,
                color: AppColors.orange,
                child: const Icon(Icons.add, size: 17, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestScrollBar extends StatelessWidget {
  const _QuestScrollBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      padding: const EdgeInsets.all(2),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: const Color(0xA8343434),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white30),
      ),
      child: Container(
        width: 6,
        height: 19,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [BoxShadow(color: Colors.orange, blurRadius: 4)],
        ),
      ),
    );
  }
}
