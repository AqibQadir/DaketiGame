import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/game_button.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.onTap,
    this.action = 'Invite Chat',
    this.compact = false,
  });
  final VoidCallback onTap;
  final String action;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: compact ? 180 : 170,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage(AppAssets.chaiHotelBackground),
            fit: BoxFit.cover,
            opacity: .32,
          ),
          color: const Color(0xC512100E),
          border: Border.all(color: Colors.white38),
          borderRadius: BorderRadius.circular(5),
        ),
        child: compact
            ? Row(children: [
                const _Avatar(radius: 24),
                const SizedBox(width: 8),
                Expanded(child: _Identity(action: action, onTap: onTap)),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const _Avatar(radius: 36),
                const SizedBox(height: 7),
                _Identity(action: action, onTap: onTap),
              ]),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.radius});
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFD6D3CF),
        child: Icon(Icons.face,
            size: radius * 1.35, color: const Color(0xFF4B382B)),
      );
}

class _Identity extends StatelessWidget {
  const _Identity({required this.action, required this.onTap});
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'THE FULL NAME',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.orange,
              fontFamily: 'Dirty Brush',
              fontSize: 13,
            ),
          ),
          const Text('The Dakait Group', style: TextStyle(fontSize: 7)),
          const Text(
            'RANKING',
            style: TextStyle(
              color: AppColors.orange,
              fontFamily: 'Dirty Brush',
              fontSize: 12,
            ),
          ),
          if (action.isNotEmpty) ...[
            const SizedBox(height: 4),
            GameButton(text: action, width: 90, onTap: onTap),
          ],
        ],
      );
}
