import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_close_button.dart';
import '../../../../core/widgets/glass_panel.dart';

enum _DukanTab { coins, xp, tables }

class DukanScreen extends StatefulWidget {
  const DukanScreen({super.key});

  @override
  State<DukanScreen> createState() => _DukanScreenState();
}

class _DukanScreenState extends State<DukanScreen> {
  _DukanTab selectedTab = _DukanTab.coins;

  static const coinItems = [
    ('Buy Coins', '50,000'),
    ('Buy Coins', '500,000'),
    ('Buy Coins', '100,000'),
    ('Buy Coins', '750,000'),
    ('Buy Coins', '250,000'),
    ('Buy Coins', '1,000,000'),
  ];

  static const xpItems = [
    ('Buy XP’s', '10,000'),
    ('Buy XP’s', '40,000'),
    ('Buy XP’s', '20,000'),
    ('Buy XP’s', '50,000'),
    ('Buy XP’s', '30,000'),
    ('Buy XP’s', '60,000'),
  ];

  static const tableItems = [
    ('ENTER OLD LAHORE', ''),
    ('ENTER THAI BLISS', ''),
    ('ENTER KARACHI CLAN', ''),
    ('ENTER DUBAI BLISS', ''),
    ('ENTER DUBAI RISE', ''),
    ('ENTER LONDON LOUNGE', ''),
  ];

  List<(String, String)> get items => switch (selectedTab) {
        _DukanTab.coins => coinItems,
        _DukanTab.xp => xpItems,
        _DukanTab.tables => tableItems,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        overlayOpacity: .23,
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
                    top: 26,
                    child: Row(
                      children: [
                        GameCloseButton(
                          size: 38,
                          onTap: Navigator.of(context).pop,
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'DUKAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Dirty Brush',
                            fontSize: 23,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 39,
                    right: 39,
                    top: 100,
                    child: GlassPanel(
                      width: 766,
                      height: 230,
                      padding: const EdgeInsets.fromLTRB(42, 24, 52, 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _TabButton(
                                label: 'COINS',
                                selected: selectedTab == _DukanTab.coins,
                                onTap: () => setState(
                                  () => selectedTab = _DukanTab.coins,
                                ),
                              ),
                              const SizedBox(width: 35),
                              _TabButton(
                                label: 'XP',
                                selected: selectedTab == _DukanTab.xp,
                                onTap: () => setState(
                                  () => selectedTab = _DukanTab.xp,
                                ),
                              ),
                              const SizedBox(width: 35),
                              _TabButton(
                                label: 'TABLES',
                                selected: selectedTab == _DukanTab.tables,
                                onTap: () => setState(
                                  () => selectedTab = _DukanTab.tables,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  right: 17,
                                  child: GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 8.5,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return _StoreRow(
                                        label: item.$1,
                                        amount: item.$2,
                                        showCoin:
                                            selectedTab == _DukanTab.coins,
                                        showHandshake:
                                            selectedTab == _DukanTab.xp,
                                      );
                                    },
                                  ),
                                ),
                                const Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: _DecorativeScrollBar(),
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

class _TabButton extends StatelessWidget {
  const _TabButton({
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 90,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xB53E3E3E) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: selected ? Border.all(color: Colors.white30) : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Dirty Brush',
            fontSize: 16,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.label,
    required this.amount,
    required this.showCoin,
    required this.showHandshake,
  });

  final String label;
  final String amount;
  final bool showCoin;
  final bool showHandshake;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 2, 4, 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xC74B4B4B), Color(0xAD161616)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (amount.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(
              showCoin
                  ? Icons.monetization_on
                  : showHandshake
                      ? Icons.handshake
                      : Icons.circle,
              color: AppColors.orange,
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Spacer(),
          Container(
            width: 51,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF58A2A),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFFFC987)),
            ),
            child: const Text(
              'Buy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
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

class _DecorativeScrollBar extends StatelessWidget {
  const _DecorativeScrollBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      decoration: BoxDecoration(
        color: const Color(0xAA303030),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white38),
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.all(2),
      child: Container(
        width: 7,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [BoxShadow(color: Colors.orange, blurRadius: 4)],
        ),
      ),
    );
  }
}
