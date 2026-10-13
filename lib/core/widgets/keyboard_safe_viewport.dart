import 'dart:async';
import 'package:flutter/material.dart';

/// Keeps the game canvas at its original size while making its foreground
/// scrollable above the keyboard. Applied around the navigator so every route,
/// including form dialogs, receives the same keyboard behavior.
class KeyboardSafeViewport extends StatefulWidget {
  const KeyboardSafeViewport({super.key, required this.child});
  final Widget child;

  @override
  State<KeyboardSafeViewport> createState() => _KeyboardSafeViewportState();
}

class _KeyboardSafeViewportState extends State<KeyboardSafeViewport> {
  final _scroll = ScrollController();
  double _keyboardHeight = 0;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_scheduleReveal);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final height = MediaQuery.viewInsetsOf(context).bottom;
    if (height != _keyboardHeight) {
      _keyboardHeight = height;
      _scheduleReveal();
    }
  }

  void _scheduleReveal() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !_scroll.hasClients) return;
      if (_keyboardHeight == 0) {
        if (_scroll.offset != 0) _scroll.jumpTo(0);
        return;
      }
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext == null || !focusContext.mounted) return;
      unawaited(Scrollable.ensureVisible(
        focusContext,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ));
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_scheduleReveal);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final keyboard =
          media.viewInsets.bottom.clamp(0.0, constraints.maxHeight);
      final visibleHeight =
          (constraints.maxHeight - keyboard).clamp(1.0, constraints.maxHeight);
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: visibleHeight,
          width: constraints.maxWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SingleChildScrollView(
              controller: _scroll,
              physics: keyboard > 0
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: SizedBox(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                child: MediaQuery(
                  data: media.copyWith(
                    viewInsets: media.viewInsets.copyWith(bottom: 0),
                    padding: media.padding
                        .copyWith(bottom: media.viewPadding.bottom),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
