import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/domain/models/models.dart';
import 'package:kele_speak/features/me/metrics.dart';

SessionRecord sess(
  String id,
  int startedAt, {
  int hintCount = 0,
  int turnCount = 8,
  String status = 'completed',
}) =>
    SessionRecord(
      id: id,
      scenarioId: 'cafe_order',
      startedAt: startedAt,
      durationSec: 600,
      turnCount: turnCount,
      hintCount: hintCount,
      status: status,
    );

Correction corr(String id, String sessionId, String improved) => Correction(
      id: id,
      sessionId: sessionId,
      messageId: '',
      original: 'rough version',
      improved: improved,
      reasonZh: '更自然',
      createdAt: 0,
    );

MessageRecord msg(String id, String sessionId, String text) => MessageRecord(
      id: id,
      sessionId: sessionId,
      seq: 1,
      role: 'user',
      textEn: text,
      createdAt: 0,
    );

void main() {
  final now = DateTime(2026, 11, 12, 12);
  final weeks = trendWeeks(now);
  int at(int index) =>
      weeks[index].add(const Duration(hours: 12)).millisecondsSinceEpoch;

  TrendInput input({
    List<SessionRecord> sessions = const [],
    Map<String, List<Correction>> corrections = const {},
    Map<String, List<MessageRecord>> messages = const {},
  }) =>
      TrendInput(
        sessions: sessions,
        correctionsBySession: corrections,
        messagesBySession: messages,
        now: now,
      );

  group('近 4 周分桶', () {
    test('4 个周、都以周一为起点、从早到晚', () {
      expect(weeks.length, 4);
      for (final week in weeks) {
        expect(week.weekday, DateTime.monday);
      }
      expect(weeks.first.isBefore(weeks.last), isTrue);
      expect(mondayOf(now), weeks.last);
    });

    test('关键词提取去标点、去停用词、去重', () {
      final words = keywordsOf('Could I get a flat white, please? flat white');
      expect(words.contains('flat'), isTrue);
      expect(words.contains('white'), isTrue);
      expect(words.where((w) => w == 'flat').length, 1);
      expect(words.contains('please'), isFalse);
      expect(words.contains('could'), isFalse);
      expect(words.contains('get'), isFalse);
    });
  });

  group('趋势计算', () {
    test('没有任何练习时两条趋势都无数据，不伪造 0 分', () {
      final series = computeTrends(input());
      expect(series.length, 2);
      expect(series.every((item) => !item.hasData), isTrue);
      for (final item in series) {
        expect(item.points.length, 4);
        expect(item.points.every((point) => point.value == null), isTrue);
      }
    });

    test('只有 1 次练习时不给比率，两条趋势都留空', () {
      final series = computeTrends(input(sessions: [sess('s1', at(3))]));
      expect(
        series.every((item) => item.points.every((point) => point.value == null)),
        isTrue,
      );
      final hints = series.firstWhere((item) => item.key == 'hintUsage');
      expect(hints.points.last.sample, 1);
      expect(canDrawTrend(series), isFalse);
    });

    test('每周至少 2 次已完成练习才画点，未完成会话不算样本', () {
      final series = computeTrends(input(sessions: [
        sess('s1', at(2)),
        sess('draft', at(2), status: 'in_progress'),
        sess('s2', at(3)),
        sess('s3', at(3)),
      ]));
      final hints = series.firstWhere((item) => item.key == 'hintUsage');
      expect(hints.points[2].value, isNull);
      expect(hints.points[2].sample, 1);
      expect(hints.points[3].value, isNotNull);
      expect(canDrawTrend(series), isFalse);
    });

    test('连续两周各有 2 次练习时可以画出折线', () {
      final series = computeTrends(input(sessions: [
        sess('w2a', at(2)),
        sess('w2b', at(2)),
        sess('w3a', at(3)),
        sess('w3b', at(3)),
      ]));
      expect(canDrawTrend(series), isTrue);
    });

    test('提示使用率 = 提示次数 / 开口轮次，仅统计已完成会话', () {
      final series = computeTrends(input(sessions: [
        sess('s1', at(3), hintCount: 2, turnCount: 8),
        sess('s2', at(3), hintCount: 2, turnCount: 8),
        sess('draft', at(3), hintCount: 9, status: 'in_progress'),
      ]));
      final hints = series.firstWhere((item) => item.key == 'hintUsage');
      expect(hints.points.last.value, closeTo(0.25, 0.0001));
      expect(hints.points.last.sample, 2);
      expect(hints.points.first.value, isNull);
    });

    test('改法复现：前一周改过的说法在后面再次出现才算命中', () {
      final series = computeTrends(input(
        sessions: [
          sess('s0', at(0)),
          sess('s1', at(1)),
          sess('s2', at(2)),
        ],
        corrections: {
          's0': [
            corr('c1', 's0', 'Could I get a flat white please'),
            corr('c2', 's0', 'That works for me tomorrow'),
          ],
        },
        messages: {
          's1': [
            msg('m1', 's1', 'Could I get a flat white please'),
            msg('m2', 's1', 'That works for me tomorrow'),
          ],
          's2': [msg('m3', 's2', 'Something completely different')],
        },
      ));
      final reuse = series.firstWhere((item) => item.key == 'correctionReuse');
      expect(reuse.points[0].value, isNull);
      expect(reuse.points[1].value, closeTo(1.0, 0.0001));
      expect(reuse.points[2].value, closeTo(0.0, 0.0001));
    });

    test('可追踪改法不足 2 条时返回 null，不显示假趋势', () {
      final series = computeTrends(input(
        sessions: [sess('s0', at(0)), sess('s1', at(1))],
        corrections: {
          's0': [corr('c1', 's0', 'Could I get a flat white please')],
        },
        messages: {
          's1': [msg('m1', 's1', 'Could I get a flat white please')],
        },
      ));
      final reuse = series.firstWhere((item) => item.key == 'correctionReuse');
      expect(reuse.points[1].value, isNull);
      expect(reuse.points[1].sample, 1);
    });

    test('两条趋势都带口径说明，且键名稳定', () {
      final series = computeTrends(input());
      expect(series.map((item) => item.key).toList(),
          ['hintUsage', 'correctionReuse']);
      for (final item in series) {
        expect(item.explain.isNotEmpty, isTrue);
        expect(item.title.isNotEmpty, isTrue);
      }
    });
  });
}
