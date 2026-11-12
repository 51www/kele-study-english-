/// 三期待复练项与排程纯逻辑。
///
/// 完全离线：不调用模型、不联网。来源可以是复盘改法（correction）、
/// 表达本短语（phrase）或听写错句（segment），三者共用同一队列。
library;

/// 固定阶梯（Q1 默认口径）：答对顺延到下一档，走完 4 档即视为已巩固。
const List<int> kReviewLadderDays = <int>[1, 3, 7, 14];

class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.textEn,
    this.textZh,
    required this.dueAt,
    this.stage = 0,
    this.streak = 0,
    this.consolidated = false,
    this.lastPassed,
    required this.createdAt,
  });

  final String id;
  final String sourceType;
  final String sourceId;
  final String textEn;
  final String? textZh;
  final int dueAt;
  final int stage;
  final int streak;
  final bool consolidated;
  final bool? lastPassed;
  final int createdAt;

  ReviewItem copyWith({
    String? textEn,
    String? textZh,
    int? dueAt,
    int? stage,
    int? streak,
    bool? consolidated,
    bool? lastPassed,
  }) =>
      ReviewItem(
        id: id,
        sourceType: sourceType,
        sourceId: sourceId,
        textEn: textEn ?? this.textEn,
        textZh: textZh ?? this.textZh,
        dueAt: dueAt ?? this.dueAt,
        stage: stage ?? this.stage,
        streak: streak ?? this.streak,
        consolidated: consolidated ?? this.consolidated,
        lastPassed: lastPassed ?? this.lastPassed,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'source_type': sourceType,
        'source_id': sourceId,
        'text_en': textEn,
        'text_zh': textZh,
        'due_at': dueAt,
        'stage': stage,
        'streak': streak,
        'consolidated': consolidated ? 1 : 0,
        'last_passed': lastPassed == null ? null : (lastPassed! ? 1 : 0),
        'created_at': createdAt,
      };

  factory ReviewItem.fromMap(Map<String, Object?> map) => ReviewItem(
        id: map['id'] as String,
        sourceType: (map['source_type'] ?? 'correction') as String,
        sourceId: (map['source_id'] ?? '') as String,
        textEn: (map['text_en'] ?? '') as String,
        textZh: map['text_zh'] as String?,
        dueAt: (map['due_at'] as num?)?.toInt() ?? 0,
        stage: (map['stage'] as num?)?.toInt() ?? 0,
        streak: (map['streak'] as num?)?.toInt() ?? 0,
        consolidated: ((map['consolidated'] as num?)?.toInt() ?? 0) == 1,
        lastPassed: map['last_passed'] == null
            ? null
            : ((map['last_passed'] as num?)?.toInt() ?? 0) == 1,
        createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      );
}

class ReviewScheduler {
  const ReviewScheduler._();

  static int _days(int days) => days * 24 * 60 * 60 * 1000;

  static ReviewItem create({
    required String id,
    required String sourceType,
    required String sourceId,
    required String textEn,
    String? textZh,
    required int nowMs,
  }) =>
      ReviewItem(
        id: id,
        sourceType: sourceType,
        sourceId: sourceId,
        textEn: textEn,
        textZh: textZh,
        dueAt: nowMs + _days(kReviewLadderDays.first),
        createdAt: nowMs,
      );

  /// 答对顺延一档、答错缩短到 1 天后并退回一档；走完阶梯即已巩固。
  static ReviewItem applyResult(
    ReviewItem item, {
    required bool passed,
    required int nowMs,
  }) {
    if (passed) {
      final next = (item.stage + 1).clamp(0, kReviewLadderDays.length);
      final done = next >= kReviewLadderDays.length;
      return item.copyWith(
        stage: next,
        streak: item.streak + 1,
        consolidated: done,
        lastPassed: true,
        dueAt: done ? item.dueAt : nowMs + _days(kReviewLadderDays[next]),
      );
    }
    final next = (item.stage - 1).clamp(0, kReviewLadderDays.length - 1);
    return item.copyWith(
      stage: next,
      streak: 0,
      consolidated: false,
      lastPassed: false,
      dueAt: nowMs + _days(kReviewLadderDays.first),
    );
  }

  /// 确定性排序：到期时间升序，同时间按 id，避免每次打开顺序抖动。
  static List<ReviewItem> due(
    List<ReviewItem> items,
    int nowMs, {
    int limit = 5,
  }) {
    final rows = items
        .where((e) => !e.consolidated && e.dueAt <= nowMs && e.textEn.trim().isNotEmpty)
        .toList();
    rows.sort((a, b) {
      final byDue = a.dueAt.compareTo(b.dueAt);
      return byDue == 0 ? a.id.compareTo(b.id) : byDue;
    });
    return rows.take(limit).toList();
  }

  static ReviewItem? pickToday(List<ReviewItem> items, int nowMs) {
    final rows = due(items, nowMs, limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// 同一来源只保留一条，避免表达本 / 错句本重复入队。
  static bool hasSource(List<ReviewItem> items, String sourceType, String sourceId) =>
      items.any((e) => e.sourceType == sourceType && e.sourceId == sourceId);
}
