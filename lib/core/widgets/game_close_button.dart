import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

class GameCloseButton extends StatelessWidget {
  const GameCloseButton({super.key, required this.onTap, this.size = 68});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x36101413),
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white30),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Image.asset(
              AppAssets.closeCross,
              width: size * .62,
              height: size * .62,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
