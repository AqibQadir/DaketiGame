import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../constants/app_assets.dart';

/// Video fills the background only; route transitions belong to the foreground.
class LoopingVideoBackground extends StatefulWidget {
  const LoopingVideoBackground(
      {super.key,
      this.videoAsset = AppAssets.chaiHotelVideo,
      this.posterAsset = AppAssets.chaiHotelVideoPoster});
  final String videoAsset;
  final String posterAsset;

  @override
  State<LoopingVideoBackground> createState() => _LoopingVideoBackgroundState();
}

class _LoopingVideoBackgroundState extends State<LoopingVideoBackground>
    with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _visible = true;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(
      widget.videoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      await _controller.setVolume(0);
      await _controller.setLooping(true);
      if (!mounted) return;
      setState(() => _ready = true);
      await _syncPlayback();
    } catch (_) {
      // The matching still remains visible if video playback is unavailable.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    unawaited(_syncPlayback());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    unawaited(_syncPlayback());
  }

  Future<void> _syncPlayback() async {
    if (!_ready || !mounted) return;
    try {
      if (_visible && _resumed) {
        await _controller.play();
      } else {
        await _controller.pause();
      }
    } catch (_) {
      // Keep the still fallback usable after a platform playback failure.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(widget.posterAsset, fit: BoxFit.cover),
            if (_ready)
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, _) => value.hasError
                    ? const SizedBox.shrink()
                    : ClipRect(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: value.size.width,
                            height: value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      );
}

/// Marks the persistent background mounted outside the Navigator.
class PersistentBackgroundScope extends InheritedWidget {
  const PersistentBackgroundScope({super.key, required super.child});
  static bool present(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PersistentBackgroundScope>() !=
      null;
  @override
  bool updateShouldNotify(PersistentBackgroundScope oldWidget) => false;
}
