import 'dart:async';
import 'package:flutter/material.dart';

/// A still police light replaces the bike, GIF and flying-card sequence.
class PoliceSirenOverlay extends StatefulWidget {
  const PoliceSirenOverlay({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<PoliceSirenOverlay> createState() => _PoliceSirenOverlayState();
}

class _PoliceSirenOverlayState extends State<PoliceSirenOverlay> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer =
        Timer(const Duration(milliseconds: 900), () => widget.onComplete());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Semantics(
              label: 'Police siren: cards stolen',
              child: const Text('🚨', style: TextStyle(fontSize: 64)),
            ),
          ),
        ),
      );
}
