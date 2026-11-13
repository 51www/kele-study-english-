import '../../domain/models/models.dart';

/// 场景的「本场 3 件小事」。
///
/// 内置场景用下表给出可见、可勾选的目标；自建场景由 `successCriteria` 反解析，
/// 无法解析时退化为 1 条整体目标。零改表、零改种子，也不会覆盖用户自建场景；
/// 下表条目应与 `builtinScenarios` 的 id 逐一对齐。
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
  'haircut_request': <String>[
    '说清想剪多短',
    '指出要保留和要避开的地方',
    '在下剪前确认一次方案',
  ],
  'laundry_stain': <String>[
    '凭票取衣并说明来意',
    '指出洗后仍在的污渍，不指责人',
    '问清能否重洗和其他处理方式',
  ],
  'repair_visit': <String>[
    '说清故障什么时候开始、具体表现',
    '回答师傅的两个追问',
    '问清配件、工期和费用',
  ],
  'wrong_pickup': <String>[
    '开口说明自己可能拿错了',
    '核对名字或订单内容找出差异',
    '提出换回并礼貌收尾',
  ],
  'small_favour': <String>[
    '礼貌开口并说出具体要帮什么',
    '给对方留一个拒绝的余地',
    '简单说明怎么操作并道谢',
  ],
  'polite_reminder': <String>[
    '不带指责地把情况说出来',
    '给一个中性的原因',
    '提出替代做法并让对方不难堪',
  ],
  'salary_negotiation': <String>[
    '先表达感谢和兴趣',
    '用职责或市场依据说出具体区间',
    '回应还价并约定下一步',
  ],
  'bad_news_report': <String>[
    '开头就把坏消息说清楚',
    '交代影响范围和原因，不过度道歉',
    '给出补救方案和明确的回复时间',
  ],
  'cross_team_help': <String>[
    '说清背景再提出一个具体请求',
    '说明大概工作量和期望时间',
    '确认对方是否方便并给个更小的备选',
  ],
  'interview_questions': <String>[
    '问两个和岗位真正相关的问题',
    '就回答里的某一点追问一次',
    '问清后续流程并得体收尾',
  ],
  'work_handover': <String>[
    '逐项交代还在进行中的事',
    '点出一个容易踩坑的风险和文档位置',
    '确认对方听懂、可以接手',
  ],
  'pushback_deadline': <String>[
    '不硬顶，说清现有任务占了多少时间',
    '把两个任务的冲突讲成具体取舍',
    '给出替代方案并把优先级交回去',
  ],
  'lost_luggage': <String>[
    '报告行李没到并说清航班',
    '描述箱子的外观和明显标记',
    '问清何时有消息、能否送到住处',
  ],
  'hotel_checkout_bill': <String>[
    '说明要退房',
    '不带指责地问清看不懂的一项',
    '核对解释后完成付款',
  ],
  'car_rental': <String>[
    '确认预订信息',
    '问清保险、油费和里程规则',
    '复述还车的时间和地点',
  ],
  'immigration_questions': <String>[
    '简短回答来意和停留时间',
    '说清住宿和返程安排',
    '听懂一个追问后准确补充',
  ],
  'attraction_ticket': <String>[
    '问清票价和今天几点关门',
    '买对数量的票',
    '确认要不要预约或排队',
  ],
  'wrong_train': <String>[
    '说出自己坐反了和要去哪里',
    '问清在哪站下车、往哪个方向',
    '把对方的建议复述一遍',
  ],
  'sincere_apology': <String>[
    '具体说出自己做错了什么',
    '不找借口地承担责任',
    '提出补救并给对方情绪空间',
  ],
  'comfort_friend': <String>[
    '先接住情绪，不急着给建议',
    '问一个开放问题让对方多说一点',
    '表达会陪着、不着急解决',
  ],
  'clear_misunderstanding': <String>[
    '先复述对方理解成了什么',
    '说明事实和自己的原意，不带指责',
    '约定一个简单的避免办法',
  ],
  'introduce_friends': <String>[
    '带一点背景把两人互相介绍',
    '找出一个共同点当话题',
    '把话头递出去再自然退开',
  ],
  'end_conversation': <String>[
    '接住对方刚说的最后一句',
    '给一个中性的离场理由',
    '温暖收尾并留个下次的由头',
  ],
  'thanks_return_favour': <String>[
    '具体说出对方帮了什么、有什么用',
    '道谢但不过度',
    '提出一个不给人压力的回请',
  ],
  'medicine_instructions': <String>[
    '问清一天几次、什么时候吃',
    '问清要吃多久和有没有相互作用',
    '把说明复述一遍确认',
  ],
  'symptom_change': <String>[
    '按天数说清症状怎么变化',
    '区分好转的部分和新出现的部分',
    '说明自己有没有按医嘱用药',
  ],
  'ask_doctor_explain': <String>[
    '请医生把术语换成简单说法',
    '问清这个结论对日常意味着什么',
    '确认什么情况才需要再来',
  ],
  'stress_sleep': <String>[
    '说清持续多久、睡眠具体怎么变',
    '讲出对白天状态的影响',
    '问清需不需要进一步处理',
  ],
  'speak_for_family': <String>[
    '让家属先自己说，自己补背景',
    '区分亲眼看到的和听说的',
    '交代用药和过敏史并确认家属能表达',
  ],
  'checkup_registration': <String>[
    '完成登记并确认预约',
    '问清要不要空腹和检查顺序',
    '确认总共大概花多久',
  ],
  'weigh_options': <String>[
    '用同一组标准比较两个选项',
    '把权衡的代价明确说出来',
    '给一个有条件的选择而不是绝对结论',
  ],
  'restate_view': <String>[
    '不带评价地复述对方的观点',
    '回头确认自己说得准不准',
    '指出真正的分歧在哪里',
  ],
  'personal_story': <String>[
    '交代时间地点背景',
    '按经过讲到转折和结果',
    '收尾时带出一点当时的感受',
  ],
  'persuade_someone': <String>[
    '先接住对方的顾虑再回应',
    '用具体细节回应至少两个反对点',
    '给一个低门槛的尝试方案',
  ],
  'explain_chart': <String>[
    '先说清图表量的是什么',
    '按趋势和一个具体数字讲',
    '给一个可能原因并落到一句结论',
  ],
  'admit_unsure': <String>[
    '坦白不确定，不猜答案',
    '把已知和未知分开说',
    '给出核实方式和回复时间',
  ],
  'apartment_viewing': <String>[
    '问清租金包含什么、押金多少',
    '问清最早入住日和一项设施',
    '约定再看一次的时间',
  ],
  'landlord_repair': <String>[
    '说清哪里坏了、什么时候开始',
    '说明目前怎么临时处理',
    '约好上门的时间段',
  ],
  'neighbour_noise': <String>[
    '用具体时间和影响开口，不指责',
    '提出一个按时间执行的具体约定',
    '给对方留台阶并致谢',
  ],
  'move_delivery': <String>[
    '报清地址、时间段和易碎物品',
    '确认有人签收',
    '问清费用按小时还是固定价',
  ],
  'cleaning_service': <String>[
    '说清房型大小和重点打扫区域',
    '约好日期并确认是否自带工具',
    '问清改约需要提前多久',
  ],
  'roommate_rules': <String>[
    '把家务分清楚并说好怎么轮换',
    '约定忘记时怎么直接提醒',
    '说清带客人回家的规矩和试行期',
  ],
  'bank_account': <String>[
    '说清要开哪种账户',
    '问清要带的材料和月费',
    '确认卡什么时候能拿到',
  ],
  'service_counter': <String>[
    '说清要办哪项业务并列出带的材料',
    '核对是否还缺一样',
    '问清办理时长和领取方式',
  ],
  'insurance_claim': <String>[
    '按时间讲清事故经过和发现时间',
    '列出已有的照片和证明',
    '问清免责范围和还要补什么',
  ],
  'medical_bill': <String>[
    '指出账单里看不懂的一项',
    '问清医保覆盖和自己要付多少',
    '确认谁提交材料、截止到哪天',
  ],
  'lost_card': <String>[
    '报失并说清大概什么时候丢的',
    '问有没有不认识的消费并要求冻结',
    '确认补卡要多久',
  ],
  'application_followup': <String>[
    '报出受理编号和提交日期',
    '说明自己为什么有时间压力',
    '问清卡在哪一步、缺不缺材料、能否加急',
  ],
  'course_options': <String>[
    '说清自己的年级和兴趣',
    '问清两门课的差别、先修要求和作业量',
    '请对方按自己的水平给个建议',
  ],
  'ask_after_class': <String>[
    '指出具体是哪一步没听懂',
    '请老师换个说法并复述确认',
    '问清复习重点',
  ],
  'group_project': <String>[
    '把任务拆成具体的几块',
    '认领一块并让对方选另一块',
    '定下一个明确的检查节点',
  ],
  'library_borrow': <String>[
    '完成借书并问清能借多久',
    '问清能否在线续借和逾期怎么办',
    '请对方帮自己预约另一本',
  ],
  'deadline_extension': <String>[
    '给出真实原因和已有证明',
    '说明已经完成了多少',
    '提出具体新日期并接受扣分条件',
  ],
  'borrow_notes': <String>[
    '简短说明为什么需要',
    '提出范围小、负担轻的请求和归还方式',
    '道谢并提出以后可以互相帮忙',
  ],
  'online_support': <String>[
    '说清订单号和具体问题',
    '告诉客服自己已经查过什么',
    '确认对方会怎么处理、什么时候回复',
  ],
  'dropped_video_call': <String>[
    '具体说清是听不清还是画面卡',
    '提出换语音或重拨的方案',
    '请对方重复漏掉的内容并约定文字纪要',
  ],
  'account_recovery': <String>[
    '说出准确的报错和试过的办法',
    '配合提供验证信息',
    '确认重设之后还要做什么',
  ],
  'internet_fault': <String>[
    '说清多久断一次、什么时候开始',
    '按提示检查并读出指示灯状态',
    '约定上门时间',
  ],
  'cancel_autorenew': <String>[
    '明确说要关掉自动续费，不被挽留带偏',
    '问清已付费权益到哪天、能否退最近一笔',
    '要求邮件确认取消结果',
  ],
  'guide_family_phone': <String>[
    '一次只说一步，用屏幕上看得见的词',
    '每一步都先核对对方看到了什么',
    '耐心收尾并给一句鼓励',
  ],
  'express_disappointment': <String>[
    '用一件具体的事说出自己的感受',
    '明确不翻旧账、不指责',
    '提出一个面向以后的小请求',
  ],
  'advice_without_offence': <String>[
    '先问一句能不能说说自己的观察',
    '把建议说成有限的个人看法，不下结论',
    '给一个轻量做法并把决定权交回去',
  ],
  'refuse_sales_pitch': <String>[
    '第一句就清楚说不，不编理由',
    '第二次推销时守住边界、不留个人信息',
    '礼貌收尾直接离开',
  ],
  'personal_boundary': <String>[
    '说清自己长期能接受的范围',
    '给出两个可执行的替代做法',
    '被追问时不动摇也不生硬',
  ],
  'share_good_news': <String>[
    '把好消息和一点背景讲清楚',
    '说说自己最在意哪一点',
    '接住祝贺并提议一起庆祝',
  ],
  'make_up': <String>[
    '承认自己那一半责任',
    '确认对方的感受，不争细节',
    '提出一个新的具体约定收尾',
  ],
  'bargain_price': <String>[
    '先问清单价',
    '礼貌问折扣或多买优惠，给一个具体还价',
    '确认最后成交的总价',
  ],
  'membership_points': <String>[
    '问清怎么攒积分、会不会过期',
    '问清能换什么、自己现有多少',
    '明确说这次用不用',
  ],
  'escalate_complaint': <String>[
    '简短讲清时间线和手上的凭证',
    '说明柜台的处理为什么不能接受',
    '提出一个明确诉求和一个退一步的方案',
  ],
  'ride_hailing': <String>[
    '核对身份和上车点',
    '补充目的地的一个具体细节',
    '礼貌提一个路线或温度上的小要求',
  ],
  'alteration_request': <String>[
    '说清哪里不合身、想改成什么样',
    '点明哪些地方要保持不变',
    '问清费用、工期和能否先试穿确认',
  ],
  'deposit_refund': <String>[
    '下单前问清订金比例',
    '问清取消能不能退、什么情况不可退',
    '把条款复述一遍确认',
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
