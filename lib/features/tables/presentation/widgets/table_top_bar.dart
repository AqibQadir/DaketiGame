import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';

class TableTopBar extends ConsumerWidget {
  const TableTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final coins = auth.isAuthenticated
        ? auth.stats.totalScore.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')
        : '—';
    return Row(
      children: [
        _Counter(
          icon: Icons.monetization_on,
          text: 'Buy Coins',
          onTap: () => Navigator.pushNamed(context, AppRoutes.dukan),
        ),
        const SizedBox(width: 24),
        _Counter(
            icon: Icons.stars_rounded,
            text: coins,
            add: true,
            onTap: () => Navigator.pushNamed(context, AppRoutes.dukan)),
        const SizedBox(width: 24),
        _Counter(
            icon: Icons.handshake,
            text: '—',
            add: true,
            onTap: () => Navigator.pushNamed(context, AppRoutes.sideQuests)),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.text,
    this.onTap,
    this.add = false,
  });

  final IconData icon;
  final String text;
  final bool add;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 23,
        padding: EdgeInsets.only(left: 8, right: add ? 3 : 9),
        decoration: BoxDecoration(
          color: const Color(0xDE46321F),
          border: Border.all(color: AppColors.tileBorder),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.orange),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            if (add) ...[
              const SizedBox(width: 7),
              Container(
                width: 20,
                height: 20,
                color: AppColors.orange,
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
