/// 统一超时表（M2 / T2.1）。
///
/// 所有网络、识别、朗读、播放环节的等待时间都从这里取值，避免散落各处后
/// 出现「15 秒还没有任何反馈」的死角。修改任一环节超时时只需改这里，
/// 并在《开发文档》§5 记录默认值。
class Timeouts {
  Timeouts._();

  /// 建连超时。
  static const connect = Duration(seconds: 10);

  /// 单次响应体读取上限（流式同样适用）。
  static const receive = Duration(seconds: 25);

  /// 请求体发送上限。
  static const send = Duration(seconds: 10);

  /// 设置页「测试连接」：/models 探测。
  static const checkModels = Duration(seconds: 10);

  /// 设置页「测试连接」：/chat/completions 探针。
  static const checkChat = Duration(seconds: 12);

  /// 流式首字等待；超时自动转非流式。
  static const firstToken = Duration(seconds: 6);

  /// 弱网提示条出现时间（在请求仍在进行时给可操作出口）。
  static const slowNotice = Duration(seconds: 15);

  /// 系统语音识别等待 final 结果。
  static const asrSystem = Duration(seconds: 9);

  /// 兼容接口 /audio/transcriptions 识别。
  static const asrHttp = Duration(seconds: 20);

  /// 用对话模型做识别的实验路径。
  static const asrExperimental = Duration(seconds: 40);

  /// Edge TTS 单次合成。
  static const ttsSynthesize = Duration(seconds: 12);

  /// 系统 TTS 整段朗读（含长句）。
  static const systemTts = Duration(seconds: 30);

  /// just_audio 加载音频源。
  static const playerLoad = Duration(seconds: 10);

  /// 旁路请求（提示 / 翻译 /「我想说」）整体上限。
  static const sideRequest = Duration(seconds: 15);

  /// 可重试错误的退避序列：最多重试 2 次。
  static const List<Duration> retryBackoff = [
    Duration(milliseconds: 1200),
    Duration(seconds: 3),
  ];
}
