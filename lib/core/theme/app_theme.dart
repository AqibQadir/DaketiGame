import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.orange,
        secondary: AppColors.cream,
        surface: Colors.black,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}
