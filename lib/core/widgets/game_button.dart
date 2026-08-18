import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.text,
    required this.onTap,
    this.width = 155,
    this.icon,
    this.backgroundAsset = AppAssets.buttonBrush,
    this.splatterColor = const Color(0xFFFF8500),
  });

  final String text;
  final VoidCallback? onTap;
  final double width;
  final IconData? icon;
  final String backgroundAsset;
  final Color splatterColor;

  @override
  Widget build(BuildContext context) {
    // Preserve the source artwork's 152:39 aspect ratio at every button width.
    final height = width * 39 / 152;
    const fontSize = 18.0;

    return Semantics(
      button: true,
      label: text,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  backgroundAsset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  color: onTap == null ? Colors.grey : null,
                  colorBlendMode: onTap == null ? BlendMode.saturation : null,
                ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        text.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Dirty Brush',
                          fontSize: fontSize,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          shadows: [
                            Shadow(
                              color: Color(0x66000000),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
