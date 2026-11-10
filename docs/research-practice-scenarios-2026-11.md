# 练习场景库调研：同类产品的场景设计与 24 个新增场景

- 调研时间：2026-11-10
- 触发：用户先要求「结合同类产品，丰富场景。先调研」，随后把目标升级为「参考同类产品的练习场景设计，在现有基础上新增 10~30 个练习场景」。
- 范围：只研究「练习场景库怎么组织、单个场景长什么样、如何被发现」，不重新讨论语音链路、纠错时机或收费（见 `docs/research-speaking-apps-2026-11.md`）。
- 方法：优先官方页面（ELSA / TalkPal / Praktika / Speak / 可栗 / WeSpeak），第三方测评与导航站只作方向性证据，不作为精确数字。
- 证据标记：**【调研】** 有可查来源（文末 S#）；**【推理】** 基于调研结论与本产品现状的判断；**【待验证】** 合理假设但缺可靠来源。
- 本仓内部依据：`docs/requirements-speaking-app-v0.2.md` §2.2（12 个候选场景）、F1 场景库、`prototype/index.html`（分类 Chip + 场景横滑卡）、`lib/domain/models/models.dart`（`Scenario` 字段）、`lib/data/db/seeds.dart`（现有 2 个种子）。

---

## 0. 结论先行

1. **同类产品做的是「具体任务」，不是「大类课程」。** 一个场景 = 一个具体场合 + 一个对手角色 + 一个可判定完成的目标（团队会议里提问并确认分工、客户投诉后给补救方案、机场值机托运并问登机口），而不是「商务英语」这种大主题。【调研 S52/S53/S57】
2. **场景库靠「分类 + 可快速选择」承载数量。** ELSA 把预设话题按主题分类整理以便快速选择；TalkPal 分 everyday life / professional / entertaining dialogues；Speak 有「聊工作」专区近 40 个职场情境；可栗按行业与岗位组织。【调研 S51/S54/S55/S58/S60】
3. **每个场景的内容结构高度一致**：角色、用户目标、AI 开场白、3–5 条目标表达、8–12 个短回合、1–2 个「意外分支 / curveball」，先把表达给到用户再进入对话应用。【调研 S53/S57/S58 + `docs/research-speaking-apps-2026-11.md` §4.1】
4. **难度普遍挂 CEFR**：TalkPal A1–C2，Speak/ELSA/可栗按水平调整；WeSpeak 更进一步做「同一场景 4 个难度级别」。【调研 S61/S51】本产品把 `level` 存在场景上、AI 用词取全局水平设置，属于两套值，本次保持不改。
5. **发现与进度感**：ELSA 有「惊喜话题 / 自由话题 / 预设话题」三种入口，Praktika 练习页 1000+ 课；原型里已有「练过 N 次」标签，需求 F1 也要求「完成后标记练过」。【调研 S51/S15 + 原型 + 需求】
6. **常见短板是「内容重复 / 进阶天花板」**（Speak、ELSA、Praktika 的高频差评），因此数量不是目的：**场景要覆盖不同沟通动作，而不是把同一句点单换 20 个地点**。【调研 `docs/research-speaking-apps-2026-11.md` §4.4】【推理】
7. **落地结论**：在现有 2 个场景之上新增 **24 个**，合计 26 个；按 6 类组织（日常 / 工作 / 旅行 / 社交 / 健康 / 观点），新增独立「场景库」页承载分类 Chip、搜索与「练过 N 次」，首页仍只放 2 张推荐卡 +「全部 N 个」入口，守住首屏信息预算。【推理】

---

## 1. 同类产品的场景库设计

### 1.1 分类方式

| 产品 | 分类 / 组织方式 | 证据 |
|---|---|---|
| ELSA「Role-Play Lab」 | 预设话题按主题分类整理，方便快速选择；另有「惊喜话题」随机、「自由话题」自定义。预设含面试、庆祝活动、爱好讨论、自我介绍 | 【调研 S51】 |
| ELSA 场景库（第三方整理） | 日常生活（咖啡馆点单、问路、超市购物）/ 职场沟通（模拟面试、项目会议、产品演示）/ 旅行社交（预订酒店、登机、闲聊）/ 特殊挑战（客户投诉、礼貌拒绝、表达不同意见） | 【调研 S53，方向性证据】 |
| TalkPal | Roleplay 覆盖 everyday life、professional situations、entertaining dialogues；2026 年一次更新新增 100 个 real-life scenarios；另有 Call（纯音频、无视觉线索）、Debate、Dialogue（点餐、做计划、自我介绍、购物） | 【调研 S54/S55/S56】 |
| Praktika | 社交场合（自我介绍、问路、餐厅点单）与 7 个职场 role-play（会议、客户延迟交付等），练习页 1000+ 课按日常情境组织 | 【调研 S57，及 `docs/research-speaking-apps-2026-11.md` S15】 |
| Speak | 「聊工作」专区近 40 个职场角色扮演：面试、开会提意见、主管 1:1、客户提案跟进、跨部门协作；流程是「选情境 → 开口对话 → 每句即时回馈 → 对话后复习错误」 | 【调研 S58】 |
| 可栗口语 | 按行业与岗位组织内容（项目汇报、客户对接、会议主持、面试应答），「选场景 → 打基础 → 实战对话（目标导向通关）→ 进步追踪」；第三方称分日常 / 旅游 / 职场 / 学术 | 【调研 S60，方向性证据】 |
| 开言英语 | 生活、商务、留学、旅游主题课程（输入型，非 AI 对话） | 【调研 `docs/research-speaking-apps-2026-11.md` S41】 |
| WeSpeak | 100 个人工撰写的真实生活场景（点咖啡、酒店入住、给进度更新），每个场景可玩 4 个难度级别 | 【调研 S61】 |
| 本产品原型 | 「全部 / 日常 / 工作 / 旅行 / 社交」Chip + 场景横滑卡 +「N 个可练」计数 + 未开放卡片置灰 | `prototype/index.html:1127-1138, 1645-1653` |

**共识**：分类数量在 4–6 个，用 Chip 一行切换；分类名是「使用者会说的场合」，不是语法点或教材单元。【调研 + 推理】

### 1.2 单个场景的颗粒度与内容结构

- 颗粒度：一个可完成的沟通任务。Speak 的「团队会议」场景明确到「在会议里提出疑问、确认分工」；Praktika 的「客户投诉」场景明确到「不否认、不轻描淡写，24 小时内给书面方案」。【调研 S58/S57】
- 内容结构（与本产品 `Scenario` 字段的对应关系）：

| 竞品共性要素 | 本产品字段 | 现状 |
|---|---|---|
| AI 对手角色（咖啡师 / 面试官 / 客户） | `aiRole` | 已进 `chatSystem` |
| 用户目标 / 通关条件 | `userGoal` / `successCriteria` | 已进 `chatSystem` |
| AI 开场白 | `openingLine` | 已落为首条消息 |
| 3–5 条目标表达（先学再练） | `targetPhrases` | **只在详情页展示，未进 prompt**（本次补上） |
| 8–12 个短回合 | `expectedTurns` | 仅用于文案，不控制结束 |
| 1–2 个意外分支 / curveball | `branchHint` | 已进 `chatSystem` |
| CEFR 难度 | `level` | 场景标注；AI 用词取全局设置 |
| 分类 | `category` | **存了但 UI 未消费**（本次用于 Chip 与图标） |
| 练过次数 | 无字段，由 `session` 聚合 | **未实现**（本次加派生 provider） |

- 对话节奏的硬约束（沿用 `docs/research-speaking-apps-2026-11.md` §4.1 与 §4.6）：AI 每次 1–2 句 + 一个追问，不打断、不纠错、不跳角色。

### 1.3 发现机制与进度感

- 随机入口：ELSA「惊喜话题」开盲盒。【调研 S51】
- 自定义：ELSA 自由话题、TalkPal 自定义角色、ChatGPT 口头指定角色；本产品 F9 自定义场景是 P1，**本次不做**。【调研 S51 + 需求 §F9】
- 指定主题：Speak 通话可直接说「I have a job interview next week」让 AI 调整对话。【调研 S59】
- 练过标记：原型卡片 `${s.category} · ${s.level} · 练过 ${s.practiced} 次`；需求 F1 验收标准也写了「完成后标记练过，并记录次数」。【原型 + 需求 §F1】

> 【待验证】「随机来一个」对单人自用的留存价值没有可靠数据；本次只做分类 + 搜索 + 练过次数，不新增随机/自定义入口。【推理】

### 1.4 明确不照搬的部分

| 不照搬 | 理由 |
|---|---|
| 上千门课程 / 每周更新素材 | 个人自用不需要内容量；高频差评恰恰是「内容重复、进阶天花板」。【调研 + 推理】 |
| 同一场景 4 档难度（WeSpeak） | 需要多套话术与 prompt，性价比低；本产品已有全局 A2/B1/B2/C1 水平设置。【调研 S61 + 推理】 |
| 自定义场景、场景市场、惊喜话题 | 需求 F9 标 P1、§10.1 明确不做自定义场景 / 场景市场。【需求】 |
| 虚拟人 / 视频 / 打分 | 需求 §10.3 明确不做。【需求】 |
| 发音分维度反馈、发音分数 | 需求 §10.3 明确不做。【需求】 |

---

## 2. 本次场景集设计

### 2.1 分类

沿用原型已有 4 类并补 2 类，共 6 类 +「全部」Chip：

| 分类 | 覆盖的沟通动作 | 来源 |
|---|---|---|
| 日常 | 买、退、预约、寄件 | 需求 §2.2 #1/#6；ELSA 日常生活；TalkPal Dialogue |
| 工作 | 汇报、面试、1:1、投诉补救 | 需求 #2/#3/#5/#9；Speak「聊工作」；Praktika 职场 7 场景 |
| 旅行 | 值机、入住、问路、改签 | 需求 #4/#11；原型「机场值机」置灰卡；ELSA 旅行社交 |
| 社交 | 破冰、闲聊、接话、婉拒 | 需求 #8；原型「和新同事闲聊」置灰卡；Praktika 社交场景 |
| 健康 | 描述症状、买药、请假、急诊 | 需求 #7；TalkPal Roleplay「看医生」 |
| 观点 | 反驳、解释、辩论、协商 | 需求 #9/#10；TalkPal Debate；ELSA 特殊挑战 |

> 需求 §2.2 #12「自由聊（无场景）」不是场景数据，是模式，仍按 P2 不做；「突发状况求助」(#11) 由「航班改签」「客户投诉处理」「电话请假」三个场景的意外分支承接。【推理】

### 2.2 新增 24 个场景清单

`sortOrder` 从 2 递增到 25；`level` 只取 A2 / B1 / B2；`expectedTurns` 8 / 10 / 12（<=8 显示「约 5 分钟」，>8 显示「约 10 分钟」）；每个场景 5 条目标表达、1 个 `branchHint` 意外分支。

| # | id | 标题 / English | 分类 | 级别 | 回合 | 训练目标 | 竞品依据 |
|---|---|---|---|---|---|---|---|
| 1 | `restaurant_order` | 餐厅点餐 / Ordering at a Restaurant | 日常 | A2 | 8 | 订位、点菜、忌口、加菜、结账 | S53/S57 |
| 2 | `grocery_checkout` | 超市结账 / At the Checkout | 日常 | A2 | 8 | 找商品、问价、袋子、付款方式 | S53 |
| 3 | `return_exchange` | 退换商品 / Returning an Item | 日常 | B1 | 8 | 说明问题、出示小票、换货/退款 | S53/S54 |
| 4 | `post_office` | 邮局寄件 / At the Post Office | 日常 | A2 | 8 | 寄往哪里、普通/加急、称重、追踪 | S56（TalkPal Daily Life & Errands 邮局对话） |
| 5 | `phone_booking` | 打电话预约 / Booking by Phone | 日常 | B1 | 8 | 无视觉线索下确认日期、时间、姓名拼写 | 需求 #6；S56/S59（Call 模式） |
| 6 | `standup_update` | 每日站会 / Daily Standup | 工作 | B1 | 8 | 昨天/今天/阻塞，回应追问 | 需求 #3；S58 |
| 7 | `interview_intro` | 面试自我介绍 / Job Interview Intro | 工作 | B1 | 12 | 60 秒自我介绍 + STAR 式经历追问 | 需求 #5；S51/S52/S58 |
| 8 | `one_on_one` | 主管 1:1 / One-on-One with Your Manager | 工作 | B2 | 10 | 讲进展、要资源、接受反馈 | S58 |
| 9 | `client_complaint` | 客户投诉处理 / Handling a Client Complaint | 工作 | B2 | 10 | 先承认、给补救方案、约定回访时间 | S53/S57（curveball） |
| 10 | `airport_checkin` | 机场值机 / Airport Check-in | 旅行 | A2 | 8 | 办值机、托运行李、问登机口与时间 | 原型置灰卡；S53 |
| 11 | `hotel_checkin` | 酒店入住 / Hotel Check-in | 旅行 | A2 | 8 | 报预订、确认房型/早餐/退房时间 | 需求 #4；S53/S57 |
| 12 | `asking_directions` | 街头问路 / Asking for Directions | 旅行 | A2 | 8 | 问地点、听懂转向/距离、复述确认 | S53/S57 |
| 13 | `flight_rebook` | 航班改签 / Rebooking a Flight | 旅行 | B1 | 10 | 说明取消、比较备选、确认行李与费用 | 需求 #4/#11；S54 |
| 14 | `new_colleague` | 和新同事闲聊 / Small Talk with a New Colleague | 社交 | B1 | 8 | 自我介绍、开放式追问、接话 | 原型置灰卡；需求 #8；S57 |
| 15 | `weekend_recap` | 聊聊周末 / Talking About the Weekend | 社交 | B1 | 8 | 讲一件小事、回应并反问 | 需求 #8；S55 |
| 16 | `party_icebreaker` | 聚会破冰 / Breaking the Ice at a Party | 社交 | B1 | 8 | 主动搭话、找共同点、礼貌结束 | S57（社交场合自我介绍） |
| 17 | `decline_invitation` | 婉拒邀请 / Politely Declining an Invitation | 社交 | B1 | 8 | 感谢 + 理由 + 给替代方案 | S53（礼貌地拒绝请求） |
| 18 | `clinic_symptoms` | 门诊说症状 / Describing Symptoms at a Clinic | 健康 | A2 | 8 | 部位、时长、程度、过敏史 | 需求 #7；S56（看医生） |
| 19 | `pharmacy` | 药店买药 / At the Pharmacy | 健康 | A2 | 8 | 说需求、问剂量与频次、确认禁忌 | 需求 #7；S54 |
| 20 | `call_in_sick` | 电话请假 / Calling in Sick | 健康 | B1 | 8 | 说明状况、交接工作、确认时长 | S56（Call 模式）+ 需求 #11 |
| 21 | `emergency_help` | 突发状况求助 / Asking for Help in an Emergency | 健康 | B1 | 8 | 说清地点与问题、请求具体帮助、确认对方已理解 | 需求 #11；S57（curveball） |
| 22 | `disagree_politely` | 表达不同意见 / Disagreeing Politely | 观点 | B2 | 10 | 先认同再转折、给理由、提替代 | 需求 #9；S53 |
| 23 | `explain_topic` | 解释熟悉话题 / Explaining a Familiar Topic | 观点 | B2 | 12 | 总—分—总、举例、被追问时补细节 | 需求 #10；S55（Debate/Dialogue） |
| 24 | `mini_debate` | 小型辩论 / A Short Debate | 观点 | B2 | 12 | 立论、反驳、让步后重申立场 | S56（Debate 模式） |

**分布（新增 24 个）**：日常 5 / 工作 4 / 旅行 4 / 社交 4 / 健康 4 / 观点 3；A2 8 个、B1 11 个、B2 5 个；8 回合 17 个、10 回合 4 个、12 回合 3 个。加上原有 2 个（日常 A2 / 工作 B1），共 **26 个场景**；全库分布为 A2 9 / B1 12 / B2 5，日常 6 / 工作 5 / 旅行 4 / 社交 4 / 健康 4 / 观点 3。【推理】

### 2.3 内容写法约定（写进 `seeds.dart`）

- `aiRole`：英文，固定「你是谁 + 说话风格 + 每次只问一个问题」，与 `chatSystem` 的 Rules 不冲突。
- `userGoal`：中文一句话，写「要完成什么」，不写「要学什么语法」。
- `openingLine`：AI 第一句必须是能接的自然口语，不解释规则、不做教学。
- `targetPhrases`：5 条真实高频表达，覆盖该场景的关键动作；本次把它们追加进 `chatSystem` 作为「自然引导但不强塞」的参考。
- `successCriteria`：可观察的完成条件（说出 X、确认 Y、达成一致 Z），供 AI 收口。
- `branchHint`：1 个意外分支（缺货、改期、听不清、客户二次发难、路线变更等），承接竞品的 curveball 设计。【调研 S57】

---

## 3. 落地改动面与验收

### 3.1 最小改动面

| 类别 | 文件 | 改动 |
|---|---|---|
| 数据 | `lib/data/db/seeds.dart` | `builtinScenarios` 追加 24 个常量；启动按 id 幂等 upsert，老用户下次启动自动获得，不需迁移 |
| 新页面 | `lib/features/scenario/scenario_library_page.dart` | `/scenarios`：分类 Chip + 搜索 + 场景列表 +「练过 N 次」 |
| 新组件 | `lib/features/scenario/scenario_visual.dart` | 分类 → 图标 / 浅底 / 强调色映射，替换 3 处 `id.contains('cafe')` |
| 路由 | `lib/app/app.dart` | 新增 `/scenarios` |
| Provider | `lib/app/providers.dart` | 新增 `scenarioLibraryProvider`（场景 + 按 `scenarioId` 聚合练过次数） |
| 首页 | `lib/features/home/home_page.dart` | 「场景练习」右侧改「全部 N 个」→ `/scenarios`；图标改用分类映射；仍只展示 2 张推荐卡 |
| 详情页 | `lib/features/scenario/scenario_page.dart` | Hero 图标按分类；标题行补分类 |
| 记录页 | `lib/features/history/history_page.dart` | 图标按分类 |
| Prompt | `lib/services/llm/prompt_builder.dart` | `chatSystem` 追加 `Target phrases` 行（自然引导，不强制逐句checklist） |
| 刷新 | `chat_page.dart` / `data_settings_page.dart` | 会话结束、清空数据后 invalidate `scenarioLibraryProvider` |
| 注释 | `repositories.dart` | 「2 个内置场景」→「全部内置场景」 |

**不需要改**：`Scenario` 模型、Drift 表 / `.g.dart`、`schemaVersion` / 迁移、`LocalStore` 接口与 SQL、`WebStore`、现有 2 个场景的 id、底部导航、设置项与配置项。

### 3.2 验收口径（本次新增，不替代需求 §10.2 的 11 条清单）

1. 启动后场景库显示 26 个场景，6 个分类 Chip 均可切换，计数与筛选结果一致。
2. 搜索中文标题 / 英文标题能命中；无结果时显示空态，不报错。
3. 首页仍只有 2 张推荐卡，点「全部 26 个」一次进入场景库；从场景库到场景详情一次点击。
4. 每个新场景都能打开详情、开始练习、进入对话页；AI 开场白与角色一致。
5. 完成一次对话后，场景库卡片显示「练过 1 次」；「清空所有数据」后计数归零、26 个场景仍在。
6. 老设备覆盖安装（不清数据）后，下次启动自动出现新场景；已有记录、表达本的 `scenario_id` 引用不变。
7. `flutter analyze` 无 error / warning；Android 真机安装无 `FlutterError` / `overflowed`。

> 逐条真机验证结果见 `docs/milestones-speaking-app-v0.1.md` §12.5；需真实 API 或会清空本机数据的项目保持待验收。

---

## 4. 未核实与局限

- ELSA 场景库的四分法、可栗的「按行业与岗位」细目，主要来自第三方导航/测评页，带推广属性，只作**方向性证据**；官方页面能确认的是「预设话题按主题分类」「Role-Play Lab 三种入口」。【调研 S51/S53/S60】
- TalkPal「一次新增 100 个 real-life scenarios」是官方新闻稿口径，未核实其完整场景清单与分类名。【调研 S54】
- Praktika「1000+ 课」来自第三方 100 小时实测文章，不是官方数字。【`docs/research-speaking-apps-2026-11.md` S15】
- 各产品「单个场景是否都含 5 条目标表达 / 意外分支」未逐个核实；本产品的字段结构以自身需求 §F1 与市场调研 §4.1 为准。
- 本次只做静态场景内容 + 浏览 UI，不做场景效果评测（哪个场景更容易卡住、练几次算掌握）；缺数据前不推断「场景越多越好」。【推理】
- 需求 §10.1 原来把场景限定为「2 个内置场景」，本次由用户明确要求扩容到 26 个；需求文档需同步记录该范围变更，MVP 验收清单 §10.2 保持未勾选。

---

## 5. 来源

### 本次新增（S51–S61）

- [S51] ELSA 台湾官方：2026 更新 / Role-Play Lab 三种话题入口、预设话题分类、课后反馈：https://tw.elsaspeak.com/hot-promotion/nova-4551/
- [S52] ELSA 官方：ELSA Professional / Interview Coach 与职场情境：https://tw.elsaspeak.com/?p=16719
- [S53] 第三方导航站（方向性证据）：ELSA 场景库四类划分、退货/预约/问路/客户投诉等细目：https://engsoeasy.com/sites/elsaspeak.html
- [S54] TalkPal 官方新闻稿：新增 100 个 real-life scenarios：https://talkpal.ai/de/press-releases/talkpal-ai-announces-major-content-update-to-expand-interactive-roleplays-feature/
- [S55] TalkPal 官方 Roleplays 页：everyday life / professional situations / entertaining dialogues：https://talkpal.ai/roleplays
- [S56] TalkPal 官方帮助：Chat / Call / Roleplay / Debate / Dialogue 模式；以及 Daily Life & Errands 邮局对话：https://talkpal.ai/support/which-learning-modes-are-available-on-talkpal/ 、https://podcast.talkpal.ai/episodes/ep-2-daily-life-errands/transcript
- [S57] Praktika 官方：社交场景（自我介绍、问路、餐厅点单）与 7 个职场 role-play / curveball：https://praktika.ai/ja/ai%e3%81%a7%e8%8b%b1%e8%aa%9e%e3%82%92%e5%ad%a6%e3%81%b6%ef%bc%9a%e6%b5%b7%e5%a4%96%e3%81%a7%e7%a4%be%e4%ba%a4%e3%81%ae%e5%a0%b4%e3%81%ab%e6%ba%b6%e3%81%91%e8%be%bc%e3%82%80/ 、https://praktika.ai/blog/it/role-play-inglese-lavoro-praktika
- [S58] Speak 官方：「聊工作」专区近 40 个职场情境、选情境→对话→回馈→复习流程：https://www.speak.com/blog-tw/business-english-speaking-guide
- [S59] Speak 官方：AI 家教通话可指定练习主题、中文求助、字幕：https://speak.com/blog-tw/speak-ai-tutor-call
- [S60] 可栗口语官网：按行业与岗位组织场景、目标导向通关；第三方细目（方向性证据）：http://www.oral-craft.com/ 、https://openi.cn/286218.html
- [S61] WeSpeak：100 个人工撰写场景、每个场景 4 个难度级别：https://www.wespeak.now/

### 仓内既有依据

- `docs/research-speaking-apps-2026-11.md`（S1–S50，尤其 §4.1 场景比开放话题更容易开口、§4.4 内容重复/天花板差评、§4.6 回合制）
- `docs/requirements-speaking-app-v0.2.md` §2.2、F1、§10.1、§10.2、§10.3、F9
- `docs/UI 设计规范.md` §1.5 Chip / 搜索 / 列表卡、§3.4 组件规格
- `prototype/index.html` home 场景选择区与 `SCENES` 数据
