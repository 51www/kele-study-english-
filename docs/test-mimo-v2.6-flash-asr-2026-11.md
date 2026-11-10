# MiMo-V2.6-Flash 语音识别实测记录（2026-11-10）

> 目的：确认 aiping.cn 上的 `MiMo-V2.6-Flash` 能否作为 kele-study-english M1 的识别引擎。
> 密钥仅在测试命令中临时使用，未写入本文件、仓库任何文件或截图。
> 本文是实测记录，不改动需求文档与技术设计主体。

---

## 1. 结论

| 问题 | 结论 |
|---|---|
| 模型是否存在 | 存在，模型 ID 就是 `MiMo-V2.6-Flash` |
| 能否处理音频 | **能**，但只能走 `/chat/completions` 的 `input_audio`（base64） |
| 标准 `/audio/transcriptions` | **404，不支持** |
| 转写结果 | 准确（干净英文语音），但**输出位置不稳定**：普通指令下结果落在 `reasoning_content`，`content` 为空 |
| 词级时间戳 | **没有** |
| 延迟 | 5.3 秒音频：非流式 3.8–5.8 秒；流式首字节 1.56 秒、总 4.06 秒 |
| 是否可作 M1 引擎 | **可作实验性备选，不建议作默认** |
| aiping 上的独立 ASR 模型 | **没有**（140 个模型中只有 `MiniMax-Speech-*` 两个 TTS） |

---

## 2. 模型与协议查证

- `GET /models` 返回 140 个模型，匹配 `mimo|asr|whisper|transcri|audio|speech|voice|tts` 的只有：`MiniMax-Speech-2.8-hd`、`MiniMax-Speech-02-hd`、`MiMo-V2.6-Flash`、`MiMo-V2.6-Pro`。
- 模型详情页：`MiMo-V2.6-Flash`，977K 上下文，¥1.00/M 输入、¥2.00/M 输出、¥0.02/M 缓存；兼容协议为 OpenAI Chat Completions 与 Anthropic Messages；服务商 UCloud、金山云星流。
- `POST /audio/transcriptions`（multipart，`model=MiMo-V2.6-Flash`）→ `{"detail":"Not Found"}`，HTTP 404。
- 音频只能塞进 `/chat/completions` 的 `input_audio` 内容块，实测可用。

---

## 3. 可复跑请求

测试音频：系统 TTS 合成 5.3 秒英文，转 16 kHz 单声道 MP3（43 KB）。

```bash
BASE=https://aiping.cn/api/v1
KEY=$AIPING_KEY

curl -s "$BASE/chat/completions" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "MiMo-V2.6-Flash",
    "max_tokens": 300,
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "Listen to the audio. Return ONLY this JSON: {\"text\":\"<exact words the speaker said>\"}"},
        {"type": "input_audio", "input_audio": {"data": "<BASE64_MP3>", "format": "mp3"}}
      ]
    }]
  }'
```

- `input_audio.format` 实测用 `mp3`；`wav` 未测（未核实）。
- 请求体大小 ≈ 音频字节 × 1.33（base64 膨胀），5.3 秒音频约 58 KB。

---

## 4. 实测结果

音频原文：`Hi, I would like a medium latte with oat milk, please.`

| # | 指令 | `content` | `reasoning_content` | 耗时 |
|---|---|---|---|---|
| 1 | `Transcribe the following English audio verbatim. Output the transcript only.` | **空** | 完整转写 | 4.24 s |
| 2 | 加 system：「你是语音转文字引擎，只输出转写」 | **空** | 完整转写 | 5.83 s |
| 3 | `What drink did the customer order?` | `The customer ordered a medium latte with oat milk.` | 推理过程 | 4.15 s |
| 4 | `Return ONLY this JSON: {"text":"..."}` | ` ```json {"text":"Hi, I would like a medium latte with oat milk, please."} ``` ` | 推理过程 | 3.78 s |
| 5 | 同 #4，`stream=true` | 流式，先 reasoning 后 content | — | 首字节 1.56 s，总 4.06 s |

`usage` 参考：5.3 秒音频计 `audio_tokens = 34`；第 4 次 `completion_tokens = 88`（其中 reasoning 63）。

**转写准确率**：干净 TTS 英文一次即中，无漏词、无改写。真人带口音的表现未测（未核实）。

**成本估算**：34 audio tokens / 5.3 秒 ≈ 385 tokens/分钟；按 ¥1/M 输入计 ≈ ¥0.0004/分钟（约 ¥0.02/小时）。实际计费口径以平台账单为准（未核实）。

**时间戳**：无 `words` / `segments` 字段，拿不到词级时间戳。

---

## 5. 接入成本与限制

**要接进 M1，需要额外做的事**
1. `AsrEngine` 增加一个 `ChatAudioAsrEngine`：录音 → MP3/16 kHz → base64 → 拼 `content` 数组 → 解析。
2. 提示词必须写成「输出 JSON」这类强制格式，否则 `content` 可能为空、结果只出现在 `reasoning_content`。
3. 返回可能被 ` ```json ` 代码块包裹，需要剥离围栏再解析。
4. 结果为空时要回退读 `reasoning_content`（这是模型的思考内容，不是稳定契约）。

**与专用 ASR 的差距**
- 协议非标准：不能复用标准 OpenAI 转写客户端，也不兼容硅基流动/Groq/OpenAI 的 `/audio/transcriptions`。
- 延迟 4–6 秒，明显高于专用 ASR；M1 的「识别中」状态会停留较久。
- 无词级时间戳，后续做发音/流利度反馈用不上。
- 输出结构依赖提示词，属于推断性契约，模型升级可能变。

**优势**
- 无需再申请第二家 key，复用现有 aiping 配置即可跑通语音闭环。
- 成本几乎为零；顺带具备「听音频回答问题」的能力，未来可做听力理解题。

---

## 6. 建议

- **M1 默认仍走系统 ASR 或硅基流动 `SenseVoiceSmall`**（标准协议、低延迟、免费）。
- `MiMo-V2.6-Flash` 作为**实验性第三方引擎**接入：设置页给一个「用对话模型做识别（实验）」开关，默认关闭。
- 若接入，配置为：`asr.base_url = https://aiping.cn/api/v1`、`asr.model = MiMo-V2.6-Flash`、协议 `chat+input_audio`、提示词固定为 JSON 模板、`max_tokens = 300`。
- 不建议把「读 `reasoning_content`」写成主路径；它只是兜底。

---

## 7. 未核实项

- `input_audio.format` 是否支持 `wav` / `m4a`；
- 真人带口音、噪声环境下的识别准确率；
- audio token 与实际账单金额的换算口径；
- 模型升级后 `content` / `reasoning_content` 的行为是否变化；
- aiping 是否计划上线独立 ASR 模型。
