import 'package:flutter/material.dart';

class GameCloseButton extends StatelessWidget {
  const GameCloseButton({super.key, required this.onTap, this.size = 52});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                Icons.close_rounded,
                size: size * .46,
                color: const Color(0xFFFFF1D1),
                shadows: const [
                  Shadow(color: Color(0xFFFF8500), blurRadius: 7),
                  Shadow(color: Colors.black, blurRadius: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
