import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';
import 'llm_error_mapper.dart';
import 'llm_models.dart';
import 'sse_parser.dart';

class ConnectionCheck {
  const ConnectionCheck({
    required this.status,
    required this.message,
    required this.latencyMs,
    this.models = const [],
  });

  /// ok / fail
  final String status;
  final String message;
  final int latencyMs;
  final List<String> models;

  bool get ok => status == 'ok';
}

class LlmClient {
  LlmClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 90),
              sendTimeout: const Duration(seconds: 15),
            ));

  final Dio _dio;

  Options _options(LlmConfig config) => Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
        validateStatus: (status) => true,
      );

  Future<LlmReply> chat(
    LlmConfig config,
    List<LlmMessage> messages, {
    int maxTokens = 700,
    double temperature = 0.8,
    CancelToken? cancelToken,
  }) async {
    final started = DateTime.now();
    final watch = Stopwatch()..start();
    try {
      // 可重试错误（网络中断 / 429 / 5xx）最多重试 2 次，退避 1.2s、3s。
      late Response<Map<String, dynamic>> response;
      var attempt = 0;
      while (true) {
        try {
          response = await _dio.post<Map<String, dynamic>>(
            config.chatUrl,
            data: {
              'model': config.model,
              'messages': messages.map((e) => e.toJson()).toList(),
              'stream': false,
              'temperature': temperature,
              'max_tokens': maxTokens,
            },
            options: _options(config),
            cancelToken: cancelToken,
          );
        } on DioException catch (e) {
          final mapped = mapDioError(e);
          if (mapped.retryable && attempt < 2 && e.type != DioExceptionType.cancel) {
            attempt++;
            AppLogger.warn('chat retry #$attempt after ${e.type}');
            await Future<void>.delayed(Duration(milliseconds: attempt == 1 ? 1200 : 3000));
            continue;
          }
          rethrow;
        }
        final status = response.statusCode ?? 0;
        if ((status == 429 || status >= 500) && attempt < 2) {
          attempt++;
          AppLogger.warn('chat retry #$attempt after HTTP $status');
          await Future<void>.delayed(Duration(milliseconds: attempt == 1 ? 1200 : 3000));
          continue;
        }
        break;
      }
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw AppError(
          kind: _kindFor(status),
          detail: _bodyMessage(response.data) ?? '请求失败（HTTP $status）',
          retryable: status == 429 || status >= 500,
          statusCode: status,
        );
      }
      final text = _contentOf(response.data);
      if (text.isEmpty) {
        final reason = _finishReason(response.data);
        throw AppError(
          kind: AppErrorKind.server,
          detail: '模型没有返回正文内容${reason == null ? '' : '（finish_reason=$reason）'}',
          retryable: true,
          statusCode: status,
        );
      }
      watch.stop();
      return LlmReply(
        text: text,
        usage: LlmUsage.fromJson(
          (response.data?['usage'] as Map?)?.cast<String, Object?>(),
        ),
        latencyMs: watch.elapsedMilliseconds,
        usedStream: false,
        model: config.model,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } finally {
      AppLogger.debug(
        'chat model=${config.model} start=${started.toIso8601String()} cost=${watch.elapsedMilliseconds}ms',
      );
    }
  }

  /// 流式正文。调用方需自行处理“无正文增量”的降级。
  Stream<String> streamChat(
    LlmConfig config,
    List<LlmMessage> messages, {
    int maxTokens = 700,
    double temperature = 0.8,
    CancelToken? cancelToken,
  }) async* {
    try {
      late Response<ResponseBody> response;
      var attempt = 0;
      while (true) {
        try {
          response = await _dio.post<ResponseBody>(
            config.chatUrl,
            data: {
              'model': config.model,
              'messages': messages.map((e) => e.toJson()).toList(),
              'stream': true,
              'temperature': temperature,
              'max_tokens': maxTokens,
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer ${config.apiKey}',
                'Content-Type': 'application/json',
                'Accept': 'text/event-stream',
              },
              responseType: ResponseType.stream,
              validateStatus: (status) => true,
            ),
            cancelToken: cancelToken,
          );
        } on DioException catch (e) {
          final mapped = mapDioError(e);
          if (mapped.retryable && attempt < 2 && e.type != DioExceptionType.cancel) {
            attempt++;
            AppLogger.warn('stream retry #$attempt after ${e.type}');
            await Future<void>.delayed(Duration(milliseconds: attempt == 1 ? 1200 : 3000));
            continue;
          }
          rethrow;
        }
        final code = response.statusCode ?? 0;
        if ((code == 429 || code >= 500) && attempt < 2) {
          attempt++;
          AppLogger.warn('stream retry #$attempt after HTTP $code');
          await Future<void>.delayed(Duration(milliseconds: attempt == 1 ? 1200 : 3000));
          continue;
        }
        break;
      }
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final raw = await _readBody(response.data);
        throw AppError(
          kind: _kindFor(status),
          detail: raw.isEmpty ? '流式请求失败（HTTP $status）' : raw,
          retryable: status == 429 || status >= 500,
          statusCode: status,
        );
      }
      final body = response.data;
      if (body == null) {
        throw const AppError(kind: AppErrorKind.server, detail: '流式响应为空');
      }
      final parser = SseParser();
      await for (final chunk in body.stream) {
        final text = utf8.decode(chunk, allowMalformed: true);
        for (final delta in parser.feed(text)) {
          yield delta;
        }
      }
      for (final delta in parser.flush()) {
        yield delta;
      }
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ConnectionCheck> check(LlmConfig config) async {
    final watch = Stopwatch()..start();
    final models = <String>[];
    String? modelsError;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        config.modelsUrl,
        options: Options(
          headers: {'Authorization': 'Bearer ${config.apiKey}'},
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => true,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final data = response.data?['data'];
        if (data is List) {
          for (final item in data) {
            if (item is Map && item['id'] != null) models.add(item['id'].toString());
          }
        }
      } else {
        modelsError = '模型列表 HTTP $status';
      }
    } on DioException catch (e) {
      modelsError = e.type.name;
    }

    try {
      final started = DateTime.now();
      final response = await _dio.post<Map<String, dynamic>>(
        config.chatUrl,
        data: {
          'model': config.model,
          'messages': [
            LlmMessage.system('Reply with the single word OK.').toJson(),
            LlmMessage.user('ping').toJson(),
          ],
          'stream': false,
          'max_tokens': 80,
          'temperature': 0,
        },
        options: _options(config).copyWith(receiveTimeout: const Duration(seconds: 25)),
      );
      watch.stop();
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return ConnectionCheck(
          status: 'fail',
          message: '连接失败：${_bodyMessage(response.data) ?? 'HTTP $status'}',
          latencyMs: watch.elapsedMilliseconds,
          models: models,
        );
      }
      final choices = response.data?['choices'];
      if (choices is! List || choices.isEmpty) {
        return ConnectionCheck(
          status: 'fail',
          message: '接口返回 200，但没有 choices，可能不是 OpenAI 兼容格式',
          latencyMs: watch.elapsedMilliseconds,
          models: models,
        );
      }
      final content = _contentOf(response.data);
      final reason = _finishReason(response.data);
      final note = content.isEmpty
          ? '接口可用（思考模型仅返回思考内容，finish_reason=$reason）'
          : '接口可用，模型已返回内容';
      AppLogger.debug('connection check ok latency=${watch.elapsedMilliseconds}ms');
      return ConnectionCheck(
        status: 'ok',
        message: '$note${modelsError == null ? '' : '；模型列表读取失败：$modelsError'}',
        latencyMs: DateTime.now().difference(started).inMilliseconds,
        models: models,
      );
    } on DioException catch (e) {
      final mapped = mapDioError(e);
      return ConnectionCheck(
        status: 'fail',
        message: mapped.detail ?? '连接失败',
        latencyMs: watch.elapsedMilliseconds,
        models: models,
      );
    }
  }

  String _contentOf(Map<String, dynamic>? data) {
    final choices = data?['choices'];
    if (choices is! List || choices.isEmpty) return '';
    final message = (choices.first as Map)['message'];
    if (message is! Map) return '';
    final content = message['content'];
    return content is String ? content.trim() : '';
  }

  String? _finishReason(Map<String, dynamic>? data) {
    final choices = data?['choices'];
    if (choices is! List || choices.isEmpty) return null;
    return (choices.first as Map)['finish_reason']?.toString();
  }

  String? _bodyMessage(Map<String, dynamic>? data) {
    if (data == null) return null;
    final error = data['error'];
    if (error is Map && error['message'] != null) return error['message'].toString();
    if (data['message'] != null) return data['message'].toString();
    return null;
  }

  Future<String> _readBody(ResponseBody? body) async {
    if (body == null) return '';
    try {
      final bytes = <int>[];
      await for (final chunk in body.stream) {
        bytes.addAll(chunk);
      }
      final text = utf8.decode(bytes, allowMalformed: true);
      return text.length > 200 ? text.substring(0, 200) : text;
    } catch (_) {
      return '';
    }
  }

  AppErrorKind _kindFor(int status) {
    if (status == 401 || status == 403) return AppErrorKind.auth;
    if (status == 404) return AppErrorKind.notFound;
    if (status == 429) return AppErrorKind.rateLimited;
    if (status >= 500) return AppErrorKind.server;
    return AppErrorKind.server;
  }
}
