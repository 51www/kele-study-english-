import 'dart:async';
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
import 'tts_speech.dart';

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

  /// 每次 [stop] 自增。speak() 在每个 await 后校验，避免已被取消的旧朗读
  /// 在合成完成后又出声（典型场景：Edge 被 cancel 后错误地回退系统 TTS），
  /// 造成用户按下录音后仍有两段声音叠加。
  int _stopGeneration = 0;

  static const Duration _probeInterval = Duration(minutes: 2);

  bool get edgeDisabled => _edgeDisabled;

  /// 这句话是否已有 Edge 音频缓存（内存或磁盘）；断网重听时用它决定能否立即播放。
  bool hasCached(String text, {
    String voice = EdgeTtsEngine.defaultVoice,
    double rate = 1.0,
    TtsSpeechStyle style = TtsSpeechStyle.none,
  }) {
    final key = _cacheKey(text.trim(), voice, rate, style);
    if (TtsCache.instance.contains(key)) return true;
    return disk?.has(key) ?? false;
  }

  /// 返回实际使用的引擎（edge / system）。
  Future<String> speak(
    String text, {
    String voice = EdgeTtsEngine.defaultVoice,
    double rate = 1.0,
    TtsSpeechStyle style = TtsSpeechStyle.none,
    bool preferEdge = true,
    bool autoPlay = true,
    double playbackSpeed = 1.0,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty || !autoPlay) return lastEngine;
    final generation = _stopGeneration;
    bool cancelled() => generation != _stopGeneration;
    AppLogger.debug(
      'tts speak len=${clean.length} preferEdge=$preferEdge edgeDisabled=$_edgeDisabled voice=$voice rate=$rate style=${style.value}',
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
      final cacheKey = _cacheKey(clean, voice, rate, style);
      final cached = TtsCache.instance.get(cacheKey) ?? await disk?.read(cacheKey);
      if (cancelled()) return lastEngine;
      if (cached != null) {
        try {
          onPlaybackStart?.call();
          await player.playBytes(cached, speed: playbackSpeed);
          if (cancelled()) return lastEngine;
          _consecutiveFailures = 0;
          lastEngine = 'edge';
          AppLogger.debug(
            'tts fromCache=true bytes=${cached.length} cacheSize=${TtsCache.instance.sizeBytes}',
          );
          return 'edge';
        } on Object catch (e) {
          if (cancelled()) return lastEngine;
          AppLogger.warn('tts cached play failed: $e');
        }
      }
      try {
        final result = await edge.synthesize(clean, voice: voice, rate: rate, style: style);
        if (cancelled()) return lastEngine;
        final bytes = result.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          TtsCache.instance.put(cacheKey, bytes);
          onPlaybackStart?.call();
          // 落盘缓存不挡首音：与播放并行，避免每句都多一次磁盘写入等待。
          final playback = player.playBytes(
            bytes,
            mimeType: result.mimeType,
            speed: playbackSpeed,
          );
          unawaited(disk?.write(cacheKey, bytes, voice: voice, rate: rate));
          await playback;
          if (cancelled()) return lastEngine;
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
        // Edge 被 cancel() 打断也会抛 TtsException，此时绝不能走系统兜底出声。
        if (cancelled()) return lastEngine;
        _consecutiveFailures++;
        AppLogger.warn('edge tts failed ($_consecutiveFailures): ${e.error.detail}');
        if (_consecutiveFailures >= 2) {
          _edgeDisabled = true;
          _disabledAt = DateTime.now();
        }
      } catch (e) {
        if (cancelled()) return lastEngine;
        _consecutiveFailures++;
        AppLogger.warn('edge tts unexpected error: $e');
        if (_consecutiveFailures >= 2) {
          _edgeDisabled = true;
          _disabledAt = DateTime.now();
        }
      }
    }

    // 走到系统兜底前再校验一次：期间被 stop() 取消就不再出声。
    if (cancelled()) return lastEngine;
    try {
      final result = await system.synthesize(clean, voice: voice, rate: rate);
      if (cancelled()) return lastEngine;
      if (result.spoken) {
        lastEngine = 'system';
        return 'system';
      }
    } on TtsException catch (e) {
      if (cancelled()) return lastEngine;
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

  String _cacheKey(String text, String voice, double rate, TtsSpeechStyle style) {
    // v3：SSML 移除 break 注入后旧键缓存的音频必须失效，避免听到旧停顿版本。
    final raw = 'edge|v3|$voice|${rate.toStringAsFixed(2)}|${style.value}|$text';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  Future<void> stop() async {
    _stopGeneration++;
    await system.stop();
    await edge.cancel();
    await player.stop();
  }
}
