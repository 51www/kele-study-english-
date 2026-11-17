import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';
import 'asr_engine.dart';

/// 系统语音识别（Android: 系统 RecognitionService；Web: Web Speech API）。
///
/// 系统识别内部自己占用麦克风，因此识别可用时不再额外用 `record` 采集，
/// 避免两个插件争抢麦克风。
class SystemAsrEngine implements AsrEngine {
  SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _initialized = false;
  bool _listening = false;
  String _finalText = '';
  String _partialText = '';
  Completer<void>? _resultCompleter;
  String? _lastError;

  @override
  String get provider => 'system';

  @override
  bool get available => _available;

  bool get listening => _listening;

  @override
  void Function(String partial)? onPartial;

  @override
  Future<bool> initialize() async {
    if (_initialized && _available) return _available;
    // 上次初始化失败：换新实例重试，避开插件「只能初始化一次」的限制。
    if (_initialized) _speech = SpeechToText();
    _initialized = true;
    try {
      _available = await _speech.initialize(
        onError: _handleError,
        onStatus: (status) {
          AppLogger.debug('asr status: $status');
          if (status == 'done' || status == 'notListening') {
            _listening = false;
            _completeIfNeeded();
          }
        },
      );
      if (_available) {
        try {
          final locales = await _speech.locales();
          final hasEnglish = locales.any(
            (l) => l.localeId.toLowerCase().startsWith('en'),
          );
          if (!hasEnglish) {
            AppLogger.warn('asr has no English locale, keep default');
          }
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.warn('asr initialize failed: $e');
      _available = false;
    }
    return _available;
  }

  void _handleError(SpeechRecognitionError error) {
    _lastError = '${error.errorMsg}${error.permanent ? ' (permanent)' : ''}';
    AppLogger.warn('asr error: $_lastError');
    _listening = false;
    _completeIfNeeded();
  }

  @override
  Future<void> start() async {
    if (!_available) {
      throw const AsrException(
        AppError(kind: AppErrorKind.config, detail: '当前设备没有可用的语音识别服务'),
      );
    }
    _finalText = '';
    _partialText = '';
    _lastError = null;
    _resultCompleter = Completer<void>();
    try {
      await _speech.listen(
        onResult: _handleResult,
        listenOptions: SpeechListenOptions(
          localeId: kIsWeb ? 'en-US' : 'en_US',
          listenFor: const Duration(seconds: 60),
          // 停顿不自动定稿：结束完全由调用方的 stop()（松手）决定。
          // 3 秒静默就 finalize 会把一句带停顿的话切成多段，只剩最后一段。
          pauseFor: const Duration(seconds: 60),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      _listening = true;
    } catch (e) {
      _listening = false;
      throw AsrException(
        AppError(kind: AppErrorKind.permission, detail: '无法启动语音识别：$e'),
      );
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (result.finalResult) {
      // 部分 ROM 会把一句话切出多个 final：recognizedWords 有时只含当前段，
      // 有时是整段累积。能接在上次结果后面就替换，否则按新段追加，
      // 避免「说了一整句却只剩最后一句」。这里不提前置 _listening=false，
      // 结束时机只由 stop() 或状态回调决定。
      final previous = _finalText;
      if (previous.isEmpty ||
          words.toLowerCase().startsWith(previous.toLowerCase())) {
        _finalText = words;
      } else {
        _finalText = '$previous $words'.trim();
      }
      _partialText = _finalText;
      _completeIfNeeded();
    } else {
      _partialText = words;
    }
    onPartial?.call(_partialText);
  }

  void _completeIfNeeded() {
    final completer = _resultCompleter;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  @override
  Future<String> stop() async {
    if (!_listening && _finalText.isNotEmpty) return _finalText;
    try {
      await _speech.stop();
    } catch (e) {
      AppLogger.warn('asr stop failed: $e');
    }
    // 等待 final 结果，8 秒超时。
    try {
      await _resultCompleter?.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      AppLogger.warn('asr final result timeout');
    }
    _listening = false;
    final text = _finalText.isNotEmpty ? _finalText : _partialText;
    if (text.isEmpty && _lastError != null) {
      throw AsrException(
        AppError(kind: AppErrorKind.audio, detail: '识别失败：$_lastError'),
      );
    }
    return text.trim();
  }

  @override
  Future<void> cancel() async {
    _listening = false;
    _partialText = '';
    _finalText = '';
    try {
      await _speech.cancel();
    } catch (e) {
      AppLogger.warn('asr cancel failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }
}
