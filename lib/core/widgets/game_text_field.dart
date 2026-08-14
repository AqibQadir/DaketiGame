import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class GameTextField extends StatelessWidget {
  const GameTextField({
    super.key,
    required this.hint,
    this.obscureText = false,
    this.controller,
  });

  final String hint;
  final bool obscureText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 235,
      height: 39,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
          filled: true,
          fillColor: AppColors.field,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.tileBorder,
            ),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.tileBorder,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.orange,
            ),
          ),
        ),
      ),
    );
  }
}
