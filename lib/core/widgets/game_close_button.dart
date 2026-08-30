import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

class GameCloseButton extends StatelessWidget {
  const GameCloseButton({super.key, required this.onTap, this.size = 68});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: EdgeInsets.all(size * .12),
            child: Image.asset(
              AppAssets.closeCross,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
