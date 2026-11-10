# 语音识别（ASR）选型说明（2026-11）

> 用途：为 M1 语音回合确定 ASR 供应商与接入方式。
> 本文只给选型结论，不改动需求文档与技术设计主体；涉及配置项的改动以「建议」形式列出，待确认后再生效。
> 结论时间：2026-11-10。价格随时变动，以第 7 节官方链接为准。

---

## 1. 结论速览

| 问题 | 结论 |
|---|---|
| aiping.cn 能做 ASR 吗 | **不能**。只有文本对话与少量 TTS 条目，`/audio/transcriptions` 实测 404 |
| 首选 | **硅基流动 `FunAudioLLM/SenseVoiceSmall`**：免费、标准 OpenAI `/audio/transcriptions`、国内可直连 |
| 首选的质量升级 | 同平台 `Qwen/Qwen3-ASR-1.7B`（¥0.00022/秒）；或 Groq `whisper-large-v3-turbo`（$0.04/小时，英文更稳） |
| 零配置兜底 | Android 系统 `speech_to_text`，M1 首日即可跑通 |
| 离线兜底 | `sherpa-onnx`（后续里程碑） |
| 对 M1 的硬影响 | ASR 必须**独立配置**，不能复用对话的 base_url / key |

---

## 2. aiping.cn 查证（能否当 ASR 用）

**平台性质**：AI Ping（清程极智），是大模型 API 的评测 + 统一调用 + 智能路由平台。官方文档只描述「统一接口访问各服务商的大模型」与「按延迟/吞吐/价格智能路由」，即文本（含视觉）对话模型。

**模型列表**：公开模型列表页显示 140 个模型，系列为 DeepSeek / GLM / Kimi / MiniMax / Qwen / 豆包 / 即梦 / Kling / Vidu / Wan / bge / Kolors / Hunyuan / Step / MiMo / V2Fun / MOSS，**没有 ASR / Whisper / 转写分类**，页面内也搜不到语音识别条目（仅有 `DeepSeek-OCR` 这类视觉 OCR）。

**接口实测**（引自仓库 `.logs/milestone-0.md`，2026-11-10 实测，接口 `https://aiping.cn/api/v1`）：

| 请求 | 结果 |
|---|---|
| `GET /models` | 200，返回 130+ 模型；含对话模型，以及 `MiniMax-Speech-2.8-hd` 等**语音合成**条目 |
| `POST /audio/transcriptions` | **404，未提供语音识别** |
| `POST /audio/speech` | 422（端点存在但参数不被接受） |

**本轮补充核查**：本机环境变量 `AIPING_KEY` 未设置，因此没有重复调用接口（也未做任何消耗性调用）；密钥未写入任何文件或文档。

**结论**：aiping.cn 当前只能当纯文本对话用。M1 的 ASR 不能挂在用户的对话配置上。

---

## 3. 候选清单（2026-11）

### 3.1 支持标准 OpenAI `/audio/transcriptions`（可直接复用一套客户端）

| 模型 | 提供方 | 中/英 | 价格 | 备注 |
|---|---|---|---|---|
| `gpt-transcribe` | OpenAI | ✅ / ✅ | $0.0045/分钟（$0.27/小时） | 2026 年的低价转写档 |
| `gpt-4o-mini-transcribe` | OpenAI | ✅ / ✅ | $0.003/分钟 | 便宜，准确率略低 |
| `gpt-4o-transcribe` | OpenAI | ✅ / ✅ | $0.006/分钟 | 支持 prompt 上下文 |
| `whisper-large-v3-turbo` | Groq | ✅ / ✅ | $0.04/小时（≈$0.00067/分钟） | 端点 `api.groq.com/openai/v1/audio/transcriptions`，支持 `verbose_json` + 词级时间戳 |
| `whisper-large-v3` | Groq | ✅ / ✅ | $0.111/小时 | 更准、更慢 |
| `FunAudioLLM/SenseVoiceSmall` | 硅基流动 | ✅ 中英日韩粤 | **免费** | 只返回 `text`，无时间戳 |
| `TeleAI/TeleSpeechASR` | 硅基流动 | ✅ / ✅ | 未核实（在端点模型枚举内） | 备用 |
| `Qwen/Qwen3-ASR-1.7B` | 硅基流动 | ✅ 52 语种 | ¥0.00022/秒（≈¥0.79/小时） | 价格页有，**是否走 `/audio/transcriptions` 未核实**（端点文档只列了上面两个模型） |
| `whisper-1` | OpenAI | ✅ / ✅ | 定价页已不列该条目 | 疑似已退役，**未核实** |

### 3.2 需单独 SDK / 私有协议（不能直接走标准转写端点）

| 模型 / 服务 | 提供方 | 中/英 | 价格 | 协议 |
|---|---|---|---|---|
| `qwen-audio-3.1-asr-flash`（含 `-filetrans` / `-streaming` / `-message`） | 阿里云百炼 | ✅ 多语种 + 方言 | ¥0.00022/秒（≈¥0.79/小时） | DashScope 原生；官方「OpenAI 兼容」文档只覆盖 Chat |
| 豆包录音文件识别 2.0 / 流式识别 | 火山引擎 | ✅ / ✅ | 文件 ¥0.8/小时；流式 ¥1.0/小时起 | 火山自有 HTTP/WS |
| 语音听写 / 实时语音转写 | 讯飞开放平台 | ✅ / ✅ | 听写 ¥15/万次；转写 ¥1.5/小时起 | 讯飞自有 WS |
| Nova-3 | Deepgram | ✅ / ✅ | 批量 $0.0043/分钟；流式 $0.0077/分钟 | 自有 Listen API |
| Universal-3.5 Pro | AssemblyAI | ✅ / ✅（英文最强档） | 异步 $0.21/小时；实时 $0.45/小时 | 自有 API |
| 腾讯云语音识别 | 腾讯云 | ✅ / ✅ | 未核实 | 自有 SDK |
| `sherpa-onnx` / `whisper.cpp` / `faster-whisper` | 开源本地 | ✅ / ✅ | 0（只付算力） | 端上推理，无网络 |

---

## 4. 推荐（英语口语 App / 用户自填接口 / MVP 优先 / 成本敏感）

**首选：硅基流动 `FunAudioLLM/SenseVoiceSmall`**

- 标准 OpenAI `/audio/transcriptions`，`flutter` 侧一个 `MultipartRequest` 就能接，和现有 `LlmClient` 风格一致；
- **免费**，国内可直连，不需要额外网络条件；
- 中英日韩粤都支持，英语场景够用；
- 缺点：只返回纯文本，没有词级时间戳；对中式口音英语的准确率不如 Whisper large-v3。

**同一平台的质量升级项**：`Qwen/Qwen3-ASR-1.7B`（¥0.00022/秒）。若 M1 实测 SenseVoiceSmall 识别率不够，只改 `model` 字段就能切换（前提是确认它支持该端点，见 3.1 备注）。

**备选（英文准确率优先）：Groq `whisper-large-v3-turbo`**（$0.04/小时）。标准 OpenAI 兼容路径，支持 `verbose_json` 与词级时间戳，英文鲁棒性明显更好；代价是需要海外网络可达。

**两层兜底**：
1. Android 系统 `speech_to_text`——零配置、零成本，M1 第一天就能打通语音回合，作为「用户没配 ASR」时的默认；
2. 本地 `sherpa-onnx`——离线可用，放到后续里程碑，不进 M1。

**成本测算**（每天 10 分钟 ≈ 5 小时/月）：

| 方案 | 月成本 |
|---|---|
| SenseVoiceSmall | ¥0 |
| Qwen3-ASR-1.7B / 阿里云 ASR | ≈¥4 |
| Groq turbo | ≈¥1.4 |
| `gpt-transcribe` | ≈¥9.6 |
| 火山文件识别 | ≈¥4 |

结论：个人自用规模下**成本不是瓶颈**，不要为省几块钱牺牲识别准确率；真正要控的是「配置复杂度」和「首字延迟」。

---

## 5. 对 M1 的影响（建议，待确认）

1. **新增独立 ASR 配置**：`asr.base_url` / `asr.api_key` / `asr.model`。默认值可预填硅基流动；默认策略为「先尝试沿用对话配置，探测 `/audio/transcriptions` 失败后提示单独填写」。
2. **`AsrEngine` 实现顺序**：`SystemAsrEngine`（保底）→ `OpenAiCompatAsrEngine`（首选）→ `WhisperAsrEngine`（离线，后置）。技术设计里已有的抽象不用改，只补一个实现。
3. **录音格式**：16 kHz 单声道；单次上传 ≤ 25 MB（OpenAI 限制）/ ≤ 50 MB、≤ 1 小时（硅基流动限制）。一次按住说话远低于上限。
4. **需要词级时间戳**（发音/流利度反馈）时，只能选 Groq `verbose_json` 或本地 Whisper；SenseVoiceSmall 给不了。

---

## 6. 查证 / 推断分界

**已查证**
- aiping.cn 的平台定位、模型分类、公开文档范围（只覆盖 LLM 统一调用与路由）；
- aiping `POST /audio/transcriptions` 返回 404（M0 实测记录）；
- 硅基流动 `/v1/audio/transcriptions` 端点、模型枚举（`SenseVoiceSmall`、`TeleSpeechASR`）、价格页标价；
- Groq 的 OpenAI 兼容端点、两个 Whisper 模型、$0.111 / $0.04 每小时的官方价格与词级时间戳能力；
- OpenAI 官方定价页 `gpt-transcribe` $0.0045、`gpt-4o-transcribe` $0.006、`gpt-4o-mini-transcribe` $0.003 每分钟；
- 阿里云百炼 `qwen-audio-3.0-asr-flash` ¥0.00022/秒；火山 ¥0.8/小时（文件）与 ¥1.0/小时（流式）；讯飞 ¥1.5/小时、¥15/万次；Deepgram / AssemblyAI 公开价目。

**推断（需实测确认）**
- SenseVoiceSmall 对中式口音英语的实际识别率；
- `Qwen/Qwen3-ASR-1.7B` 是否支持硅基流动的 `/audio/transcriptions`；
- `whisper-1` 是否已正式退役（官方定价页已无该条目）；
- 腾讯云 ASR 的具体计费；
- 第 5 节的配置项设计与 M1 实现顺序。

---

## 7. 来源

- aiping.cn 平台介绍：https://aiping.cn/docs/PlatformOverview/product
- aiping.cn 智能路由文档：https://aiping.cn/docs/UserGuide/smart-routing
- aiping.cn 模型列表：https://aiping.cn/modelList
- 硅基流动语音转文本接口：https://docs.siliconflow.cn/cn/api-reference/audio/create-audio-transcriptions
- 硅基流动价格：https://siliconflow.cn/pricing
- Groq Speech to Text：https://console.groq.com/docs/speech-to-text
- Groq 价格：https://groq.com/pricing
- OpenAI API 定价：https://developers.openai.com/api/docs/pricing
- 阿里云百炼语音识别概览：https://help.aliyun.com/en/model-studio/asr-model
- 阿里云百炼模型价格：https://help.aliyun.com/zh/model-studio/model-pricing
- 火山引擎语音识别：https://www.volcengine.com/product/asr
- 讯飞实时语音转写：https://www.xfyun.cn/services/rtasr
- Deepgram 价格：https://deepgram.com/pricing
- AssemblyAI 价格：https://www.assemblyai.com/blog/speech-to-text-api-pricing
