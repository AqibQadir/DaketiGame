import 'package:flutter/material.dart';

class GameDialogTitle extends StatelessWidget {
  const GameDialogTitle(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title)),
        IconButton(
            tooltip: 'Close dialog',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded)),
      ]);
}
