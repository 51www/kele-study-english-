# 里程碑清单（M15）：每日打卡 v0.1

- 文档状态：**已完成（代码 + 文档）**，走查与截图归档见 `.logs/milestone-15.md`
- 日期：2026-11-13
- 上游：需求 [requirements-speaking-app-v0.2.md](requirements-speaking-app-v0.2.md) F17；方案 [design-daily-checkin-v0.1.md](design-daily-checkin-v0.1.md)
- 里程碑编号：**M15**（沿用连续编号）
- 一句话目标：**把"长期学英语要靠输入→吸收→输出闭环"落成可持续的每日打卡记录——App 内活动自动判定、App 外学习手动补记，中性展示、不游戏化。**

---

## 1. 隔离原则（本轮硬约束）

1. **不改验收口径**：需求 §10.2 的 MVP 清单保持未勾选；M0–M14 验收标准不变。
2. **不动主链路**：不改底部 4 Tab、不改 `ConversationController` 主对话状态机、不改复盘主流程；打卡日历页挂 `ShellRoute` 外（路由 `/checkin`），首页今日卡插入首页顶部。
3. **最小改表**：新增 `daily_checkin` 用裸 SQL（`beforeOpen` 的 `CREATE TABLE IF NOT EXISTS`）建表，不注册到 Drift `tables`、不触碰 `.g.dart`、不跑 `build_runner`；`schemaVersion` 3→4；老表一律不 ALTER / 不 DROP / 不回填，覆盖安装零数据丢失；drift / web 双端 `LocalStore` 都实现打卡方法、`clearAll` 纳入新表。
4. **不游戏化**：不做连胜 / 勋章 / 排行榜 / 每日推送 / 分数等级；连续天数复用 F8 口径（有效练习 ∪ 手动补记，按自然日去重），日历只展示"哪天练了、练了什么"。
5. **不新增网络与依赖**：打卡全部本地聚合，断网 / 无密钥可记可看。
6. **一屏一个主色 CTA**：首页主色实心 CTA 归「下一步」卡；今日卡与日历的入口用次要按钮，避免第二个主色实心 CTA。
7. **文档与代码同批**：需求 F17、开发文档 §1.2/§4.1/§4.3/§6.3、UI 规范 §3.4、索引同一次改动完成。
8. **教材导入 UI 暂隐藏（非移除）**：移除教材库导入按钮与首页「听写教材」入口，底层代码 / 路由 `/materials`、`/materials/import`、数据全部保留，后续可恢复。

---

## 2. 任务

| # | 任务 | 模块 | 交付物 | 点数 |
|---|---|---|---|---|
| T15.1 | 数据层：每日打卡表与仓储 | `domain/models/checkin_models.dart`、`data/db/app_database.dart`（裸 SQL 建表）、`local_store.dart`/`drift_store.dart`/`web_store.dart`（双端实现 + `clearAll`）、`repositories.dart`（`CheckinRepository`） | `daily_checkin` 表 + 双端 CRUD + `CheckinRepository`（save/toggleType/setNote/manualDates） | 5 |
| T15.2 | Provider 聚合 | `app/providers.dart` | `checkinRepositoryProvider` / `todayCheckinProvider` / `checkinMonthProvider`；`homeDataProvider` 连续天数纳入手动补记（统一 `_computeStreaks`）；`streakDays` 口径不变 | 5 |
| T15.3 | 首页今日卡 + 三段式重组 | `features/checkin/checkin_card.dart`、`features/home/home_page.dart`、`features/history/history_page.dart` | `CheckinCard`（打卡状态 + 连续天数 + 学习构成 chip + 目标进度 + 入口）；首页收拢为「今日 → 下一步 → 统一练习入口」；卡在哪 / 继续 / 最近移入 `history` 页「接着练」区块 | 5 |
| T15.4 | 打卡日历页 | `features/checkin/checkin_calendar_page.dart`、`app/app.dart` | `/checkin`（ShellRoute 外）：7 列月历 + 当日明细 Sheet（自动活动只读 + 手动补记 FilterChip + 备注）+ 本月/当前/最长连续统计 | 4 |
| T15.5 | 教材导入 UI 暂隐藏 | `features/dictation/pages/material_library_page.dart`、`features/home/home_page.dart` | 移除教材库 AppBar 导入按钮、空态导入按钮、首页「听写教材」入口；底层代码 / 路由 / 数据保留 | 1 |
| T15.6 | 编译验证 | — | `flutter analyze` 0 error / 0 warning（仅既有 info） | 1 |

---

## 3. 交付物

首页「今日」主卡显示打卡状态、连续天数、当日学习构成与目标进度；点「查看打卡日历」进入 `/checkin` 月历，点亮已打卡天、看每日明细、统计连续；App 外学习可在首页或日历手动补记（背单词 / 影子跟读 / 其它），断网可记。原有会话、复盘、表达本、教材（UI 暂隐藏）、复练、密钥、设置与底部 4 Tab 完全不受影响。

---

## 4. 验收标准（逐条当场判定）

1. 首页今日卡显示今日打卡状态（已/待）、连续天数（含手动补记）、学习构成 chip（已做亮起、手动类型点按可补记）、今日分钟/目标进度、本周次数；未打卡给「开始今日学习」、已打卡给「查看打卡日历」。
2. `/checkin` 月历正确点亮有口语/轻量/听写/手动补记的天；点击某天弹出明细，自动活动只读、手动类型可勾选即时保存、备注可保存；顶部三块统计（本月打卡/当前连续/最长连续）与首页连续天数口径一致。
3. 手动补记断网可写可读；清空练习数据后 `daily_checkin` 一并清空，覆盖安装不残留、不崩。
4. 首页三段式：今日卡在最上，其次「下一步」主色 CTA，再次统一练习入口（场景练习/复盘复练/3 分钟轻量）；卡在哪/继续/最近只在 `history` 页「接着练」出现，首页不再重复。
5. 教材导入 UI 入口（AppBar 按钮、空态按钮、首页「听写教材」项）全部移除；`/materials`、`/materials/import` 路由与底层代码保留，可通过 URL/历史续练直达。
6. 无第二个主色实心 CTA；连续天数口径与 F8 一致（有效练习 ∪ 手动补记，按自然日去重）。
7. `flutter analyze` 0 error / 0 warning；Web release 与 Android debug 构建通过。
8. 截图归档 `docs/shortscreen/M15/`，文件名带序号；工作记录 `.logs/milestone-15.md`。

---

## 5. 风险点

| 风险 | 缓解 |
|---|---|
| 手动补记与自动活动重复统计连续天数 | 统一 `_computeStreaks`，按自然日去重；`DayCheckin.types` 用可变默认避免共享集合污染 |
| 新增表触发 build_runner 重生成 | `daily_checkin` 用裸 SQL 建表，不注册 Drift `tables`、不触碰 `.g.dart` |
| 覆盖安装丢失打卡数据 | 老表不 ALTER/DROP/回填；新表 IF NOT EXISTS 幂等 |
| 首页主色 CTA 多于一个 | 「下一步」卡占主色 CTA，今日卡与日历用次要按钮 |

---

## 6. 与现有文档的对应关系

| 改动 | 已同步 |
|---|---|
| 功能范围、优先级、验收 | 需求 F17、§2.2 优先级表 |
| 模块映射、表、迁移、页面树 | 开发文档 §1.2、§4.1、§4.3、§6.3 |
| 组件规格 | UI 设计规范 §3.4「每日打卡新增组件规格」 |
| 索引 | `AGENTS.md` §1 |

---

## 7. 实现状态

- 代码已完成并通过 `flutter analyze`（0 error / 0 warning，仅既有 info）、`flutter test`（79 项全通过，含 v4 迁移回归）、`flutter build apk --debug` 与 `flutter build web --release`。
- 真机走查完成（PKC110 / Android 17）：手动补记、连续天数、日历点亮、单日 Sheet、`toggleType` 即时保存全部通过；走查中修复首页练习入口卡片溢出（`childAspectRatio` 1.7 → 1.3）。
- 截图归档 `docs/shortscreen/M15/`（device-01 ~ device-07）；工作记录 `.logs/milestone-15.md`。
- 未复验：Web 端逐屏截图、清空数据端到端验证。
