import 'package:flutter/material.dart';

class GameCloseButton extends StatelessWidget {
  const GameCloseButton({super.key, required this.onTap, this.size = 68});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size * .18),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF929292),
            size: size * .72,
          ),
        ),
      ),
    );
  }
}
