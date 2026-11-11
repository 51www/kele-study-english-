import 'dart:convert';
import 'dart:typed_data';

import 'package:charset/charset.dart' as charset;
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/features/dictation/ingest/subtitle_parser.dart';

Uint8List _bytes(String text, {bool bom = false}) => Uint8List.fromList([
      if (bom) ...const [0xEF, 0xBB, 0xBF],
      ...utf8.encode(text),
    ]);

void main() {
  group('SRT / VTT 解析', () {
    test('标准 SRT 能读出时间轴与文本', () {
      final parsed = SubtitleParser.parse(
        _bytes('''1
00:00:01,000 --> 00:00:03,500
Hello there.

2
00:00:04,000 --> 00:00:07,250
<i>I would like</i> a coffee.
'''),
        fileName: 'lesson.srt',
      );
      expect(parsed.encoding, 'UTF-8');
      expect(parsed.cues.length, 2);
      expect(parsed.cues.first.startMs, 1000);
      expect(parsed.cues.first.endMs, 3500);
      expect(parsed.cues.last.text, 'I would like a coffee.');
      expect(parsed.durationMs, 7250);
    });

    test('VTT 能跳过头块、cue 标识与样式，时间码用点号也能读', () {
      final parsed = SubtitleParser.parse(
        _bytes('''WEBVTT

NOTE this is a note

cue-1
00:01.000 --> 00:03.000 align:start position:0%
<b>Good morning.</b>

cue-2
00:03.000 --> 00:06.000
See you later.
'''),
        fileName: 'lesson.vtt',
      );
      expect(parsed.cues.length, 2);
      expect(parsed.cues.first.startMs, 1000);
      expect(parsed.cues.first.text, 'Good morning.');
      expect(parsed.cues.last.endMs, 6000);
    });

    test('UTF-8 BOM 与 GBK 都不乱码', () {
      final withBom = SubtitleParser.parse(
        _bytes('1\n00:00:01,000 --> 00:00:02,000\nHello.\n', bom: true),
        fileName: 'bom.srt',
      );
      expect(withBom.encoding, 'UTF-8 BOM');
      expect(withBom.cues.single.text, 'Hello.');

      final gbkBytes = Uint8List.fromList(charset.gbk.encode(
        '1\n00:00:01,000 --> 00:00:02,000\n你好，世界\n',
      ));
      final parsed = SubtitleParser.parse(gbkBytes, fileName: 'gbk.srt');
      expect(parsed.encoding, 'GBK');
      expect(parsed.cues.single.text, contains('世界'));
    });

    test('无有效时间轴、格式不支持、超过 30 分钟都有明确原因', () {
      expect(
        () => SubtitleParser.parse(_bytes('just some text'), fileName: 'bad.srt'),
        throwsA(isA<SubtitleParseException>()),
      );
      expect(
        () => SubtitleParser.parse(_bytes('hello'), fileName: 'bad.txt'),
        throwsA(isA<SubtitleParseException>()),
      );
      expect(
        () => SubtitleParser.parse(
          _bytes('1\n00:31:00,000 --> 00:31:05,000\nToo long.\n'),
          fileName: 'long.srt',
        ),
        throwsA(
          isA<SubtitleParseException>().having(
            (e) => e.message,
            'message',
            contains('30 分钟'),
          ),
        ),
      );
      expect(
        () => SubtitleParser.parse(Uint8List(0), fileName: 'empty.srt'),
        throwsA(isA<SubtitleParseException>()),
      );
    });
  });
}
