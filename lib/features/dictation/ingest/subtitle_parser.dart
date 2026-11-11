import 'dart:convert';
import 'dart:typed_data';

import 'package:charset/charset.dart' as charset;

/// 一条原始字幕（解析后、切句前）。
class SubtitleCue {
  const SubtitleCue({required this.startMs, required this.endMs, required this.text});

  final int startMs;
  final int endMs;
  final String text;

  SubtitleCue copyWith({int? startMs, int? endMs, String? text}) => SubtitleCue(
        startMs: startMs ?? this.startMs,
        endMs: endMs ?? this.endMs,
        text: text ?? this.text,
      );
}

class ParsedSubtitle {
  const ParsedSubtitle({
    required this.cues,
    required this.encoding,
    required this.durationMs,
  });

  final List<SubtitleCue> cues;
  final String encoding;
  final int durationMs;
}

/// 字幕解析失败：文案直接给导入页展示，包含「原因 + 下一步」。
class SubtitleParseException implements Exception {
  const SubtitleParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 只解析本地 `.srt` / `.vtt`，不联网、不调用模型。
class SubtitleParser {
  SubtitleParser._();

  static const maxDurationMs = 30 * 60 * 1000; // 需求 Q17：单集上限 30 分钟

  static final _timeCode = RegExp(r'^(?:(\d{1,2}):)?(\d{1,2}):(\d{2})[.,](\d{1,3})$');
  static final _tag = RegExp(r'<[^>]*>|\{[^}]*\}');

  static ParsedSubtitle parse(
    Uint8List bytes, {
    required String fileName,
    int maxDurationMs = SubtitleParser.maxDurationMs,
  }) {
    if (bytes.isEmpty) {
      throw const SubtitleParseException('字幕文件是空的，请重新选择一份 .srt 或 .vtt 字幕。');
    }
    final text = _decode(bytes);
    final name = fileName.toLowerCase();
    final isVtt = name.endsWith('.vtt') || text.trimLeft().toUpperCase().startsWith('WEBVTT');
    if (!isVtt && !name.endsWith('.srt')) {
      throw const SubtitleParseException('只支持 .srt / .vtt 字幕，请换一份文件。');
    }

    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = normalized.split(RegExp(r'\n[ \t]*\n'));
    final cues = <SubtitleCue>[];
    for (final block in blocks) {
      final lines = block.split('\n').where((e) => e.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      final first = lines.first.trim().toUpperCase();
      if (isVtt && (first.startsWith('WEBVTT') || first.startsWith('NOTE') || first.startsWith('STYLE'))) {
        continue;
      }
      final arrowIndex = lines.indexWhere((e) => e.contains('-->'));
      if (arrowIndex < 0) continue;
      final parts = lines[arrowIndex].split('-->');
      if (parts.length < 2) continue;
      final start = _parseTime(parts[0].trim().split(RegExp(r'\s+')).first);
      final end = _parseTime(parts[1].trim().split(RegExp(r'\s+')).first);
      if (start == null || end == null || end <= start) continue;
      final raw = lines.skip(arrowIndex + 1).join(' ');
      final clean = _clean(raw);
      if (clean.isEmpty) continue;
      cues.add(SubtitleCue(startMs: start, endMs: end, text: clean));
    }

    if (cues.isEmpty) {
      throw const SubtitleParseException(
        '没有读到带时间轴的字幕行，请确认文件是标准的 .srt / .vtt，或另存为 UTF-8 后重试。',
      );
    }
    final durationMs = cues.map((e) => e.endMs).reduce((a, b) => a > b ? a : b);
    if (durationMs > maxDurationMs) {
      throw const SubtitleParseException(
        '这份素材超过 30 分钟，二期只支持单集 30 分钟以内。请剪辑成较短的一段再导入。',
      );
    }
    return ParsedSubtitle(cues: cues, encoding: _encodingLabel(bytes), durationMs: durationMs);
  }

  static String _decode(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      try {
        return utf8.decode(bytes.sublist(3), allowMalformed: false);
      } on FormatException {
        throw const SubtitleParseException('字幕编码有问题，请另存为 UTF-8 后重试。');
      }
    }
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      try {
        final decoded = charset.gbk.decode(bytes);
        if (decoded.contains('\uE7B3')) {
          throw const SubtitleParseException('字幕编码无法识别，请另存为 UTF-8 后重试。');
        }
        return decoded;
      } on SubtitleParseException {
        rethrow;
      } on Object {
        throw const SubtitleParseException('字幕编码无法识别，请另存为 UTF-8 后重试。');
      }
    }
  }

  static String _encodingLabel(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return 'UTF-8 BOM';
    }
    try {
      utf8.decode(bytes, allowMalformed: false);
      return 'UTF-8';
    } on FormatException {
      return 'GBK';
    }
  }

  static int? _parseTime(String raw) {
    final match = _timeCode.firstMatch(raw);
    if (match == null) return null;
    final hour = match.group(1) != null ? int.parse(match.group(1)!) : 0;
    final minute = int.parse(match.group(2)!);
    final second = int.parse(match.group(3)!);
    final ms = int.parse(match.group(4)!.padRight(3, '0'));
    return ((hour * 60 + minute) * 60 + second) * 1000 + ms;
  }

  static String _clean(String raw) => raw
      .replaceAll(_tag, '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
