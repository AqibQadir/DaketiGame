import 'dart:async';
import 'audio_settings.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralized, best-effort playback for short gameplay sound effects.
///
/// Separate channels let an interface cue, gameplay effect, and result sting
/// overlap naturally without repeatedly allocating native audio players.
class GameSoundService {
  GameSoundService._();

  static final _uiPlayer = AudioPlayer(playerId: 'daketi_ui_sounds');
  static final _gamePlayer = AudioPlayer(playerId: 'daketi_game_sounds');
  static final _stealPlayer = AudioPlayer(playerId: 'daketi_steal_sounds');
  static final _alertPlayer = AudioPlayer(playerId: 'daketi_alert_sounds');
  static final _countdownPlayer = AudioPlayer(playerId: 'daketi_countdown');
  static bool _countdownEnabled = false;
  static Future<void> _countdownQueue = Future<void>.value();
  static final Future<void> _configured = _configureAudioSession();

  static final bool _listening = _listenForMute();
  static bool _listenForMute() {
    AudioSettings.media.addListener(() {
      if (!AudioSettings.media.value) {
        setCountdownWarning(false);
        for (final player in [
          _uiPlayer,
          _gamePlayer,
          _stealPlayer,
          _alertPlayer
        ]) {
          unawaited(player.stop().catchError((Object _) {}));
        }
      }
    });
    return true;
  }

  static const _assetRoot = 'audio/game/';
  static const _masterVolumeBoost = 1.4;

  static void uiClick() => _play(_uiPlayer, 'CardMove.wav', volume: .4);
  static void cardSelected() => _play(_uiPlayer, 'SwipeCard.wav', volume: .55);
  static void shuffle() => _play(_gamePlayer, 'cards.wav', volume: .72);
  static void cardMove() => _play(_gamePlayer, 'anycard.wav', volume: .78);
  static void aceDrawn() => _play(_gamePlayer, 'ifyougetA.wav', volume: .78);
  static void stealCard({required bool third}) =>
      _play(_stealPlayer, third ? 'steal3.wav' : 'steal1-2.mp3', volume: .82);
  static void invalidMove() =>
      _play(_alertPlayer, 'invalidmove.wav', volume: .7);
  static void nextPlayerMove() => _play(_alertPlayer, 'turn.wav', volume: .75);
  static void timerWarning() =>
      _play(_alertPlayer, 'timerwarning10secondsleft.wav', volume: .72);

  static void timerEnd() {
    setCountdownWarning(false);
    _play(_alertPlayer, 'timerend.mp3', volume: .8);
  }

  /// A separate looping channel keeps other game effects from cutting off
  /// the final-three-second warning. Serialize transitions so a late start
  /// cannot race a turn-ending stop.
  static void setCountdownWarning(bool enabled) {
    if (!_listening || !AudioSettings.media.value) enabled = false;
    if (_countdownEnabled == enabled) return;
    _countdownEnabled = enabled;
    _countdownQueue = _countdownQueue.then((_) async {
      try {
        await _configured;
        await _countdownPlayer.stop();
        if (!_countdownEnabled) return;
        await _countdownPlayer.setReleaseMode(ReleaseMode.loop);
        await _countdownPlayer.play(
          AssetSource('${_assetRoot}timer3seconds.wav'),
          volume: (.72 * _masterVolumeBoost).clamp(0.0, 1.0),
          mode: PlayerMode.mediaPlayer,
        );
      } catch (error) {
        debugPrint('Unable to update countdown warning: $error');
      }
    });
  }

  static void playerJoined() =>
      _play(_alertPlayer, 'TurnChange2.wav', volume: .6);

  static void matchFound() =>
      _play(_alertPlayer, 'Timer Start.wav', volume: .7);

  static void reaction() {}

  static void roundWon() => _play(_alertPlayer, 'rOUNDwIN.wav', volume: .8);

  static void gameLost() {}

  static void _play(
    AudioPlayer player,
    String asset, {
    required double volume,
  }) {
    if (!_listening || !AudioSettings.media.value) return;
    unawaited(_replace(player, asset, volume));
  }

  static Future<void> _replace(
    AudioPlayer player,
    String asset,
    double volume,
  ) async {
    try {
      await _configured;
      await player.stop();
      if (!AudioSettings.media.value) return;
      final boostedVolume = (volume * _masterVolumeBoost).clamp(0.0, 1.0);
      await player.play(
        AssetSource('$_assetRoot$asset'),
        volume: boostedVolume,
        mode: PlayerMode.mediaPlayer,
      );
    } catch (error, stackTrace) {
      // Sound must never interrupt gameplay when a platform audio service is
      // unavailable or an individual device cannot decode an effect.
      debugPrint('Unable to play game sound "$asset": $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _configureAudioSession() =>
      AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
}
