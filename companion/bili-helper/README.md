# B 站素材配套服务（bili-helper）

手机 App「B 站导入」的配套后端：用 yt-dlp 拉取 B 站视频的音频（m4a）与字幕（转 SRT），
App 从本服务取回两份文件后，走既有的「字幕解析 → 按句切分 → 落库」管线生成听写教材。

仅供个人学习使用，素材版权归原权利人；请只导入你有权使用的 内容。

## 启动

```powershell
cd companion/bili-helper
pip install -r requirements.txt
python server.py
```

或双击 `start.bat`（已按本机 conda Python 路径写好）。服务监听 `0.0.0.0:8787`。

## App 侧配置

1. 设置 → 听写练习 →「B 站导入」分区：
   - 服务地址：填电脑的局域网地址，如 `http://192.168.1.5:8787`；
   - B 站 Cookie：从浏览器登录 B 站后复制（至少包含 `SESSDATA=...`，可整段粘贴）。
     很多视频的 CC / AI 字幕必须登录后才能拿到，不填则只能拿公开字幕。
2. 手机与电脑需在同一局域网；Windows 防火墙首次启动需放行 Python。

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
