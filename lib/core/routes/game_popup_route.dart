import 'package:flutter/material.dart';
import '../widgets/looping_video_background.dart';
import 'app_routes.dart';

/// Secondary app tools sit over the current main page without replacing it.
class GamePopupRoute<T> extends PopupRoute<T> {
  GamePopupRoute(
      {required this.child,
      required super.settings,
      this.videoBackground = false});
  final bool videoBackground;
  final Widget child;
  bool get referencePanel =>
      settings.name == AppRoutes.profile || settings.name == AppRoutes.support;
  @override
  bool get opaque => referencePanel;
  @override
  Color get barrierColor => const Color(0x99000000);
  @override
  bool get barrierDismissible => false;
  @override
  String get barrierLabel => 'Close panel';
  @override
  Duration get transitionDuration => Duration.zero;
  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      SafeArea(
        child: Center(
            child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: AspectRatio(
              aspectRatio: 844 / 390,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Material(
                  color: Colors.transparent,
                  child: Stack(children: [
                    Positioned.fill(
                        child: Theme(
                            data: Theme.of(context).copyWith(
                                scaffoldBackgroundColor: Colors.transparent),
                            child: child)),
                    Positioned(
                        top: 5,
                        right: 5,
                        child: IconButton(
                          tooltip: 'Close popup',
                          onPressed: () {
                            final navigator = Navigator.of(context);
                            if (settings.name == AppRoutes.guestName) {
                              if (navigator.canPop()) {
                                navigator.pop();
                              } else {
                                navigator.pushNamedAndRemoveUntil(
                                    AppRoutes.welcome, (_) => false);
                              }
                              return;
                            }
                            navigator.pushNamedAndRemoveUntil(
                                AppRoutes.home, (_) => false);
                          },
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFFFFD699)),
                          style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF30251B)),
                        )),
                  ]),
                ),
              ),
            ),
          ),
        )),
      );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      Stack(fit: StackFit.expand, children: [
        if (videoBackground && !PersistentBackgroundScope.present(context))
          const LoopingVideoBackground(),
        FadeTransition(
          opacity: animation,
          child: ScaleTransition(
              scale: animation.drive(Tween(begin: .97, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeOutCubic))),
              child: child),
        ),
      ]);
}
