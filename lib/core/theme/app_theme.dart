import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double bodyFontSize = 14;
  static const double controlFontSize = 14;
  static const double iconSize = 20;

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
          fontSize: bodyFontSize,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(
        size: iconSize,
        color: AppColors.cream,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xF2181411),
        titleTextStyle: TextStyle(
          color: AppColors.cream,
          fontFamily: 'Dirty Brush',
          fontSize: 22,
        ),
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: bodyFontSize,
          height: 1.35,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cream,
          textStyle: const TextStyle(
            fontSize: controlFontSize,
            fontWeight: FontWeight.w800,
          ),
          minimumSize: const Size(48, 44),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: controlFontSize,
            fontWeight: FontWeight.w800,
          ),
          minimumSize: const Size(48, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: controlFontSize,
            fontWeight: FontWeight.w800,
          ),
          minimumSize: const Size(48, 44),
        ),
      ),
    );
  }
}
