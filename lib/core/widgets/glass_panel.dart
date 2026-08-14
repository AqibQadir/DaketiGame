import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.width = 520,
    this.height,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final double width;
  final double? height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.panelBorder,
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xE6000000),
                blurRadius: 26,
                spreadRadius: 2,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
