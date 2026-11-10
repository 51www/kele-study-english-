# 开发文档：英语口语练习 App v0.1

- 文档状态：实施说明初稿
- 日期：2026-11-10
- 面向：实际编码阶段（本文只给结构与约定，**不含业务实现代码**）
- 上游文档：
  - 需求：[requirements-speaking-app-v0.2.md](requirements-speaking-app-v0.2.md)
  - 技术设计：[tech-design-speaking-app-v0.1.md](tech-design-speaking-app-v0.1.md)
  - 视觉：[UI 设计规范.md](UI%20设计规范.md)
  - 交互：[prototype/index.html](../prototype/index.html)
- 下游文档：里程碑清单 [milestones-speaking-app-v0.1.md](milestones-speaking-app-v0.1.md)（本文的模块名与里程碑任务一一对应）
- 冲突处理：**技术设计与本文件冲突时以技术设计为准**；视觉冲突以 UI 设计规范的 Token 为准；交互流程以原型为准，原型未覆盖处按需求文档。

---

## 0. 阅读顺序与术语

| 术语 | 含义 | 落地位置 |
|---|---|---|
| Page | 一个路由页面 | `features/<name>/<name>_page.dart` |
| Widget（组件） | 页面内可复用单元 | `app/widgets/` 或 `features/<name>/widgets/` |
| Service | 与外部世界交互的能力封装（网络/音频/存储） | `services/` |
| Repository | 对本地数据的读写门面 | `data/repositories/` |
| UseCase | 一次业务动作的编排 | `domain/usecases/` |
| Controller | 页面级状态机（Riverpod Notifier） | `features/<name>/<name>_controller.dart` |
| 回合 | 用户说一次 + AI 回一次 | 见 §3 |

**分层铁律**

1. `features` 不得直接依赖 `dio`、`drift`、`record`、`just_audio` 的类型。
2. `services` 不得依赖 `BuildContext`、不得弹 SnackBar、不得跳路由。
3. `domain/usecases` 只依赖接口与领域模型，不依赖具体实现。
4. 异常只能在 Controller 边界被转成 UI 状态，不允许冒泡到 Widget。

---

## 1. 工程结构

### 1.1 目录树

```text
lib/
  main.dart                        # runApp(ProviderScope(child: App()))
  app/
    app.dart                       # MaterialApp.router + 全局错误边界
    router.dart                    # go_router 路由表
    shell.dart                     # AppShell：承载 4 个 Tab
    theme/
      app_colors.dart              # 对应 UI 规范 §3.1
      app_text.dart                # 对应 §3.2
      app_metrics.dart             # 间距/圆角/阴影/布局常量 §3.3 §3.5
      app_theme.dart               # ThemeData + ThemeExtension<AppPalette>
    widgets/                       # 跨页通用组件（见 §6.3）
      gradient_scaffold.dart
      white_panel.dart
      app_button.dart
      app_card.dart
      app_chip.dart
      app_tag.dart
      app_field.dart
      segmented_control.dart
      app_switch_row.dart
      floating_tabbar.dart
      app_bottom_sheet.dart
      app_toast.dart
      empty_state.dart
      error_banner.dart
  core/
    result.dart                    # Result<T> / Failure
    errors.dart                    # AppError 枚举 + 分类
    logger.dart                    # 脱敏日志
    formatters.dart                # 时长、日期、百分比
    debouncer.dart
  data/
    db/
      app_database.dart            # Drift 数据库 + schemaVersion + 迁移
      tables/                      # 7 张表定义
      daos/                        # scenario_dao / session_dao / message_dao ...
    repositories/
      scenario_repository.dart
      session_repository.dart
      phrase_repository.dart
      settings_repository.dart
      llm_profile_repository.dart
    secure/
      key_store.dart               # flutter_secure_storage 封装
  domain/
    models/                        # 领域模型（与表解耦的只读对象）
    usecases/
      start_session.dart
      submit_turn.dart
      request_hint.dart
      translate_message.dart
      end_session.dart
      save_phrase.dart
  services/
    llm/
      llm_client.dart              # 抽象
      openai_compatible_client.dart
      sse_parser.dart
      llm_error_mapper.dart
    asr/
      asr_engine.dart
      system_asr_engine.dart
      http_asr_engine.dart
      chat_audio_asr_engine.dart
      asr_audio_io.dart / asr_audio_web.dart
      whisper_asr_engine.dart
    tts/
      tts_engine.dart
      tts_router.dart
      edge_tts_engine.dart
      system_tts_engine.dart
      tts_cache.dart
    audio/
      audio_session_manager.dart
      audio_recorder.dart
      audio_player.dart
    prompt/
      prompt_builder.dart
      prompt_templates.dart
    review/
      review_service.dart
  features/
    home/            home_page.dart / home_controller.dart / widgets/
    scenario/        scenario_page.dart / widgets/
    conversation/    conversation_page.dart / conversation_controller.dart / widgets/
    review/          review_page.dart / review_controller.dart / widgets/
    history/         history_page.dart / session_detail_page.dart / widgets/
    phrasebook/      phrasebook_page.dart / widgets/
    settings/        settings_page.dart / widgets/
    profile/         model_profile_page.dart / model_profile_controller.dart
```

### 1.2 模块 ↔ 需求功能映射

| 需求功能 | 主要模块 | 次要模块 | 里程碑 |
|---|---|---|---|
| F0 模型配置与自检 | `features/profile`、`features/settings` | `llm`、`data/secure`、`llm_profile` 表 | M0 |
| F1 场景库 | `features/scenario`、`features/home` | `scenario` 表、`ScenarioRepository` | M0 / M4 |
| F2 语音对话回合 | `features/conversation` | `audio`、`asr`、`llm`、`tts` | M1 / M2 |
| F3 翻译开关 | `features/conversation` | `usecases/translate_message`、`llm` | M4（状态骨架 M1 起） |
| F4 分级提示 | `features/conversation` | `usecases/request_hint`、`prompt` | M4 |
| F5 纠错与复盘 | `features/review` | `review`、`correction` 表 | M3 |
| F6 记录与表达本 | `features/history`、`features/phrasebook` | `session`/`message`/`phrase` 表 | M3 |
| F7 设置 | `features/settings` | `SettingsRepository` | M0 起增量 |
| F8 坚持机制（极简） | `features/home` | `session` 聚合查询 | M3 |
| F9 自定义场景（P1） | `features/scenario` | `scenario` 表 | 二期后 |
| F10 发音反馈（P2） | — | — | 不做 |

### 1.3 模块边界

| 模块 | 可以做 | 不可以做 |
|---|---|---|
| `features/*` | 读 Provider、渲染、把用户意图交给 Controller | 发网络请求、读写数据库、操作音频设备 |
| `domain/usecases` | 编排多个 service/repository、决定流程与降级 | 持有 Widget、直接读 `BuildContext` |
| `services/*` | 协议、超时、重试、错误归一、缓存 | 决定 UI 文案、写业务表 |
| `data/*` | SQL、迁移、事务、类型映射 | 发网络、决定业务规则 |

---

## 2. 模块职责与依赖

### 2.1 依赖方向

```text
features ──▶ domain/usecases ──▶ services（接口）
   │                │                ▲
   │                └──▶ data/repositories ──▶ data/db
   └────────────────────────────────────────────┘
                  （只读 Provider 注入，不反向引用）
```

- 允许 `features` 直接使用 `data/repositories` 做只读列表查询；**写入与多步操作一律走 UseCase**。
- `services` 之间不互相调用；编排在 UseCase 里做。

### 2.2 关键类清单

| 类 | 层 | 职责 | 依赖 | 关键状态 |
|---|---|---|---|---|
| `AppShell` | app | 底部 4 Tab 与悬浮导航 | router | 当前 Tab |
| `AppPalette`（ThemeExtension） | app | 承载 Material 未覆盖的色（tint/wash/辅助色） | — | 无状态 |
| `LlmClient`（抽象） | service | 一次对话请求：消息数组 → 文本流/文本 | — | 无状态，可取消 |
| `OpenAiCompatibleClient` | service | HTTP/SSE、鉴权头、超时、重试、错误归一 | `dio`、`SseParser` | `CancelToken` |
| `SseParser` | service | 按行解析 `data:`，过滤心跳、空 delta、未知字段 | — | 单次流状态 |
| `LlmErrorMapper` | service | HTTP 码/响应体 → `AppError` 四分类 | — | 无状态 |
| `PromptBuilder` | service | 场景 + 水平 + 最近 N 轮 + 约束 → 消息数组 | `prompt_templates` | 无状态 |
| `AsrEngine`（抽象） | service | 音频 → 文本 / 流式结果 | — | 会话级 |
| `SystemAsrEngine` | service | 调系统识别，处理权限、空结果、超时 | `speech_to_text` | 监听句柄 |
| `WhisperAsrEngine` | service | 端侧识别（P1 开关） | `whisper_ggml` | 模型加载态 |
| `TtsEngine`（抽象） | service | 文本+音色+语速 → 音频文件/句柄 | — | 可取消 |
| `EdgeTtsEngine` | service | WSS 合成、SSML、分帧拼接 | `web_socket_channel` | 连接态、熔断计数 |
| `SystemTtsEngine` | service | 系统朗读兜底 | `flutter_tts` | 播放句柄 |
| `TtsRouter` | service | 选引擎、失败切换、全局熔断 | 两个 Engine + `TtsCache` | 熔断计数、当前引擎 |
| `TtsCache` | service | 键生成、命中、写入、LRU | `path_provider`、`tts_cache` 表 | 缓存目录 |
| `AudioSessionManager` | service | 音频焦点/路由配置与监听 | `audio_session` | 焦点状态 |
| `AudioRecorder` | service | 按住录音、权限、PCM16 16k、取消 | `record` | 录音句柄 |
| `AudioPlayer` | service | 播放/停止/重听/变速 | `just_audio` | 播放器实例 |
| `ConversationController` | feature | 回合状态机、取消、降级、计时 | 上述 service + UseCases | 状态枚举 + 消息列表 |
| `SubmitTurn` | usecase | 识别结果 → 落库 → 请求 → 流式回调 → 落库 | `LlmClient`、`SessionRepository` | 无状态 |
| `ReviewService` | service | 会话 → 结构化复盘（容错解析） | `LlmClient`、`PromptBuilder` | 无状态 |

### 2.3 依赖注入

- 全部通过 Riverpod Provider 暴露：`llmClientProvider`、`asrEngineProvider`、`ttsRouterProvider`、`databaseProvider`、`settingsProvider`。
- 测试/离线调试时在这些 Provider 上覆写 Fake，不改业务代码。
- `ConversationController` 依赖的是接口，不是具体实现；切 Whisper 或切系统 TTS 只改 Provider 配置。

---

## 3. 核心数据流：一轮对话

### 3.1 时序（分层标注）

| # | 步骤 | 执行层 | 说明 |
|---|---|---|---|
| 1 | 用户按下麦克风 | UI `MicButton` | 手势 down，禁用其他入口 |
| 2 | 检查权限与音频焦点 | `ConversationController` → `AudioSessionManager` | 权限缺失直接进 `permissionDenied` 状态 |
| 3 | 停播当前音频 | `AudioPlayer.stop()` | 按下即停，属于手动打断 |
| 4 | 开始录音 | `AudioRecorder.start()` | 16 kHz / 单声道 / PCM16；最长 30s |
| 5 | 松手 | UI → Controller | 少于 0.4s 视为误触，回 Idle |
| 6 | 结束录音 | `AudioRecorder.stop()` → `AsrEngine` | 系统识别直接返回 final；Whisper 走文件 |
| 7 | 识别结果 | `SystemAsrEngine` | 空结果 → `emptyTranscript`，保留录音可重试 1 次 |
| 8 | 用户消息落库 | `SessionRepository.appendMessage()` | 事务开始 |
| 9 | 组装上下文 | `PromptBuilder` | 场景卡 + 水平 + 最近 6 轮 + 本回合用户文本 |
| 10 | 请求模型（流式） | `LlmClient.stream()` | 6s 无首字 → 转非流式 |
| 11 | 增量文本 | `SseParser` → Controller | 更新 AI 气泡，`isStreaming=true` |
| 12 | 句末切分 | Controller | 遇 `. ? !` 且 ≥8 字符 → 入 TTS 队列 |
| 13 | 合成并播放 | `TtsRouter` → `EdgeTtsEngine` → `AudioPlayer` | 首句就绪即播，不等全文 |
| 14 | 流结束 | `OpenAiCompatibleClient` | 拼接完整文本 |
| 15 | AI 消息落库 + 计数 | `SessionRepository.completeTurn()` | 与第 8 步同一会话事务边界内提交 |
| 16 | 延迟埋点 | Controller | 记录 `latency_ms`（松手 → 首音） |
| 17 | 回 Idle | Controller | 允许下一回合 |

**事务边界**：第 8 步先写"用户消息 + session 计数"，第 15 步在流结束后补写"AI 消息 + 回合数"。若第 10–14 步失败，用户消息仍保留，AI 消息以 `failed` 标记补一条（便于复盘时看到"这回合没答上来"）。

### 3.2 各层职责边界

| 关注点 | 归属 | 说明 |
|---|---|---|
| 录音权限、设备 | `services/audio` | UI 只展示状态 |
| 识别质量兜底 | `services/asr` | 空结果/超时归一为 `AppError` |
| 协议与流式解析 | `services/llm` | UI 只收到 `Stream<String>` |
| 切句与播放编排 | `features/conversation` | 属于体验策略，不进 service |
| 落库与统计 | `data/repositories` | 事务在这里 |
| 错误文案 | `features/*` | service 只给错误类型，不给中文文案 |

### 3.3 异常向上传递

```text
dio / plugin 异常
   → Service 捕获并归一为 AppError{kind, retryable, detail}
   → UseCase 决定：重试 / 降级 / 直接失败
   → Controller 转成页面状态（ErrorState{kind, action}）
   → UI 渲染 ErrorBanner / 底部提示 + 可执行按钮
```

**错误四分类**（与需求 §7.3 一致）

| kind | 触发 | retryable | UI 动作 |
|---|---|---|---|
| `auth` | 401 / 403 | 否 | "去设置检查 Key" |
| `notFound` | 404 / 模型不存在 | 否 | "检查接口地址或模型名" |
| `rateLimited` | 429 | 是（3s 后 1 次） | "稍等，正在重试" |
| `server` | 5xx / 超时 / 断网 | 是（退避 2 次） | "重试本回合" |

**禁止**：把 `Exception.toString()` 直接展示给用户；把 stack trace 写进普通日志。

### 3.4 两条旁路

| 旁路 | 触发 | 走哪层 | 是否进对话历史 |
|---|---|---|---|
| 翻译 | 点按 AI 气泡 / 常开字幕 | `TranslateMessage` → `LlmClient`（非流式、独立 prompt） | 否 |
| 提示 L1 | 点"重听" | `AudioPlayer` / `TtsRouter` | 否 |
| 提示 L2–L4 | 点提示项 | `RequestHint` → `LlmClient`（独立 prompt） | 否 |

旁路结果写入 `message.text_zh`（翻译）或页面内存（提示），会话结束后提示不落库（除非用户收藏）。

---

## 4. 数据模型与表清单

### 4.1 表总览

| 表 | 用途 | 写入方 | 读取方 |
|---|---|---|---|
| `scenario` | 场景内容（内置 + P1 自定义） | 首次启动种子 / 编辑页 | 首页、场景页、PromptBuilder |
| `session` | 一次会话 | `SessionRepository` | 首页统计、记录页、复盘 |
| `message` | 会话内消息 | `SessionRepository` | 对话页、记录详情、复盘 |
| `correction` | 纠错条目 | `ReviewService` 落库 | 复盘页、记录详情 |
| `phrase` | 表达本 | `PhraseRepository` | 表达本页、首页"上次卡住" |
| `llm_profile` | 接口配置（不含 Key 明文） | `LlmProfileRepository` | 设置页、LlmClient |
| `setting` | 键值设置 | `SettingsRepository` | 全局 |
| `tts_cache` | 语音缓存索引 | `TtsCache` | TtsRouter、设置页清理 |
| `app_meta` | 版本、熔断到期等 | 各模块 | 启动流程 |

### 4.2 字段清单

**scenario**

| 字段 | 类型 | 可空 | 说明 |
|---|---|---|---|
| id | TEXT PK | 否 | `cafe_order` / `meeting_clarify` |
| title_zh / title_en | TEXT | 否 | 显示名 |
| category | TEXT | 否 | 日常/工作/旅行/社交（首页 Chip 用） |
| level | TEXT | 否 | A2/B1/B2 |
| ai_role | TEXT | 否 | 英文角色描述，进 prompt |
| user_goal | TEXT | 否 | 用户目标 |
| opening_line | TEXT | 否 | AI 开场白 |
| target_phrases | TEXT(JSON) | 否 | 5 条目标表达 |
| expected_turns | INTEGER | 否 | 8–12 |
| success_criteria | TEXT | 否 | 进 prompt |
| branch_hint | TEXT | 是 | 1–2 个意外分支 |
| is_builtin | INTEGER | 否 | 1/0 |
| sort_order | INTEGER | 否 | 首页排序 |

**session**

| 字段 | 类型 | 可空 | 说明 |
|---|---|---|---|
| id | TEXT PK | 否 | UUID |
| scenario_id | TEXT FK | 是 | 可为空 |
| started_at / ended_at | INTEGER | 否/是 | 毫秒 |
| duration_sec | INTEGER | 否 | 默认 0 |
| turn_count / hint_count / assist_turns / translate_count | INTEGER | 否 | 默认 0 |
| status | TEXT | 否 | `draft`/`completed`/`aborted` |
| model_name / tts_engine | TEXT | 是 | 记录本次环境 |
| review_json | TEXT | 是 | 结构化复盘 |
| cost_estimate | REAL | 是 | 本地估算 |

**message**

| 字段 | 类型 | 可空 | 说明 |
|---|---|---|---|
| id | TEXT PK | 否 | UUID |
| session_id | TEXT FK | 否 | 级联删除 |
| seq | INTEGER | 否 | 会话内递增 |
| role | TEXT | 否 | `user`/`assistant` |
| text_en | TEXT | 否 | 转写/原文 |
| text_zh | TEXT | 是 | 翻译缓存 |
| audio_path | TEXT | 是 | 朗读缓存路径 |
| asr_provider | TEXT | 是 | `system`/`whisper`/`typed` |
| latency_ms | INTEGER | 是 | 松手→首音 |
| is_hint / hint_level | INTEGER | 否/是 | 提示来源 |
| status | TEXT | 否 | `ok`/`failed`（AI 失败占位） |
| created_at | INTEGER | 否 | — |

**correction**

| 字段 | 类型 | 可空 | 说明 |
|---|---|---|---|
| id / session_id / message_id | TEXT | 否 | — |
| original / improved | TEXT | 否 | 原句/改进句 |
| reason_zh | TEXT | 否 | ≤25 字 |
| audio_path | TEXT | 是 | 改进句音频 |
| is_deleted | INTEGER | 否 | 软删 |
| created_at | INTEGER | 否 | — |

**phrase**

| 字段 | 类型 | 可空 | 说明 |
|---|---|---|---|
| id / text_en | TEXT | 否 | — |
| text_zh | TEXT | 是 | — |
| source_session_id / source_scenario_id | TEXT | 是 | 来源 |
| audio_path | TEXT | 是 | — |
| mastered | INTEGER | 否 | P1 |
| created_at | INTEGER | 否 | — |

**llm_profile**

| 字段 | 类型 | 可空 | 说明 |
|---|---|---|---|
| id | TEXT PK | 否 | UUID |
| name | TEXT | 否 | 显示名 |
| base_url / model | TEXT | 否 | 规范化后 |
| key_ref | TEXT | 否 | **安全存储键名**，非密钥 |
| extra_json | TEXT | 是 | 预留 |
| last_check_status / last_check_message / last_checked_at | TEXT/TEXT/INTEGER | 是 | 三态 |
| is_active | INTEGER | 否 | 1 |

**setting**

| key | value 类型 | 默认 |
|---|---|---|
| `tts.engine` | string | `edge` |
| `tts.voice` | string | `en-US-AriaNeural` |
| `tts.rate` | double | `1.0` |
| `tts.autoPlay` | bool | `true` |
| `practice.level` | string | `B1` |
| `practice.correctionMode` | string | `gentle` |
| `practice.translateDefault` | string | `off` |
| `practice.inputMode` | string | `voice` |
| `practice.targetMinutes` | int | `10` |
| `data.cacheLimitMb` | int | `80` |

### 4.3 索引与迁移

- 索引：`message(session_id, seq)` 唯一；`session(started_at)`；`phrase(created_at)`；`tts_cache(last_used_at)`。
- 外键：`message.session_id`、`correction.session_id` 级联删除。
- `schemaVersion = 1`；每次结构变更必须提供迁移，禁止 `destructiveMigration`。
- 种子数据：首次启动插入 2 个内置场景（幂等：按 `id` upsert）。

---

## 5. 配置项清单

| 配置 | 存储 | 默认值 | 校验 | 失败表现 |
|---|---|---|---|---|
| `base_url` | `llm_profile.base_url` | 空 | 必填；`http(s)://` 开头；去尾部 `/`；无 `/v1` 时提示但不阻断 | 保存禁用 + 字段级错误 |
| `api_key` | SecureStorage(`llm_key_<id>`) | 空 | 必填；非空即可（不校验格式）；只显示尾 4 位 | 保存禁用；不回显 |
| `model` | `llm_profile.model` | 空 | 必填；可手填；`/models` 成功后给下拉候选 | 保存禁用 |
| 连接状态 | `last_check_status` | `never` | `ok`/`failed`/`never` 三态 | 首页黄条/红条 |
| `tts.engine` | setting | `edge` | 枚举 `edge`/`system` | 非法值回落 `edge` |
| `tts.voice` | setting | `en-US-AriaNeural` | 必须在该引擎音色表中；否则用引擎默认 | 静默回落 + 设置页提示 |
| `tts.rate` | setting | `1.0` | 0.7–1.3，步进 0.05 | 越界钳制 |
| `tts.autoPlay` | setting | `true` | bool | — |
| `practice.level` | setting | `B1` | A2/B1/B2 | 回落 B1 |
| `practice.correctionMode` | setting | `gentle` | `gentle`；`strict` 仅占位 | 选 strict 时提示"暂未开放" |
| `practice.translateDefault` | setting | `off` | `off`/`tap`/`always` | 回落 `off` |
| `practice.inputMode` | setting | `voice` | `voice`/`text` | 回落 `voice` |
| `practice.targetMinutes` | setting | `10` | 5/10/15 | 回落 10 |
| `data.cacheLimitMb` | setting | `80` | 20–300 | 钳制 |
| `asr.baseUrl` | setting | `https://api.siliconflow.cn/v1` | `http(s)://` 开头；去尾部 `/` | 保存禁用 |
| `asr.model` | setting | `FunAudioLLM/SenseVoiceSmall` | 必填；预设可切 Qwen3-ASR / Groq Whisper | 保存禁用 |
| `asr.language` | setting | `en` | ISO 639-1 | 回落 `en` |
| `asr_api_key` | SecureStorage | 空 | 与对话密钥分开；只显示尾 4 位 | 未配置时退回系统识别 |
| `asr.experimental.enabled` | setting | `false` | bool | 默认关闭，仅兜底 |
| `asr.experimental.baseUrl` | setting | `https://aiping.cn/api/v1` | `http(s)://` 开头 | 回落默认值 |
| `asr.experimental.model` | setting | `MiMo-V2.6-Flash` | 必填 | 回落默认值 |
| `asr_experimental_api_key` | SecureStorage | 空 | 留空复用对话密钥 | — |

**测试连接流程**（三态）

1. `GET {base}/models`：成功 → 展示候选模型；失败不判错。
2. `POST {base}/chat/completions`，`max_tokens=8`、单条 `user` 消息：200 且有 `choices[0]` → `ok`。
3. 失败 → `failed` + 截断后的错误摘要（不含 Key），并给出下一步建议。

---

## 6. UI 设计规范 → Flutter 落地

### 6.1 Token 映射

| 规范 | Flutter | 说明 |
|---|---|---|
| `AppColors`（§3.1） | `app_colors.dart` 常量 + `ThemeExtension<AppPalette>` | Material `ColorScheme` 只映射 `primary/surface/error/onSurface` 等；`primaryTint/primaryWash/line/divider` 放扩展 |
| `AppText`（§3.2） | `TextTheme`（display/h1/h2 映射到 `displayLarge/headlineMedium/titleLarge`） | 业务代码优先用 `AppText.xxx`，避免 Theme 层级被 Material 默认覆盖 |
| `AppSpacing` / `AppRadius` / `AppShadows`（§3.3） | `app_metrics.dart` 常量 | 不建 `ThemeExtension`，直接用常量更易读 |
| `AppLayout`（§3.5） | `app_metrics.dart` | `pagePadding=24`、`contentWidth=345`、`navHeight=58` |
| 背景渐变 | `GradientScaffold` | 顶部 `#D5DDFB` → 底部 `#B9C6F4`，禁止纯白铺满 |
| 白色大面板 | `WhitePanel` | 顶部圆角 32、内边距 20、极轻投影 |
| 15 个通用 Widget（§6.3） | `app/widgets/` | 统一入口，页面不重复写装饰 |

### 6.2 关键组件映射

| 规范组件 | Widget | 参数要点 |
|---|---|---|
| 主按钮 | `AppButton.primary` | 高 50、pill、`AppShadows.primary`、禁用态 tint |
| 次按钮 | `AppButton.secondary` | 高 48、白底 1px line、字 `#46527A` |
| 文字按钮 | `AppButton.text` | 主色 13–14、右 chevron |
| 圆形图标按钮 | `IconCircleButton` | 40–44、图标 20、浅底 |
| 主卡片 / 信息卡 | `AppCard` | 白底、圆角 24、内边距 20、`AppShadows.card` |
| 彩色场景卡 | `SceneCardTile` | 主色/粉/薄荷轮换、圆角 18、白字、右上插画裁切 |
| 列表卡 | `ListTileCard` | 高 56–64、左图标 40、右 chevron、间距 12 |
| 输入框 | `AppField` | 高 48、圆角 14、聚焦主色描边 + 3px 外环 |
| 搜索框 | `AppSearchBar` | 高 44、pill、左图标 18 |
| 标签 | `AppTag` | 高 26、圆角 8、wash 底 + 主色字 |
| 可点 Chip | `AppChip` | 白底描边 → 选中 tint + 主色描边 |
| 分段控件 | `SegmentedControl` | 浅紫底 pill、选中白底 600、轻阴影 |
| 开关 | `AppSwitchRow` | 42×25、选中主色 |
| 分步进度 | `StepDots` | 4 点、10px、连线 2px |
| 线性进度 | `ThinProgressBar` | 高 3、圆角 2 |
| 底部导航 | `FloatingTabBar` | 左右 24、高 58、圆角 30、浮动阴影 |
| 底部 Sheet | `AppBottomSheet` | 顶部圆角 32、拖拽条、40% 黑紫遮罩 |
| Toast | `AppToast` | 单行、底部安全区上方 |

### 6.3 页面 → Widget 树

| 页面（原型 screen） | 根 Widget | 主要子组件 |
|---|---|---|
| 首页 `home` | `HomePage` | `HomeHeader`（头像+问候+设置）、`WhitePanel`、`QuickStartCard`、`MiniStats`、`RecallCard`、`CategoryChips`、`SceneRail`、`HomeFoot` |
| 场景卡 `scene` | `ScenarioPage` | `TopBar`、`ScenarioHero`（角色/目标/难度）、`LevelTag`、`TargetPhraseList`（可试听）、`StartDock` |
| 对话 `chat` | `ConversationPage` | `ChatHeader`（标题/角色/结束）、`ThinProgressBar`、`MessageList`、`AiBubble`、`UserBubble`、`ComposerBar`、`HintRail`、`TalkZone`（波形+大圆按钮）、`TextComposer` |
| 复盘 `review` | `ReviewPage` | `TopBar`、`HighlightCard`、`CorrectionList`、`PhrasePickList`、`NextTipCard`、`ReviewDock` |
| 设置 `settings` | `SettingsPage` | `SetIntro`、`SettingGroup`、`LlmConfigCard`（`AppField`+`TestConnectionRow`）、`VoicePicker`、`SpeedSlider`、`AppSwitchRow`、`SegmentedControl`、`RestoreButton` |
| 模型配置（设置内区块） | `ModelProfileSheet` / `ModelProfilePage` | `AppField`×3、`FetchModelsButton`、`ConnResult`、`SaveButton` |
| 记录列表 | `HistoryPage` | `SessionTile`、`EmptyState` |
| 记录详情 | `SessionDetailPage` | `MessageList(readOnly)`、`CorrectionList` |
| 表达本 | `PhrasebookPage` | `PhraseTile`、`EmptyState`、`FilterChips` |

### 6.4 与规范的已知差异（落地时必须处理）

| # | 差异 | 处理建议 |
|---|---|---|
| 1 | 规范写"底部导航 4 项"，原型只有 3 个（练习/表达本/设置） | 按需求 §7.2 落 4 项：练习 / 记录 / 表达本 / 我的；设置收进"我的"。**此项需用户确认** |
| 2 | 原型设置里有"严格 · 即时"纠错 | MVP 只放开"温和"，严格项置灰并提示待开放 |
| 3 | 原型"表达本"是浮层入口 | 落地为独立页面（`PhrasebookPage`），保留浮层作为快速预览 |
| 4 | 规范未定义底部 Sheet 是否可拖拽 | 按固定圆角容器实现，不做拖拽手势 |
| 5 | 规范英文字体 Poppins | 若包体受限，用系统字体并保留字号/字重；不为字体阻塞 M0 |

---

## 7. 第三方包与风险点

| 包 | 版本 | 用途 | 可能出问题的地方 |
|---|---|---|---|
| `flutter_riverpod` | 3.4.3 | 状态管理与注入 | 版本升级 API 变动；不要在 `build` 里做副作用 |
| `drift` + `sqlite3_flutter_libs` | 2.35.3 | 本地库 | 迁移写错会丢数据；桌面/移动类型差异 |
| `flutter_secure_storage` | 11.2.0 | Key 存储 | 部分 ROM Keystore 异常；卸载/换机后失效 |
| `record` | 7.1.2 | 录音 | 机型杂音/权限行为差异；与系统识别同时占用麦克风 |
| `just_audio` | 0.10.6 | 播放 | 快速 stop→play 的竞态；不同解码器 seek 精度 |
| `audio_session` | 0.2.4 | 焦点/路由 | 蓝牙 HFP 切换延迟；来电中断恢复 |
| `speech_to_text` | 7.5.0 | 系统识别 | 国产 ROM 可能无服务；长句提前截断 |
| `whisper_ggml` | 2.8.1 | 端侧识别（可选） | 模型体积/首次加载慢；中端机实时率 |
| `flutter_tts` | 4.2.5 | 系统 TTS 兜底 | 音色集合因 ROM 而异；语速映射不一致 |
| `edge_tts` | 0.1.5 | Edge TTS | **成熟度低**，可能与当前签名/端点不匹配；需自写兜底 |
| `dio` | 5.11.1 | HTTP/SSE | 拦截器里抛错会吞掉原始错误；超时需分 connect/receive |
| `web_socket_channel` | 2.4.x | Edge TTS WSS | 断线重连与半包处理需自己兜 |
| `permission_handler` | 13.0.2 | 权限 | Android 14+ 部分权限语义变化 |
| `wakelock_plus` | 1.8.2 | 常亮 | 长时间常亮耗电；离开页面必须释放 |
| `connectivity_plus` | 7.3.2 | 网络状态 | 只反映链路，不代表服务可达 |

**许可证提醒**：`piper` GPL、`aeneas` AGPL、`libreTranslate` AGPL 不要引入；`edge_tts` 上游为 LGPLv3（本项目只调用远程服务，不拷贝其源码）。

---

## 8. 编码约定与质量门槛

| 项 | 约定 |
|---|---|
| 错误类型 | 统一 `AppError{kind, retryable, detail}`，禁止裸 `Exception` 跨层 |
| 日志 | 统一走 `AppLogger`，自动过滤 `authorization`/`api_key`/`sk-`；release 关闭 debug 日志 |
| 异步 | Controller 内所有请求持有 `CancelToken`/句柄，页面销毁必须取消 |
| 时间 | 存毫秒时间戳，展示层格式化；`duration_sec` 用有效时长 |
| 文案 | 错误文案集中在 `features/<x>/copy.dart`，service 不返回中文 |
| 测试边界 | 必须有单测：`SseParser`、`LlmErrorMapper`、`PromptBuilder`、`TtsCache` 键生成、判分/统计（M3 后） |
| 真机门槛 | 每个里程碑结束必须在一台 Android 真机跑通，不以模拟器代替 |
| 依赖新增 | 引入新包前记录：用途、许可证、最近更新时间、替代方案 |

---

## 9. 模块 ↔ 里程碑对照

| 模块 | M0 | M1 | M2 | M3 | M4 |
|---|---|---|---|---|---|
| `app/theme`、`app/widgets` | 建 | 补对话组件 | 补错误态 | 补复盘组件 | 视觉走查 |
| `data/db`、`repositories` | 建表 + 配置 | 消息落库 | 缓存表 | 复盘/表达本/统计 | 清理 |
| `services/llm` | 非流式 + 错误 | 流式 + 切句 | 重试/取消/降级 | 复盘请求 | 提示/翻译请求 |
| `services/asr` | — | 系统识别 | Whisper（可选） | — | — |
| `services/tts` | — | Edge 最小实现 | 路由/熔断/缓存 | 改进句朗读 | — |
| `services/audio` | — | 录音 + 播放 | 焦点/设备切换 | — | — |
| `features/profile`、`settings` | 全量 | 引擎/音色 | 降级提示 | — | 打磨 |
| `features/conversation` | 文字版 | 语音全链路 | 稳定性 | 纠错标记 | 提示/翻译 |
| `features/review` | — | — | — | 全量 | 打磨 |
| `features/history`、`phrasebook` | — | — | — | 全量 | 打磨 |

> 每个里程碑的任务编号、验收标准与依赖关系见 [milestones-speaking-app-v0.1.md](milestones-speaking-app-v0.1.md)。

---

## 10. 待确认项（会影响本文结构）

| # | 事项 | 影响 |
|---|---|---|
| 1 | 底部导航 3 项还是 4 项（原型 vs 规范） | 决定 `AppShell` 与路由表 |
| 2 | 是否引入端侧 Whisper | 决定 `WhisperAsrEngine` 是否进 M2 |
| 3 | Edge TTS 用 `edge_tts` 包还是自写 WSS | 决定 `EdgeTtsEngine` 的实现量 |
| 4 | iOS 是否同步 | 决定 `AudioSessionManager` 是否需要平台分支 |
| 5 | 是否保留视频画面（二期） | 本次不影响 |
