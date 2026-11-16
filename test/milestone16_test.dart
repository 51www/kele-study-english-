import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/domain/models/models.dart';
import 'package:kele_speak/features/me/metrics.dart';
import 'package:kele_speak/features/path/path_model.dart';
import 'package:kele_speak/features/path/path_plan.dart';
import 'package:kele_speak/services/llm/prompt_builder.dart';

PathSnapshot _snap({DateTime? now}) => PathSnapshot(
      sessions: const <SessionRecord>[],
      scenarios: const <Scenario>[],
      practiceCounts: const <String, int>{},
      hintByScenario: const <String, int>{},
      lastCompletedAtByScenario: const <String, int>{},
      trends: const <TrendSeries>[],
      now: now ?? DateTime(2026, 11, 16, 10),
    );

const base = '''
亮点: 你把需求说清楚了
纠错:
1. I am convenient || It works for me || convenient 不用来形容人
表达:
- Sounds good
下次: 多用完整句
''';

void main() {
  group('三档粗评解析（T16.1）', () {
    test('表现段解析出档位与依据，同义词归一到三档', () {
      final smooth = ReviewParser.parse('''
$base
表现: 流畅 || 基本没求助
''');
      expect(smooth.rating, '顺畅');
      expect(smooth.ratingReason, '基本没求助');

      final steady = ReviewParser.parse('''
$base
表现：还行 || 有点磕绊
''');
      expect(steady.rating, '稳住');
      expect(steady.ratingReason, '有点磕绊');

      final hard = ReviewParser.parse('''
$base
表现: 困难 || 提示用得多
''');
      expect(hard.rating, '吃力');
    });

    test('缺段或档位不合法时不显示档位，且不算 degraded', () {
      final missing = ReviewParser.parse(base);
      expect(missing.rating, isNull);
      expect(missing.ratingReason, isNull);
      expect(missing.degraded, isFalse);

      final invalid = ReviewParser.parse('''
$base
表现: 82 分 || 很好
''');
      expect(invalid.rating, isNull);
    });

    test('review_json 往返保留粗评，旧数据无键解码为 null', () {
      const result = ReviewResult(
        highlight: 'h',
        corrections: <ReviewCorrection>[],
        phrases: <String>['p'],
        nextTip: 't',
        rating: '稳住',
        ratingReason: '有点磕绊',
      );
      final decoded = ReviewResult.tryDecode(result.encode())!;
      expect(decoded.rating, '稳住');
      expect(decoded.ratingReason, '有点磕绊');

      final old = ReviewResult.tryDecode(
        '{"highlight":"h","corrections":[],"phrases":[],"nextTip":"t"}',
      )!;
      expect(old.rating, isNull);
      expect(old.goalResults, isEmpty);
    });
  });

  group('旅程地图数据（T16.4）', () {
    test('未配置时旅程为空，不生成假路线', () {
      expect(computeJourneyStages(const LearningPathState(), _snap()), isEmpty);
      expect(computePathPlan(const LearningPathState(), _snap()).journey, isEmpty);
    });

    test('四个阶段全部成图，当前阶段高亮，与计划同口径', () {
      const state = LearningPathState(
        configured: true,
        goal: 'work',
        level: 'B1',
        stage: 2,
      );
      final journey = computeJourneyStages(state, _snap());
      expect(journey.length, 4);
      expect(journey.map((e) => e.stage.index).toList(), [1, 2, 3, 4]);
      expect(journey.where((e) => e.current).single.stage.index, 2);
      for (final stage in journey) {
        expect(stage.items.length, inInclusiveRange(5, 7));
      }

      // 地图与计划对当前阶段用同一套状态口径（状态由真实数据推导）。
      final plan = computePathPlan(state, _snap());
      final current = journey.singleWhere((e) => e.current);
      expect(current.items.map((e) => e.id).toList(), plan.items.map((e) => e.id).toList());
      expect(
        current.items.map((e) => e.status).toList(),
        plan.items.map((e) => e.status).toList(),
      );
      expect(plan.journey.length, 4);
    });

    test('跳过覆盖项在地图上同样生效，且不锁后续节点', () {
      const state = LearningPathState(
        configured: true,
        goal: 'work',
        level: 'B1',
        stage: 1,
      );
      final plan = computePathPlan(state, _snap());
      final target = plan.next!;
      final skipped = skipPathItem(state, target, DateTime(2026, 11, 16, 10));
      final journey = computeJourneyStages(skipped, _snap());
      final stage1 = journey.first;
      expect(
        stage1.items.singleWhere((e) => e.id == target.id).status,
        'skipped',
      );
      final after = computePathPlan(skipped, _snap());
      expect(after.next, isNotNull);
      expect(after.next!.id, isNot(target.id));
    });
  });
}
