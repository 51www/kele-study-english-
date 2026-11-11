import 'dart:convert';

/// 二期：一份用户导入的本地教材（需求 F11 / F15）。
///
/// 字段与 SQLite `material` 表、Web 兜底 JSON 完全一致。
class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.title,
    required this.mediaPath,
    required this.mediaName,
    required this.mediaKind,
    required this.subtitleName,
    required this.sourceHash,
    required this.durationMs,
    required this.segmentCount,
    required this.createdAt,
    this.lastPracticedAt,
  });

  final String id;
  final String title;
  final String mediaPath;
  final String mediaName;
  final String mediaKind; // audio / video / web
  final String subtitleName;
  final String sourceHash;
  final int durationMs;
  final int segmentCount;
  final int createdAt;
  final int? lastPracticedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'media_path': mediaPath,
        'media_name': mediaName,
        'media_kind': mediaKind,
        'subtitle_name': subtitleName,
        'source_hash': sourceHash,
        'duration_ms': durationMs,
        'segment_count': segmentCount,
        'created_at': createdAt,
        'last_practiced_at': lastPracticedAt,
      };

  factory MaterialItem.fromMap(Map<String, Object?> map) => MaterialItem(
        id: map['id'] as String,
        title: (map['title'] ?? '') as String,
        mediaPath: (map['media_path'] ?? '') as String,
        mediaName: (map['media_name'] ?? '') as String,
        mediaKind: (map['media_kind'] ?? 'audio') as String,
        subtitleName: (map['subtitle_name'] ?? '') as String,
        sourceHash: (map['source_hash'] ?? '') as String,
        durationMs: (map['duration_ms'] as num?)?.toInt() ?? 0,
        segmentCount: (map['segment_count'] as num?)?.toInt() ?? 0,
        createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
        lastPracticedAt: (map['last_practiced_at'] as num?)?.toInt(),
      );

  MaterialItem copyWith({
    String? title,
    String? mediaPath,
    int? durationMs,
    int? segmentCount,
    int? lastPracticedAt,
  }) =>
      MaterialItem(
        id: id,
        title: title ?? this.title,
        mediaPath: mediaPath ?? this.mediaPath,
        mediaName: mediaName,
        mediaKind: mediaKind,
        subtitleName: subtitleName,
        sourceHash: sourceHash,
        durationMs: durationMs ?? this.durationMs,
        segmentCount: segmentCount ?? this.segmentCount,
        createdAt: createdAt,
        lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      );
}

/// 二期：教材里的一句（需求 F12）。手动修正直接改 [startMs] / [endMs] / [textEn]。
class MaterialSegment {
  const MaterialSegment({
    required this.id,
    required this.materialId,
    required this.seq,
    required this.textEn,
    required this.startMs,
    required this.endMs,
    required this.wordCount,
    this.isHard = false,
    required this.createdAt,
  });

  final String id;
  final String materialId;
  final int seq;
  final String textEn;
  final int startMs;
  final int endMs;
  final int wordCount;
  final bool isHard;
  final int createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'material_id': materialId,
        'seq': seq,
        'text_en': textEn,
        'start_ms': startMs,
        'end_ms': endMs,
        'word_count': wordCount,
        'is_hard': isHard ? 1 : 0,
        'created_at': createdAt,
      };

  factory MaterialSegment.fromMap(Map<String, Object?> map) => MaterialSegment(
        id: map['id'] as String,
        materialId: (map['material_id'] ?? '') as String,
        seq: (map['seq'] as num?)?.toInt() ?? 0,
        textEn: (map['text_en'] ?? '') as String,
        startMs: (map['start_ms'] as num?)?.toInt() ?? 0,
        endMs: (map['end_ms'] as num?)?.toInt() ?? 0,
        wordCount: (map['word_count'] as num?)?.toInt() ?? 0,
        isHard: ((map['is_hard'] as num?)?.toInt() ?? 0) == 1,
        createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      );

  MaterialSegment copyWith({
    int? seq,
    String? textEn,
    int? startMs,
    int? endMs,
    int? wordCount,
    bool? isHard,
  }) =>
      MaterialSegment(
        id: id,
        materialId: materialId,
        seq: seq ?? this.seq,
        textEn: textEn ?? this.textEn,
        startMs: startMs ?? this.startMs,
        endMs: endMs ?? this.endMs,
        wordCount: wordCount ?? this.wordCount,
        isHard: isHard ?? this.isHard,
        createdAt: createdAt,
      );
}

/// 二期：一次单句听写提交（需求 F13 / F14）。
class DictationAttempt {
  const DictationAttempt({
    required this.id,
    required this.materialId,
    required this.segmentId,
    required this.userText,
    required this.accuracy,
    required this.passed,
    required this.diffJson,
    required this.createdAt,
  });

  final String id;
  final String materialId;
  final String segmentId;
  final String userText;
  final double accuracy; // 0..1
  final bool passed;
  final String diffJson;
  final int createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'material_id': materialId,
        'segment_id': segmentId,
        'user_text': userText,
        'accuracy': accuracy,
        'passed': passed ? 1 : 0,
        'diff_json': diffJson,
        'created_at': createdAt,
      };

  factory DictationAttempt.fromMap(Map<String, Object?> map) => DictationAttempt(
        id: map['id'] as String,
        materialId: (map['material_id'] ?? '') as String,
        segmentId: (map['segment_id'] ?? '') as String,
        userText: (map['user_text'] ?? '') as String,
        accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
        passed: ((map['passed'] as num?)?.toInt() ?? 0) == 1,
        diffJson: (map['diff_json'] ?? '[]') as String,
        createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      );
}

/// 逐词差异的一种（判分结果序列化用）。
class WordDiff {
  const WordDiff({required this.word, required this.kind, this.detail});

  /// kind: correct / missing / extra / misspelled
  final String word;
  final String kind;
  final String? detail;

  Map<String, Object?> toMap() => {
        'word': word,
        'kind': kind,
        if (detail != null) 'detail': detail,
      };

  factory WordDiff.fromMap(Map<String, Object?> map) => WordDiff(
        word: (map['word'] ?? '') as String,
        kind: (map['kind'] ?? 'correct') as String,
        detail: map['detail'] as String?,
      );

  static String encode(List<WordDiff> diffs) =>
      jsonEncode(diffs.map((e) => e.toMap()).toList());

  static List<WordDiff> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => WordDiff.fromMap((e as Map).cast<String, Object?>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
