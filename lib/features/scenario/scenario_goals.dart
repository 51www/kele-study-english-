import '../../domain/models/models.dart';

/// 场景的「本场 3 件小事」。
///
/// 内置场景用下表给出可见、可勾选的目标；自建场景由 `successCriteria` 反解析，
/// 无法解析时退化为 1 条整体目标。零改表、零改 26 个种子，也不会覆盖用户自建场景。
const Map<String, List<String>> kBuiltinGoals = <String, List<String>>{
  'cafe_order': <String>[
    '点清饮品和杯型',
    '追加一个小食并确认价格',
    '说清堂食还是外带',
  ],
  'meeting_clarify': <String>[
    '说出自己没听清的那一点',
    '请对方把结论换个说法再讲一遍',
    '复述一遍确认双方理解一致',
  ],
  'restaurant_order': <String>[
    '问清今天的推荐或配料',
    '点好主餐并提出一个口味要求',
    '确认上菜顺序或结账方式',
  ],
  'grocery_checkout': <String>[
    '回应店员的寒暄',
    '问清一件商品的价格或位置',
    '决定要不要袋子并完成付款',
  ],
  'return_exchange': <String>[
    '说明商品哪里有问题',
    '提出想退还是想换',
    '确认小票和退款方式',
  ],
  'post_office': <String>[
    '说清要寄到哪里、寄什么',
    '问清不同寄法的价格和时效',
    '确认单号和预计到达时间',
  ],
  'phone_booking': <String>[
    '说明想预约的服务和时间',
    '听清可约时段并换一个备选',
    '复述日期时间完成确认',
  ],
  'standup_update': <String>[
    '说清昨天做完了什么',
    '讲今天要做的和卡住的地方',
    '用一句话收尾并交给下一位',
  ],
  'interview_intro': <String>[
    '用两三句介绍背景',
    '讲一个和岗位相关的具体经历',
    '说明为什么想来这里',
  ],
  'one_on_one': <String>[
    '说出这周最有进展的一件事',
    '提出一个想请主管帮忙的问题',
    '约定下一步和大致时间',
  ],
  'client_complaint': <String>[
    '先复述对方的问题表示听懂了',
    '说明能做的处理和大致时间',
    '确认对方是否接受这个方案',
  ],
  'airport_checkin': <String>[
    '出示行程并说清目的地',
    '提出座位或行李的要求',
    '确认登机口和登机时间',
  ],
  'hotel_checkin': <String>[
    '报出预订人姓名和订单',
    '问清房型、早餐或退房时间',
    '确认押金与房卡',
  ],
  'asking_directions': <String>[
    '礼貌打招呼并说出要去的地方',
    '听清路线后追问一个地标',
    '复述一遍方向并道谢',
  ],
  'flight_rebook': <String>[
    '说明原航班和改签原因',
    '问清可选班次与差价',
    '确认新航班和行李是否直挂',
  ],
  'new_colleague': <String>[
    '打招呼并自我介绍',
    '问一个关于团队或工作的轻量问题',
    '自然收尾并留个下次聊的由头',
  ],
  'weekend_recap': <String>[
    '说一件周末做过的事',
    '追问对方周末怎么过的',
    '接住回答再补一句感受',
  ],
  'party_icebreaker': <String>[
    '用一句轻松的话开场',
    '抛出一个双方都能接的话题',
    '把话题递给对方或第三个人',
  ],
  'decline_invitation': <String>[
    '先感谢邀请',
    '给出一个简单不过度解释的理由',
    '提出替代时间或祝对方玩得开心',
  ],
  'clinic_symptoms': <String>[
    '说清哪里不舒服、什么时候开始',
    '补充一个相关细节或过往情况',
    '问清接下来要做什么检查',
  ],
  'pharmacy': <String>[
    '说清要买什么或什么症状',
    '问清用法用量和注意事项',
    '确认价格和是否有替代',
  ],
  'call_in_sick': <String>[
    '说明今天不能到岗',
    '简单交代症状，不展开细节',
    '说清工作交接和预计返岗时间',
  ],
  'emergency_help': <String>[
    '一句话说清发生了什么',
    '给出位置或联系方式',
    '确认对方能提供的帮助',
  ],
  'disagree_politely': <String>[
    '先认可对方说法里合理的部分',
    '用委婉句式说出自己的不同看法',
    '给一个可讨论的折中建议',
  ],
  'explain_topic': <String>[
    '用一句话给这个话题下定义',
    '举一个具体例子说明',
    '问对方有没有听懂或想追问',
  ],
  'mini_debate': <String>[
    '明确说出自己的立场',
    '给出一条理由和一个例子',
    '回应对方反方观点并收束',
  ],
};

/// 内置场景取预设；自建场景从 `successCriteria` 反解析。
List<String> scenarioGoals(Scenario scenario) {
  final preset = kBuiltinGoals[scenario.id];
  if (preset != null && preset.isNotEmpty) return preset;
  return goalsFromCriteria(scenario.successCriteria, scenario.titleZh);
}

/// 支持 `1. … 2. … 3. …` 编号清单；解析不出时退化为 1 条整体目标。
List<String> goalsFromCriteria(String criteria, String titleZh) {
  final text = criteria.trim();
  if (text.isEmpty) return <String>['用英语完成「$titleZh」的对话'];
  final matches = RegExp(r'(?:^|\s)(\d)[.、)]\s*([^0-9]+?)(?=\s+\d[.、)]\s*|$)')
      .allMatches(text)
      .map((match) => match.group(2)!.trim())
      .where((goal) => goal.isNotEmpty)
      .toList();
  if (matches.length >= 2) return matches.take(3).toList();
  return <String>[text];
}

/// 把 3 条目标写成可反解析的完成标准，供一句话生成场景使用。
String goalsToCriteria(List<String> goals) => goals
    .asMap()
    .entries
    .map((entry) => '${entry.key + 1}. ${entry.value}')
    .join(' ');
