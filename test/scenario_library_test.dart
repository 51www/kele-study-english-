import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/data/db/seeds.dart';
import 'package:kele_speak/features/scenario/scenario_goals.dart';
import 'package:kele_speak/features/scenario/scenario_visual.dart';

void main() {
  group('内置场景数据契约', () {
    test('id 与 sortOrder 均唯一，且按追加顺序递增', () {
      final ids = <String>{};
      final orders = <int>{};
      var previous = -1;
      for (final scenario in builtinScenarios) {
        expect(ids.add(scenario.id), isTrue, reason: '重复 id: ${scenario.id}');
        expect(orders.add(scenario.sortOrder), isTrue,
            reason: '重复 sortOrder: ${scenario.sortOrder}');
        expect(scenario.sortOrder > previous, isTrue,
            reason: '${scenario.id} 的 sortOrder 未递增');
        previous = scenario.sortOrder;
        expect(scenario.isBuiltin, isTrue, reason: '${scenario.id} 应为内置');
      }
    });

    test('每个场景的字段齐全且取值合法', () {
      for (final scenario in builtinScenarios) {
        final id = scenario.id;
        expect(id.trim().isNotEmpty, isTrue);
        expect(scenario.titleZh.trim().isNotEmpty, isTrue, reason: id);
        expect(scenario.titleEn.trim().isNotEmpty, isTrue, reason: id);
        expect(scenario.aiRole.trim().isNotEmpty, isTrue, reason: id);
        expect(scenario.userGoal.trim().isNotEmpty, isTrue, reason: id);
        expect(scenario.openingLine.trim().isNotEmpty, isTrue, reason: id);
        expect(scenario.successCriteria.trim().isNotEmpty, isTrue, reason: id);
        expect(scenario.branchHint?.trim().isNotEmpty, isTrue, reason: id);
        expect(scenario.targetPhrases, hasLength(5), reason: id);
        for (final phrase in scenario.targetPhrases) {
          expect(phrase.trim().isNotEmpty, isTrue, reason: id);
        }
        expect(<String>['A2', 'B1', 'B2'].contains(scenario.level), isTrue,
            reason: id);
        expect(<int>[8, 10, 12].contains(scenario.expectedTurns), isTrue,
            reason: id);
      }
    });

    test('实际出现的分类都能取到专属视觉，且图标不退化', () {
      final categories = scenarioCategoriesOf(
        builtinScenarios.map((scenario) => scenario.category),
      ).skip(1);
      for (final category in categories) {
        expect(scenarioCategoryOrder.contains(category), isTrue,
            reason: '$category 未登记展示顺序');
        expect(
          scenarioVisual(category).icon,
          isNot(Icons.chat_bubble_outline_rounded),
          reason: '$category 落到了默认图标',
        );
      }
    });

    test('每个内置场景都有 3 条可勾选目标', () {
      for (final scenario in builtinScenarios) {
        final goals = scenarioGoals(scenario);
        expect(goals, hasLength(3), reason: scenario.id);
        for (final goal in goals) {
          expect(goal.trim().isNotEmpty, isTrue, reason: scenario.id);
        }
      }
    });
  });
}
