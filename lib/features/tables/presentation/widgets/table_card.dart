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
  final String title, subtitle, buyIn, reward, badge;
  final VoidCallback onTap;
  final String? imageAsset;
  final bool locked, purple;

  @override
  Widget build(BuildContext context) {
    final popular = badge == 'POPULAR';
    final frame = popular ? const Color(0xFFAD4A08) : const Color(0xFF77736A);
    return Container(
      height: 226,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xAF080808),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: frame, width: popular ? 2 : 1),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(
            imageAsset ?? AppAssets.chaiHotelBackground,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Image.asset(AppAssets.chaiHotelBackground, fit: BoxFit.cover),
          ),
          const DecoratedBox(
              decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Color(0x10000000), Color(0x65000000)],
            ),
          )),
          Positioned(
            top: title.contains('\n') ? 30 : 33,
            left: 5,
            right: 5,
            child: Column(children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Dirty Brush',
                      fontSize: 22,
                      height: 1.02,
                      color: Colors.white)),
              const SizedBox(height: 5),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, color: Colors.white)),
            ]),
          ),
          Positioned(
            bottom: 54,
            left: 8,
            right: 8,
            child: Row(children: [
              Expanded(
                  child: _Value(
                      label: 'BUY IN',
                      icon: Icons.monetization_on_outlined,
                      value: buyIn)),
              Container(width: 1, height: 30, color: Colors.white54),
              Expanded(
                  child: _Value(
                      label: 'REQUIRED XP',
                      icon: Icons.handshake,
                      value: reward)),
            ]),
          ),
          Positioned(
            bottom: 17,
            left: 10,
            right: 10,
            child: Center(
                child: IgnorePointer(
                    ignoring: locked,
                    child: GameButton(
                      text: 'Enter Match',
                      width: 118,
                      fontSize: 12,
                      backgroundAsset: popular
                          ? AppAssets.buttonBrush
                          : AppAssets.actionButtonBrush,
                      onTap: onTap,
                    ))),
          ),
          if (badge.isNotEmpty)
            Positioned(
              top: 0,
              right: -2,
              child: Container(
                width: 66,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage(AppAssets.actionButtonBrush),
                    fit: BoxFit.fill,
                    colorFilter: ColorFilter.mode(
                      popular
                          ? const Color(0xFFAA4400)
                          : const Color(0xFFD99B52),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                child: Text(badge,
                    style: const TextStyle(
                        fontFamily: 'Dirty Brush',
                        fontSize: 12,
                        color: Colors.white)),
              ),
            ),
          if (locked) ...[
            const Positioned.fill(
                child:
                    IgnorePointer(child: ColoredBox(color: Color(0x99000000)))),
            const Center(
                child: Icon(Icons.lock, color: Color(0xFF8B673B), size: 44)),
          ],
        ]),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.icon, required this.value});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label, style: const TextStyle(fontSize: 7, color: Colors.white60)),
        const SizedBox(height: 2),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: AppColors.orange),
              const SizedBox(width: 3),
              Text(value,
                  style: const TextStyle(fontSize: 17, color: Colors.white70)),
            ])),
      ]);
}
