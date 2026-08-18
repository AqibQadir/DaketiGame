import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class GameIconButton extends StatelessWidget {
  const GameIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.tile : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        enabled ? AppColors.tileBorder : Colors.grey.shade600,
                  ),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.cream : Colors.grey.shade500,
                  size: 23,
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(fontSize: 8),
                  ),
                ),
              ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              color: enabled ? AppColors.cream : Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}
