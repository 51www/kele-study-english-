import '../../domain/models/models.dart';

/// 首次启动写入的 2 个内置场景（按 id 幂等 upsert）。
const builtinScenarios = <Scenario>[
  Scenario(
    id: 'cafe_order',
    titleZh: '咖啡店点单',
    titleEn: 'Ordering Coffee',
    category: '日常',
    level: 'A2',
    aiRole:
        'You are a friendly barista at a busy coffee shop. You speak naturally, keep replies short, and stay in character.',
    userGoal: '点一杯饮品、追加一个小食，并确认堂食还是外带。',
    openingLine: 'Hi there! What can I get for you today?',
    targetPhrases: [
      "I'd like a medium latte, please.",
      'Could I get that to go?',
      'For here, please.',
      'Can I add a croissant?',
      "That's all, thanks.",
    ],
    expectedTurns: 8,
    successCriteria:
        'The user orders a drink, adds a snack, and confirms whether it is for here or to go.',
    branchHint: 'If an item is sold out, offer an alternative and ask if that works.',
    sortOrder: 0,
  ),
  Scenario(
    id: 'meeting_clarify',
    titleZh: '工作会议澄清',
    titleEn: 'Clarifying in a Meeting',
    category: '工作',
    level: 'B1',
    aiRole:
        'You are a colleague in a project meeting. You speak clearly, use realistic work English, and ask one question at a time.',
    userGoal: '没听清时追问、确认数字与时间、礼貌表达不同意见。',
    openingLine:
        "Thanks for joining. Before we move on, do you have any questions about the timeline?",
    targetPhrases: [
      'Sorry, could you repeat that?',
      'Just to confirm, the deadline is Friday, right?',
      "I'm not sure I follow. Could you clarify?",
      'I see it a bit differently.',
      'That works for me.',
    ],
    expectedTurns: 10,
    successCriteria:
        'The user asks for clarification at least once, confirms a number or date, and states a different opinion politely.',
    branchHint: 'Mention a changed deadline and a conflicting priority to create clarification moments.',
    sortOrder: 1,
  ),
];
