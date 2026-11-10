import 'dart:typed_data';

import '../../core/errors.dart';

class TtsVoice {
  const TtsVoice({required this.id, required this.label});

  final String id;
  final String label;
}

class TtsResult {
  const TtsResult({
    this.bytes,
    this.mimeType = 'audio/mpeg',
    this.spoken = false,
    this.fromCache = false,
    required this.engine,
  });

  /// Edge TTS 返回的音频数据；系统 TTS 直接朗读时为空。
  final Uint8List? bytes;
  final String mimeType;

  /// true 表示音频已经由引擎直接播放完成（系统 TTS）。
  final bool spoken;
  final bool fromCache;
  final String engine;
}

class TtsException implements Exception {
  const TtsException(this.error);

  final AppError error;

  @override
  String toString() => 'TtsException(${error.debugLabel}: ${error.detail})';
}

/// 朗读能力抽象：文本 + 音色 + 语速 → 可播放音频 / 已直接朗读。
abstract class TtsEngine {
  String get id;

  Future<List<TtsVoice>> voices();

  Future<TtsResult> synthesize(
    String text, {
    required String voice,
    required double rate,
  });

  Future<void> cancel();

  Future<void> dispose();
}
