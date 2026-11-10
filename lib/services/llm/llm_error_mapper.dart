import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';

AppError mapDioError(DioException error) {
  final response = error.response;
  final status = response?.statusCode;
  final body = _extractMessage(response?.data);
  AppLogger.error('LLM request failed', '${error.type} status=$status body=$body');

  if (error.type == DioExceptionType.cancel) {
    return const AppError(
      kind: AppErrorKind.network,
      detail: '已取消本次请求',
      retryable: false,
    );
  }
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return AppError(
      kind: AppErrorKind.network,
      detail: '请求超时，请检查网络后重试',
      retryable: true,
      statusCode: status,
    );
  }
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.unknown) {
    return AppError(
      kind: AppErrorKind.network,
      detail: '网络连接失败，请检查网络或接口地址',
      retryable: true,
      statusCode: status,
    );
  }

  switch (status) {
    case 401:
    case 403:
      return AppError(
        kind: AppErrorKind.auth,
        detail: '密钥无效或没有权限（HTTP $status）',
        statusCode: status,
      );
    case 404:
      return AppError(
        kind: AppErrorKind.notFound,
        detail: '接口或模型不存在，请检查接口地址是否包含 /v1（HTTP 404）',
        statusCode: status,
      );
    case 429:
      return AppError(
        kind: AppErrorKind.rateLimited,
        detail: '请求过于频繁，请稍后重试（HTTP 429）',
        retryable: true,
        statusCode: status,
      );
    default:
      if (status != null && status >= 500) {
        return AppError(
          kind: AppErrorKind.server,
          detail: '服务端异常（HTTP $status）${body.isEmpty ? '' : '：$body'}',
          retryable: true,
          statusCode: status,
        );
      }
      return AppError(
        kind: AppErrorKind.server,
        detail: body.isEmpty ? '请求失败（HTTP $status）' : '请求失败（HTTP $status）：$body',
        retryable: false,
        statusCode: status,
      );
  }
}

String _extractMessage(Object? data) {
  if (data == null) return '';
  if (data is String) return _truncate(data);
  if (data is Map) {
    final error = data['error'];
    if (error is Map && error['message'] != null) {
      return _truncate(error['message'].toString());
    }
    if (data['message'] != null) return _truncate(data['message'].toString());
  }
  return '';
}

String _truncate(String value) {
  final single = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return single.length > 200 ? '${single.substring(0, 200)}…' : single;
}
