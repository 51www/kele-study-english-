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

    test('全角标点折成半角，避免英文音色在 ！ 处插入超长停顿', () {
      expect(normalizeForSpeech('Really！ Great？ Yes。'), 'Really! Great? Yes.');
      expect(
        normalizeForSpeech('Hi，there；ok：go、now（please）'),
        'Hi, there; ok: go, now(please)',
      );
    });
  });

  group('speechSentenceCut', () {
    test('! 不作为切句边界，避免句中感叹号拆成多批合成', () {
      expect(speechSentenceCut('Wow! Amazing! Incredible!'), -1);
    });

    test('. 与 ? 在达到最小长度后切句', () {
      expect(speechSentenceCut('How are you today? Fine.'), 18);
      expect(speechSentenceCut('Sure! Let us start.'), 19);
    });

    test('过短的文本不切，超长文本按长度兜底切', () {
      expect(speechSentenceCut('Hi.'), -1);
      expect(speechSentenceCut('a' * 119), -1);
      expect(speechSentenceCut('a' * 120), 120);
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

    test('不再注入 break 标签，标点与小数千分位保持原样', () {
      final ssml = buildEdgeSsml(
        text: 'Well, it costs \$3.50. Really? Yes, 1,000 people came.',
        voice: 'en-US-AriaNeural',
        rate: 1.0,
      );
      // 新版 Edge 端点拒绝 <break>（1007 SSML is invalid），停顿交给标点。
      expect(ssml, isNot(contains('<break')));
      expect(ssml, contains('Well, it costs \$3.50. Really? Yes, 1,000 people came.'));
    });

    test('全角感叹号在 SSML 里已折成半角', () {
      final ssml = buildEdgeSsml(
        text: 'Wow！ Amazing！',
        voice: 'en-US-AriaNeural',
        rate: 1.0,
      );
      expect(ssml, contains('Wow! Amazing!'));
      expect(ssml, isNot(contains('！')));
    });

    test('XML 特殊字符被转义', () {
      final ssml = buildEdgeSsml(
        text: 'A < B & C > D, ok.',
        voice: 'en-US-AriaNeural',
        rate: 1.0,
      );
      expect(ssml, contains('A &lt; B and C &gt; D'));
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
