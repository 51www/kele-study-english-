/// 模型 / 语音识别的简化配置方案。
///
/// 「只需一个 Key」的方案会把同一个 Key 同时写入对话模型与语音识别的
/// Key 引用，其余地址、模型名、识别协议全部由预设决定。
enum ConfigScheme {
  deepseek,
  mimo,
  custom;

  String get value => switch (this) {
        ConfigScheme.deepseek => 'deepseek',
        ConfigScheme.mimo => 'mimo',
        ConfigScheme.custom => 'custom',
      };

  String get label => switch (this) {
        ConfigScheme.deepseek => 'DeepSeek',
        ConfigScheme.mimo => 'MiMo',
        ConfigScheme.custom => '自定义',
      };

  static ConfigScheme from(String? value) => switch (value) {
        'deepseek' => ConfigScheme.deepseek,
        'mimo' => ConfigScheme.mimo,
        _ => ConfigScheme.custom,
      };
}

/// 语音识别请求协议。
abstract final class AsrModes {
  static const openai = 'openai';
  static const deepseek = 'deepseek';
  static const mimo = 'mimo';
}

class ProviderPreset {
  const ProviderPreset({
    required this.scheme,
    required this.llmBaseUrl,
    required this.llmModel,
    required this.asrBaseUrl,
    required this.asrModel,
    required this.asrMode,
    required this.asrLabel,
  });

  final ConfigScheme scheme;
  final String llmBaseUrl;
  final String llmModel;
  final String asrBaseUrl;
  final String asrModel;
  final String asrMode;
  final String asrLabel;
}

/// DeepSeek：对话用 deepseek-v4-flash，识别用官方 /v1/tools/asr。
/// ASR 接口不接收 model 参数，asrModel 仅用于本地展示与配置完整性校验。
const deepSeekPreset = ProviderPreset(
  scheme: ConfigScheme.deepseek,
  llmBaseUrl: 'https://api.deepseek.com/v1',
  llmModel: 'deepseek-v4-flash',
  asrBaseUrl: 'https://api.deepseek.com/v1',
  asrModel: 'deepseek-asr',
  asrMode: AsrModes.deepseek,
  asrLabel: 'DeepSeek 语音识别',
);

/// MiMo：对话用 mimo-v2.6-flash，识别用 mimo-v2.5-asr
/// （Chat Completions + input_audio，官方 ASR 协议）。
const mimoPreset = ProviderPreset(
  scheme: ConfigScheme.mimo,
  llmBaseUrl: 'https://api.xiaomimimo.com/v1',
  llmModel: 'mimo-v2.6-flash',
  asrBaseUrl: 'https://api.xiaomimimo.com/v1',
  asrModel: 'mimo-v2.5-asr',
  asrMode: AsrModes.mimo,
  asrLabel: 'mimo-v2.5-asr',
);

/// 自定义方案的历史默认值（保持旧用户配置 semantics 不变）。
const customPreset = ProviderPreset(
  scheme: ConfigScheme.custom,
  llmBaseUrl: 'https://aiping.cn/api/v1',
  llmModel: 'GLM-5.3-Flash',
  asrBaseUrl: 'https://api.siliconflow.cn/v1',
  asrModel: 'FunAudioLLM/SenseVoiceSmall',
  asrMode: AsrModes.openai,
  asrLabel: 'FunAudioLLM/SenseVoiceSmall',
);

ProviderPreset presetFor(ConfigScheme scheme) => switch (scheme) {
      ConfigScheme.deepseek => deepSeekPreset,
      ConfigScheme.mimo => mimoPreset,
      ConfigScheme.custom => customPreset,
    };
