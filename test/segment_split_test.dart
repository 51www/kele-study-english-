import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/features/dictation/align/segment_splitter.dart';
import 'package:kele_speak/features/dictation/ingest/subtitle_parser.dart';

SubtitleCue _cue(String text, int start, int end) =>
    SubtitleCue(startMs: start, endMs: end, text: text);

void main() {
  group('句子切分与对齐', () {
    test('过滤音乐行、合并过短字幕行、首尾留余量', () {
      final drafts = splitSegments([
        _cue('[Music]', 0, 1500),
        _cue('Hello there, my friend.', 1500, 3000),
        _cue('How are you today?', 3000, 6000),
        _cue('I would like a large coffee, please.', 6000, 11000),
        _cue('Thank you very much.', 11000, 14000),
      ]);
      expect(drafts, isNotEmpty);
      expect(drafts.every((e) => e.wordCount >= 5), isTrue);
      expect(drafts.every((e) => e.endMs > e.startMs), isTrue);
      expect(drafts.any((e) => e.text.contains('[Music]')), isFalse);
      expect(drafts.first.startMs, lessThan(1500));
      expect(drafts.last.endMs, greaterThan(14000));
    });

    test('Mr. 这类缩写不会被切成两句', () {
      final drafts = splitSegments([
        _cue('Mr. Smith went to the cafe yesterday.', 0, 4000),
        _cue('He ordered a large coffee and sat down.', 4000, 8000),
      ]);
      expect(drafts.length, 2);
      expect(drafts.first.text, startsWith('Mr. Smith went'));
      expect(drafts.last.text, startsWith('He ordered'));
    });

    test('过长句在逗号 / 连词处再切', () {
      final drafts = splitSegments([
        _cue(
          'I went to the market yesterday morning, and I bought some fresh apples, '
          'then I walked back home, because the bus was late, so I missed the '
          'meeting, but everything was fine in the end.',
          0,
          15000,
        ),
      ]);
      expect(drafts.length, greaterThanOrEqualTo(2));
      expect(drafts.every((e) => e.wordCount <= 22), isTrue);
      expect(drafts.every((e) => e.endMs - e.startMs <= 12000), isTrue);
      expect(drafts.map((e) => e.text).join(' '), contains('market'));
    });

    test('相邻重复句合并、无有效字幕时返回空', () {
      final repeated = splitSegments([
        _cue('I really like this coffee shop downtown.', 0, 5000),
        _cue('I really like this coffee shop downtown.', 5000, 10000),
      ]);
      expect(repeated.length, 1);
      expect(repeated.single.endMs, greaterThan(10000));
      expect(splitSegments([_cue('[Music]', 0, 1000), _cue('(applause)', 1000, 2000)]),
          isEmpty);
    });
  });
}
