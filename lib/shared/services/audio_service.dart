import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static bool enabled = true;
  static final Random _random = Random();

  static final List<AudioPlayer> _pool = [];
  static int _poolIndex = 0;
  static const int _poolSize = 4;
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    for (int i = 0; i < _poolSize; i++) {
      _pool.add(AudioPlayer());
    }
  }

  static AudioPlayer _getPlayer() {
    if (!_initialized) init();
    final player = _pool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _poolSize;
    return player;
  }

  static Future<void> _playSound(String assetPath) async {
    if (!enabled) return;
    try {
      final player = _getPlayer();
      await player.stop();
      await player.play(AssetSource(assetPath), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('AudioService playSound error: $e');
    }
  }

  /// Randomly play one of pop_1, pop_2, pop_3
  static Future<void> playRandomPop() async {
    final idx = _random.nextInt(3) + 1;
    await _playSound('sounds/pop_$idx.wav');
  }

  /// Play unpack sound
  static Future<void> playUnpack() async {
    await _playSound('sounds/unpack.wav');
  }

  /// Play zipper sound
  static Future<void> playZip() async {
    await _playSound('sounds/zip.wav');
  }

  /// Play door sound
  static Future<void> playDoor() async {
    await _playSound('sounds/door.wav');
  }
}
