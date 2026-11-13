import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/domain/models/models.dart';
import 'package:kele_speak/features/me/metrics.dart';
import 'package:kele_speak/features/path/path_model.dart';
import 'package:kele_speak/features/path/path_plan.dart';

Scenario scenario(String id, String category, String level, int order) => Scenario(
      id: id,
      titleZh: id,
      titleEn: id,
      category: category,
      level: level,
      aiRole: 'clerk',
      userGoal: 'order something',
      openingLine: 'Hi',
      targetPhrases: const <String>['a', 'b', 'c', 'd', 'e'],
      expectedTurns: 8,
      successCriteria: '1. a 2. b 3. c',
      sortOrder: order,
    );

final List<Scenario> demoScenarios = <Scenario>[
  scenario('a1', '日常', 'A2', 0),
  scenario('a2', '日常', 'A2', 1),
  scenario('a3', '旅行', 'A2', 2),
  scenario('b1', '工作', 'B1', 3),
  scenario('b2', '工作', 'B1', 4),
  scenario('b3', '社交', 'B1', 5),
  scenario('c1', '观点', 'B2', 6),
  scenario('c2', '工作', 'B2', 7),
];

final DateTime now = DateTime(2026, 11, 13, 10);

PathSnapshot snap({
  List<SessionRecord> sessions = const <SessionRecord>[],
  List<TrendSeries> trends = const <TrendSeries>[],
  int dueCount = 0,
  int consolidatedCount = 0,
  int phrasesCount = 0,
  int weekSessions = 0,
  int materialCount = 0,
  int materialPracticedCount = 0,
}) =>
    PathSnapshot(
      sessions: sessions,
      scenarios: demoScenarios,
      practiceCounts: const <String, int>{},
      hintByScenario: const <String, int>{},
      lastCompletedAtByScenario: const <String, int>{},
      trends: trends,
      now: now,
      dueCount: dueCount,
      consolidatedCount: consolidatedCount,
      phrasesCount: phrasesCount,
      weekSessions: weekSessions,
      materialCount: materialCount,
      materialPracticedCount: materialPracticedCount,
    );

const LearningPathState configured = LearningPathState(
  configured: true,
  goal: 'work',
  level: 'B1',
  stage: 2,
);

void main() {
  group('M14 路径状态解码', () {
    test('空值 / 坏值都回落到未配置空态', () {
      expect(LearningPathState.decode(null).configured, isFalse);
      expect(LearningPathState.decode('').configured, isFalse);
      expect(LearningPathState.decode('not json').configured, isFalse);
      expect(LearningPathState.decode('[]').configured, isFalse);
    });

    test('编码解码保留字段，越界值被夹住', () {
      final state = const LearningPathState(
        configured: true,
        goal: 'travel',
        specificGoal: '开会能追问',
        level: 'B2',
        stage: 3,
        confidence: 5,
        items: <PathItem>[
          PathItem(id: 'x', kind: 'scene', title: 'T', reason: 'R'),
        ],
      );
      final decoded = LearningPathState.decode(state.encode());
      expect(decoded.goal, 'travel');
      expect(decoded.specificGoal, '开会能追问');
      expect(decoded.stage, 3);
      expect(decoded.confidence, 5);
      expect(decoded.items.single.id, 'x');

      final raw = jsonDecode(state.encode()) as Map<String, Object?>;
      raw['stage'] = 99;
      raw['confidence'] = 0;
      final clamped = LearningPathState.decode(jsonEncode(raw));
      expect(clamped.stage, kPathStages.length);
      expect(clamped.confidence, 1);
    });
  });

  group('M14 目标与内容范围', () {
    test('目标只映射场景库里真实存在的分类，综合目标按实际数据全取', () {
      final work = goalCategories('work', demoScenarios);
      expect(work, contains('工作'));
      expect(work, contains('观点'));
      expect(work, isNot(contains('旅行')));
      final all = goalCategories('general', demoScenarios);
      expect(all.toSet(), demoScenarios.map((e) => e.category).toSet());
    });

    test('四阶段都生成 5–7 条安排、id 不重复、含场景与复练', () {
      for (var stage = 1; stage <= 4; stage++) {
        final pool = stageScenarios(stage, 'work', snap(materialCount: 1));
        final items = buildStageItems(stage: stage, snap: snap(materialCount: 1), pool: pool);
        expect(items.length, inInclusiveRange(5, 7), reason: 'stage $stage');
        expect(items.map((e) => e.id).toSet().length, items.length);
        expect(items.any((e) => e.kind == 'scene'), isTrue);
        expect(items.any((e) => e.kind == 'review'), isTrue);
      }
    });
  });

  group('M14 计划与下一步', () {
    test('未配置时返回可用空态，不生成假计划', () {
      final plan = computePathPlan(const LearningPathState(), snap());
      expect(plan.configured, isFalse);
      expect(plan.items, isEmpty);
      expect(plan.next, isNull);
      expect(plan.nextRoute, '/scenarios');
    });

    test('已配置时能回答三问，下一步有理由且可点开', () {
      final plan = computePathPlan(configured, snap(dueCount: 3, weekSessions: 1));
      expect(plan.configured, isTrue);
      expect(plan.stage.name, '稳定表达');
      expect(plan.items.length, inInclusiveRange(5, 7));
      expect(plan.scopeScenarioIds, isNotEmpty);
      expect(plan.evaluation.evidence.length, 3);
      expect(plan.next, isNotNull);
      expect(plan.nextReason, isNotEmpty);
      expect(plan.nextRoute, startsWith('/'));
      // 到期复练优先，理由与记录对得上。
      expect(plan.next!.kind, 'review');
      expect(plan.nextReason, contains('3 条到期复练'));
      expect(plan.nextReason, contains('1/3 次'));
    });

    test('今天先跳过后不再推荐这一条，且不锁后续', () {
      final before = computePathPlan(configured, snap());
      final skippedId = before.next!.id;
      final state = skipPathItem(configured, before.next!, now);
      final after = computePathPlan(state, snap());
      expect(after.items.where((e) => e.id == skippedId).single.status, 'skipped');
      expect(after.next, isNotNull);
      expect(after.next!.id, isNot(skippedId));
      expect(after.pendingCount, greaterThan(0));
    });

    test('换一个之后跳过当前条，会顺延到再下一条而不是退回第一条', () {
      final firstId = computePathPlan(configured, snap()).next!.id;
      final altState = nextPathAlternative(configured);
      final altId = computePathPlan(altState, snap()).next!.id;
      final after = computePathPlan(
        skipPathItem(altState, computePathPlan(altState, snap()).next!, now),
        snap(),
      );
      expect(after.next, isNotNull);
      expect(after.next!.id, isNot(firstId));
      expect(after.next!.id, isNot(altId));
    });

    test('换一个在下一条之间轮换，阶段可自由前后切换（不解锁）', () {
      final first = computePathPlan(configured, snap());
      final second = computePathPlan(nextPathAlternative(configured), snap());
      expect(second.next, isNotNull);
      expect(second.next!.id, isNot(first.next!.id));

      final toFour = changePathStage(configured, 4, now);
      expect(toFour.stage, 4);
      final backToOne = changePathStage(toFour, 1, now);
      expect(backToOne.stage, 1);
      expect(backToOne.items, isEmpty);
    });

    test('无数据时完成标准不成立，只给「还差什么」不给分数', () {
      final evaluation = evaluateStage(1, configured, snap());
      expect(evaluation.complete, isFalse);
      expect(evaluation.pending, isNotEmpty);
      for (final line in evaluation.evidence) {
        expect(line.contains('分'), isFalse);
      }
    });

    test('起点随水平与历史练习量变化，但不产生等级', () {
      expect(suggestStageIndex('A2', 0), 1);
      expect(suggestStageIndex('B1', 0), 2);
      expect(suggestStageIndex('B1', 6), 3);
      expect(suggestStageIndex('B2', 0), 3);
    });
  });
}
