/// 统一错误类型：service 层只返回 [AppError]，由 Controller 转成 UI 文案。
enum AppErrorKind { auth, notFound, rateLimited, server, network, config, permission, audio, unknown }

class AppError implements Exception {
  const AppError({
    required this.kind,
    this.detail,
    this.retryable = false,
    this.statusCode,
  });

  final AppErrorKind kind;
  final String? detail;
  final bool retryable;
  final int? statusCode;

  String get debugLabel {
    switch (kind) {
      case AppErrorKind.auth:
        return 'auth';
      case AppErrorKind.notFound:
        return 'notFound';
      case AppErrorKind.rateLimited:
        return 'rateLimited';
      case AppErrorKind.server:
        return 'server';
      case AppErrorKind.network:
        return 'network';
      case AppErrorKind.config:
        return 'config';
      case AppErrorKind.permission:
        return 'permission';
      case AppErrorKind.audio:
        return 'audio';
      case AppErrorKind.unknown:
        return 'unknown';
    }
  }

  @override
  String toString() => 'AppError($debugLabel, status=$statusCode, detail=$detail)';
}
