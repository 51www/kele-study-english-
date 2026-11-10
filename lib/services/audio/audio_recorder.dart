import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/logger.dart';

/// 按住录音：16k / 单声道 / PCM16（Web 端由 record_web 编码成 16k WAV）。
/// 只在系统语音识别不可用时使用；识别可用时由识别引擎独占麦克风。
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  DateTime? _startedAt;

  bool get recording => _recording;

  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      AppLogger.warn('recorder permission check failed: $e');
      return false;
    }
  }

  Future<void> start() async {
    if (_recording) return;
    final path = await _outputPath();
    // Web 也录 WAV：识别接口与对话模型（input_audio）对 wav 兼容性最好。
    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    );
    await _recorder.start(config, path: path);
    _recording = true;
    _startedAt = DateTime.now();
  }

  Future<String?> stop() async {
    if (!_recording) return null;
    _recording = false;
    _startedAt = null;
    try {
      return await _recorder.stop();
    } catch (e) {
      AppLogger.warn('recorder stop failed: $e');
      return null;
    }
  }

  Future<void> cancel() async {
    if (!_recording) return;
    _recording = false;
    _startedAt = null;
    try {
      await _recorder.cancel();
    } catch (e) {
      AppLogger.warn('recorder cancel failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _recorder.dispose();
    } catch (_) {}
  }

  Future<String> _outputPath() async {
    final name = 'rec_${DateTime.now().microsecondsSinceEpoch}';
    if (kIsWeb) return '$name.wav';
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/recordings_$name.wav';
  }
}
