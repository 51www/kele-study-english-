import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/features/scenario/scenario_goals.dart';
import 'package:kele_speak/services/llm/prompt_builder.dart';

void main() {
  group('场景目标清单（T10.2）', () {
    test('26 个内置场景各有 3 条可勾选目标', () {
      expect(kBuiltinGoals.length, 26);
      for (final entry in kBuiltinGoals.entries) {
        expect(entry.value.length, 3, reason: '${entry.key} 应有 3 条目标');
        for (final goal in entry.value) {
          expect(goal.trim().isNotEmpty, isTrue);
        }
      }
    });

    test('编号完成标准可反解析为 3 条', () {
      const raw = '1. 回应寒暄 2. 抛一个话题 3. 自然收尾';
      expect(goalsFromCriteria(raw, '随便聊聊'), [
        '回应寒暄',
        '抛一个话题',
        '自然收尾',
      ]);
    });

    test('自由文本退化为 1 条整体目标，空文本给兜底', () {
      expect(goalsFromCriteria('用英语完成对话。', '自定义'), ['用英语完成对话。']);
      expect(goalsFromCriteria('', '自定义'), ['用英语完成「自定义」的对话']);
    });

    test('goalsToCriteria 与解析可往返', () {
      const goals = ['说明来意', '问清细节', '确认下一步'];
      expect(goalsFromCriteria(goalsToCriteria(goals), '任意'), goals);
    });
  });

  group('复盘补充段（T10.1）', () {
    const base = '''
亮点: 你把需求说清楚了
纠错:
1. I am convenient || It works for me || convenient 不用来形容人
表达:
- Sounds good
下次: 多用完整句
''';

    test('没有补充段时原三列完整、扩展字段全为 null', () {
      final result = ReviewParser.parse(base);
      expect(result.corrections, hasLength(1));
      expect(result.corrections.single.improved, 'It works for me');
      expect(result.corrections.single.causeZh, isNull);
      expect(result.corrections.single.casual, isNull);
      expect(result.corrections.single.formal, isNull);
      expect(result.corrections.single.registerNote, isNull);
      expect(result.phrases, ['Sounds good']);
      expect(result.degraded, isFalse);
    });

    test('补充段按原句回填中式成因与两种语体', () {
      final result = ReviewParser.parse('''
$base
补充:
1. I am convenient || 中文「我方便」直接对应主语 || It works for me || That time suits me || 闲聊用前者，会议约时间用后者
''');
      final correction = result.corrections.single;
      expect(correction.original, 'I am convenient');
      expect(correction.causeZh, '中文「我方便」直接对应主语');
      expect(correction.casual, 'It works for me');
      expect(correction.formal, 'That time suits me');
      expect(correction.registerNote, '闲聊用前者，会议约时间用后者');
      expect(result.phrases, ['Sounds good']);
    });

    test('补充段缺列 / 原句对不上时不影响原复盘', () {
      final broken = ReviewParser.parse('''
$base
补充:
1. I am convenient || 只写了两段
2. Some other sentence || a || b || c || d
''');
      expect(broken.corrections, hasLength(1));
      expect(broken.corrections.single.causeZh, isNull);
      expect(broken.corrections.single.improved, 'It works for me');
      expect(broken.nextTip, '多用完整句');
    });

    test('补充段大小写不同也能匹配', () {
      final result = ReviewParser.parse('''
$base
补充:
1. i am convenient || 成因 || 日常 || 正式 || 场合
''');
      expect(result.corrections.single.casual, '日常');
      expect(result.corrections.single.formal, '正式');
    });
  });
}
