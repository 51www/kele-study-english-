import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logger.dart';
import '../../core/timeouts.dart';

/// 播放 TTS 音频。
///
/// - IO 平台写临时文件再播放（data URI 在部分 Android 机型上会令
///   ExoPlayer 卡在加载态、永不发声，见 KI-13）；Web 仍用 data URI。
/// - [playBytes] 会真实等待播放完成（或被 stop/新播放打断）才返回，
///   保证上层「正在朗读」状态与实际出声一致。
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;

  bool _playing = false;
  double _speed = 1.0;
  int _generation = 0;
  File? _lastFile;

  bool get playing => _playing;

  Stream<PlayerState> get stateStream => _player.playerStateStream;

  Future<void> playBytes(
    Uint8List bytes, {
    String mimeType = 'audio/mpeg',
    double speed = 1.0,
  }) async {
    await stop();
    final generation = ++_generation;
    final started = DateTime.now();
    AppLogger.debug(
      'player playBytes bytes=${bytes.length} mime=$mimeType speed=$speed',
    );
    _stateSub ??= _player.playerStateStream.listen(
      (s) => AppLogger.debug(
        'player state=${s.processingState.name} playing=${s.playing}',
      ),
      onError: (Object e) => AppLogger.warn('player state error: $e'),
    );
    try {
      final source = await _buildSource(bytes, mimeType);
      await _player.setAudioSource(source).timeout(Timeouts.playerLoad);
      AppLogger.debug(
        'player source ready duration=${_player.duration} '
        'elapsed=${DateTime.now().difference(started).inMilliseconds}ms',
      );
      await _player.setSpeed(speed);
      _speed = speed;
      _playing = true;
      await _player.play();
      if (generation != _generation) return;
      // 等待真实播放完成；被 stop() 打断时 processingState 回 idle。
      await _player.playerStateStream.firstWhere(
        (s) =>
            s.processingState == ProcessingState.completed ||
            (s.processingState == ProcessingState.idle && !s.playing),
      );
    } on Object catch (e) {
      AppLogger.warn('player playBytes failed: $e');
      rethrow;
    } finally {
      if (generation == _generation) _playing = false;
      await _cleanupLastFile();
    }
  }

  /// IO 平台走临时文件，Web 走 data URI。
  Future<AudioSource> _buildSource(Uint8List bytes, String mimeType) async {
    if (kIsWeb) {
      return AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: mimeType));
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(dir.path, 'tts_${DateTime.now().microsecondsSinceEpoch}.mp3'),
    );
    await file.writeAsBytes(bytes, flush: true);
    await _cleanupLastFile();
    _lastFile = file;
    return AudioSource.uri(file.uri);
  }

  Future<void> _cleanupLastFile() async {
    final file = _lastFile;
    _lastFile = null;
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      AppLogger.warn('player temp file cleanup failed: $e');
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
    _generation++; // 让上一轮的完成等待立即结束。
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
    _generation++;
    await _stateSub?.cancel();
    _stateSub = null;
    try {
      await _player.dispose();
    } catch (_) {}
    await _cleanupLastFile();
  }
}
