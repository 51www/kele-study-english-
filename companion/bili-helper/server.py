# -*- coding: utf-8 -*-
"""B 站素材配套服务（kele-study-english 听写导入用）。

在电脑上运行本服务，手机 App（同一局域网）把 B 站视频地址交给本服务：
服务用 yt-dlp 拉取音频（m4a）与字幕（转成 SRT），App 再从本服务取回两份文件，
复用 App 内既有的「字幕解析 → 按句切分 → 落库」管线。

仅供个人学习使用，素材版权归原权利人。

接口：
  GET  /api/ping                    健康检查
  POST /api/bili/import             {url, cookie?} -> {jobId}
  GET  /api/bili/job/<id>           状态/进度/标题
  GET  /api/bili/job/<id>/audio     m4a 音频字节流
  GET  /api/bili/job/<id>/subtitle  SRT 字幕文本
"""

import json
import re
import shutil
import tempfile
import threading
import time
import uuid
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import requests
from flask import Flask, jsonify, request, send_file
from yt_dlp import YoutubeDL

app = Flask(__name__)

SERVICE_VERSION = "0.1.0"
JOB_TTL_SECONDS = 30 * 60  # 完成后文件保留 30 分钟，过期清理

_BILI_HOSTS = ("bilibili.com", "b23.tv")
_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
)

_jobs = {}
_lock = threading.Lock()


def _job_headers(cookie: str | None) -> dict:
    headers = {"User-Agent": _UA, "Referer": "https://www.bilibili.com/"}
    if cookie:
        headers["Cookie"] = cookie.strip()
    return headers


def _is_bili_url(url: str) -> bool:
    try:
        host = urlparse(url).hostname or ""
    except ValueError:
        return False
    host = host.lower()
    return any(host == h or host.endswith("." + h) for h in _BILI_HOSTS)


def _resolve_short_link(url: str, headers: dict) -> str:
    """b23.tv 短链先跟随跳转拿到真实地址。"""
    if "b23.tv" not in (urlparse(url).hostname or ""):
        return url
    try:
        resp = requests.get(url, headers=headers, timeout=15, allow_redirects=True)
        if resp.url and _is_bili_url(resp.url):
            return resp.url
    except requests.RequestException:
        pass
    return url


def _pick_part(url: str, info: dict) -> dict:
    """多 P 视频按 URL 里的 p= 参数选分 P，默认第一个。"""
    entry = info
    if "entries" in info:
        entries = [e for e in (info.get("entries") or []) if e]
        if not entries:
            raise RuntimeError("该视频没有可用的分 P。")
        try:
            p = int((parse_qs(urlparse(url).query).get("p") or ["1"])[0])
        except ValueError:
            p = 1
        entry = entries[min(max(p - 1, 0), len(entries) - 1)]
    return entry


def _subtitle_candidates(entry: dict):
    """人工字幕优先，其次 AI 字幕；同一来源内优先含 en 的轨道。"""
    manual = entry.get("subtitles") or {}
    auto = entry.get("automatic_captions") or {}
    for source in (manual, auto):
        keys = sorted(source.keys(), key=lambda k: ("en" not in k.lower(), k))
        for key in keys:
            for item in source[key]:
                yield key, item


def _download_subtitle(entry: dict, headers: dict) -> tuple[str, str]:
    """下载并转成 SRT，返回 (字幕文本, 轨道名)。失败返回 ('', '')。"""
    for key, item in _subtitle_candidates(entry):
        url = item.get("url")
        if not url:
            continue
        try:
            resp = requests.get(url, headers=headers, timeout=20)
            resp.raise_for_status()
            if item.get("ext") == "srt":
                return resp.text, key
            data = resp.json()
            body = data.get("body") or data.get("data", {}).get("body") or []
            srt = _json_to_srt(body)
            if srt.strip():
                return srt, key
        except (requests.RequestException, ValueError, KeyError):
            continue
    return "", ""


def _fmt_srt_time(t: float) -> str:
    t = max(t, 0.0)
    h = int(t // 3600)
    m = int(t % 3600 // 60)
    s = int(t % 60)
    ms = int(round((t - int(t)) * 1000)) % 1000
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def _json_to_srt(body: list) -> str:
    lines = []
    for i, cue in enumerate(body, start=1):
        start = cue.get("from")
        end = cue.get("to")
        text = (cue.get("content") or "").strip()
        if start is None or end is None or not text:
            continue
        lines.append(str(i))
        lines.append(f"{_fmt_srt_time(start)} --> {_fmt_srt_time(end)}")
        lines.append(text)
        lines.append("")
    return "\n".join(lines)


def _run_job(job_id: str, url: str, cookie: str | None) -> None:
    job = _jobs[job_id]
    workdir = Path(tempfile.mkdtemp(prefix="bili-helper-"))
    headers = _job_headers(cookie)
    try:
        real_url = _resolve_short_link(url, headers)
        if not _is_bili_url(real_url):
            raise RuntimeError("只支持 B 站视频地址（bilibili.com / b23.tv）。")

        job["stage"] = "解析视频信息"
        ydl_info_opts = {
            "quiet": True,
            "no_warnings": True,
            "noplaylist": True,
            "http_headers": headers,
            "socket_timeout": 30,
        }
        with YoutubeDL(ydl_info_opts) as ydl:
            info = ydl.extract_info(real_url, download=False)
        entry = _pick_part(real_url, info)
        job["title"] = entry.get("title") or job["title"]
        duration = entry.get("duration")
        job["durationSec"] = int(duration) if duration else None

        sub_text, sub_lang = _download_subtitle(entry, headers)
        if not sub_text:
            raise RuntimeError(
                "没有拿到可用字幕（很多视频的 CC/AI 字幕需要登录 Cookie）。"
                "请在 App 设置里填入 B 站 Cookie 后重试。"
            )
        (workdir / "subtitle.srt").write_text(sub_text, encoding="utf-8")
        job["subLang"] = sub_lang
        job["progress"] = 0.08
        job["stage"] = "下载音频"

        def hook(d):
            if d.get("status") == "downloading":
                total = d.get("total_bytes") or d.get("total_bytes_estimate") or 0
                done = d.get("downloaded_bytes") or 0
                if total > 0:
                    job["progress"] = 0.08 + min(done / total, 1.0) * 0.84
            elif d.get("status") == "finished":
                job["progress"] = 0.95
                job["stage"] = "整理文件"

        ydl_opts = {
            "format": "bestaudio[ext=m4a]/bestaudio",
            "outtmpl": str(workdir / "audio.%(ext)s"),
            "quiet": True,
            "no_warnings": True,
            "noplaylist": True,
            "http_headers": headers,
            "socket_timeout": 30,
            "progress_hooks": [hook],
        }
        with YoutubeDL(ydl_opts) as ydl:
            ydl.download([entry.get("webpage_url") or real_url])

        audio_files = [f for f in workdir.glob("audio.*") if f.is_file()]
        if not audio_files:
            raise RuntimeError("音频下载失败，未生成本地文件。")
        job["audioFile"] = str(audio_files[0])
        job["audioExt"] = audio_files[0].suffix.lstrip(".").lower() or "m4a"
        job["subtitleFile"] = str(workdir / "subtitle.srt")
        job["state"] = "done"
        job["progress"] = 1.0
        job["stage"] = "完成"
    except Exception as e:  # noqa: BLE001 - 任务线程内兜底，错误回传给 App
        job["state"] = "error"
        job["error"] = str(e)
        shutil.rmtree(workdir, ignore_errors=True)


def _sweep_expired() -> None:
    now = time.time()
    expired = [
        jid
        for jid, job in _jobs.items()
        if job["state"] in ("done", "error")
        and job.get("finishedAt")
        and now - job["finishedAt"] > JOB_TTL_SECONDS
    ]
    for jid in expired:
        job = _jobs.pop(jid, None)
        if job:
            d = job.get("workdir")
            if d:
                shutil.rmtree(d, ignore_errors=True)


@app.get("/api/ping")
def ping():
    return jsonify({"ok": True, "version": SERVICE_VERSION})


@app.post("/api/bili/import")
def create_import():
    body = request.get_json(silent=True) or {}
    url = (body.get("url") or "").strip()
    cookie = (body.get("cookie") or "").strip() or None
    if not url:
        return jsonify({"error": "缺少视频地址。"}), 400
    if not _is_bili_url(url):
        return jsonify({"error": "只支持 B 站视频地址（bilibili.com / b23.tv）。"}), 400

    _sweep_expired()
    job_id = uuid.uuid4().hex[:12]
    with _lock:
        _jobs[job_id] = {
            "id": job_id,
            "state": "running",
            "stage": "排队中",
            "progress": 0.0,
            "title": "",
            "durationSec": None,
            "subLang": "",
            "error": "",
            "workdir": None,
            "audioFetched": False,
            "subtitleFetched": False,
            "finishedAt": None,
            "created": time.time(),
        }
    threading.Thread(
        target=_run_job, args=(job_id, url, cookie), daemon=True
    ).start()
    return jsonify({"jobId": job_id})


def _get_job_or_404(job_id: str):
    job = _jobs.get(job_id)
    if job is None:
        return None, (jsonify({"error": "任务不存在或已过期，请重新发起导入。"}), 404)
    return job, None


@app.get("/api/bili/job/<job_id>")
def job_status(job_id: str):
    job, err = _get_job_or_404(job_id)
    if err:
        return err[1]
    return jsonify(
        {
            "jobId": job["id"],
            "state": job["state"],
            "progress": round(job["progress"], 3),
            "stage": job["stage"],
            "title": job["title"],
            "durationSec": job["durationSec"],
            "subLang": job["subLang"],
            "audioExt": job.get("audioExt") or "m4a",
            "error": job["error"],
        }
    )


def _finish_fetch(job: dict, kind: str) -> None:
    job[f"{kind}Fetched"] = True
    if job["audioFetched"] and job["subtitleFetched"]:
        shutil.rmtree(job.get("workdir") or "", ignore_errors=True)
        _jobs.pop(job["id"], None)


@app.get("/api/bili/job/<job_id>/audio")
def job_audio(job_id: str):
    job, err = _get_job_or_404(job_id)
    if err:
        return err[1]
    if job["state"] != "done":
        return jsonify({"error": "任务尚未完成。"}), 409
    path = Path(job["audioFile"])
    if not path.is_file():
        return jsonify({"error": "音频文件已失效，请重新发起导入。"}), 410
    ext = job["audioExt"]
    mime = "audio/mp4" if ext in ("m4a", "mp4") else "application/octet-stream"
    resp = send_file(path, mimetype=mime, as_attachment=True, download_name=f"audio.{ext}")
    _finish_fetch(job, "audio")
    return resp


@app.get("/api/bili/job/<job_id>/subtitle")
def job_subtitle(job_id: str):
    job, err = _get_job_or_404(job_id)
    if err:
        return err[1]
    if job["state"] != "done":
        return jsonify({"error": "任务尚未完成。"}), 409
    path = Path(job["subtitleFile"])
    if not path.is_file():
        return jsonify({"error": "字幕文件已失效，请重新发起导入。"}), 410
    resp = send_file(
        path,
        mimetype="text/plain; charset=utf-8",
        as_attachment=True,
        download_name="subtitle.srt",
    )
    _finish_fetch(job, "subtitle")
    return resp


def main() -> None:
    print("B 站配套服务已启动：http://0.0.0.0:8787（局域网内 App 可访问）")
    app.run(host="0.0.0.0", port=8787, threaded=True)


if __name__ == "__main__":
    main()
