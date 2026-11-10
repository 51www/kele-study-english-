import '../../core/errors.dart';

/// 语音识别能力抽象。识别引擎独占麦克风。
abstract class AsrEngine {
  String get provider;

  /// 初始化并检测当前设备是否有可用的识别服务。
  Future<bool> initialize();

  bool get available;

  /// 开始一次识别（内部开始采集麦克风）。
  Future<void> start();

  /// 结束识别并返回最终文本；无结果返回空字符串。
  Future<String> stop();

  /// 放弃本次识别。
  Future<void> cancel();

  /// 实时中间结果（用于 UI 展示）。
  void Function(String partial)? onPartial;

  Future<void> dispose();
}

class AsrException implements Exception {
  const AsrException(this.error);

  final AppError error;

  @override
  String toString() => 'AsrException(${error.debugLabel})';
}
