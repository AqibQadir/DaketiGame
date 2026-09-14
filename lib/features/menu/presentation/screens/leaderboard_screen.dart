import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../support/presentation/widgets/support_page_shell.dart';
import '../../../tables/presentation/widgets/table_top_bar.dart';
import '../../data/leaderboard_client.dart';

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final client = LeaderboardClient();
  ref.onDispose(client.dispose);
  return client.load();
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SupportPageShell(
        title: 'Leaderboard',
        width: 725,
        height: 245,
        topRight: const TableTopBar(),
        child: ref.watch(leaderboardProvider).when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.orange)),
              error: (error, _) => Center(
                  child: Text(error.toString(), textAlign: TextAlign.center)),
              data: (players) => players.isEmpty
                  ? const Center(child: Text('NO RANKED PLAYERS YET'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 8,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 10),
                      itemCount: players.length,
                      itemBuilder: (_, index) =>
                          _RankRow(entry: players[index], rank: index + 1),
                    ),
            ),
      );
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.rank});
  final LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) => Container(
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
              '${entry.name}  •  ${entry.gamesWon} WINS  •  ${entry.totalScore} PTS',
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
      );
}

String _ordinal(int value) {
  if (value == 1) return '1st';
  if (value == 2) return '2nd';
  if (value == 3) return '3rd';
  return '${value}th';
}
