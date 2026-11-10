import '../../domain/models/models.dart';

/// 首次启动写入的 26 个内置场景（2 个 MVP 首批 + 24 个扩展，按 id 幂等 upsert）。
///
/// 选题与分类依据见 `docs/research-practice-scenarios-2026-11.md`。
/// 约定：id 稳定不复用；level 取 A2/B1/B2；expectedTurns 8–12；
/// 每个场景 5 条目标表达 + 1 个 branchHint 意外分支。
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
  // ── 日常 ────────────────────────────────────────────────────────────────
  Scenario(
    id: 'restaurant_order',
    titleZh: '餐厅点餐',
    titleEn: 'Ordering at a Restaurant',
    category: '日常',
    level: 'A2',
    aiRole:
        'You are a friendly server at a casual restaurant. You speak simply, keep replies to one or two short sentences, ask one question at a time, and stay in character.',
    userGoal: '订位或入座、点一份主食与饮料、说明忌口、追加一份小食，最后结账。',
    openingLine: 'Hi! Welcome in. Do you have a reservation, or is it just you today?',
    targetPhrases: [
      'A table for one, please.',
      'Could I see the menu, please?',
      "I'll have the grilled chicken, please.",
      "I'm allergic to nuts — does this have any?",
      'Could we get the bill, please?',
    ],
    expectedTurns: 8,
    successCriteria:
        'The user is seated, orders a main dish and a drink, states a dietary restriction, and asks for the bill.',
    branchHint: 'After the order, say the daily special is sold out and offer a similar alternative.',
    sortOrder: 2,
  ),
  Scenario(
    id: 'grocery_checkout',
    titleZh: '超市结账',
    titleEn: 'At the Checkout',
    category: '日常',
    level: 'A2',
    aiRole:
        'You are a cashier at a neighborhood supermarket. You speak slowly and clearly, keep replies short, and ask one question at a time.',
    userGoal: '找到需要的商品、问清价格、确认是否要袋子，并选择付款方式。',
    openingLine: 'Hi there! Did you find everything you were looking for?',
    targetPhrases: [
      'Where can I find the milk?',
      'How much is this, please?',
      "I don't need a bag, thanks.",
      'Can I pay by card?',
      'Could I have the receipt, please?',
    ],
    expectedTurns: 8,
    successCriteria: 'The user locates an item, checks a price, decides about a bag, and pays.',
    branchHint: 'The card terminal is slow; offer to try again or ask if the user has cash.',
    sortOrder: 3,
  ),
  Scenario(
    id: 'return_exchange',
    titleZh: '退换商品',
    titleEn: 'Returning an Item',
    category: '日常',
    level: 'B1',
    aiRole:
        'You are a polite store clerk at the customer service desk. You ask for one detail at a time and explain the store policy in simple English.',
    userGoal: '说明商品问题、出示小票、在换货与退款之间做选择，并确认处理时间。',
    openingLine: 'Hello, how can I help you today?',
    targetPhrases: [
      "I'd like to return this, please.",
      "It doesn't fit — the size is too small.",
      "Here's my receipt.",
      'Could I exchange it for a larger size?',
      'How long will the refund take?',
    ],
    expectedTurns: 8,
    successCriteria:
        'The user explains the problem, presents proof of purchase, chooses exchange or refund, and confirms the timing.',
    branchHint: 'The same size is out of stock; offer a different color or a refund instead.',
    sortOrder: 4,
  ),
  Scenario(
    id: 'post_office',
    titleZh: '邮局寄件',
    titleEn: 'At the Post Office',
    category: '日常',
    level: 'A2',
    aiRole:
        'You are a postal clerk. You speak plainly, ask one question at a time, and give short practical answers.',
    userGoal: '说明包裹寄往哪里、比较普通与加急、确认重量与追踪方式。',
    openingLine: 'Next, please! What can I do for you today?',
    targetPhrases: [
      "I'd like to send this package, please.",
      "It's going to New York.",
      "What's the difference between standard and express?",
      'How much does it weigh?',
      'Will I get a tracking number?',
    ],
    expectedTurns: 8,
    successCriteria:
        'The user sends a package, compares two shipping options, checks the weight, and asks about tracking.',
    branchHint: 'The address is missing a postal code; ask the user to confirm it.',
    sortOrder: 5,
  ),
  Scenario(
    id: 'phone_booking',
    titleZh: '打电话预约',
    titleEn: 'Booking by Phone',
    category: '日常',
    level: 'B1',
    aiRole:
        'You are a receptionist on a phone call. You speak clearly, spell out key details, repeat confirmations back, and never rely on visual information.',
    userGoal: '在没有视觉线索的情况下预约服务，说清日期时间，并确认姓名拼写与联系方式。',
    openingLine: 'Good morning, Sunrise Dental, how may I help you?',
    targetPhrases: [
      "I'd like to make an appointment, please.",
      'Do you have anything available on Thursday afternoon?',
      'Could you repeat the time, please?',
      "It's Chen, that's C-H-E-N.",
      "So that's 3:30 on Thursday, right?",
    ],
    expectedTurns: 8,
    successCriteria:
        'The user books a slot, confirms the date and time by repeating them, and spells their name.',
    branchHint: 'The requested slot is taken; propose two alternatives and wait for a choice.',
    sortOrder: 6,
  ),
  // ── 工作 ────────────────────────────────────────────────────────────────
  Scenario(
    id: 'standup_update',
    titleZh: '每日站会',
    titleEn: 'Daily Standup',
    category: '工作',
    level: 'B1',
    aiRole:
        'You are a teammate running the daily standup. You speak in realistic work English, keep replies short, and ask one follow-up at a time.',
    userGoal: '用三句话讲清昨天做了什么、今天要做什么、有什么阻塞，并回应一次追问。',
    openingLine: 'Morning! Ready for standup? What did you get done yesterday?',
    targetPhrases: [
      'Yesterday I finished the login fix.',
      "Today I'm working on the signup tests.",
      "I'm blocked on the API credentials.",
      'Could you clarify who owns that task?',
      "I'll follow up with you after the meeting.",
    ],
    expectedTurns: 8,
    successCriteria:
        'The user reports yesterday, today, and one blocker, and answers a follow-up question.',
    branchHint: "Mention a priority change mid-call and ask how it affects the user's plan.",
    sortOrder: 7,
  ),
  Scenario(
    id: 'interview_intro',
    titleZh: '面试自我介绍',
    titleEn: 'Job Interview Intro',
    category: '工作',
    level: 'B1',
    aiRole:
        'You are a hiring manager conducting a first-round interview. You are warm but professional, ask one question at a time, and follow up on specific details.',
    userGoal: '完成 60 秒自我介绍，用具体经历回答追问，并说明为什么适合这个岗位。',
    openingLine: 'Thanks for coming in. To start, could you tell me a little about yourself?',
    targetPhrases: [
      "I've been working in product design for about four years.",
      "One project I'm proud of is the checkout redesign.",
      'My role was to coordinate the design and engineering teams.',
      'The result was a 15% drop in drop-off.',
      "I'd love to bring that experience to this team.",
    ],
    expectedTurns: 12,
    successCriteria:
        'The user gives a structured self-introduction, answers at least two follow-ups with concrete examples, and links their experience to the role.',
    branchHint: 'Ask about a project that did not go well, then ask what the user would do differently.',
    sortOrder: 8,
  ),
  Scenario(
    id: 'one_on_one',
    titleZh: '主管 1:1',
    titleEn: 'One-on-One with Your Manager',
    category: '工作',
    level: 'B2',
    aiRole:
        "You are the user's manager in a weekly one-on-one. You are supportive but direct, give one piece of feedback at a time, and ask open questions.",
    userGoal: '汇报进展、说明遇到的阻力、提出需要的支持，并对一条反馈给出回应。',
    openingLine: 'Good to see you. How are things going on your side this week?',
    targetPhrases: [
      'The main thing I want to discuss is the release schedule.',
      "We're on track, but I'm worried about the review time.",
      'Would it be possible to get one more reviewer?',
      "I take your point about the documentation.",
      "I'll send you an updated plan by Friday.",
    ],
    expectedTurns: 10,
    successCriteria:
        'The user reports progress, names a concrete obstacle, asks for support, and responds to feedback with a next step.',
    branchHint: 'Give a piece of feedback the user may not expect, then pause for their reaction.',
    sortOrder: 9,
  ),
  Scenario(
    id: 'client_complaint',
    titleZh: '客户投诉处理',
    titleEn: 'Handling a Client Complaint',
    category: '工作',
    level: 'B2',
    aiRole:
        'You are a dissatisfied client on a support call. You are firm but not rude, and you expect a concrete remedy rather than an apology alone.',
    userGoal: '先承认问题、不推卸，给出补救方案与明确时间，并确认客户接受。',
    openingLine: 'I need to talk about the delivery — this is the second time it has slipped.',
    targetPhrases: [
      "You're right, and I'm sorry we missed the date.",
      'Let me make sure I understand the impact.',
      "Here's what I can do right now.",
      "I'll come back to you within 24 hours with a written plan.",
      'Does that work for you?',
    ],
    expectedTurns: 10,
    successCriteria:
        'The user acknowledges the problem without deflecting, offers a concrete remedy with a deadline, and confirms the client accepts it.',
    branchHint: 'Push back once: say a verbal promise is not enough and ask for something in writing.',
    sortOrder: 10,
  ),
  // ── 旅行 ────────────────────────────────────────────────────────────────
  Scenario(
    id: 'airport_checkin',
    titleZh: '机场值机',
    titleEn: 'Airport Check-in',
    category: '旅行',
    level: 'A2',
    aiRole:
        'You are a check-in agent at the airport. You speak slowly, use simple travel English, and ask one question at a time.',
    userGoal: '办理值机、托运行李、确认座位偏好，并问清登机口与登机时间。',
    openingLine: 'Good morning! May I see your passport and booking reference?',
    targetPhrases: [
      "Here's my passport.",
      "I'd like to check in one bag, please.",
      'Could I have a window seat?',
      'Which gate is it?',
      'What time does boarding start?',
    ],
    expectedTurns: 8,
    successCriteria:
        'The user checks in, checks a bag, states a seat preference, and confirms gate and boarding time.',
    branchHint:
        'The bag is two kilos over the limit; explain the fee and offer to move one item to hand luggage.',
    sortOrder: 11,
  ),
  Scenario(
    id: 'hotel_checkin',
    titleZh: '酒店入住',
    titleEn: 'Hotel Check-in',
    category: '旅行',
    level: 'A2',
    aiRole:
        'You are a front desk agent at a small hotel. You are welcoming, speak clearly, and ask one question at a time.',
    userGoal: '报出预订、确认房型与住几晚、问清早餐与退房时间，并索要 Wi-Fi 信息。',
    openingLine: 'Welcome! Do you have a reservation with us?',
    targetPhrases: [
      'I have a reservation under Chen.',
      "It's for two nights, a double room.",
      'Is breakfast included?',
      'What time is check-out?',
      'Could I have the Wi-Fi password, please?',
    ],
    expectedTurns: 8,
    successCriteria:
        'The user confirms the booking and room type, asks about breakfast and check-out, and gets the Wi-Fi details.',
    branchHint: 'The room is not ready yet; offer to store the luggage and suggest a nearby cafe.',
    sortOrder: 12,
  ),
  Scenario(
    id: 'asking_directions',
    titleZh: '街头问路',
    titleEn: 'Asking for Directions',
    category: '旅行',
    level: 'A2',
    aiRole:
        'You are a local passer-by on the street. You speak in simple everyday English, give one direction at a time, and are happy to repeat.',
    userGoal: '问清怎么去一个地点，听懂转向与距离，并复述确认。',
    openingLine: 'Oh, hi! You look a bit lost — can I help you find something?',
    targetPhrases: [
      'Excuse me, how do I get to the train station?',
      'Is it within walking distance?',
      'Could you say that again more slowly?',
      'So I turn left at the second traffic light?',
      'Thanks so much for your help!',
    ],
    expectedTurns: 8,
    successCriteria:
        'The user asks for a destination, requests clarification at least once, and repeats the directions back to confirm.',
    branchHint: 'The direct road is closed; give an alternative route with one extra turn.',
    sortOrder: 13,
  ),
  Scenario(
    id: 'flight_rebook',
    titleZh: '航班改签',
    titleEn: 'Rebooking a Flight',
    category: '旅行',
    level: 'B1',
    aiRole:
        'You are an airline service agent. You stay calm, explain options clearly, and ask one question at a time.',
    userGoal: '说明航班被取消、比较 2 个备选、确认托运行李与差价，最后确认新航班号。',
    openingLine: "I'm sorry for the disruption. How can I help you rebook today?",
    targetPhrases: [
      'My flight to Shanghai was cancelled.',
      'What are my options for today?',
      'Is there an earlier one that still has a seat?',
      'Will my checked bag be transferred automatically?',
      'Is there any extra charge?',
    ],
    expectedTurns: 10,
    successCriteria:
        'The user explains the disruption, compares two options, confirms luggage and fees, and repeats the new flight details.',
    branchHint:
        'The first alternative is full; offer a later flight via a different city and ask if that works.',
    sortOrder: 14,
  ),
  // ── 社交 ────────────────────────────────────────────────────────────────
  Scenario(
    id: 'new_colleague',
    titleZh: '和新同事闲聊',
    titleEn: 'Small Talk with a New Colleague',
    category: '社交',
    level: 'B1',
    aiRole:
        'You are a new colleague who just joined the team. You are friendly, speak casually, and ask one open question at a time.',
    userGoal: '自我介绍、聊一小段共同话题、接话并反问，自然结束闲聊。',
    openingLine: "Hey, I don't think we've met — I'm Jamie, the new designer.",
    targetPhrases: [
      "Nice to meet you, I'm on the data team.",
      'How long have you been here?',
      'What are you working on at the moment?',
      "That sounds interesting — how did you get into that?",
      "Let's grab coffee sometime!",
    ],
    expectedTurns: 8,
    successCriteria:
        'The user introduces themselves, asks at least two open questions, responds to answers, and closes the chat naturally.',
    branchHint: 'Mention you are still looking for a good lunch spot and ask for a recommendation.',
    sortOrder: 15,
  ),
  Scenario(
    id: 'weekend_recap',
    titleZh: '聊聊周末',
    titleEn: 'Talking About the Weekend',
    category: '社交',
    level: 'B1',
    aiRole:
        'You are a friend catching up on Monday. You speak casually, show interest, and ask one follow-up question at a time.',
    userGoal: '讲一件周末的小事、回应对方的分享并反问，把闲聊维持 8 轮以上。',
    openingLine: 'Hey! How was your weekend? Did you get up to anything fun?',
    targetPhrases: [
      'It was pretty relaxed, to be honest.',
      'I finally tried that new noodle place.',
      'No way — what was it like?',
      'What about you, did you do anything?',
      'We should go together next time.',
    ],
    expectedTurns: 8,
    successCriteria:
        "The user shares a specific anecdote, reacts to the friend's story, and asks at least two follow-up questions.",
    branchHint:
        'Mention an unexpected small problem (rain, a closed shop) and see how the user keeps the conversation going.',
    sortOrder: 16,
  ),
  Scenario(
    id: 'party_icebreaker',
    titleZh: '聚会破冰',
    titleEn: 'Breaking the Ice at a Party',
    category: '社交',
    level: 'B1',
    aiRole:
        "You are a guest at a friend's party who does not know the user. You are warm but a little shy, and you answer in short turns.",
    userGoal: '主动搭话、找到一个共同点、把话题展开，并礼貌地结束去拿杯饮料。',
    openingLine: "Hi — I don't think we've met. I'm Alex, a friend of the host.",
    targetPhrases: [
      'Hi, mind if I join you?',
      'How do you know the host?',
      'Oh, we both work in the same area?',
      "That's funny — I had the same experience.",
      "It was nice talking to you; I'm going to grab a drink.",
    ],
    expectedTurns: 8,
    successCriteria:
        'The user starts a conversation with someone new, finds common ground, keeps it going, and closes politely.',
    branchHint: 'Give a very short answer once, so the user has to carry the conversation with a follow-up.',
    sortOrder: 17,
  ),
  Scenario(
    id: 'decline_invitation',
    titleZh: '婉拒邀请',
    titleEn: 'Politely Declining an Invitation',
    category: '社交',
    level: 'B1',
    aiRole:
        'You are a friend inviting the user to a dinner this weekend. You are easy-going, but you gently try one alternative before accepting the no.',
    userGoal: '感谢邀请、给出真实但简短的理由、提出替代方案，并保持关系不尴尬。',
    openingLine: 'Hey! A few of us are having dinner on Saturday — would you like to come?',
    targetPhrases: [
      'Thanks so much for thinking of me.',
      "I'd love to, but I already have plans that day.",
      'Could we do the following weekend instead?',
      "I'm free on Sunday if that's easier.",
      'Have a great time, and send me photos!',
    ],
    expectedTurns: 8,
    successCriteria:
        'The user thanks the inviter, declines with a brief reason, proposes a concrete alternative, and ends warmly.',
    branchHint: 'Suggest a different time once and ask again; let the user hold their boundary politely.',
    sortOrder: 18,
  ),
  // ── 健康 ────────────────────────────────────────────────────────────────
  Scenario(
    id: 'clinic_symptoms',
    titleZh: '门诊说症状',
    titleEn: 'Describing Symptoms at a Clinic',
    category: '健康',
    level: 'A2',
    aiRole:
        'You are a doctor at a walk-in clinic. You speak gently and simply, ask one question at a time, and never give a diagnosis in the first turn.',
    userGoal: '说清哪里不舒服、持续多久、有多严重、有无过敏，并听懂下一步安排。',
    openingLine: 'Hello, come in. What seems to be the problem today?',
    targetPhrases: [
      "I've had a sore throat since Monday.",
      'It hurts most when I swallow.',
      "It's not too bad, maybe a 4 out of 10.",
      "I'm allergic to penicillin.",
      'Should I take anything before the test results?',
    ],
    expectedTurns: 8,
    successCriteria:
        'The user describes the location, duration, severity, and allergy history, and confirms the next step.',
    branchHint: 'Ask about a symptom the user did not mention (fever or cough) and wait for the answer.',
    sortOrder: 19,
  ),
  Scenario(
    id: 'pharmacy',
    titleZh: '药店买药',
    titleEn: 'At the Pharmacy',
    category: '健康',
    level: 'A2',
    aiRole:
        'You are a pharmacist. You speak clearly, check understanding, and ask one question at a time.',
    userGoal: '说明需要什么、问清剂量与服用频次、确认是否会与现有药物冲突。',
    openingLine: 'Hi there, how can I help you today?',
    targetPhrases: [
      "I'm looking for something for a dry cough.",
      'Do I need a prescription for this?',
      'How often should I take it?',
      "I'm already taking an allergy medicine — is that okay?",
      'Could you write the dosage down for me?',
    ],
    expectedTurns: 8,
    successCriteria:
        'The user states the need, confirms dosage and frequency, checks an interaction, and asks for written instructions.',
    branchHint:
        'The first brand is out of stock; offer a generic equivalent and explain the difference briefly.',
    sortOrder: 20,
  ),
  Scenario(
    id: 'call_in_sick',
    titleZh: '电话请假',
    titleEn: 'Calling in Sick',
    category: '健康',
    level: 'B1',
    aiRole:
        "You are a team lead receiving a morning phone call. You are understanding but need to know what will happen to today's work.",
    userGoal: '说明身体状况、预计请假多久、交接今天的紧急事项，并确认沟通方式。',
    openingLine: "Morning! You're on my list for the 10 o'clock sync — everything okay?",
    targetPhrases: [
      "I'm afraid I need to take today off sick.",
      "I've had a fever since last night.",
      "I'll probably be back tomorrow.",
      "I've already handed the demo to Priya.",
      "I'll keep my phone on if anything urgent comes up.",
    ],
    expectedTurns: 8,
    successCriteria:
        'The user reports the illness, estimates the absence, hands over urgent work, and agrees on how to stay reachable.',
    branchHint: 'Mention one meeting that cannot be moved and ask the user for a suggestion.',
    sortOrder: 21,
  ),
  Scenario(
    id: 'emergency_help',
    titleZh: '突发状况求助',
    titleEn: 'Asking for Help in an Emergency',
    category: '健康',
    level: 'B1',
    aiRole:
        'You are a bystander who stops to help. You stay calm, ask for one concrete detail at a time, and confirm what you understood.',
    userGoal: '说清发生了什么和所在位置、请求一个具体帮助、确认对方已经理解并正在行动。',
    openingLine: 'Hey, are you okay? Do you need a hand?',
    targetPhrases: [
      "My friend has twisted her ankle and can't stand.",
      "We're right outside the subway exit on King Street.",
      'Could you call an ambulance, please?',
      'Could you stay with us until help arrives?',
      "So you've called them — how long did they say?",
    ],
    expectedTurns: 8,
    successCriteria:
        'The user states the problem and location, asks for a specific action, and confirms the helper understood and acted.',
    branchHint: 'Mishear the street name once and ask the user to repeat and spell it.',
    sortOrder: 22,
  ),
  // ── 观点 ────────────────────────────────────────────────────────────────
  Scenario(
    id: 'disagree_politely',
    titleZh: '表达不同意见',
    titleEn: 'Disagreeing Politely',
    category: '观点',
    level: 'B2',
    aiRole:
        'You are a colleague proposing a plan in a meeting. You are confident but reasonable, and you defend your idea once before listening.',
    userGoal: '先认同对方、再清楚表达不同意见、给出理由与替代方案，最后找到一个折中。',
    openingLine: 'I think we should ship the whole feature next month. What do you think?',
    targetPhrases: [
      "I see why that's attractive, but I have a concern.",
      "I'm not sure I agree with the timeline.",
      'The main reason is that we have no test coverage yet.',
      'What if we shipped the core flow first?',
      "That's a compromise I can work with.",
    ],
    expectedTurns: 10,
    successCriteria:
        'The user acknowledges the other view, states a disagreement with a reason, proposes an alternative, and reaches a compromise.',
    branchHint:
        'Defend the original plan once with a new argument, then invite the user to restate their proposal.',
    sortOrder: 23,
  ),
  Scenario(
    id: 'explain_topic',
    titleZh: '解释熟悉话题',
    titleEn: 'Explaining a Familiar Topic',
    category: '观点',
    level: 'B2',
    aiRole:
        "You are a curious friend who knows nothing about the user's hobby or job. You ask one genuine follow-up at a time and sometimes ask for an example.",
    userGoal: '用「先总述 → 分两点 → 举例 → 收尾」把一个熟悉话题讲清楚，并应对两轮追问。',
    openingLine: "You mentioned you're really into photography — what is it that you like about it?",
    targetPhrases: [
      'There are basically two reasons I got into it.',
      'The first one is that it makes me slow down and notice things.',
      'For example, last weekend I spent an hour on one street corner.',
      'Does that make sense, or should I go into more detail?',
      'So, in short, it is less about the gear and more about attention.',
    ],
    expectedTurns: 12,
    successCriteria:
        'The user gives a structured explanation with at least one example, handles two follow-ups, and summarizes at the end.',
    branchHint: 'Say you still do not understand one term and ask the user to explain it in simpler words.',
    sortOrder: 24,
  ),
  Scenario(
    id: 'mini_debate',
    titleZh: '小型辩论',
    titleEn: 'A Short Debate',
    category: '观点',
    level: 'B2',
    aiRole:
        'You are a debate partner arguing the opposite side. You are friendly but firm, make one point at a time, and concede fairly when the user makes a good point.',
    userGoal: '立论、回应反驳、做一次让步后重申立场，并给出一句收尾。',
    openingLine: "Here's my position: remote work is always better than office work. Convince me otherwise?",
    targetPhrases: [
      "I'd argue that it depends on the kind of work.",
      "That's fair, but it doesn't address the cost of commuting.",
      'Let me give you a concrete example.',
      "I'll concede that point about junior teammates.",
      'Even so, I still think a hybrid setup wins overall.',
    ],
    expectedTurns: 12,
    successCriteria:
        'The user states a clear position, answers at least two counterarguments, makes one concession, and restates their conclusion.',
    branchHint: 'Bring in a statistic the user has not mentioned and ask how they would respond to it.',
    sortOrder: 25,
  ),
];
