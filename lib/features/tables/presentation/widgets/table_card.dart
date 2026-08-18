import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/game_button.dart';

class TableCard extends StatelessWidget {
  const TableCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buyIn,
    required this.reward,
    required this.badge,
    required this.onTap,
    this.imageAsset,
    this.locked = false,
    this.purple = false,
  });

  final String title;
  final String subtitle;
  final String buyIn;
  final String reward;
  final String badge;
  final VoidCallback onTap;
  final String? imageAsset;
  final bool locked;
  final bool purple;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 169,
      height: 245,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xCB080808),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white38),
        boxShadow: const [
          BoxShadow(
              color: Colors.black87, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageAsset ?? AppAssets.chaiHotelBackground,
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: locked ? .70 : .37),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => Image.asset(
                AppAssets.chaiHotelBackground,
                fit: BoxFit.cover,
                color: purple
                    ? const Color(0x8E5B00A4)
                    : Colors.black.withValues(alpha: locked ? .70 : .40),
                colorBlendMode: purple ? BlendMode.color : BlendMode.darken,
              ),
            ),
            Positioned(
              top: 0,
              left: 54,
              right: 5,
              child: Container(
                height: 20,
                alignment: Alignment.center,
                color: const Color(0xD7613D23),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontFamily: 'Dirty Brush',
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Dirty Brush',
                      fontSize: 22,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 27,
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8, height: 1.12),
                    ),
                  ),
                  if (locked)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Icon(Icons.lock, color: AppColors.cream, size: 28),
                    )
                  else
                    const SizedBox(height: 13),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Value(icon: Icons.monetization_on, value: buyIn),
                      const SizedBox(width: 19),
                      _Value(icon: Icons.handshake, value: reward),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: locked ? .32 : 1,
                    child: GameButton(
                      text: 'Enter Match',
                      width: 112,
                      onTap: locked ? null : onTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 15, color: AppColors.orange),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 9)),
      ],
    );
  }
}
