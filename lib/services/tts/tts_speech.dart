import 'dart:convert';

import 'tts_voices.dart';

/// 朗读语气风格。`none` 表示不注入 express-as（保持 Edge 默认语调）。
///
/// 只有部分 Neural 音色支持 express-as；Edge 引擎在注入风格失败后会自动
/// 用同一段文本重试无风格版本，因此这里的值可以安全地全部开放。
enum TtsSpeechStyle {
  none('none', '自然（默认）'),
  friendly('friendly', '友好'),
  cheerful('cheerful', '轻快'),
  empathetic('empathetic', '温和'),
  excited('excited', '兴奋'),
  gentle('gentle', '轻柔');

  const TtsSpeechStyle(this.value, this.label);

  final String value;
  final String label;
}

TtsSpeechStyle ttsSpeechStyleFrom(String? value) {
  for (final style in TtsSpeechStyle.values) {
    if (style.value == value) return style;
  }
  return TtsSpeechStyle.none;
}

const _htmlEscape = HtmlEscape(HtmlEscapeMode.element);

const _abbreviations = <String, String>{
  'mr.': 'Mister',
  'mrs.': 'Misses',
  'ms.': 'Miss',
  'dr.': 'Doctor',
  'prof.': 'Professor',
  'e.g.': 'for example',
  'i.e.': 'that is',
  'etc.': 'etcetera',
  'vs.': 'versus',
  'approx.': 'approximately',
  'no.': 'Number',
};

// 缩写键自带结尾句点，不能用 \b 收尾（句点与空白之间没有词边界）；
// 用 (?=\s|$) 收尾，同时开头 \b 避免把 "piano." 里的 "no." 误展开。
final _abbreviationPattern = RegExp(
  r'\b(' +
      _abbreviations.keys.map(RegExp.escape).join('|') +
      r')(?=\s|$)',
  caseSensitive: false,
);

/// 朗读前的纯文本归一化：只改写会影响读音的写法，保留句子结构与标点。
String normalizeForSpeech(String raw) {
  var text = raw.trim();
  text = text.replaceAll('\r', ' ').replaceAll('\n', ' ');
  text = text.replaceAll('\u2018', "'").replaceAll('\u2019', "'");
  text = text.replaceAll('\u201c', '"').replaceAll('\u201d', '"');
  text = text.replaceAll('\u2013', ', ').replaceAll('\u2014', ', ');
  text = text.replaceAll('\u2026', '...');
  text = text.replaceAll(RegExp(r'\s+'), ' ');
  final beforeAbbrev = text;
  text = text.replaceAllMapped(
    _abbreviationPattern,
    (m) {
      final expanded = _abbreviations[m.group(1)!.toLowerCase()] ?? m.group(0)!;
      // 缩写位于句尾时把句点补回来，保住句子结束的停顿信号。
      return m.end == beforeAbbrev.length ? '$expanded.' : expanded;
    },
  );
  // 独立的 & 读作 and；&amp; 之类不会命中（两侧需是空白）。
  text = text.replaceAll(RegExp(r'\s+&\s+'), ' and ');
  return text.trim();
}

/// 朗读正文：归一化后的文本整体做 XML 转义。
///
/// 此前会在标点后注入 `<break time>` 停顿；微软 2025-11 升级端点后
/// `<break>` 一律被拒（1007 "SSML is invalid"），停顿改由标点本身产生。
String _spokenBody(String normalized) => _htmlEscape.convert(normalized);

/// 生成 Edge TTS 的 SSML 帧正文（纯函数，便于单测）。
String buildEdgeSsml({
  required String text,
  required String voice,
  required double rate,
  TtsSpeechStyle style = TtsSpeechStyle.none,
}) {
  final percent = ((rate - 1) * 100).round();
  final rateText = percent >= 0 ? '+$percent%' : '$percent%';
  final safeVoice = voice.replaceAll("'", '').replaceAll('"', '');
  final body = _spokenBody(normalizeForSpeech(text));
  final useStyle = style != TtsSpeechStyle.none;
  final msttsNamespace = useStyle
      ? " xmlns:mstts='http://www.w3.org/2001/mstts'"
      : '';
  final spoken = useStyle
      ? "<mstts:express-as style='${style.value}'>$body</mstts:express-as>"
      : body;
  return "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis'"
      "$msttsNamespace xml:lang='${ttsVoiceLocale(voice)}'>"
      "<voice name='$safeVoice'>"
      "<prosody rate='$rateText' pitch='+0Hz' volume='+0%'>$spoken</prosody>"
      '</voice></speak>';
}
