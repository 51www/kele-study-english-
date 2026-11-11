import '../../../domain/models/dictation_models.dart';

class ScoringOptions {
  const ScoringOptions({
    this.contractionEquivalent = true,
    this.numberEquivalent = true,
    this.passThreshold = 0.9,
  });

  final bool contractionEquivalent;
  final bool numberEquivalent;
  final double passThreshold;

  String describe() {
    final parts = <String>['忽略大小写、标点与多余空格'];
    if (contractionEquivalent) parts.add('缩写等价');
    if (numberEquivalent) parts.add('数字等价');
    parts.add('长词拼错半计分 / 多写计入分母');
    parts.add('通过线 ${(passThreshold * 100).round()}%');
    return parts.join(' · ');
  }
}

class ScoringResult {
  const ScoringResult({
    required this.diffs,
    required this.accuracy,
    required this.passed,
    required this.referenceWords,
    required this.correctWords,
    required this.misspelledWords,
    required this.extraWords,
  });

  final List<WordDiff> diffs;
  final double accuracy; // 0..1
  final bool passed;
  final int referenceWords;
  final int correctWords;
  final int misspelledWords;
  final int extraWords;

  String get accuracyLabel => '${(accuracy * 100).round()}%';

  String get explanation =>
      '正确词 $correctWords / 参考词 $referenceWords'
      '${misspelledWords == 0 ? '' : ' · 拼错 $misspelledWords 词按半词计'}'
      '${extraWords == 0 ? '' : ' · 多写 $extraWords 词计入分母'}';
}

const _contractions = <String, String>{
  "i'm": 'i am', "i've": 'i have', "i'd": 'i would', "i'll": 'i will',
  "you're": 'you are', "you've": 'you have', "you'd": 'you would', "you'll": 'you will',
  "he's": 'he is', "she's": 'she is', "it's": 'it is', "that's": 'that is',
  "there's": 'there is', "we're": 'we are', "we've": 'we have',
  "we'd": 'we would', "we'll": 'we will', "they're": 'they are',
  "they've": 'they have', "they'd": 'they would', "they'll": 'they will',
  "don't": 'do not', "doesn't": 'does not', "didn't": 'did not',
  "can't": 'can not', 'cannot': 'can not', "won't": 'will not',
  "wouldn't": 'would not', "shouldn't": 'should not', "couldn't": 'could not',
  "isn't": 'is not', "aren't": 'are not', "wasn't": 'was not',
  "weren't": 'were not', "let's": 'let us', "haven't": 'have not',
  "hasn't": 'has not', "hadn't": 'had not',
};

const _digits = <String, String>{
  '0': 'zero', '1': 'one', '2': 'two', '3': 'three', '4': 'four',
  '5': 'five', '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine',
  '10': 'ten', '11': 'eleven', '12': 'twelve', '13': 'thirteen',
  '14': 'fourteen', '15': 'fifteen', '16': 'sixteen', '17': 'seventeen',
  '18': 'eighteen', '19': 'nineteen', '20': 'twenty', '30': 'thirty',
  '40': 'forty', '50': 'fifty', '60': 'sixty', '70': 'seventy',
  '80': 'eighty', '90': 'ninety', '100': 'one hundred', '1000': 'one thousand',
};

/// 离线判分：规范化 + 词级对齐 + 可解释正确率（需求 F14）。
///
/// 不联网、不调用模型；规则通过 [ScoringOptions] 暴露给界面，用户可见可调。
class DictationScorer {
  DictationScorer._();

  static ScoringResult score(
    String reference,
    String answer, {
    ScoringOptions options = const ScoringOptions(),
  }) {
    final ref = tokenize(reference, options);
    final ans = tokenize(answer, options);
    if (ref.isEmpty) {
      return const ScoringResult(
        diffs: [],
        accuracy: 0,
        passed: false,
        referenceWords: 0,
        correctWords: 0,
        misspelledWords: 0,
        extraWords: 0,
      );
    }
    final ops = _align(ref, ans);
    final diffs = <WordDiff>[];
    var correct = 0;
    var misspelled = 0;
    var extra = 0;
    for (final op in ops) {
      switch (op.kind) {
        case _OpKind.correct:
          correct++;
          diffs.add(WordDiff(word: op.reference!, kind: 'correct'));
          break;
        case _OpKind.misspelled:
          misspelled++;
          diffs.add(WordDiff(
            word: op.answer!,
            kind: 'misspelled',
            detail: '应为 ${op.reference}',
          ));
          break;
        case _OpKind.missing:
          diffs.add(WordDiff(word: op.reference!, kind: 'missing'));
          break;
        case _OpKind.extra:
          extra++;
          diffs.add(WordDiff(word: op.answer!, kind: 'extra'));
          break;
      }
    }
    final accuracy =
        ((correct + misspelled * 0.5) / (ref.length + extra)).clamp(0.0, 1.0);
    final passed = ans.isNotEmpty && accuracy >= options.passThreshold;
    return ScoringResult(
      diffs: diffs,
      accuracy: accuracy,
      passed: passed,
      referenceWords: ref.length,
      correctWords: correct,
      misspelledWords: misspelled,
      extraWords: extra,
    );
  }

  /// 公开给单测与设置页：确认规范化规则确实按配置生效。
  static List<String> tokenize(String raw, [ScoringOptions options = const ScoringOptions()]) {
    var text = raw
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAllMapped(RegExp(r'\$(\d+)'), (m) => '${m.group(1)} dollars')
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return const [];
    final words = text.split(' ');
    final result = <String>[];
    for (final word in words) {
      final clean = word.replaceAll(RegExp(r"^'+|'+$"), '');
      if (clean.isEmpty) continue;
      if (options.contractionEquivalent && _contractions.containsKey(clean)) {
        result.addAll(_contractions[clean]!.split(' '));
        continue;
      }
      if (options.numberEquivalent && _digits.containsKey(clean)) {
        result.addAll(_digits[clean]!.split(' '));
        continue;
      }
      result.add(clean);
    }
    return result;
  }

  static List<_Op> _align(List<String> ref, List<String> ans) {
    final n = ref.length;
    final m = ans.length;
    final dp = List.generate(n + 1, (_) => List<double>.filled(m + 1, 0));
    final choice = List.generate(
      n + 1,
      (_) => List<_Step>.filled(m + 1, _Step.match),
    );
    for (var i = 1; i <= n; i++) {
      dp[i][0] = i.toDouble();
      choice[i][0] = _Step.delete;
    }
    for (var j = 1; j <= m; j++) {
      dp[0][j] = j.toDouble();
      choice[0][j] = _Step.insert;
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final same = ref[i - 1] == ans[j - 1];
        final similar = !same && _isMisspelling(ref[i - 1], ans[j - 1]);
        final diagonal = dp[i - 1][j - 1] + (same ? 0 : (similar ? 1.5 : 2.1));
        final delete = dp[i - 1][j] + 1;
        final insert = dp[i][j - 1] + 1;
        var best = diagonal;
        var step = similar ? _Step.misspelled : (same ? _Step.match : _Step.substitute);
        if (delete < best) {
          best = delete;
          step = _Step.delete;
        }
        if (insert < best) {
          best = insert;
          step = _Step.insert;
        }
        dp[i][j] = best;
        choice[i][j] = step;
      }
    }
    final ops = <_Op>[];
    var i = n;
    var j = m;
    while (i > 0 || j > 0) {
      final step = choice[i][j];
      switch (step) {
        case _Step.match:
        case _Step.misspelled:
        case _Step.substitute:
          if (step == _Step.match) {
            ops.add(_Op(_OpKind.correct, reference: ref[i - 1]));
          } else if (step == _Step.misspelled) {
            ops.add(_Op(_OpKind.misspelled, reference: ref[i - 1], answer: ans[j - 1]));
          } else {
            ops.add(_Op(_OpKind.missing, reference: ref[i - 1]));
            ops.add(_Op(_OpKind.extra, answer: ans[j - 1]));
          }
          i--;
          j--;
          break;
        case _Step.delete:
          ops.add(_Op(_OpKind.missing, reference: ref[i - 1]));
          i--;
          break;
        case _Step.insert:
          ops.add(_Op(_OpKind.extra, answer: ans[j - 1]));
          j--;
          break;
      }
    }
    return ops.reversed.toList();
  }

  /// 只对长度 ≥6 的词放宽 1 个编辑距离（需求 F14）。
  static bool _isMisspelling(String reference, String answer) =>
      reference.length >= 6 && answer.length >= 4 && editDistance(reference, answer) <= 1;

  static int editDistance(String a, String b) {
    if (a == b) return 0;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      for (var j = 0; j <= b.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }
}

enum _Step { match, misspelled, substitute, delete, insert }

enum _OpKind { correct, missing, extra, misspelled }

class _Op {
  const _Op(this.kind, {this.reference, this.answer});

  final _OpKind kind;
  final String? reference;
  final String? answer;
}
