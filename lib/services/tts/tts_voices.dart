/// Edge TTS 音色清单（单一数据源）。
///
/// 设置页与朗读引擎都读这里，避免两处硬编码不一致（曾出现设置页有 Ryan、
/// 引擎 voices() 没有的情况）。入选原则是社区长期稳定可用的 Neural 音色。
class TtsVoiceSpec {
  const TtsVoiceSpec({
    required this.id,
    required this.label,
    required this.locale,
  });

  final String id;
  final String label;

  /// 供 xml:lang 与系统 TTS 降级时选择语言。
  final String locale;
}

const defaultTtsVoiceId = 'en-US-AriaNeural';

const ttsVoiceCatalog = <TtsVoiceSpec>[
  TtsVoiceSpec(id: 'en-US-AriaNeural', label: 'Aria（女声·美音）', locale: 'en-US'),
  TtsVoiceSpec(id: 'en-US-JennyNeural', label: 'Jenny（女声·美音）', locale: 'en-US'),
  TtsVoiceSpec(id: 'en-US-GuyNeural', label: 'Guy（男声·美音）', locale: 'en-US'),
  TtsVoiceSpec(id: 'en-US-AndrewNeural', label: 'Andrew（男声·美音）', locale: 'en-US'),
  TtsVoiceSpec(id: 'en-GB-SoniaNeural', label: 'Sonia（女声·英音）', locale: 'en-GB'),
  TtsVoiceSpec(id: 'en-GB-LibbyNeural', label: 'Libby（女声·英音）', locale: 'en-GB'),
  TtsVoiceSpec(id: 'en-GB-RyanNeural', label: 'Ryan（男声·英音）', locale: 'en-GB'),
  TtsVoiceSpec(id: 'en-AU-NatashaNeural', label: 'Natasha（女声·澳音）', locale: 'en-AU'),
  TtsVoiceSpec(id: 'en-AU-WilliamNeural', label: 'William（男声·澳音）', locale: 'en-AU'),
];

/// 未知音色（老数据 / 用户自填）一律按美音处理，并原样交给 Edge。
TtsVoiceSpec? findTtsVoice(String id) {
  for (final spec in ttsVoiceCatalog) {
    if (spec.id == id) return spec;
  }
  return null;
}

String ttsVoiceLocale(String id) => findTtsVoice(id)?.locale ?? 'en-US';

String ttsVoiceLabel(String id) => findTtsVoice(id)?.label ?? id;
