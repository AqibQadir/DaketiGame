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
