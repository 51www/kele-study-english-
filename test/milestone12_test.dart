import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/domain/models/models.dart';
import 'package:kele_speak/features/chat/learner_profile.dart';
import 'package:kele_speak/features/retention/review_item.dart';
import 'package:kele_speak/services/llm/prompt_builder.dart';

Scenario scenario() => const Scenario(
      id: 'cafe_order',
      titleZh: '咖啡店点单',
      titleEn: 'Ordering Coffee',
      category: '生活',
      level: 'A2',
      aiRole: 'a waiter taking the order',
      userGoal: 'order a drink and a snack',
      openingLine: 'What can I get for you?',
      targetPhrases: <String>['Could I get a flat white', 'Anything else?'],
      expectedTurns: 8,
      successCriteria: '3 small goals',
    );

/// M8 结束时的 chatSystem 原文，用于「关闭档案后行为完全一致」的逐字校验。
const String m8ChatSystemBaseline = 'You are playing a role in an English speaking '
    'practice app. Stay in character at all times.\n'
    '\n'
    'Scenario: 咖啡店点单 / Ordering Coffee\n'
    'Your role: a waiter taking the order\n'
    'User goal: order a drink and a snack\n'
    'Success criteria: 3 small goals\n'
    '\n'
    'Target phrases: Could I get a flat white | Anything else?\n'
    '\n'
    'Rules:\n'
    '- Reply in natural English only. Never use Chinese unless the user explicitly asks.\n'
    '- When it fits naturally, elicit or reuse the target phrases; never list them, '
    'quiz the user, or force them in.\n'
    '- Keep every reply to 1-2 short sentences, then ask exactly one question to '
    'keep the conversation going.\n'
    '- Use vocabulary and grammar at B1 level. Do not correct the user inside the '
    'role-play.\n'
    '- Never mention that you are an AI, a model, or a prompt.\n'
    '- If the user is silent or unclear, gently prompt them with a simple question.';

SessionRecord sess(String id, int startedAt, {String? reviewJson}) => SessionRecord(
      id: id,
      scenarioId: 'cafe_order',
      startedAt: startedAt,
      durationSec: 600,
      turnCount: 8,
      status: 'completed',
      reviewJson: reviewJson,
    );

Correction corr(String id, String sessionId, String reason) => Correction(
      id: id,
      sessionId: sessionId,
      messageId: '',
      original: 'rough version',
      improved: 'Could I get a flat white please',
      reasonZh: reason,
      createdAt: 0,
    );

ReviewItem item(String id, String text, int createdAt) => ReviewItem(
      id: id,
      sourceType: 'correction',
      sourceId: id,
      textEn: text,
      dueAt: createdAt,
      consolidated: true,
      createdAt: createdAt,
    );

Phrase phrase(String id, String text, int createdAt) => Phrase(
      id: id,
      textEn: text,
      audioPath: 'AUDIO-PATH-MARK',
      mastered: true,
      createdAt: createdAt,
    );

MessageRecord msg(String id, String text) => MessageRecord(
      id: id,
      sessionId: 'current',
      seq: 1,
      role: 'user',
      textEn: text,
      createdAt: 0,
    );

void main() {
  final s = scenario();

  group('关闭学习者档案时行为一致', () {
    test('chatSystem 与 M8 原文逐字相同', () {
      expect(PromptBuilder.chatSystem(s, 'B1'), m8ChatSystemBaseline);
      expect(
        PromptBuilder.chatSystem(s, 'B1', profile: null, pressure: null),
        m8ChatSystemBaseline,
      );
      expect(
        PromptBuilder.chatMessages(
          scenario: s,
          level: 'B1',
          history: <MessageRecord>[],
        ).first.content,
        m8ChatSystemBaseline,
      );
      expect(
        PromptBuilder.chatSystem(s, 'B1'),
        contains('Use vocabulary and grammar at B1 level'),
      );
    });

    test('开关关闭时聚合直接返回 null', () {
      final profile = buildLearnerProfile(LearnerProfileInput(
        enabled: false,
        sessions: <SessionRecord>[sess('s1', 1000)],
        correctionsBySession: <String, List<Correction>>{},
        reviewItems: <ReviewItem>[],
        phrases: <Phrase>[],
        scenarios: <Scenario>[s],
        currentSessionId: 'current',
      ));
      expect(profile, isNull);
      expect(
        PromptBuilder.chatSystem(s, 'B1', profile: profile),
        m8ChatSystemBaseline,
      );
    });
  });

  group('只读档案聚合', () {
    test('固定 3 类、只取尾部会话、不读复盘 JSON / 音频、整块有上限', () {
      final now = 1794000000000;
      final sessions = <SessionRecord>[
        for (var i = 0; i < 10; i++)
          sess('s$i', now - i * 86400000, reviewJson: 'REVIEW-JSON-MARK'),
      ];
      final corrections = <String, List<Correction>>{
        's0': <Correction>[corr('a', 's0', '时态不对')],
        's1': <Correction>[corr('b', 's1', '语序要调整')],
        's2': <Correction>[corr('c', 's2', '时态不对')],
        's3': <Correction>[corr('d', 's3', '语序要调整')],
        's7': <Correction>[corr('e', 's7', '冠词漏了')],
        's8': <Correction>[corr('f', 's8', '冠词漏了')],
        's9': <Correction>[corr('g', 's9', '冠词漏了')],
      };
      final profile = buildLearnerProfile(LearnerProfileInput(
        enabled: true,
        sessions: sessions,
        correctionsBySession: corrections,
        reviewItems: <ReviewItem>[
          item('r1', 'Could I get a flat white, please?', now),
          item('r2', 'That works for me tomorrow', now - 1),
          item('r3', 'Anything else?', now - 2),
          item('r4', '第四条不该进档案', now - 3),
        ],
        phrases: <Phrase>[phrase('p1', 'Could I get a flat white, please?', now)],
        scenarios: <Scenario>[s],
        currentSessionId: 'current',
      ))!;

      expect(profile.weakSpots.length, lessThanOrEqualTo(learnerProfileMaxWeakSpots));
      expect(profile.mastered.length, lessThanOrEqualTo(learnerProfileMaxMastered));
      expect(profile.weakSpots, isNot(contains('冠词'))); // 只取尾部 6 次会话
      expect(profile.lastTopic, contains('咖啡店点单 / Ordering Coffee'));
      final rendered = profile.render();
      expect(rendered.length, lessThanOrEqualTo(learnerProfileMaxBlockChars));
      expect(rendered, contains('Recurring weak spots'));
      expect(rendered, contains('Expressions already mastered'));
      expect(rendered, contains('Last topic'));
      expect(rendered, isNot(contains('REVIEW-JSON-MARK')));
      expect(rendered, isNot(contains('AUDIO-PATH-MARK')));
      expect(rendered, isNot(contains('第四条不该进档案')));
      for (final text in profile.mastered) {
        expect(text.length, lessThanOrEqualTo(learnerProfileMaxItemChars));
      }
    });

    test('超长字段被截断，整块仍不超过上限', () {
      final profile = LearnerProfile(
        weakSpots: <String>[List<String>.filled(40, '时态').join(), '介词'],
        mastered: <String>[
          List<String>.filled(40, 'flat white').join(' '),
        ],
        lastTopic: List<String>.filled(40, '咖啡店点单').join(),
      );
      expect(profile.render().length, lessThanOrEqualTo(learnerProfileMaxBlockChars));
    });

    test('没有历史数据时档案为空，但防脚本化规则仍在', () {
      final profile = buildLearnerProfile(LearnerProfileInput(
        enabled: true,
        sessions: <SessionRecord>[],
        correctionsBySession: <String, List<Correction>>{},
        reviewItems: <ReviewItem>[],
        phrases: <Phrase>[],
        scenarios: <Scenario>[],
        currentSessionId: 'current',
      ))!;
      expect(profile.isEmpty, isTrue);
      final prompt = PromptBuilder.chatSystem(s, 'B1', profile: profile);
      expect(prompt, isNot(contains('Learner profile')));
      expect(prompt, contains('Rules for variety'));
      expect(prompt, contains('Do not reuse an opening line'));
      expect(prompt, contains('Move one step deeper'));
      expect(prompt, contains('exactly one question'));
      expect(prompt, contains('Use vocabulary and grammar at B1 level'));
    });
  });

  group('主对话与旁路隔离', () {
    test('档案只进 chatSystem，SessionContext 范围未扩大', () {
      final profile = LearnerProfile(
        weakSpots: <String>['时态'],
        mastered: <String>['Could I get a flat white'],
        lastTopic: '咖啡店点单 / Ordering Coffee',
      );
      final system = PromptBuilder.chatSystem(s, 'B1', profile: profile);
      expect(system, contains('Learner profile (read-only'));
      expect(system, contains('Last topic: 咖啡店点单 / Ordering Coffee'));
      expect(system, contains('Rules for variety'));

      final ctx = SessionContext(
        scenario: s,
        history: <MessageRecord>[msg('m1', 'I very like it')],
      );
      final rendered = ctx.render();
      expect(rendered, isNot(contains('Learner profile')));
      expect(rendered, isNot(contains('Last topic')));
      expect(rendered, isNot(contains('Recurring weak spots')));
      expect(rendered, isNot(contains('Use vocabulary and grammar')));
      expect(rendered, isNot(contains('B1')));
      expect(SessionContext.sideHistoryMessages, 12);
      expect(SessionContext.mainHistoryMessages, 16);
      expect(PromptBuilder.hintMessages(context: ctx, level: 2).length, 2);
      expect(PromptBuilder.improveMessages('I very like it', ctx).length, 2);
    });

    test('主对话历史窗口仍是 16 条，档案不进消息数组', () {
      final history = <MessageRecord>[
        for (var i = 0; i < 20; i++) msg('m$i', 'line-$i'),
      ];
      final messages = PromptBuilder.chatMessages(
        scenario: s,
        level: 'B1',
        history: history,
        profile: LearnerProfile(
          weakSpots: <String>['时态'],
          mastered: <String>[],
        ),
      );
      expect(messages.length, SessionContext.mainHistoryMessages + 1);
      expect(messages.first.role, 'system');
      expect(messages.first.content, contains('Learner profile'));
      for (final message in messages.skip(1)) {
        expect(message.content, isNot(contains('Learner profile')));
      }
    });
  });

  group('一键加压', () {
    test('只在系统提示里追加一次，且不改已发消息', () {
      final history = <MessageRecord>[msg('m1', 'I very like it')];
      final profile = LearnerProfile(
        weakSpots: <String>['时态'],
        mastered: <String>[],
      );
      final withPressure = PromptBuilder.chatMessages(
        scenario: s,
        level: 'B1',
        history: history,
        profile: profile,
        pressure: kPressureInstructions['angle'],
      );
      final withoutPressure = PromptBuilder.chatMessages(
        scenario: s,
        level: 'B1',
        history: history,
        profile: profile,
      );
      expect(withPressure.first.content, contains('Next-turn instruction'));
      expect(withPressure.first.content, contains('Change the angle'));
      expect(withoutPressure.first.content, isNot(contains('Next-turn instruction')));
      expect(withPressure.length, withoutPressure.length);
      for (final message in withPressure.skip(1)) {
        expect(message.content, 'I very like it');
        expect(message.content, isNot(contains('Change the angle')));
      }
      expect(kPressureOptions.length, 2);
      expect(kPressureInstructions.length, 2);
    });
  });
}
