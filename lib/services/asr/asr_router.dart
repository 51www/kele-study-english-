import '../../core/errors.dart';
import '../../core/logger.dart';
import '../../data/db/local_store.dart';
import '../../data/repositories/repositories.dart';
import '../../data/secure/key_store.dart';
import '../../domain/models/models.dart';
import '../audio/audio_recorder.dart';
import 'asr_engine.dart';
import 'chat_audio_asr_engine.dart';
import 'http_asr_engine.dart';
import 'system_asr_engine.dart';

/// 轻量页（今日复练 / 热身 / 听写）共用的识别路由。
///
/// 引擎优先级与聊天页语音输入一致（技术设计 §2.4.1、设置页「语音识别配置」
/// 的口径「未配置时用系统识别」）：
///
/// 1. 已配置独立识别接口（base + model + Key）→ [HttpAsrEngine]；
/// 2. 未配置接口但显式开启实验开关 → [ChatAudioAsrEngine]；
/// 3. 其余退回系统识别 [SystemAsrEngine]。
///
/// 每次 [initialize] 都重新读配置，设置页改完识别接口后无需重启即生效。
/// 无任何识别通道时 [initialize] 返回 false，页面按既有设计降级键盘输入。
class AsrRouter implements AsrEngine {
  AsrRouter({
    required this.settings,
    required this.keyStore,
    required this.profiles,
    required this.recorder,
    SystemAsrEngine? system,
  }) : _system = system ?? SystemAsrEngine();

  final LocalStore settings;
  final KeyStore keyStore;
  final LlmProfileRepository profiles;
  final AudioRecorderService recorder;
  final SystemAsrEngine _system;

  AsrEngine? _active;

  @override
  String get provider => _active?.provider ?? 'system';

  @override
  bool get available => _active?.available ?? false;

  @override
  void Function(String partial)? onPartial;

  @override
  Future<bool> initialize() async {
    final engine = await _pick();
    _active = engine;
    final ok = await engine.initialize();
    AppLogger.debug('asr router provider=${engine.provider} available=$ok');
    return ok;
  }

  Future<AsrEngine> _pick() async {
    final base = await settings.setting(SettingsKeys.asrBaseUrl) ??
        'https://api.siliconflow.cn/v1';
    final model = await settings.setting(SettingsKeys.asrModel) ??
        'FunAudioLLM/SenseVoiceSmall';
    final key = await keyStore.read(SettingsKeys.asrKeyRef);
    final language = await settings.setting(SettingsKeys.asrLanguage) ?? 'en';

    // 实验引擎（默认关闭）：用对话模型做识别，最后兜底。
    ChatAudioAsrEngine? chatAudio;
    final experimentalOn =
        await settings.setting(SettingsKeys.asrExperimentalEnabled) == 'true';
    if (experimentalOn) {
      final profile = await profiles.loadOrCreate();
      final expKey = await keyStore.read(SettingsKeys.asrExperimentalKeyRef) ??
          await keyStore.read(profile.keyRef);
      if (expKey != null && expKey.isNotEmpty) {
        chatAudio = ChatAudioAsrEngine(
          config: AsrConfig(
            baseUrl: await settings
                    .setting(SettingsKeys.asrExperimentalBaseUrl) ??
                'https://aiping.cn/api/v1',
            apiKey: expKey,
            model: await settings.setting(SettingsKeys.asrExperimentalModel) ??
                'MiMo-V2.6-Flash',
            language: language,
          ),
          recorder: recorder,
        );
      }
    }

    if (base.trim().isNotEmpty &&
        model.trim().isNotEmpty &&
        key != null &&
        key.isNotEmpty) {
      return HttpAsrEngine(
        config: AsrConfig(
          baseUrl: base,
          apiKey: key,
          model: model,
          language: language,
        ),
        recorder: recorder,
      );
    }
    return chatAudio ?? _system;
  }

  @override
  Future<void> start() async {
    final engine = _active;
    if (engine == null || !engine.available) {
      throw const AsrException(
        AppError(kind: AppErrorKind.config, detail: '当前设备没有可用的语音识别服务'),
      );
    }
    engine.onPartial = (text) => onPartial?.call(text);
    await engine.start();
  }

  @override
  Future<String> stop() async {
    final engine = _active;
    if (engine == null) return '';
    return engine.stop();
  }

  @override
  Future<void> cancel() async {
    await _active?.cancel();
  }

  @override
  Future<void> dispose() async {
    // Http/ChatAudio 引擎持有的是共享录音器，dispose 会连带停掉其它页面的
    // 录音会话，这里只取消识别、只回收自建的系统引擎。
    await _active?.cancel();
    await _system.dispose();
  }
}
