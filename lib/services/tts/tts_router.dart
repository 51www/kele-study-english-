import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';
import '../audio/audio_player.dart';
import 'edge_tts_engine.dart';
import 'system_tts_engine.dart';
import 'tts_cache.dart';
import 'tts_disk_cache.dart';
import 'tts_engine.dart';

/// 朗读路由：优先 Edge TTS，失败切系统 TTS。
///
/// - 连续失败 2 次后本会话内熔断 Edge，2 分钟后允许一次探活（恢复策略）。
/// - Edge 音频按「音色 + 语速 + 文本」哈希缓存到 [TtsCache]（LRU 80MB）。
class TtsRouter {
  TtsRouter({
    required this.edge,
    required this.system,
    required this.player,
    this.disk,
  });

  final EdgeTtsEngine edge;
  final SystemTtsEngine system;
  final AudioPlayerService player;

  /// 落盘缓存（可选）：Android 上有，Web 上自动跳过。
  final TtsDiskCache? disk;

  /// 音频真正开始播放的回调，用于「松手 → 首音」埋点。
  void Function()? onPlaybackStart;

  int _consecutiveFailures = 0;
  bool _edgeDisabled = false;
  DateTime? _disabledAt;
  String lastEngine = '';

  static const Duration _probeInterval = Duration(minutes: 2);

  bool get edgeDisabled => _edgeDisabled;

  /// 这句话是否已有 Edge 音频缓存（内存或磁盘）；断网重听时用它决定能否立即播放。
  bool hasCached(String text, {String voice = EdgeTtsEngine.defaultVoice, double rate = 1.0}) {
    final key = _cacheKey(text.trim(), voice, rate);
    if (TtsCache.instance.contains(key)) return true;
    return disk?.has(key) ?? false;
  }

  /// 返回实际使用的引擎（edge / system）。
  Future<String> speak(
    String text, {
    String voice = EdgeTtsEngine.defaultVoice,
    double rate = 1.0,
    bool preferEdge = true,
    bool autoPlay = true,
    double playbackSpeed = 1.0,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty || !autoPlay) return lastEngine;
    AppLogger.debug(
      'tts speak len=${clean.length} preferEdge=$preferEdge edgeDisabled=$_edgeDisabled voice=$voice rate=$rate',
    );

    // 熔断后每 2 分钟放行一次探活，避免整场一直用系统 TTS。
    if (_edgeDisabled &&
        _disabledAt != null &&
        DateTime.now().difference(_disabledAt!) >= _probeInterval) {
      AppLogger.debug('tts edge probe after circuit break');
      _edgeDisabled = false;
      _consecutiveFailures = 0;
    }

    if (preferEdge && !_edgeDisabled) {
      final cacheKey = _cacheKey(clean, voice, rate);
      final cached = TtsCache.instance.get(cacheKey) ?? await disk?.read(cacheKey);
      if (cached != null) {
        try {
          onPlaybackStart?.call();
          await player.playBytes(cached, speed: playbackSpeed);
          _consecutiveFailures = 0;
          lastEngine = 'edge';
          AppLogger.debug(
            'tts fromCache=true bytes=${cached.length} cacheSize=${TtsCache.instance.sizeBytes}',
          );
          return 'edge';
        } on Object catch (e) {
          AppLogger.warn('tts cached play failed: $e');
        }
      }
      try {
        final result = await edge.synthesize(clean, voice: voice, rate: rate);
        final bytes = result.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          TtsCache.instance.put(cacheKey, bytes);
          await disk?.write(cacheKey, bytes, voice: voice, rate: rate);
          onPlaybackStart?.call();
          await player.playBytes(bytes, mimeType: result.mimeType, speed: playbackSpeed);
          _consecutiveFailures = 0;
          lastEngine = 'edge';
          AppLogger.debug(
            'tts fromCache=false bytes=${bytes.length} cacheSize=${TtsCache.instance.sizeBytes}',
          );
          return 'edge';
        }
        throw const TtsException(
          AppError(kind: AppErrorKind.audio, detail: 'Edge 朗读返回空音频'),
        );
      } on TtsException catch (e) {
        _consecutiveFailures++;
        AppLogger.warn('edge tts failed ($_consecutiveFailures): ${e.error.detail}');
        if (_consecutiveFailures >= 2) {
          _edgeDisabled = true;
          _disabledAt = DateTime.now();
        }
      } catch (e) {
        _consecutiveFailures++;
        AppLogger.warn('edge tts unexpected error: $e');
        if (_consecutiveFailures >= 2) {
          _edgeDisabled = true;
          _disabledAt = DateTime.now();
        }
      }
    }

    try {
      final result = await system.synthesize(clean, voice: voice, rate: rate);
      if (result.spoken) {
        lastEngine = 'system';
        return 'system';
      }
    } on TtsException catch (e) {
      throw TtsException(
        AppError(kind: AppErrorKind.audio, detail: '朗读失败：${e.error.detail}'),
      );
    }

    throw const TtsException(
      AppError(kind: AppErrorKind.audio, detail: '朗读不可用'),
    );
  }

  /// 重启熔断（用户手动重试 Edge 或重新进入会话时）。
  void resetCircuit() {
    _consecutiveFailures = 0;
    _edgeDisabled = false;
    _disabledAt = null;
  }

  String _cacheKey(String text, String voice, double rate) {
    final raw = 'edge|$voice|${rate.toStringAsFixed(2)}|$text';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  Future<void> stop() async {
    await system.stop();
    await edge.cancel();
    await player.stop();
  }
}
