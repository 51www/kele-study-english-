import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/domain/models/models.dart';
import 'package:kele_speak/services/llm/prompt_builder.dart';

Scenario _scenario({
  String titleZh = '餐厅点餐',
  String titleEn = 'Ordering food',
  String aiRole = 'a waiter taking the order',
  String userGoal = 'order a main course and a drink',
  String successCriteria = 'place a complete order politely',
  List<String> targetPhrases = const ['I would like', 'Could I have'],
  String level = 'C2-PROFICIENCY-MARK',
  String branchHint = 'BRANCH-CONTROL-MARK',
}) =>
    Scenario(
      id: 's1',
      titleZh: titleZh,
      titleEn: titleEn,
      category: 'daily',
      level: level,
      aiRole: aiRole,
      userGoal: userGoal,
      openingLine: 'Welcome!',
      targetPhrases: targetPhrases,
      expectedTurns: 6,
      successCriteria: successCriteria,
      branchHint: branchHint,
    );

MessageRecord _msg(
  String id,
  String role,
  String text, {
  bool isHint = false,
  String status = 'ok',
}) =>
    MessageRecord(
      id: id,
      sessionId: 'session-1',
      seq: int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? 0,
      role: role,
      textEn: text,
      isHint: isHint,
      status: status,
      createdAt: 0,
    );

void main() {
  test('会话快照：场景 5 字段 + 本次会话消息，范围封闭', () {
    final context = SessionContext(
      scenario: _scenario(),
      history: <MessageRecord>[
        _msg('m1', 'assistant', 'What would you like to drink?'),
        _msg('m2', 'user', 'I very like it'),
        _msg('m3', 'user', 'HINT-RESULT-MARK', isHint: true),
        _msg('m4', 'user', 'BROKEN-MARK', status: 'failed'),
        _msg('m5', 'user', '   '),
      ],
    );
    final rendered = context.render();

    expect(rendered, contains('餐厅点餐'));
    expect(rendered, contains('Ordering food'));
    expect(rendered, contains('a waiter taking the order'));
    expect(rendered, contains('order a main course and a drink'));
    expect(rendered, contains('place a complete order politely'));
    expect(rendered, contains('I would like | Could I have'));
    expect(rendered, contains('AI: What would you like to drink?'));
    expect(rendered, contains('User: I very like it'));

    // Q9/Q11/Q12：水平、分支控制、提示结果、失败消息都不进快照。
    expect(rendered, isNot(contains('C2-PROFICIENCY-MARK')));
    expect(rendered, isNot(contains('BRANCH-CONTROL-MARK')));
    expect(rendered, isNot(contains('Use vocabulary and grammar')));
    expect(rendered, isNot(contains('HINT-RESULT-MARK')));
    expect(rendered, isNot(contains('BROKEN-MARK')));

    // Q11 只作用于旁路；主对话仍按水平调整用词。
    expect(
      PromptBuilder.chatSystem(_scenario(), 'B1'),
      contains('Use vocabulary and grammar at B1 level'),
    );
  });

  test('会话快照：超窗按消息条数截断，只保留尾部 12 条', () {
    String marker(int i) => 'line-${i.toString().padLeft(2, '0')}';
    final history = <MessageRecord>[
      for (var i = 0; i < 20; i++) _msg('m$i', 'user', marker(i)),
    ];
    final transcript = SessionContext(scenario: null, history: history).transcript;

    for (var i = 0; i < 8; i++) {
      expect(transcript, isNot(contains(marker(i))));
    }
    for (var i = 8; i < 20; i++) {
      expect(transcript, contains(marker(i)));
    }
    // 主链路窗口保持 16 条，两个常量取值独立。
    expect(SessionContext.sideHistoryMessages, 12);
    expect(SessionContext.mainHistoryMessages, 16);
  });

  test('会话快照：空历史不崩，两处旁路仍返回 system + user 两条消息', () {
    final context = SessionContext(scenario: null, history: const <MessageRecord>[]);
    expect(context.render(), contains('(no conversation yet)'));
    expect(context.scenarioBlock, contains('daily conversation'));

    final hint = PromptBuilder.hintMessages(context: context, level: 3);
    expect(hint.length, 2);
    expect(hint.first.role, 'system');
    expect(hint.last.role, 'user');
    expect(hint.first.content, contains('EN:'));
    expect(hint.first.content, contains('ZH:'));

    final improve = PromptBuilder.improveMessages('I very like it', context);
    expect(improve.length, 2);
    expect(improve.first.role, 'system');
    expect(improve.last.role, 'user');
    expect(improve.first.content, contains('BETTER:'));
    expect(improve.first.content, contains('WHY:'));
  });

  test('输出契约不变：仍是严格两行，parser 照旧能解析', () {
    final context = SessionContext(
      scenario: _scenario(),
      history: <MessageRecord>[
        _msg('m1', 'assistant', 'Anything else with your order?'),
      ],
    );
    final hint = PromptBuilder.hintMessages(context: context, level: 3);
    expect(hint.first.content, contains('exactly TWO plain-text lines'));
    expect(hint.first.content, contains('No reasoning, no markdown, no quotes'));
    expect(hint.last.content, contains('AI just said: "Anything else with your order?"'));

    final improve = PromptBuilder.improveMessages('I very like it', context);
    expect(improve.first.content, contains('exactly TWO plain-text lines'));
    expect(improve.last.content, contains('Learner said: "I very like it"'));

    expect(
      HintParser.parse('EN: I would like a coffee.\nZH: 我想要一杯咖啡。').en,
      'I would like a coffee.',
    );
    expect(
      ImprovementParser.parse('BETTER: I really like it.\nWHY: 副词位置更自然。').improved,
      'I really like it.',
    );
  });

  test('对照用例：同一句输入在不同会话语境下拼出不同的 prompt', () {
    final ordering = SessionContext(
      scenario: _scenario(),
      history: <MessageRecord>[
        _msg('m1', 'assistant', 'Would you like a drink with your meal?'),
        _msg('m2', 'user', 'Yes, I want a cola.'),
      ],
    );
    final interview = SessionContext(
      scenario: _scenario(
        titleZh: '求职面试',
        titleEn: 'Job interview',
        aiRole: 'an HR manager',
        userGoal: 'explain your work experience',
        successCriteria: 'answer with a concrete example',
        targetPhrases: const ['I am responsible for', 'In my last role'],
      ),
      history: <MessageRecord>[
        _msg('m1', 'assistant', 'Can you tell me about your last role?'),
        _msg('m2', 'user', 'I work five year.'),
      ],
    );

    final improveA = PromptBuilder.improveMessages('I very like it', ordering);
    final improveB = PromptBuilder.improveMessages('I very like it', interview);
    expect(improveA.first.content, isNot(equals(improveB.first.content)));
    expect(improveA.first.content, contains('Ordering food'));
    expect(improveA.first.content, contains('Would you like a drink with your meal?'));
    expect(improveB.first.content, contains('Job interview'));
    expect(improveB.first.content, contains('Can you tell me about your last role?'));

    final hintA = PromptBuilder.hintMessages(context: ordering, level: 3);
    final hintB = PromptBuilder.hintMessages(context: interview, level: 3);
    expect(hintA.first.content, isNot(equals(hintB.first.content)));
    expect(hintA.first.content, contains('Yes, I want a cola.'));
    expect(hintB.first.content, contains('I work five year.'));
    // 不额外增加请求：每处仍只有 system + user 两条消息。
    expect(hintA.length, 2);
    expect(hintB.length, 2);
  });
}
