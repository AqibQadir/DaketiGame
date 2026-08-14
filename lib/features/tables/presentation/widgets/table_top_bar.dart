import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';

class TableTopBar extends StatelessWidget {
  const TableTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Counter(
          icon: Icons.monetization_on,
          text: 'Buy Coins',
          onTap: () => Navigator.pushNamed(context, AppRoutes.dukan),
        ),
        const SizedBox(width: 12),
        const _Counter(icon: Icons.stars_rounded, text: '125,000', add: true),
        const SizedBox(width: 12),
        const _Counter(icon: Icons.handshake, text: '25,000', add: true),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.text,
    this.add = false,
    this.onTap,
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
        height: 27,
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
