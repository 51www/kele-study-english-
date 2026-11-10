import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';
import 'tts_engine.dart';

/// 系统 TTS 兜底：直接朗读，不产生可缓存的音频文件。
class SystemTtsEngine implements TtsEngine {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _speaking = false;

  @override
  String get id => 'system';

  bool get speaking => _speaking;

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      final lang = await _tts.setLanguage('en-US');
      final available = await _tts.isLanguageAvailable('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      AppLogger.debug('system tts init setLanguage=$lang available=$available');
      _ready = true;
    } catch (e) {
      AppLogger.warn('system tts init failed: $e');
      _ready = false;
    }
  }

  @override
  Future<List<TtsVoice>> voices() async => const [];

  @override
  Future<TtsResult> synthesize(
    String text, {
    required String voice,
    required double rate,
  }) async {
    await _ensureReady();
    if (!_ready) {
      throw const TtsException(
        AppError(kind: AppErrorKind.audio, detail: '系统朗读不可用'),
      );
    }
    try {
      // flutter_tts 的 0.5 为正常语速，按倍率映射并限制在 0.2–1.0。
      final mapped = (0.5 * rate).clamp(0.2, 1.0).toDouble();
      await _tts.setSpeechRate(mapped);
      _speaking = true;
      final started = DateTime.now();
      final code = await _tts.speak(text).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          AppLogger.warn('system tts completion timeout, treat as done');
          return 1;
        },
      );
      AppLogger.debug(
        'system tts speak code=$code elapsed=${DateTime.now().difference(started).inMilliseconds}ms len=${text.length}',
      );
      // speak 返回非 1 说明引擎没有真正入队发声（如 ROM 自带 TTS 不支持
      // 当前语言），必须抛错让 TtsRouter 报告失败，避免 UI 播放态但无声。
      if (code is num && code != 1) {
        throw TtsException(
          AppError(kind: AppErrorKind.audio, detail: '系统朗读未启动（code=$code）'),
        );
      }
      return const TtsResult(engine: 'system', spoken: true);
    } catch (e) {
      throw TtsException(
        AppError(kind: AppErrorKind.audio, detail: '系统朗读失败：$e'),
      );
    } finally {
      _speaking = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      if (!kIsWeb) AppLogger.warn('system tts stop failed: $e');
    }
    _speaking = false;
  }

  @override
  Future<void> cancel() => stop();

  @override
  Future<void> dispose() => stop();
}
