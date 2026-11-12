import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/domain/models/models.dart';
import 'package:kele_speak/features/retention/review_item.dart';

void main() {
  const day = 24 * 60 * 60 * 1000;
  const now = 1762900000000;

  ReviewItem seed() => ReviewScheduler.create(
        id: 'rv_1',
        sourceType: 'correction',
        sourceId: 's1',
        textEn: 'Could I get a flat white, please?',
        textZh: '更自然的点单说法',
        nowMs: now,
      );

  group('固定阶梯排程', () {
    test('新建项明天到期、从第 0 档开始', () {
      final item = seed();
      expect(item.dueAt, now + day);
      expect(item.stage, 0);
      expect(item.consolidated, isFalse);
    });

    test('答对顺延到下一档并累计连续答对', () {
      final first = ReviewScheduler.applyResult(seed(), passed: true, nowMs: now);
      expect(first.stage, 1);
      expect(first.streak, 1);
      expect(first.dueAt, now + 3 * day);
      final second =
          ReviewScheduler.applyResult(first, passed: true, nowMs: now + day);
      expect(second.stage, 2);
      expect(second.dueAt, now + day + 7 * day);
    });

    test('走完四档即已巩固，不再出现在到期列表', () {
      var item = seed();
      for (var i = 0; i < kReviewLadderDays.length; i++) {
        item = ReviewScheduler.applyResult(item, passed: true, nowMs: now);
      }
      expect(item.consolidated, isTrue);
      expect(ReviewScheduler.due([item], now + 100 * day), isEmpty);
    });

    test('答错缩短到 1 天后、退回一档并清零连续次数', () {
      final good = ReviewScheduler.applyResult(seed(), passed: true, nowMs: now);
      final bad = ReviewScheduler.applyResult(good, passed: false, nowMs: now);
      expect(bad.stage, 0);
      expect(bad.streak, 0);
      expect(bad.lastPassed, isFalse);
      expect(bad.dueAt, now + day);
      expect(bad.consolidated, isFalse);
    });
  });

  group('到期筛选', () {
    test('按到期时间升序，同时间按 id，结果稳定', () {
      final a = seed().copyWith(dueAt: now - 10);
      final b = ReviewScheduler.create(
        id: 'rv_0',
        sourceType: 'phrase',
        sourceId: 'p1',
        textEn: 'Sounds good to me',
        nowMs: now,
      ).copyWith(dueAt: now - 10);
      final rows = ReviewScheduler.due([a, b], now);
      expect(rows.map((e) => e.id).toList(), ['rv_0', 'rv_1']);
      expect(ReviewScheduler.pickToday([a, b], now)!.id, 'rv_0');
    });

    test('未到期、已巩固、空文本都不进队列', () {
      final future = seed().copyWith(dueAt: now + day);
      final done = seed().copyWith(consolidated: true, dueAt: now - day);
      final empty = seed().copyWith(textEn: '  ', dueAt: now - day);
      expect(ReviewScheduler.due([future, done, empty], now), isEmpty);
    });

    test('同一来源只保留一条', () {
      final items = [seed()];
      expect(ReviewScheduler.hasSource(items, 'correction', 's1'), isTrue);
      expect(ReviewScheduler.hasSource(items, 'phrase', 's1'), isFalse);
    });
  });

  group('复盘扩展字段向后兼容', () {
    test('旧版本 review_json 缺扩展键时正常解码', () {
      const raw =
          '{"highlight":"good","corrections":[{"original":"I am convenient",'
          '"improved":"It works for me","reason":"搭配不地道"}],'
          '"phrases":["Sounds good"],"nextTip":"keep going","promptCount":2}';
      final result = ReviewResult.tryDecode(raw)!;
      expect(result.corrections.single.reasonZh, '搭配不地道');
      expect(result.takeawayText, isNull);
      expect(result.goalResults, isEmpty);
      expect(result.corrections.single.causeZh, isNull);
      expect(result.corrections.single.casual, isNull);
      expect(result.degraded, isFalse);
    });

    test('扩展字段可往返，且不破坏原三列', () {
      final result = ReviewResult(
        highlight: 'good',
        corrections: [
          const ReviewCorrection(
            original: 'I am convenient',
            improved: "It's convenient for me",
            reasonZh: '中式表达',
            causeZh: '中文「我方便」直接对应主语',
            casual: 'It works for me',
            formal: 'That time suits me',
            registerNote: '日常用前者，会议用后者',
          ),
        ],
        phrases: ['Sounds good'],
        nextTip: '多练一次',
        takeawayText: "It's convenient for me",
        goalResults: ['done', 'todo', 'done'],
      );
      final decoded = ReviewResult.tryDecode(result.encode())!;
      expect(decoded.takeawayText, "It's convenient for me");
      expect(decoded.goalResults, ['done', 'todo', 'done']);
      expect(decoded.corrections.single.causeZh, '中文「我方便」直接对应主语');
      expect(decoded.corrections.single.casual, 'It works for me');
      expect(decoded.corrections.single.formal, 'That time suits me');
      expect(decoded.corrections.single.registerNote, '日常用前者，会议用后者');
      expect(decoded.corrections.single.improved, "It's convenient for me");
    });

    test('ReviewItem 序列化往返保留队列表字段', () {
      final item = seed().copyWith(stage: 2, streak: 2, lastPassed: true);
      final decoded = ReviewItem.fromMap(item.toMap());
      expect(decoded.stage, 2);
      expect(decoded.streak, 2);
      expect(decoded.lastPassed, isTrue);
      expect(decoded.textZh, '更自然的点单说法');
      expect(decoded.consolidated, isFalse);
    });
  });
}
