import '../../domain/models/models.dart';

/// 近 4 周趋势的一个点。`value` 为 null 表示样本不足，界面不画假数据。
class TrendPoint {
  const TrendPoint({
    required this.weekStart,
    required this.value,
    required this.sample,
  });

  final DateTime weekStart;
  final double? value;
  final int sample;
}

class TrendSeries {
  const TrendSeries({
    required this.key,
    required this.title,
    required this.explain,
    required this.points,
  });

  final String key;
  final String title;
  final String explain;
  final List<TrendPoint> points;

  bool get hasData => points.any((point) => point.value != null);
}

/// 至少要有一条趋势能连出两个周点，才允许展示折线卡片。
/// 单点、0% 都不是趋势；样本不足时界面给空态。
bool canDrawTrend(List<TrendSeries> series) => series.any(
      (item) => item.points.where((point) => point.value != null).length >= 2,
    );

class TrendInput {
  const TrendInput({
    required this.sessions,
    required this.correctionsBySession,
    required this.messagesBySession,
    required this.now,
  });

  final List<SessionRecord> sessions;
  final Map<String, List<Correction>> correctionsBySession;
  final Map<String, List<MessageRecord>> messagesBySession;
  final DateTime now;
}

const List<String> _stopWords = <String>[
  'that', 'this', 'with', 'have', 'would', 'could', 'please', 'really',
  'about', 'there', 'their', 'what', 'when', 'your', 'from',
];

List<String> keywordsOf(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .split(RegExp(r'\s+'))
    .where((word) => word.length > 3 && !_stopWords.contains(word))
    .toSet()
    .toList();

DateTime mondayOf(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - 1));

/// 近 4 周（含本周），从早到晚。
List<DateTime> trendWeeks(DateTime now) {
  final base = mondayOf(now);
  return List<DateTime>.generate(
    4,
    (index) => base.subtract(Duration(days: 7 * (3 - index))),
  );
}

int _weekIndex(DateTime weeksStart, int timestamp) {
  final diff = DateTime.fromMillisecondsSinceEpoch(timestamp)
      .difference(weeksStart)
      .inDays;
  return diff ~/ 7;
}

/// 两条可解释趋势：提示使用率、改法复现率。
///
/// 全部由本地已有表算出，不联网、不调模型；样本不足返回 null 而不是 0 分。
List<TrendSeries> computeTrends(TrendInput input) {
  final weeks = trendWeeks(input.now);
  final oldest = weeks.first;
  final byWeek = List<List<SessionRecord>>.generate(4, (_) => <SessionRecord>[]);
  for (final session in input.sessions) {
    final index = _weekIndex(oldest, session.startedAt);
    if (index >= 0 && index < 4) byWeek[index].add(session);
  }

  final hintPoints = <TrendPoint>[];
  for (var i = 0; i < 4; i++) {
    final rows = byWeek[i]
        .where((session) => session.status == 'completed' && session.turnCount > 0)
        .toList();
    if (rows.length < 2) {
      // 一周只练了 1 次时不出比率：单次练习算出的 0% / 100% 都不足以说明变化。
      hintPoints.add(TrendPoint(weekStart: weeks[i], value: null, sample: rows.length));
      continue;
    }
    final hints = rows.fold<int>(0, (sum, row) => sum + row.hintCount);
    final turns = rows.fold<int>(0, (sum, row) => sum + row.turnCount);
    hintPoints.add(TrendPoint(
      weekStart: weeks[i],
      value: turns == 0 ? null : (hints / turns).clamp(0.0, 1.0),
      sample: rows.length,
    ));
  }

  final reusePoints = <TrendPoint>[];
  for (var i = 0; i < 4; i++) {
    // 只拿「这一周之前」被纠正过的说法，检查之后有没有真的再说对。
    final earlier = <List<String>>[];
    for (var j = 0; j < i; j++) {
      for (final session in byWeek[j]) {
        for (final correction
            in input.correctionsBySession[session.id] ?? const <Correction>[]) {
          if (correction.isDeleted) continue;
          final words = keywordsOf(correction.improved);
          if (words.length >= 2) earlier.add(words);
        }
      }
    }
    final spoken = <String>[];
    for (final session in byWeek[i]) {
      for (final message
          in input.messagesBySession[session.id] ?? const <MessageRecord>[]) {
        if (message.isUser && message.status == 'ok') {
          spoken.add(message.textEn.toLowerCase());
        }
      }
    }
    if (earlier.length < 2 || spoken.isEmpty) {
      reusePoints.add(TrendPoint(weekStart: weeks[i], value: null, sample: earlier.length));
      continue;
    }
    var hits = 0;
    for (final words in earlier) {
      final matched = words.where((word) => spoken.any((line) => line.contains(word))).length;
      if (matched >= 2) hits++;
    }
    reusePoints.add(TrendPoint(
      weekStart: weeks[i],
      value: hits / earlier.length,
      sample: earlier.length,
    ));
  }

  return <TrendSeries>[
    TrendSeries(
      key: 'hintUsage',
      title: '提示使用率',
      explain: '每周所有已完成练习里，用了多少次提示 ÷ 一共说了多少轮。'
          '数字变小，说明越来越少依赖提示也能接住话。'
          '只统计已完成的练习；每周至少 2 次才画点，练得不够那一周就留空。',
      points: hintPoints,
    ),
    TrendSeries(
      key: 'correctionReuse',
      title: '改法复现率',
      explain: '前几周复盘给过的更自然说法，在后面几周的自己说的话里再次出现，'
          '就算复现一次（一句里命中两个以上关键词）。'
          '用命中条数 ÷ 可追踪的改法条数；可追踪的不足 2 条时不显示，避免用一两次巧合算出假趋势。',
      points: reusePoints,
    ),
  ];
}
