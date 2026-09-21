import 'package:flutter/material.dart';
import 'app_routes.dart';

/// Route changes leave the page canvas stationary. GameBackground applies
/// this route's animation to foreground controls only.
class FixedBackgroundPageRoute<T> extends MaterialPageRoute<T> {
  FixedBackgroundPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => settings.name == AppRoutes.home
      ? Duration.zero
      : super.transitionDuration;

  @override
  Duration get reverseTransitionDuration => settings.name == AppRoutes.home
      ? Duration.zero
      : super.reverseTransitionDuration;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      child;
}
