import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The studio's sound effects, in `assets/audio`.
enum Sfx { tap, place, erase, error, button, solve, keystone, whoosh }

/// One place for game feel: every tap, placement and solve goes through here
/// so haptics and sound stay consistent across puzzle types.
///
/// Sound is best effort: a missing plugin (tests) or a browser that has not
/// had a user gesture yet just stays quiet.
abstract final class Juice {
  /// Silences sound (haptics still fire). Tests set this.
  static bool muted = false;

  /// Small pool per effect so quick taps can overlap.
  static const _poolSize = 3;
  static final Map<Sfx, List<AudioPlayer>> _pools = {};
  static final Map<Sfx, int> _next = {};

  static const _volume = <Sfx, double>{
    Sfx.tap: 0.5,
    Sfx.place: 0.7,
    Sfx.erase: 0.5,
    Sfx.error: 0.6,
    Sfx.button: 0.45,
    Sfx.solve: 0.8,
    Sfx.keystone: 0.9,
    Sfx.whoosh: 0.35,
  };

  static void play(Sfx sfx, {double rate = 1}) {
    if (muted) return;
    unawaited(_play(sfx, rate));
  }

  static Future<void> _play(Sfx sfx, double rate) async {
    try {
      final pool = _pools.putIfAbsent(
        sfx,
        () => List.generate(
          _poolSize,
          (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
        ),
      );
      final i = _next[sfx] = ((_next[sfx] ?? -1) + 1) % _poolSize;
      final player = pool[i];
      await player.stop();
      if (rate != 1) await player.setPlaybackRate(rate);
      await player.play(
        AssetSource('audio/${sfx.name}.wav'),
        volume: _volume[sfx],
      );
    } catch (e) {
      // Audio is decoration; never let it break play.
      if (kDebugMode) debugPrint('Juice: $sfx failed: $e');
    }
  }

  /// Selecting a tile or starting a drag.
  static void tap() {
    HapticFeedback.selectionClick();
    play(Sfx.tap);
  }

  /// A piece lands. [step] nudges the pitch up for chains (paths, seams).
  static void place({int step = 0}) {
    HapticFeedback.lightImpact();
    play(Sfx.place, rate: 1 + (step % 8) * 0.04);
  }

  static void erase() {
    HapticFeedback.selectionClick();
    play(Sfx.erase);
  }

  static void error() {
    HapticFeedback.heavyImpact();
    play(Sfx.error);
  }

  static void button() {
    HapticFeedback.lightImpact();
    play(Sfx.button);
  }

  static void solve() {
    HapticFeedback.mediumImpact();
    play(Sfx.solve);
  }

  static void keystone() {
    HapticFeedback.heavyImpact();
    play(Sfx.keystone);
  }

  static void whoosh() => play(Sfx.whoosh);
}
