import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

Future<void> showGameAlert(
  BuildContext context,
  String message, {
  String title = 'NOTICE',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF18130F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.orange),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.orange,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(message, style: const TextStyle(color: Colors.white)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
