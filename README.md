# Saylo

个人自用的英语口语练习 App：选一个场景，用英文对话，卡住时可以看翻译和提示，练完做一次复盘。Flutter 开发，交付形态是 Android App。

## 项目说明

当前完成度（按里程碑）：

- **M0 已完成**：场景选择与详情、文字版对话（流式/非流式）、本地落库与重开恢复、模型配置页（接口地址 / API Key / 模型名 + 测试连接）、错误提示与日志脱敏。
- **M1 已完成**：按住说话录音（16kHz 单声道 WAV）、语音识别三引擎（OpenAI 兼容 `/audio/transcriptions`、系统识别、用对话模型做识别的实验开关）、Edge 朗读 + 系统朗读降级、单条消息重听、连续多回合对话。
- **M2 进行中**：请求超时 / 重试 / 取消、朗读熔断与内存缓存、离线与弱网提示、分阶段延迟日志。尚未验收。
- **M3 未开始**：复盘页完整能力、逐句纠错、练习记录详情、表达本、首页统计、删除与清空。
- **M4 未开始**：第二场景、四级提示、翻译三态、空态与异常态、成本估算、视觉走查。
- **收尾项未开始**：「技巧分享」栏目（第三方文章摘要与链接）。

## 运行说明

环境要求：

- Flutter 3.47.x（Dart 3.13.x），Android SDK 使用 Flutter 默认版本（compileSdk 36 / minSdk 默认）。
- Web 调试需要本机 Chrome；Android 构建需要可用的 JDK 与 Android SDK。

启动 Web 调试：

```bash
flutter pub get
flutter run -d chrome
# 或构建静态产物
flutter build web --release
```

构建并安装 Android：

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

首次启动需要到「我的」里填两类配置：

1. **模型配置**：接口地址（OpenAI 兼容，形如 `https://example.com/v1`）、API Key、模型名。
2. **语音识别配置**（可选）：识别接口地址、模型名、API Key；不填则用系统识别。

不填会怎样：没有对话密钥时，对话页提示「还没有配置模型密钥」，发送不会成功，可点提示直接去配置；没有识别配置时自动用系统识别，系统识别不可用时自动切到文字输入，会话不中断；朗读始终先尝试 Edge，失败后切系统朗读。

密钥保存在设备安全存储中（Android 用 Keychain/Keystore，Web 端回退到浏览器本地存储），界面上只显示尾号。

## 免责说明

- 仅供个人学习使用，不构成任何教学服务。
- 第三方 API 的密钥、费用与合规由使用者自行承担。
- 朗读依赖的 Edge 在线语音属于非官方接口，可能随时失效；失效时会降级到系统朗读。
- 「技巧分享」栏目（规划中）只提供第三方文章的摘要与原文链接，版权归原作者，不提供全文。
- 不承诺任何学习效果。

## 致谢

开源项目与依赖：Flutter、flutter_riverpod、go_router、dio、drift + sqlite3_flutter_libs、flutter_secure_storage、shared_preferences、record、speech_to_text、flutter_tts、just_audio、audio_session、web_socket_channel、crypto、connectivity_plus、wakelock_plus、uuid、intl、path / path_provider。

第三方服务：对话接口（OpenAI 兼容协议）、语音识别接口（OpenAI 兼容 `/audio/transcriptions`）、Edge 在线朗读（非官方）、系统语音识别与系统朗读。
