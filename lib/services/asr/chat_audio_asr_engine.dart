import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';
import '../audio/audio_recorder.dart';
import 'asr_audio_io.dart' if (dart.library.js_interop) 'asr_audio_web.dart';
import 'asr_engine.dart';
import 'http_asr_engine.dart';

/// 实验引擎：用对话模型（OpenAI 兼容 `/chat/completions` + `input_audio`）做语音识别。
///
/// 为什么存在：部分厂商的对话模型支持音频输入，可在没有独立 ASR 接口时兜底。
///
/// 已知缺陷（不要去掉这些说明）：
/// - 延迟 4–6 秒（实测 4.4s 音频约 5–10s），明显慢于专用 ASR（约 0.7–3s）；
/// - 无词级时间戳，拿不到发音逐词信息；
/// - 输出契约依赖提示词，模型不听话时需要剥围栏并做宽松解析；
/// - 模型升级/下线可能让该链路失效，所以默认关闭、只作为最后兜底。
class ChatAudioAsrEngine implements AsrEngine {
  ChatAudioAsrEngine({required this.config, required this.recorder});

  final AsrConfig config;
  final AudioRecorderService recorder;
  bool _available = false;

  @override
  String get provider => 'chat-audio:${config.model}';

  @override
  bool get available => _available;

  @override
  void Function(String partial)? onPartial;

  @override
  Future<bool> initialize() async {
    _available = config.isComplete;
    return _available;
  }

  @override
  Future<void> start() async {
    final granted = await recorder.hasPermission();
    if (!granted) {
      throw const AsrException(
        AppError(kind: AppErrorKind.permission, detail: '麦克风权限被拒绝'),
      );
    }
    await recorder.start();
  }

  @override
  Future<String> stop() async {
    final path = await stopCapture();
    if (path == null) return '';
    return transcribe(path);
  }

  /// 停止录音并返回文件路径，便于识别失败时换引擎复用同一段音频。
  Future<String?> stopCapture() => recorder.stop();

  Future<String> transcribe(String path) async {
    final bytes = await readAudioBytes(path);
    if (bytes == null || bytes.isEmpty) {
      throw const AsrException(
        AppError(kind: AppErrorKind.audio, detail: '没有录到声音'),
      );
    }
    // MiMo 目前只接受 wav/mp3；Web 录音已改成 wav，Android 本来就是 wav。
    final format = _formatOf(path);
    final dio = Dio(BaseOptions(
      baseUrl: config.baseUrl.replaceAll(RegExp(r'/+$'), ''),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 45),
    ));
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': config.model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are an English speech transcriber. Listen to the user audio and output ONLY one JSON object: '
                  '{"text":"<exact English words>"}. Do not translate, do not explain, do not use markdown.',
            },
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': 'Transcribe this audio exactly.'},
                {
                  'type': 'input_audio',
                  'input_audio': {'data': base64Encode(bytes), 'format': format},
                },
              ],
            },
          ],
          'max_tokens': 300,
          'temperature': 0,
        },
        options: Options(headers: {'Authorization': 'Bearer ${config.apiKey}'}),
      );
      final choices = response.data?['choices'];
      final message = (choices is List && choices.isNotEmpty && choices.first is Map)
          ? (choices.first as Map)['message'] as Map?
          : null;
      final content = (message?['content'] ?? '').toString().trim();
      final reasoning = (message?['reasoning_content'] ?? '').toString().trim();
      // content 为主；有些推理模型把结果落在 reasoning_content。
      final text = _parse(content) ?? _parse(reasoning) ?? '';
      AppLogger.debug('chat-audio asr content=${content.length} reasoning=${reasoning.length} text=${text.length}');
      return text;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? '';
      AppLogger.warn('chat-audio asr failed status=$status body=${body.length > 240 ? body.substring(0, 240) : body}');
      throw AsrException(AppError(
        kind: status == 401 || status == 403
            ? AppErrorKind.auth
            : status == 429
                ? AppErrorKind.rateLimited
                : status == 402
                    ? AppErrorKind.config
                    : AppErrorKind.network,
        detail: '实验识别请求失败${status == null ? '' : '（HTTP $status）'}',
        retryable: status != 401 && status != 403 && status != 402,
      ));
    } catch (e) {
      throw AsrException(
        AppError(kind: AppErrorKind.network, detail: '实验识别失败：$e', retryable: true),
      );
    } finally {
      dio.close();
    }
  }

  /// 剥掉 ```json 围栏后取 {"text": "..."}；解析不出来就返回 null。
  String? _parse(String raw) {
    if (raw.isEmpty) return null;
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
      final end = text.lastIndexOf('```');
      if (end >= 0) text = text.substring(0, end);
      text = text.trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      final candidate = text.substring(start, end + 1);
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map && decoded['text'] != null) {
          final value = decoded['text'].toString().trim();
          if (value.isNotEmpty) return value;
        }
      } catch (_) {
        // 落到下面的宽松提取
      }
    }
    final match = RegExp(r'"text"\s*:\s*"([^"]+)"').firstMatch(text);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String _formatOf(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp3')) return 'mp3';
    if (lower.endsWith('.webm')) return 'webm';
    return 'wav';
  }

  @override
  Future<void> cancel() async {
    await recorder.cancel();
  }

  @override
  Future<void> dispose() async {
    await recorder.dispose();
  }
}
