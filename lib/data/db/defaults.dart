import '../../domain/models/models.dart';

/// 设置项默认值（与《开发文档》§5 一致）。
const defaultSettings = <String, String>{
  SettingsKeys.ttsEngine: 'edge',
  SettingsKeys.ttsVoice: 'en-US-AriaNeural',
  SettingsKeys.ttsRate: '1.0',
  SettingsKeys.ttsAutoPlay: 'true',
  SettingsKeys.level: 'B1',
  SettingsKeys.correctionMode: 'gentle',
  SettingsKeys.translateDefault: 'off',
  SettingsKeys.inputMode: 'voice',
  SettingsKeys.targetMinutes: '10',
  SettingsKeys.cacheLimitMb: '80',
  SettingsKeys.monthlyBudget: '50',
  SettingsKeys.asrBaseUrl: 'https://api.siliconflow.cn/v1',
  SettingsKeys.asrModel: 'FunAudioLLM/SenseVoiceSmall',
  SettingsKeys.asrLanguage: 'en',
  SettingsKeys.asrExperimentalEnabled: 'false',
  SettingsKeys.asrExperimentalBaseUrl: 'https://aiping.cn/api/v1',
  SettingsKeys.asrExperimentalModel: 'MiMo-V2.6-Flash',
  // 二期：单句听写（默认值见技术补充文档 §4）
  SettingsKeys.dictationPassThreshold: '90',
  SettingsKeys.dictationContractionEquivalent: 'true',
  SettingsKeys.dictationNumberEquivalent: 'true',
  SettingsKeys.dictationSpeed: '1.0',
  // 三期：复练判分与每日上限（Q7 / Q8 默认口径）
  SettingsKeys.reviewSpeakPassThreshold: '80',
  SettingsKeys.reviewDailyLimit: '5',
  // 三期 M12：主对话学习者档案，默认开启、可一键关闭
  SettingsKeys.learnerProfileEnabled: 'true',
};
