import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../support/presentation/widgets/support_page_shell.dart';
import '../../../tables/presentation/widgets/table_top_bar.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int tier = 0;
  static const tiers = ['Rookie', 'Champion', 'Legend'];
  static const players = [
    ['DAKAIT 420', 'DAKAIT 222'],
    ['DAKAIT 302', 'DAKAIT 007'],
    ['DAKAIT 1122', 'DAKAIT 001'],
  ];

  @override
  Widget build(BuildContext context) => SupportPageShell(
        title: 'Leaderboard',
        width: 725,
        height: 245,
        topRight: const TableTopBar(),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              tiers.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: InkWell(
                  onTap: () => setState(() => tier = index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 94,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tier == index
                          ? const Color(0xB33A3733)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: tier == index
                          ? Border.all(color: AppColors.panelBorder)
                          : null,
                    ),
                    child: Text(
                      tiers[index].toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Dirty Brush',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 17),
          const Expanded(
            child: Row(children: [
              Expanded(child: _RankColumn(players: players, start: 0)),
              SizedBox(width: 18),
              Expanded(child: _RankColumn(players: players, start: 3)),
            ]),
          ),
        ]),
      );
}

class _RankColumn extends StatelessWidget {
  const _RankColumn({required this.players, required this.start});
  final List<List<String>> players;
  final int start;

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(3, (index) {
          final rank = start + index + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 31,
              padding: const EdgeInsets.only(left: 18, right: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xC13A3835), Color(0xC120201E)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.panelBorder),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    players[index][start == 0 ? 0 : 1],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 45,
                  height: 23,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    _ordinal(rank),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ]),
            ),
          );
        }),
      );
}

String _ordinal(int value) {
  if (value == 1) return '1st';
  if (value == 2) return '2nd';
  if (value == 3) return '3rd';
  return '${value}th';
}
