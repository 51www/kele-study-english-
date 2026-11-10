import '../../core/errors.dart';

/// 错误提示条上应该给用户的「下一步」。
enum ChatErrorAction { none, retry, config, text }

class ChatErrorView {
  const ChatErrorView(
    this.message, {
    this.action = ChatErrorAction.none,
    this.actionLabel,
  });

  final String message;
  final ChatErrorAction action;
  final String? actionLabel;
}

/// 错误四分类（+ 配置/权限/音频）转成可读文案与可操作按钮（M2 / T2.6）。
/// service 只给 kind 与脱敏后的 detail，中文文案集中在 features 层。
ChatErrorView describeChatError(AppErrorKind kind, String? detail) {
  final reason = _shortReason(detail);
  switch (kind) {
    case AppErrorKind.auth:
    case AppErrorKind.config:
    case AppErrorKind.notFound:
      return ChatErrorView(
        '接口、密钥或模型名不对，暂时没法回复$reason',
        action: ChatErrorAction.config,
        actionLabel: '去检查配置',
      );
    case AppErrorKind.rateLimited:
      return ChatErrorView(
        '请求太频繁，服务暂时限流了，稍等再试$reason',
        action: ChatErrorAction.retry,
        actionLabel: '稍后重试',
      );
    case AppErrorKind.network:
    case AppErrorKind.server:
      return ChatErrorView(
        '网络或服务异常，这一回合没完成，可以重试或改用文字$reason',
        action: ChatErrorAction.retry,
        actionLabel: '重试本回合',
      );
    case AppErrorKind.permission:
    case AppErrorKind.audio:
      return ChatErrorView(
        '麦克风或朗读暂不可用，已为你保留文字输入，可以直接打字继续$reason',
        action: ChatErrorAction.text,
        actionLabel: '改用文字',
      );
    case AppErrorKind.unknown:
      return ChatErrorView(
        '这一回合没完成，可以重试或改用文字$reason',
        action: ChatErrorAction.retry,
        actionLabel: '重试本回合',
      );
  }
}

String _shortReason(String? detail) {
  if (detail == null || detail.trim().isEmpty) return '';
  final clean = detail.replaceAll(RegExp(r'\s+'), ' ').trim();
  final shown = clean.length > 48 ? '${clean.substring(0, 48)}…' : clean;
  return '（$shown）';
}

/// 保留给后续错误态复用的兜底文案。
String chatErrorText(Object error) => '请求失败：$error';
