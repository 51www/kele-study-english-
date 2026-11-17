import '../../domain/models/models.dart';
import '../../domain/models/provider_presets.dart';
import 'http_asr_engine.dart';

/// 主识别通道的传输方式：HTTP 转写接口或 Chat Audio（input_audio）。
enum AsrTransport { http, chatAudio }

class ResolvedAsr {
  const ResolvedAsr(this.transport, this.config);

  final AsrTransport transport;
  final AsrConfig config;
}

/// 依据 `asr.*` 设置解析主识别通道，供聊天页与轻量页识别路由共用。
///
/// 协议由 `asr.mode` 决定：
/// - `mimo`：ChatAudioAsrEngine（官方 mimo-v2.5-asr 协议）；
/// - `deepseek`：HttpAsrEngine（官方 /v1/tools/asr，只传 file）；
/// - `openai`（默认）：HttpAsrEngine（OpenAI 兼容 /audio/transcriptions）。
///
/// 返回 null 表示未配置完整（缺地址 / 模型 / Key），调用方按既有降级链处理。
class AsrConfigResolver {
  const AsrConfigResolver({
    required this.getSetting,
    required this.readKey,
  });

  final Future<String?> Function(String key) getSetting;
  final Future<String?> Function(String keyRef) readKey;

  Future<ResolvedAsr?> resolve() async {
    final mode = await getSetting(SettingsKeys.asrMode) ?? AsrModes.openai;
    final base = (await getSetting(SettingsKeys.asrBaseUrl) ?? '').trim();
    final model = (await getSetting(SettingsKeys.asrModel) ?? '').trim();
    final language = await getSetting(SettingsKeys.asrLanguage) ?? 'en';
    final key = await readKey(SettingsKeys.asrKeyRef);
    if (base.isEmpty || model.isEmpty || key == null || key.isEmpty) {
      return null;
    }
    if (mode == AsrModes.mimo) {
      return ResolvedAsr(
        AsrTransport.chatAudio,
        AsrConfig(
          baseUrl: base,
          apiKey: key,
          model: model,
          language: language,
          apiMode: AsrApiMode.mimoAsr,
        ),
      );
    }
    return ResolvedAsr(
      AsrTransport.http,
      AsrConfig(
        baseUrl: base,
        apiKey: key,
        model: model,
        language: language,
        apiMode: mode == AsrModes.deepseek ? AsrApiMode.deepseek : AsrApiMode.openai,
      ),
    );
  }
}
