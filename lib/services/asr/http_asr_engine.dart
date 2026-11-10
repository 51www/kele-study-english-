import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';
import '../audio/audio_recorder.dart';
import 'asr_audio_io.dart' if (dart.library.js_interop) 'asr_audio_web.dart';
import 'asr_engine.dart';

class AsrConfig {
  const AsrConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.language = 'en',
  });

  final String baseUrl;
  final String apiKey;
  final String model;
  final String language;

  bool get isComplete => baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty && model.trim().isNotEmpty;
}

/// OpenAI 兼容的语音识别接口（multipart `/audio/transcriptions`）。
///
/// 默认硅基流动 `FunAudioLLM/SenseVoiceSmall`，也可换成 `Qwen/Qwen3-ASR-1.7B`
/// 或 Groq `whisper-large-v3-turbo`，只改配置不改代码。
/// 该引擎自己采集麦克风（16k 单声道；Web 为浏览器支持的 Opus）。
class HttpAsrEngine implements AsrEngine {
  HttpAsrEngine({required this.config, required this.recorder});

  final AsrConfig config;
  final AudioRecorderService recorder;
  bool _available = false;

  @override
  String get provider => 'http:${config.model}';

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
    if (!_available) {
      throw const AsrException(
        AppError(kind: AppErrorKind.config, detail: '语音识别接口未配置'),
      );
    }
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
    final path = await recorder.stop();
    if (path == null || path.isEmpty) return '';
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
    final dio = Dio(BaseOptions(
      baseUrl: config.baseUrl.replaceAll(RegExp(r'/+$'), ''),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: path.split('/').last,
        ),
        'model': config.model,
        'language': config.language,
        'response_format': 'json',
      });
      final response = await dio.post<Map<String, dynamic>>(
        '/audio/transcriptions',
        data: form,
        options: Options(headers: {'Authorization': 'Bearer ${config.apiKey}'}),
      );
      final text = (response.data?['text'] ?? '').toString().trim();
      AppLogger.debug('asr http result length=${text.length}');
      return text;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? '';
      AppLogger.warn(
        'asr http failed status=$status body=${body.length > 240 ? body.substring(0, 240) : body}',
      );
      throw AsrException(AppError(
        kind: status == 401 || status == 403
            ? AppErrorKind.auth
            : status == 429
                ? AppErrorKind.rateLimited
                : status == 402
                    ? AppErrorKind.config
                    : status == 404
                        ? AppErrorKind.notFound
                        : AppErrorKind.network,
        detail: status == 402
            ? '语音识别接口额度不足（HTTP 402），请检查账户余额'
            : '语音识别请求失败${status == null ? '' : '（HTTP $status）'}',
        retryable: status != 401 && status != 403 && status != 402,
      ));
    } catch (e) {
      throw AsrException(
        AppError(kind: AppErrorKind.network, detail: '语音识别失败：$e', retryable: true),
      );
    } finally {
      dio.close();
    }
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
