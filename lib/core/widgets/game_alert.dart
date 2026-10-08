import 'package:flutter/material.dart';
import 'game_styled_dialog.dart';

Future<void> showGameAlert(BuildContext context, String message,
        {String title = 'NOTICE'}) =>
    showDialog<void>(
        context: context,
        builder: (dialogContext) => GameStyledDialog(
              title: Text(title == 'NOTICE' ? message.toUpperCase() : title),
              content: title == 'NOTICE' ? null : Text(message),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Continue'))
              ],
            ));

/// Reusable themed confirmation. Dismissal is treated as Cancel.
Future<bool> showGameConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Continue',
  String cancelText = 'Cancel',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => GameStyledDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(cancelText)),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmText)),
        ],
      ),
    ) ??
    false;
