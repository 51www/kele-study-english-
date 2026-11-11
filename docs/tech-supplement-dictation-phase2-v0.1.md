# 技术补充（二期）：视频教材导入与单句听写 v0.1

- 文档状态：执行版（随 M5–M7 落地）
- 日期：2026-11-11
- 上游：需求 [requirements-speaking-app-v0.2.md](requirements-speaking-app-v0.2.md) 第 12 章、[技术设计 v0.1](tech-design-speaking-app-v0.1.md)、[开发文档 v0.1](dev-guide-speaking-app-v0.1.md)、[预研](research-video-material-dictation-2026-11.md)
- 定位：只补二期新增内容，**不重写、不推翻**技术设计与开发文档的 MVP 部分；索引见需求 §12.7。

---

## 1. 路线与边界

本轮只实现「路线 A：本地文件 + 自带字幕」（预研 §6）。用户用系统文件选择器给出媒体与字幕，App 端内只做：字幕解码 → 清洗过滤 → 切句与时间轴分配 → 句子级裁剪播放 → 离线判分 → 进度与错句落库。

- **不在 App 内**：视频下载、抽音轨、转码、ASR 生成字幕、文本-音频强制对齐、素材上传/分享。
- **不做**：视频画面播放（Q16 只音频）、逐词卡拉 OK 高亮、音素级评分、模型判分。
- **无字幕导入**：只提示「可自动生成字幕（后续开放）」，不提供假装可用的按钮（Q18）。
- **素材副本**：纯音频文件复制到 `getApplicationDocumentsDirectory()/materials/<id><ext>`；视频文件只记录用户选择的路径，不复制整个视频。句子片段由播放器按起止时间裁剪，**不导出片段文件**。因此需求 F11「只保留抽取出的音频片段」在本轮体现为「不落地片段文件、只保留文本与时间轴」，以避开 FFmpegKit 退役与端内转码风险（预研 §1.8、§6）。
- **源文件失效**：视频源被移动/删除时，详情页与听写页检测到不可访问，提示「源文件已移动，请重新导入」，不影响其它教材。

## 2. 模块边界（新增，不碰 MVP 模块）

```text
lib/
├─ domain/models/dictation_models.dart        3 个不可变模型 + toMap/fromMap（新增文件）
├─ data/db/app_database.dart                 3 张新表 + schemaVersion 2 + onUpgrade 只建表
├─ data/db/local_store.dart                  二期 CRUD 签名（抽象门面）
├─ data/db/drift_store.dart / web_store.dart 两端实现 + clearAll 接线
├─ services/audio/clip_player.dart           独立 AudioPlayer 实例（不改 AudioPlayerService）
├─ features/dictation/
│  ├─ ingest/subtitle_parser.dart            SRT/VTT + 编码探测（纯逻辑）
│  ├─ ingest/material_import_service.dart    选文件、复制音频、hash 去重、落库
│  ├─ align/segment_splitter.dart            切句 / 合并 / 拆分 / 边界余量（纯逻辑）
│  ├─ scoring/dictation_scorer.dart          规范化 + 词级 diff（纯逻辑、离线）
│  ├─ repository/material_repository.dart    组合 LocalStore + 进度聚合 + 文件清理
│  ├─ providers.dart                         二期专用 Riverpod Provider
│  ├─ widgets/word_diff_view.dart            逐词差异着色
│  └─ pages/                                 教材库 / 导入 / 详情 / 听写 / 错句本
└─ test/                                     字幕解析、切句、判分纯逻辑单测
```

数据流：

```text
选文件 → 解码字幕 → 清洗/过滤 → 切句(时间轴) → material + material_segment
                                                    │
                                     详情手动合并/拆分/微调 → replaceSegments
                                                    │
听写页 → ClipPlayer 按 [start,end] 播放 → 键盘输入 → DictationScorer（纯 Dart）
      → dictation_attempt（输入/正确率/是否通过/逐词差异） → 教材库统计 / 错句本
```

判分链路**不经过** `ConversationController`、`PromptBuilder`、`OpenAiCompatibleClient`、`ReviewService`；不写 `session` / `message` / `correction` 表，因此首页「今日分钟」「连续天数」「上次卡在哪」口径完全不变。

## 3. 数据模型（3 张新表）

| 表 | 字段 | 说明 |
|---|---|---|
| `material` | `id` PK、`title`、`media_path`、`media_name`、`media_kind`（audio/video）、`subtitle_name`、`source_hash`、`duration_ms`、`segment_count`、`created_at`、`last_practiced_at` | 一份教材；`source_hash` 用媒体名 + 字节数 + 字幕内容做 SHA-256，用于「已存在」判定 |
| `material_segment` | `id` PK、`material_id`、`seq`、`text_en`、`start_ms`、`end_ms`、`word_count`、`is_hard`、`created_at` | 句子；手动修正后整份 `replaceSegments` 重排序号，不重新解析字幕 |
| `dictation_attempt` | `id` PK、`material_id`、`segment_id`、`user_text`、`accuracy`、`passed`、`diff_json`、`created_at` | 每次提交一条；句子状态取「该句最新一条」 |

进度位置放既有 `app_meta`，键 `dictation.position.<materialId>`，值为 `{index,mode}` JSON；跨教材「只练全部错句」单独用 `dictation.position.all-wrong`。不走新表，避免与 `session` 统计混淆。`clearAll` 必须先删 `dictation_attempt` / `material_segment` 再删 `material`（`PRAGMA foreign_keys = ON`），Web 兜底同步删 3 个 key。

**迁移**：`schemaVersion: 1 → 2`；`onCreate` 保持 `createAll()`；`onUpgrade` 在 `from < 2` 时只对 3 个生成表执行 `m.createTable(...)`，不 `ALTER`、不 `DROP`、不回填。生成文件 `app_database.g.dart` 由 `dart run build_runner build --delete-conflicting-outputs` 重生成，禁止手改。旧用户覆盖安装后 9 张老表数据完整。

## 4. 配置项（追加，不改既有值）

| Key | 默认 | 作用 |
|---|---|---|
| `dictation.passThreshold` | `90` | 通过阈值（百分比，可在设置页调整） |
| `dictation.contractionEquivalent` | `true` | `I'm` / `I am`、`I'd like` / `I would like` 等缩写等价 |
| `dictation.numberEquivalent` | `true` | `10` / `ten`、`$5` / `five dollars` 双向等价 |
| `dictation.speed` | `1.0` | 听写默认播放速度，可切 `0.75` |

四处同步：`SettingsKeys`（`domain/models/models.dart` 追加常量）、`defaultSettings`（`data/db/defaults.dart`）、设置页「听写练习」分区、开发文档 §5。

## 5. 音频链路（隔离做法）

- `ClipPlayerService` 持有**自己的** `AudioPlayer`，用 `ClippingAudioSource(child: AudioSource.uri(...), start:, end:)` 实现片段播放与终点自动停止；`setSpeed` 支持 0.75x/1.0x；复听用 `seek(Duration.zero)` + `play()`；`positionStream` 驱动进度条；页面 `dispose` 释放。
- 进入听写页先调用既有 `audioPlayerProvider.stop()`，退出后不恢复任何 TTS 状态；`AudioPlayerService.playBytes/playPath` 的「等待播放完成才返回」契约保持原样，TTS「正在朗读」状态不受影响。
- 不做端内转码；`just_audio` 在 Android 上直接解码本地 MP4 音轨，Web 端仅作页面走查，不作为真实验收环境。
- 前后各留 100ms 边界余量（不越过 0 与相邻句起点），只保证首尾音不被明显切掉，不承诺逐词精度。

## 6. 页面与路由（不改底部 4 Tab）

| 路由 | 页面 | 入口 |
|---|---|---|
| `/materials` | 教材库（列表 / 统计 / 导入 / 错句本 / 清理） | 首页「听写教材」栏目区块 |
| `/materials/import` | 导入（选媒体 + 字幕、进度、错误、版权声明） | 教材库右上「导入」 |
| `/materials/wrong` | 错句本（跨教材、只练错句） | 教材库 / 首页栏目 |
| `/materials/:id` | 教材详情（句子列表、状态、手动修正、开始听写） | 教材库卡 |
| `/materials/:id/dictation?mode=all\|wrong` | 听写页（不泄露原文、复听、输入、判分、逐词差异、收藏） | 详情 / 错句本 |

全部挂在 `ShellRoute` 外并带 `parentNavigatorKey: rootNavigatorKey`，沿用 `_slide` 转场；`_paths` 与 `FloatingNav` 零改动。静态路由 `/materials/import`、`/materials/wrong` 必须排在 `/materials/:id` 之前。

## 7. 复用关系

| 复用 | 来自 MVP | 约束 |
|---|---|---|
| 本地文件播放 | `just_audio`（新实例） | 不改 `AudioPlayerService` |
| 朗读句子 / 存入表达本 | `TtsRouter`、`phrase` 表 | 只新增「存表达」入口，不改表达本页 |
| 语音输入（可选） | `AsrEngine` | 失败时无缝切回键盘，输入内容不丢 |
| 空态 / 错误态 / 卡片 / 按钮 | `app/widgets/common.dart` | 不新增色值、字号、间距，只用既有 Token |
| 清空所有数据 | `data_settings_page.dart` | 追加二期表与音频副本清理，不改 MVP 清空流程 |

## 8. 风险与验证策略

| 风险 | 缓解 / 验证 |
|---|---|
| 新增依赖影响 Android 构建 | `file_picker`、`charset` 固定版本；`flutter pub get` → `analyze` → `build web` → 覆盖安装 |
| 生成文件与手写列名不一致 | 只通过 build_runner 生成；`flutter test` 覆盖模型 `toMap/fromMap` |
| 字幕编码误判 | UTF-8 严格解码失败再回退 GBK；去掉 BOM；保留「编码错误」可解释失败 |
| 切句过长/过碎 | 3–12 秒、5–22 词双约束 + 标点/连词二次切分 + 过短合并；单测覆盖 |
| 判分与用户预期不一致 | 规则在页面可见、4 项可配、单测覆盖需求 §14 的四条验收 |
| 老数据丢失 | `onUpgrade` 只建表；覆盖安装不清数据后核对会话、表达本、场景数、密钥 |
| 版权 / 平台条款 | 只处理本地文件、不内置下载器、页面保留个人学习声明 |

## 9. 与需求 §12.7 索引的对应

| 需求指向 | 本文件章节 |
|---|---|
| §2.4 录音与播放 / §2.5 音频格式 / §2.6 后台行为 | §5 |
| §3.2 模块边界 | §2 |
| §4 语音链路 | §7 |
| §6 数据模型 | §3 |
| §7 UI 结构 | §6 |
| §8 里程碑 | [二期里程碑清单](milestones-phase2-dictation-v0.1.md) |

## 10. 链接导入（流程 C，2026-11-11 补）

- 入口：导入页「链接导入」模式，填音视频直链 / 播客 RSS + 可选字幕链接。
- 实现：`MaterialImportService.importFromUrl(mediaUrl, subtitleUrl?, title, onProgress?)`：
  - 先校验：非 http(s) 直接报错；命中平台域名（YouTube / BBC 等）抛 `MaterialImportException('本应用不抓取平台内容…')` 拦截，不解析网页、不绕开平台保护。
  - 若链接是 RSS/Atom Feed（`.rss/.xml/.atom`），解析 `<enclosure>` / `<media:content>` 取音频地址、`<podcast:transcript>` 取内嵌字幕。
  - 直链音视频会尝试同站点同名 `.vtt` / `.srt`（best-effort，失败忽略）。
  - 随后用 `dio` 下载字节流，调用与本地文件完全相同的 `_createMaterial`（字幕解析 → 切句 → 落库）；非 Web 端音视频写入 App 私有目录。
- 隔离：不新增网络依赖（`dio` 已在 M1 引入）；不动对话状态机、不写 `session` / `message` / `correction`。
- 失败处理：非 http(s)、平台页面、下载失败、空字幕均抛 `MaterialImportException` 给导入页展示，不静默失败。
- 限制：平台专属下载器/抓取、端内转码不做；Web 端跨域链接受 CORS 限制，以 Android 真机为准。

## 11. B 站导入（路线 D：配套服务，2026-11-11 用户决策）

用户明确要求支持 B 站视频地址导入；本轮**不推翻**「App 本体不内置下载器、不解析网页」的边界，改为引入用户自建的配套服务承担下载：

- **配套服务**：`companion/bili-helper/`（Flask + yt-dlp，Python ≥3.10，监听 `0.0.0.0:8787`），跑在用户电脑上；手机与电脑需同一局域网。协议 4 个接口：`POST /api/bili/import`（提交 `{url, cookie?}`）、`GET /api/bili/job/<id>`（进度/标题/错误）、`GET .../audio`、`GET .../subtitle`；详见其 README。
- **App 侧**：`MaterialImportService.importBiliFromCompanion(videoUrl, serviceBase, cookie?, title?, onStatus?)` 提交任务 → 800ms 轮询 → 取回 m4a 与 SRT → 复用与本地导入完全相同的 `_createMaterial` 管线（切句、30 分钟上限、去重、落库全部继承）。导入页用 `isBiliUrl`（bilibili.com / b23.tv）分流；服务地址取 `dictation.companionUrl`，Cookie 取 `dictation.biliCookie`。
- **Cookie**：CC/AI 字幕接口需登录态，设置页「B 站导入」分区由用户粘贴自己的 Cookie（至少含 `SESSDATA`），随任务明文传给配套服务；服务端只把它写进本次任务临时目录内的 Netscape `cookies.txt`、交给 yt-dlp 的 `cookiefile`（新版 yt-dlp 已弃用 Cookie HTTP 头，避免 `Deprecated Feature` 告警与跨域作用域问题），字幕接口仍用带 Cookie 的请求头，任务结束即删除、不持久化；不填则只能拿公开字幕，服务报错文案引导补配。
- **边界与合规口径**：下载由用户在自己电脑上运行的配套服务完成，App 不内置、不捆绑下载器；页面保留「素材版权归原权利人，仅供个人学习」声明；其他平台（YouTube / BBC 等）仍拦截。
- **失败处理**：服务不可达、任务报错、地址非法均抛 `MaterialImportException` 原因透传；音频与字幕被 App 取走后服务端临时文件即清理，未取走 30 分钟过期。
- **验证**：`test/companion_import_test.dart` 用假 Dio adapter 覆盖「提交→轮询→取回→落库」「服务报错透传」「服务不可达」「地址非法」四条；`test/url_import_test.dart` 平台拦截用例同步更新（B 站提示配套服务，YouTube/BBC 仍提示不抓取）。真机需验证：同一局域网连通、Cookie 拿 AI 字幕、多 P `?p=` 分 P。
| §9.1 技术风险 | §1、§8 |
