import '../ingest/subtitle_parser.dart';

/// 切句结果（尚未落库）。
class SegmentDraft {
  const SegmentDraft({required this.text, required this.startMs, required this.endMs});

  final String text;
  final int startMs;
  final int endMs;

  int get wordCount => countWords(text);
}

int countWords(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
}

const _abbreviations = <String>{
  'mr', 'mrs', 'ms', 'dr', 'prof', 'st', 'vs', 'etc', 'no',
  'e.g', 'i.e', 'u.s', 'a.m', 'p.m', 'inc', 'ltd',
};

const _conjunctions = <String>{'and', 'but', 'or', 'because', 'so', 'while', 'however'};

/// 把字幕行变成 3–12 秒 / 5–22 词的句子级单元（需求 F12）。
///
/// 纯函数：不读文件、不联网；手动修正由详情页调用 [resequence] 后整份落库。
List<SegmentDraft> splitSegments(
  List<SubtitleCue> cues, {
  int paddingMs = 100,
  int minWords = 5,
  int maxWords = 22,
  int minDurationMs = 3000,
  int maxDurationMs = 12000,
}) {
  final cleaned = <SubtitleCue>[];
  for (final cue in cues) {
    if (cue.endMs <= cue.startMs) continue;
    final text = cleanCueText(cue.text);
    if (text.isEmpty || isNoise(text)) continue;
    cleaned.add(cue.copyWith(text: text));
  }
  if (cleaned.isEmpty) return const [];

  // 1) 字幕行通常被随意断行：先合并成语义完整的单元。
  final units = <_Unit>[];
  _Unit? buffer;
  for (final cue in cleaned) {
    buffer = _Unit(
      text: buffer == null ? cue.text : '${buffer.text} ${cue.text}',
      startMs: buffer?.startMs ?? cue.startMs,
      endMs: cue.endMs,
    );
    final words = countWords(buffer.text);
    final duration = buffer.endMs - buffer.startMs;
    if ((_isComplete(buffer.text) && words >= minWords && duration >= minDurationMs) ||
        words > maxWords ||
        duration > maxDurationMs) {
      units.add(buffer);
      buffer = null;
    }
  }
  if (buffer != null) units.add(buffer);

  // 2) 按句末标点切分，时间轴按词数比例分配。
  final drafts = <SegmentDraft>[];
  for (final unit in units) {
    final sentences = _splitSentences(unit.text);
    if (sentences.isEmpty) continue;
    final totalWords = sentences.fold<int>(0, (sum, e) => sum + countWords(e));
    final duration = unit.endMs - unit.startMs;
    var cursor = unit.startMs;
    for (var i = 0; i < sentences.length; i++) {
      final end = i == sentences.length - 1
          ? unit.endMs
          : cursor + (duration * countWords(sentences[i]) / (totalWords == 0 ? 1 : totalWords)).round();
      drafts.add(SegmentDraft(
        text: sentences[i],
        startMs: cursor,
        endMs: end > cursor ? end : cursor + 1,
      ));
      cursor = end;
    }
  }

  // 3) 过长句在逗号 / 连词处再切。
  final expanded = <SegmentDraft>[];
  for (final draft in drafts) {
    expanded.addAll(_splitLong(draft, maxWords, maxDurationMs));
  }

  // 4) 过短 / 过短的相邻单元合并（不超过上限）。
  final merged = <SegmentDraft>[];
  for (final draft in expanded) {
    if (merged.isNotEmpty) {
      final prev = merged.last;
      final tooShort = draft.wordCount < minWords ||
          draft.endMs - draft.startMs < minDurationMs ||
          prev.wordCount < minWords ||
          prev.endMs - prev.startMs < minDurationMs;
      final combined = '${prev.text} ${draft.text}';
      if (tooShort &&
          countWords(combined) <= maxWords &&
          draft.endMs - prev.startMs <= maxDurationMs) {
        merged[merged.length - 1] = SegmentDraft(
          text: combined,
          startMs: prev.startMs,
          endMs: draft.endMs,
        );
        continue;
      }
    }
    merged.add(draft);
  }

  // 5) 相邻重复句去重 + 首尾各留余量。
  final deduped = <SegmentDraft>[];
  for (final draft in merged) {
    if (deduped.isNotEmpty &&
        deduped.last.text.toLowerCase() == draft.text.toLowerCase()) {
      final prev = deduped.last;
      deduped[deduped.length - 1] =
          SegmentDraft(text: prev.text, startMs: prev.startMs, endMs: draft.endMs);
      continue;
    }
    deduped.add(draft);
  }
  return [
    for (final draft in deduped)
      SegmentDraft(
        text: draft.text,
        startMs: (draft.startMs - paddingMs).clamp(0, draft.startMs),
        endMs: draft.endMs + paddingMs,
      ),
  ];
}

/// 详情页手动合并 / 拆分 / 微调后重排序号，不重新解析字幕。
List<SegmentDraft> resequence(List<SegmentDraft> drafts) => [
      for (final draft in drafts)
        SegmentDraft(text: draft.text, startMs: draft.startMs, endMs: draft.endMs),
    ];

String cleanCueText(String raw) => raw
    .replaceAll(RegExp(r'<[^>]*>|\{[^}]*\}'), '')
    .replaceAll(RegExp(r'\[[^\]]*(?:music|applause|laughter|silence)[^\]]*\]', caseSensitive: false), '')
    .replaceAll(RegExp(r'\([^\)]*(?:music|applause|laughter|silence)[^\)]*\)', caseSensitive: false), '')
    .replaceAll(RegExp(r'^\s*[-–—]\s*'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool isNoise(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return true;
  if (!RegExp(r'[A-Za-z]').hasMatch(trimmed)) return true;
  final bare = trimmed
      .replaceAll(RegExp(r'[\[\]\(\)\{\}♪♫.,!?\-]'), '')
      .trim()
      .toLowerCase();
  return bare.isEmpty ||
      const {
        'music', 'applause', 'laughter', 'silence', 'theme music',
        'background music', 'inaudible', 'crosstalk',
      }.contains(bare);
}

class _Unit {
  const _Unit({required this.text, required this.startMs, required this.endMs});

  final String text;
  final int startMs;
  final int endMs;
}

bool _isComplete(String text) => RegExp(r'''[.!?;]["')\]]?\s*$''').hasMatch(text);

List<String> _splitSentences(String text) {
  final result = <String>[];
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    buffer.write(ch);
    if (!'.?!;'.contains(ch)) continue;
    final next = i + 1 < text.length ? text[i + 1] : '';
    if (next.isNotEmpty && !RegExp(r'\s').hasMatch(next)) continue;
    final current = buffer.toString().trim();
    final lastWord = current
        .split(RegExp(r'\s+'))
        .last
        .replaceAll(RegExp(r'[.!?;]+$'), '')
        .toLowerCase();
    if (_abbreviations.contains(lastWord) || lastWord.length == 1) continue;
    if (current.isNotEmpty) result.add(current);
    buffer.clear();
  }
  final rest = buffer.toString().trim();
  if (rest.isNotEmpty) result.add(rest);
  return result;
}

List<SegmentDraft> _splitLong(SegmentDraft draft, int maxWords, int maxDurationMs) {
  if (draft.wordCount <= maxWords && draft.endMs - draft.startMs <= maxDurationMs) {
    return [draft];
  }
  final parts = _splitAtComma(draft.text);
  if (parts == null) return [draft]; // 实在切不动时保留原句，交给详情页手动拆分
  final total = countWords(parts.$1) + countWords(parts.$2);
  if (total == 0) return [draft];
  final duration = draft.endMs - draft.startMs;
  final middle = draft.startMs + (duration * countWords(parts.$1) / total).round();
  final left = SegmentDraft(text: parts.$1, startMs: draft.startMs, endMs: middle);
  final right = SegmentDraft(text: parts.$2, startMs: middle, endMs: draft.endMs);
  return [
    ..._splitLong(left, maxWords, maxDurationMs),
    ..._splitLong(right, maxWords, maxDurationMs),
  ];
}

/// 返回 (左半句, 右半句)，找不到合适的逗号 / 连词切点时返回 null。
(String, String)? _splitAtComma(String text) {
  final tokens = text.split(RegExp(r'\s+'));
  if (tokens.length < 10) return null;
  final candidates = <int>[];
  for (var i = 0; i < tokens.length - 1; i++) {
    final word = tokens[i].toLowerCase().replaceAll(RegExp(r'[^a-z,]'), '');
    if (word.endsWith(',') || _conjunctions.contains(word)) {
      final cut = i + 1;
      if (cut >= 5 && tokens.length - cut >= 5) candidates.add(cut);
    }
  }
  if (candidates.isEmpty) return null;
  final half = tokens.length / 2;
  candidates.sort((a, b) => (a - half).abs().compareTo((b - half).abs()));
  final cut = candidates.first;
  return (tokens.take(cut).join(' '), tokens.skip(cut).join(' '));
}
