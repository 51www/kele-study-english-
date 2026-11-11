import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/features/dictation/scoring/dictation_scorer.dart';

void main() {
  group('离线判分（需求 F14）', () {
    test('大小写、标点、多余空格都不判错', () {
      final result = DictationScorer.score('Hello, WORLD!', '  hello   world  ');
      expect(result.accuracy, 1.0);
      expect(result.passed, isTrue);
      expect(result.diffs.every((e) => e.kind == 'correct'), isTrue);
    });

    test('漏一个词能准确指出是哪个位置', () {
      final result = DictationScorer.score(
        'I would like a large coffee please',
        'I would like a coffee please',
      );
      final missing = result.diffs.where((e) => e.kind == 'missing').toList();
      expect(missing.length, 1);
      expect(missing.single.word, 'large');
      expect(result.diffs.indexWhere((e) => e.kind == 'missing'), 4);
      expect(result.accuracy, lessThan(1.0));
      expect(result.passed, isFalse);
    });

    test('缩写等价按配置生效，规则对用户可见', () {
      const on = ScoringOptions(contractionEquivalent: true);
      const off = ScoringOptions(contractionEquivalent: false);
      expect(
        DictationScorer.score('I would like a coffee', "I'd like a coffee", options: on).accuracy,
        1.0,
      );
      expect(
        DictationScorer.score('I would like a coffee', "I'd like a coffee", options: off).accuracy,
        lessThan(1.0),
      );
      expect(on.describe(), contains('缩写等价'));
      expect(off.describe(), isNot(contains('缩写等价')));
    });

    test('数字与货币符号双向等价', () {
      const on = ScoringOptions(numberEquivalent: true);
      const off = ScoringOptions(numberEquivalent: false);
      expect(DictationScorer.score('ten dollars', '10 dollars', options: on).accuracy, 1.0);
      expect(DictationScorer.score(r'$5', 'five dollars', options: on).accuracy, 1.0);
      expect(
        DictationScorer.score('ten dollars', '10 dollars', options: off).accuracy,
        lessThan(1.0),
      );
    });

    test('长词拼错标「拼错」而不是漏写 + 多写，阈值可调', () {
      const loose = ScoringOptions(passThreshold: 0.9);
      const strict = ScoringOptions(passThreshold: 0.95);
      final a = DictationScorer.score(
        'I need a reservation for tomorrow',
        'I need a reservation for tomorow',
        options: loose,
      );
      expect(a.diffs.where((e) => e.kind == 'misspelled').length, 1);
      expect(a.diffs.any((e) => e.kind == 'missing'), isFalse);
      expect(a.misspelledWords, 1);
      expect(a.passed, isTrue);
      final b = DictationScorer.score(
        'I need a reservation for tomorrow',
        'I need a reservation for tomorow',
        options: strict,
      );
      expect(b.passed, isFalse);

      // 短词不享受拼写容错
      final short = DictationScorer.score('a big cup', 'a bog cup');
      expect(short.diffs.any((e) => e.kind == 'misspelled'), isFalse);
    });

    test('多写会拉低正确率；空答案全判漏写；判分不依赖网络', () {
      final extra = DictationScorer.score('I like coffee', 'I really like coffee');
      expect(extra.diffs.any((e) => e.kind == 'extra'), isTrue);
      expect(extra.accuracy, lessThan(1.0));

      final empty = DictationScorer.score('I like coffee', '');
      expect(empty.accuracy, 0);
      expect(empty.passed, isFalse);
      expect(empty.diffs.where((e) => e.kind == 'missing').length, 3);
    });
  });
}
