import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import '../../core/logger.dart';

/// 播放 TTS 音频。Android 与 Web 均使用 data URI，避免平台文件系统差异。
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  bool _playing = false;
  double _speed = 1.0;

  bool get playing => _playing;

  Stream<PlayerState> get stateStream => _player.playerStateStream;

  Future<void> playBytes(
    Uint8List bytes, {
    String mimeType = 'audio/mpeg',
    double speed = 1.0,
  }) async {
    await stop();
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: mimeType)),
      );
      await _player.setSpeed(speed);
      _speed = speed;
      _playing = true;
      // just_audio 的 play() 在播放完成（或被停止）后返回。
      await _player.play();
    } finally {
      _playing = false;
    }
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      AppLogger.warn('set speed failed: $e');
    }
  }

  double get speed => _speed;

  Future<void> stop() async {
    _playing = false;
    try {
      await _player.stop();
    } catch (e) {
      AppLogger.warn('player stop failed: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      AppLogger.warn('player pause failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
