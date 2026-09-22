import 'package:flutter/material.dart';

/// Screens switch immediately over the persistent background.
class FixedBackgroundPageRoute<T> extends MaterialPageRoute<T> {
  FixedBackgroundPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      child;
}
