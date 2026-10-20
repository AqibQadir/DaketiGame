import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wallet/domain/starting_balance.dart';

import '../../../../core/constants/app_colors.dart';

class TableTopBar extends ConsumerWidget {
  const TableTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(startingBalanceProvider).coins.toString();
    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xDE46321F),
        border: Border.all(color: AppColors.tileBorder),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.stars_rounded, size: 15, color: AppColors.orange),
        const SizedBox(width: 5),
        Text(coins,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
