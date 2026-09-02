import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralized, best-effort playback for short gameplay sound effects.
///
/// Separate channels let an interface cue, gameplay effect, and result sting
/// overlap naturally without repeatedly allocating native audio players.
class GameSoundService {
  GameSoundService._();

  static final _random = Random();
  static final _uiPlayer = AudioPlayer(playerId: 'daketi_ui_sounds');
  static final _gamePlayer = AudioPlayer(playerId: 'daketi_game_sounds');
  static final _alertPlayer = AudioPlayer(playerId: 'daketi_alert_sounds');
  static final Future<void> _configured = _configureAudioSession();

  static const _assetRoot = 'audio/game/';
  static const _masterVolumeBoost = 1.4;

  static void uiClick() => _play(_uiPlayer, 'CardMove.wav', volume: .45);

  static void cardSelected() => _play(_uiPlayer, 'SwipeCard.wav', volume: .65);

  static void shuffle() => _play(_gamePlayer, 'CardShuffle.wav', volume: .72);

  static void cardSlap() => _play(_gamePlayer, 'CardMove.wav', volume: .78);

  static void goodMove() => _play(_gamePlayer, 'good move.wav', volume: .72);

  static void specialCard() =>
      _play(_gamePlayer, 'Special card.wav', volume: .78);

  static void challenge() => _play(_gamePlayer, 'Challenge.wav', volume: .82);

  static void invalidMove() =>
      _play(_alertPlayer, 'invalidmove.wav', volume: .8);

  static void yourTurn() => _play(
        _alertPlayer,
        _variant(const ['TurnChange.wav', 'TurnChange2.wav']),
        volume: .75,
      );

  static void timerWarning() =>
      _play(_alertPlayer, 'Timer Start.wav', volume: .72);

  static void timerTick() =>
      _play(_alertPlayer, 'timerwarning.wav', volume: .55);

  static void playerJoined() {}

  static void matchFound() {}

  static void reaction() {}

  static void roundWon() => _play(_gamePlayer, 'rOUNDwIN.wav', volume: .85);

  static void gameLost() {}

  static String _variant(List<String> values) =>
      values[_random.nextInt(values.length)];

  static void _play(
    AudioPlayer player,
    String asset, {
    required double volume,
  }) {
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
