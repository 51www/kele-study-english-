import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/services/tts/tts_speech.dart';
import 'package:kele_speak/services/tts/tts_voices.dart';

void main() {
  group('normalizeForSpeech', () {
    test('折叠空白并统一弯引号、破折号', () {
      expect(
        normalizeForSpeech('  I\u2019d  like\u2014  a  latte.  '),
        "I'd like, a latte.",
      );
    });

    test('展开影响读音的缩写', () {
      expect(normalizeForSpeech('Dr. Smith said etc.'),
          'Doctor Smith said etcetera.');
      expect(normalizeForSpeech('e.g. coffee'), 'for example coffee');
    });

    test('独立的 & 读作 and', () {
      expect(normalizeForSpeech('tea & coffee'), 'tea and coffee');
    });
  });

  group('buildEdgeSsml', () {
    test('默认语气不加 express-as 与 mstts 命名空间', () {
      final ssml = buildEdgeSsml(text: 'Hello.', voice: 'en-US-AriaNeural', rate: 1.0);
      expect(ssml, isNot(contains('mstts')));
      expect(ssml, isNot(contains('express-as')));
      expect(ssml, contains("xml:lang='en-US'"));
      expect(ssml, contains("name='en-US-AriaNeural'"));
      expect(ssml, contains("rate='+0%'"));
    });

    test('选择语气时注入 express-as，并按音色设置 xml:lang', () {
      final ssml = buildEdgeSsml(
        text: 'Hello.',
        voice: 'en-GB-SoniaNeural',
        rate: 1.2,
        style: TtsSpeechStyle.friendly,
      );
      expect(ssml, contains("xmlns:mstts='http://www.w3.org/2001/mstts'"));
      expect(ssml, contains("<mstts:express-as style='friendly'>"));
      expect(ssml, contains("xml:lang='en-GB'"));
      expect(ssml, contains("rate='+20%'"));
    });

    test('标点后插入停顿，小数点与千分位不受影响', () {
      final ssml = buildEdgeSsml(
        text: 'Well, it costs \$3.50. Really? Yes, 1,000 people came.',
        voice: 'en-US-AriaNeural',
        rate: 1.0,
      );
      expect(ssml, contains('Well,<break time="150ms"/>'));
      expect(ssml, contains('3.50.<break time="300ms"/>'));
      expect(ssml, contains('3.50'));
      expect(ssml, contains('1,000 people'));
      expect(ssml, contains('Really?<break time="300ms"/>'));
      expect(ssml, isNot(contains('3<break')));
      expect(ssml, isNot(contains('1<break')));
    });

    test('XML 特殊字符被转义，break 标签本身保持原样', () {
      final ssml = buildEdgeSsml(
        text: 'A < B & C > D, ok.',
        voice: 'en-US-AriaNeural',
        rate: 1.0,
      );
      expect(ssml, contains('A &lt; B and C &gt; D'));
      expect(ssml, contains('<break time="150ms"/>'));
    });
  });

  group('voice catalog', () {
    test('清单 id 唯一且含英式与澳式音色', () {
      final ids = ttsVoiceCatalog.map((v) => v.id).toList();
      expect(ids.length, ids.toSet().length);
      expect(ids, contains('en-GB-RyanNeural'));
      expect(ids, contains('en-AU-NatashaNeural'));
    });

    test('未知音色回退默认标签与美音', () {
      expect(ttsVoiceLabel('custom-voice'), 'custom-voice');
      expect(ttsVoiceLocale('custom-voice'), 'en-US');
      expect(ttsSpeechStyleFrom('nonsense'), TtsSpeechStyle.none);
    });
  });
}
