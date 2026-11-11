# B 站素材配套服务（bili-helper）

手机 App「B 站导入」的配套后端：用 yt-dlp 拉取 B 站视频的音频（m4a）与字幕（转 SRT），
App 从本服务取回两份文件后，走既有的「字幕解析 → 按句切分 → 落库」管线生成听写教材。

仅供个人学习使用，素材版权归原权利人；请只导入你有权使用的 内容。

## 启动

macOS / Linux：

```bash
cd companion/bili-helper
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 server.py
```

Windows（PowerShell）：

```powershell
cd companion/bili-helper
pip install -r requirements.txt
python server.py
```

或双击 `start.bat`（已按本机 conda Python 路径写好）。服务监听 `0.0.0.0:8787`；
在本机浏览器打开 `http://127.0.0.1:8787/api/ping` 能看到 `{"ok": true, ...}` 即启动成功。

## App 侧配置

1. 设置 → 听写练习 →「B 站导入」分区：
   - 服务地址：填电脑的局域网地址，如 `http://192.168.1.5:8787`；
   - B 站 Cookie：从浏览器登录 B 站后复制（至少包含 `SESSDATA=...`，可整段粘贴，也可带 `Cookie:` 前缀）。
     很多视频的 CC / AI 字幕必须登录后才能拿到，不填则只能拿公开字幕。
     输入框是多行的，整段不会被截断；`%2C` / `%2A` 等 URL 编码请原样保留，不要手动解码。
     Cookie 会以明文 HTTP 从手机发到电脑上的服务，**建议只填必要字段**（`SESSDATA`、`bili_jct`、
     `DedeUserID`；遇到风控再补 `buvid3` / `buvid4` / `bili_ticket`），不要连带粘贴无关的浏览偏好 Cookie。
     完整 Cookie 等同于账号登录态，请勿贴到公开渠道或提交到仓库，泄露后去 B 站退出登录使其失效。
2. 手机与电脑需在同一局域网；Windows 防火墙首次启动需放行 Python。

## Cookie 处理

新版 yt-dlp 已弃用把 Cookie 放进 HTTP 请求头（会打印 `Deprecated Feature` 告警，且 Cookie 会被限定到下载链接的域）。服务端做法是：

- 取字幕接口仍用带 Cookie 的请求头直接请求 B 站；
- yt-dlp 侧把 Cookie 转成任务临时目录内的 Netscape 格式 `cookies.txt`，按 `.bilibili.com` 作用域交给 `cookiefile` 参数；
- `cookies.txt` 不写日志、不持久化：音频与字幕被 App 取走后或任务报错时立即随临时目录删除，未被取走的会在下一次发起导入时按 30 分钟过期清理。

服务只监听你自己的电脑；Cookie 属敏感信息，请勿把服务暴露到公网。

## 字幕要求与排错

B 站导入依赖视频自带 **CC 人工字幕或 AI 字幕**：

- 先在 B 站网页端打开该视频，播放器里能看到「字幕」开关并能列出轨道再导入。很多视频本身没有字幕，此时换一个视频即可。
- 未登录时 B 站字幕接口不下发 CC / AI 字幕列表，所以必须填有效的 `SESSDATA`；服务用 `writesubtitles` 让 yt-dlp 请求字幕信息，字幕文本由 yt-dlp 转成 SRT（条目里是 `data` 而不是 `url`）。
- 失败时 App 的错误提示会带上「是否收到 Cookie / Cookie 是否已登录 / yt-dlp 返回了哪些轨道 / 各轨道失败原因」，据此区分是 Cookie 失效还是视频无字幕。

## 接口

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/ping` | 健康检查，返回 `{ok, version}` |
| POST | `/api/bili/import` | body `{url, cookie?}` → `{jobId}` |
| GET | `/api/bili/job/<id>` | `{state: running\|done\|error, progress, stage, title, durationSec, subLang, error}` |
| GET | `/api/bili/job/<id>/audio` | m4a 音频字节流 |
| GET | `/api/bili/job/<id>/subtitle` | SRT 字幕文本 |

多 P 视频按 URL 里的 `p=` 参数取对应分 P，默认第一个；b23.tv 短链自动跟随跳转。
音频与字幕被 App 取走后本地临时文件即清理；任务完成后未取走也只保留 30 分钟。
