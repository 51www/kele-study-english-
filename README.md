# Saylo

个人自用的英语口语练习 App：选一个场景，用英文对话，卡住时可以看翻译和提示，练完做一次复盘。Flutter 开发，交付形态是 Android App。

## 项目说明

当前完成度（按里程碑，代码侧均已落地，真机逐条验收清单见 `docs/milestones-speaking-app-v0.1.md` §11）：

- **M0 已完成**：场景选择与详情、文字版对话（流式/非流式）、本地落库与重开恢复、模型配置页（接口地址 / API Key / 模型名 + 测试连接）、错误提示与日志脱敏。
- **M1 已完成**：按住说话录音（16kHz 单声道 WAV）、语音识别三引擎（OpenAI 兼容 `/audio/transcriptions`、系统识别、用对话模型做识别的实验开关）、Edge 朗读 + 系统朗读降级、单条消息重听、连续多回合对话。
- **M2 已完成（代码侧）**：统一超时表（`lib/core/timeouts.dart`）、请求重试/取消、错误四分类文案与行动、朗读熔断与系统 TTS 降级（整场只提示一次）、朗读音频内存 + 落盘 LRU 缓存（80MB，断网重听命中即播）、播放端慢速、耳机/蓝牙接入与来电中断（不自动续播，可点「继续播放」）、分阶段延迟埋点（识别 / 首字 / 首音，可在「我的」查看）。
- **M3 已完成**：复盘页（亮点 / ≤3 条改法 / 表达 / 下次建议，容错解析 + 自动重试一次）、逐句纠错标记与展开（试听 / 删除）、练习记录与只读转写、表达本、首页「上次卡在哪」与本周次数 / 今日分钟 / 连续天数、删会话级联与清空所有数据（含密钥、缓存、设置恢复默认）。
- **M4 已完成**：2 个内置场景（MVP 首批）、L1–L4 提示阶梯（不自动发送、不进主历史）、翻译三态与「我想说」（中→英建议不自动发送）、空态与异常态、单次/月度成本估算与超限提示、按 UI 规范 Token 的视觉走查。
- **收尾项已完成**：「方法 / 技巧」栏目（首页区块入口，不新增 Tab），7 篇第三方文章站内全文阅读，配图以「[图：说明]」占位，保留出处与原文链接（系统浏览器打开）。
- **场景库扩容已完成**：参考同类产品场景库设计，新增 24 个练习场景，合计 **26 个内置场景**，按日常 / 工作 / 旅行 / 社交 / 健康 / 观点 6 类组织；新增独立场景库页 `/scenarios`（分类 Chip、中英文搜索、练过次数），首页只保留 2 张推荐卡 +「全部 26 个」入口。调研与完整清单见 `docs/research-practice-scenarios-2026-11.md`。

> 明确未启用：**端侧 Whisper（T2.7，里程碑可选项）**。当前识别链路是「独立 ASR 接口 → 系统识别 → 实验性对话模型识别」，端侧推理留到确有离线需求时再接入；已记录在里程碑文档 §9。

真机验证：已在 Android 17 真机（PKC110）安装并走通首页统计、技巧列表/详情、模型配置、对话页提示与翻译控件、清空数据回到首次启动状态等路径；场景库扩容后又在**不清数据的覆盖安装**上验证了首页「全部 26 个」、场景库分类/搜索/空态、新场景详情与「开始练习」的密钥引导，截图见 `docs/shortscreen/M3/` 与 `docs/shortscreen/M4/18–24`，逐条状态见里程碑清单 §11 与 §12.5。需要真实 API 的 8 回合对话、延迟 p50/p95、弱网/蓝牙降级，以及「练过 N 次」与清空数据后的计数归零，仍待现场验收。

## 运行说明

环境要求：

- Flutter 3.47.x（Dart 3.13.x），Android SDK 使用 Flutter 默认版本（compileSdk 36 / minSdk 默认）。
- Web 调试需要本机 Chrome；Android 构建需要可用的 JDK、Android SDK 与可访问 Maven 仓库的网络。

启动 Web 调试：

```bash
flutter pub get
flutter run -d chrome
# 或构建静态产物
flutter build web --release
```

构建并安装 Android 真机（开发调试）：

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### 正式包名与签名

- **正式包名**：`com.kele.saylo`（`applicationId` 与 `namespace` 一致，`MainActivity` 包路径同步；发布后不可更改），版本 `1.0.0+1`。
- **签名密钥**：`android/keystore/saylo-release.jks`，alias `saylo`，RSA 2048 / 有效期 10000 天，证书 `CN=Saylo, O=Kele, C=CN`。
- **本地配置**：`android/key.properties`（模板 `android/key.properties.example`）保存密钥库与密钥密码。它与 `android/keystore/` 均已被 `.gitignore` 忽略，**绝不提交到仓库**。
- **签名策略**：debug 与 release 共用这把正式密钥，真机覆盖安装不会再出现签名不匹配；缺少 `key.properties` 时 release 会退回 debug 签名并打印警告，不可用于发布。
- 证书 SHA-256 指纹：`69:DE:37:69:EF:B9:19:42:5A:55:B3:B4:55:C3:48:7B:4A:47:19:4C:B6:63:AC:5B:A7:A8:75:4B:19:5C:C3:B8`。

构建正式包：

```bash
flutter build apk --release
# 校验签名（apksigner 需要 JAVA_HOME 指向 Android Studio 自带 JBR）
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
~/Library/Android/sdk/build-tools/36.0.0/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

> `saylo-release.jks` 与 `key.properties` 必须一起离线备份：丢失后无法再为已安装的 App 提供可升级的包。旧的测试包 `com.kele.kele_speak` 与正式包是两个独立应用，数据不互通，可自行卸载。

首次启动需要到「我的」里填两类配置：

1. **模型配置**：接口地址（OpenAI 兼容，形如 `https://example.com/v1`）、API Key、模型名。
2. **语音识别配置**（可选）：识别接口地址、模型名、API Key；不填则用系统识别。

不填会怎样：没有对话密钥时，对话页提示「还没有配置模型密钥」，发送不会成功，可点提示直接去配置；没有识别配置时自动用系统识别，系统识别不可用时自动切到文字输入，会话不中断；朗读始终先尝试 Edge，失败后切系统朗读。

对话页的「提示」按钮提供 L1 重听/慢速 → L2 关键词 → L3 参考回答 → L4 中→英；「我想说」把中文变成一句英文建议并填入输入框，两者都不会替你发送。翻译默认关闭，可在对话页切成「点按」或「常开字幕」，也可在设置里改默认值。

密钥保存在设备安全存储中（Android 用 Keychain/Keystore，Web 端回退到浏览器本地存储），界面上只显示尾号。「清空所有数据」会把记录、表达本、密钥、缓存与设置一并清掉并恢复 26 个内置场景。

## 场景库

- **26 个内置场景**：MVP 首批 2 个（咖啡店点单 / 工作会议澄清）+ 新增 24 个，按日常 / 工作 / 旅行 / 社交 / 健康 / 观点 6 类组织；全库难度分布 A2 9 个、B1 12 个、B2 5 个。
- **入口**：首页「场景练习」只放 2 张推荐卡，右侧「全部 26 个」进入场景库；库内可切分类、搜中英文标题、看「练过 N 次」，点卡片进详情后开始练习。整体流程仍是「选场景 → 对话 → 复盘」。
- **场景内容**：AI 角色、用户目标、分类、难度、开场白、5 条目标表达、预期回合、成功条件与 1 个意外分支；目标表达会自然引导 AI 追问，但不会变成测验或逐句纠错。
- **数据**：场景写在 `lib/data/db/seeds.dart`，启动时按 `id` 幂等 upsert；**不清数据、不升级数据库版本**也会自动获得新场景。「清空所有数据」会恢复 26 个场景、把练过次数归零。
- **不做**：自定义场景、场景市场、随机话题、同一场景多难度版本。调研依据与 24 个场景清单见 `docs/research-practice-scenarios-2026-11.md`。

## 免责说明

- 仅供个人学习使用，不构成任何教学服务。
- 第三方 API 的密钥、费用与合规由使用者自行承担。
- 成本为本地按 `usage`（缺失时按字符数）的估算值，不是厂商账单。
- 朗读依赖的 Edge 在线语音属于非官方接口，可能随时失效；失效时会降级到系统朗读。
- 「方法 / 技巧」只提供第三方文章全文的个人学习副本，配图不下载，保留出处与原文链接，版权归原作者。
- 不承诺任何学习效果。

## 致谢

开源项目与依赖：Flutter、flutter_riverpod、go_router、dio、drift + sqlite3_flutter_libs、flutter_secure_storage、shared_preferences、record、speech_to_text、flutter_tts、just_audio、audio_session、web_socket_channel、crypto、connectivity_plus、wakelock_plus、url_launcher、uuid、intl、path / path_provider。

第三方服务：对话接口（OpenAI 兼容协议）、语音识别接口（OpenAI 兼容 `/audio/transcriptions`）、Edge 在线朗读（非官方）、系统语音识别与系统朗读。
