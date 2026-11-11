import 'package:just_audio/just_audio.dart';

/// 二期片段播放器：独立实例，不改 `AudioPlayerService` 的 TTS 契约。
///
/// 用 `ClippingAudioSource` 按 [start, end] 裁剪本地素材，播放到终点自动停止；
/// 复听不联网、不生成片段文件（技术补充文档 §5）。
class ClipPlayerService {
  ClipPlayerService();

  final AudioPlayer _player = AudioPlayer();

  Duration _start = Duration.zero;
  Duration _end = Duration.zero;
  double _speed = 1.0;
  bool _loaded = false;

  bool get loaded => _loaded;
  double get speed => _speed;
  Duration get clipLength => _end - _start;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get stateStream => _player.playerStateStream;

  Future<void> load(
    Uri uri, {
    required int startMs,
    required int endMs,
    double speed = 1.0,
  }) async {
    await stop();
    _start = Duration(milliseconds: startMs < 0 ? 0 : startMs);
    _end = Duration(milliseconds: endMs > startMs ? endMs : startMs + 200);
    _speed = speed;
    _loaded = false;
    try {
      await _player.setAudioSource(
        ClippingAudioSource(
          child: AudioSource.uri(uri),
          start: _start,
          end: _end,
        ),
      );
      await _player.setSpeed(_speed);
      _loaded = true;
    } on Object {
      _loaded = false;
      rethrow;
    }
  }

  /// 从头播放当前句；已播放完时也能重新听。
  Future<void> replay() async {
    if (!_loaded) return;
    await _player.seek(Duration.zero);
    await _player.setSpeed(_speed);
    await _player.play();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    if (_loaded) await _player.setSpeed(speed);
  }

  Future<void> pause() async {
    if (_loaded) await _player.pause();
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } on Object {
      // 首次调用时播放器尚未加载，stop 可能抛错，忽略即可。
    }
  }

  Future<void> dispose() async {
    _loaded = false;
    await _player.dispose();
  }
}
