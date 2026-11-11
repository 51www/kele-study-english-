# -*- coding: utf-8 -*-
"""配套服务 Cookie 处理单测（纯本地，不发起网络请求）。

运行：cd companion/bili-helper && python3 -m unittest -v test_cookiefile
"""
import io
import tempfile
import time
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest import mock

from yt_dlp import YoutubeDL

import server


class CookieFileTest(unittest.TestCase):
    def test_no_cookie_creates_no_file(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertIsNone(server._write_cookiefile(None, Path(d)))
            self.assertIsNone(server._write_cookiefile("   ", Path(d)))
            self.assertFalse((Path(d) / "cookies.txt").exists())

    def test_cookie_header_parsed_and_loadable_by_ytdlp(self):
        with tempfile.TemporaryDirectory() as d:
            path = server._write_cookiefile(
                "Cookie: SESSDATA=abc==; bili_jct=xyz; ; DedeUserID=123",
                Path(d),
            )
            self.assertIsNotNone(path)
            text = Path(path).read_text(encoding="utf-8")
            self.assertTrue(text.startswith("# Netscape HTTP Cookie File"))
            self.assertIn("SESSDATA\tabc==", text)
            self.assertIn(".bilibili.com\tTRUE\t/", text)

            with YoutubeDL({"cookiefile": path, "quiet": True}) as ydl:
                names = {c.name for c in ydl.cookiejar}
            self.assertEqual(names, {"SESSDATA", "bili_jct", "DedeUserID"})

    def test_full_browser_cookie_header_keeps_special_chars(self):
        """整段浏览器 Cookie 头：URL 编码、引号、括号、JWT 点号都原样保留。"""
        sample = (
            "buvid3=AAAA1111-BBBB-2222-CCCC-3333infoc; b_nut=1000000000; "
            "buvid4=1111-2222-3333-abcd%3D%3D; DedeUserID=12345678; "
            "rpdid=|(YYJ~Y)~u)0J'u~)~R~RkR~; "
            "default_sites=%5B%22CN%22%2C%22OVERSEAS%22%5D; "
            "SESSDATA=11111111%2C2222222222%2Cabc%2Adef_GHI; "
            "bili_jct=0123456789abcdef0123456789abcdef; "
            "bili_ticket=eyJhbGciOiJIUzI1NiJ9.abc-def_ghi.JKL-MNO_123; "
            "b_lsid=5D97FAA6_1A1CAB664CD"
        )
        with tempfile.TemporaryDirectory() as d:
            path = server._write_cookiefile(sample, Path(d))
            with YoutubeDL({"cookiefile": path, "quiet": True}) as ydl:
                jar = {c.name: c.value for c in ydl.cookiejar}
            self.assertEqual(len(jar), 10)
            self.assertEqual(jar["SESSDATA"], "11111111%2C2222222222%2Cabc%2Adef_GHI")
            self.assertEqual(jar["rpdid"], "|(YYJ~Y)~u)0J'u~)~R~RkR~")
            self.assertEqual(jar["bili_ticket"], "eyJhbGciOiJIUzI1NiJ9.abc-def_ghi.JKL-MNO_123")
            self.assertEqual(jar["buvid4"], "1111-2222-3333-abcd%3D%3D")

    def test_ydl_opts_never_put_cookie_in_headers(self):
        headers = server._job_headers("SESSDATA=abc")
        self.assertEqual(headers["Cookie"], "SESSDATA=abc")

        with tempfile.TemporaryDirectory() as d:
            path = server._write_cookiefile("SESSDATA=abc", Path(d))
            opts = server._ydl_auth_opts(headers, path)
            self.assertNotIn("Cookie", opts["http_headers"])
            self.assertEqual(opts["http_headers"]["User-Agent"], server._UA)
            self.assertEqual(opts["cookiefile"], path)

            no_cookie = server._ydl_auth_opts(headers, None)
            self.assertNotIn("Cookie", no_cookie["http_headers"])
            self.assertNotIn("cookiefile", no_cookie)

    def test_no_deprecated_feature_warning(self):
        with tempfile.TemporaryDirectory() as d:
            path = server._write_cookiefile("SESSDATA=abc", Path(d))
            opts = server._ydl_auth_opts(server._job_headers("SESSDATA=abc"), path)
            err = io.StringIO()
            with redirect_stderr(err):
                with YoutubeDL({**opts, "quiet": True, "no_warnings": True}):
                    pass
            self.assertNotIn("Deprecated Feature", err.getvalue())

    def test_finish_fetch_removes_cookie_file(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / "cookies.txt").write_text("SESSDATA=abc")
            job = {
                "id": "unit-test-job",
                "audioFetched": True,
                "subtitleFetched": False,
                "workdir": d,
            }
            server._finish_fetch(job, "subtitle")
            self.assertFalse(Path(d).exists())

    def test_sweep_expired_removes_abandoned_cookie_file(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / "cookies.txt").write_text("SESSDATA=abc")
            job_id = "unit-test-expired"
            server._jobs[job_id] = {
                "id": job_id,
                "state": "done",
                "finishedAt": time.time() - server.JOB_TTL_SECONDS - 1,
                "workdir": d,
            }
            server._sweep_expired()
            self.assertFalse(Path(d).exists())
            self.assertNotIn(job_id, server._jobs)

    def test_ydl_info_opts_enables_subtitle_extraction(self):
        """未开启 writesubtitles 时 yt-dlp 的 extract_subtitles 直接返回空 dict。"""
        opts = server._ydl_info_opts(server._ydl_auth_opts({"User-Agent": "x"}, None))
        self.assertTrue(opts["writesubtitles"])
        self.assertTrue(opts["writeautomaticsub"])
        self.assertNotIn("Cookie", opts["http_headers"])

    def test_bili_subtitle_entry_uses_inline_data(self):
        """B 站 CC/AI 字幕条目只有 data 没有 url，必须直接取用；弹幕要跳过。"""
        srt = "1\n00:00:00,000 --> 00:00:02,000\nhello world\n\n"
        entry = {
            "subtitles": {
                "danmaku": [{"ext": "xml", "url": "https://comment.bilibili.com/1.xml"}],
                "ai-zh": [{"ext": "srt", "data": srt}],
            },
            "automatic_captions": {},
        }
        text, lang, reasons = server._download_subtitle([entry], {"User-Agent": "x"})
        self.assertEqual(text, srt)
        self.assertEqual(lang, "ai-zh")
        self.assertEqual(reasons, [])
        self.assertEqual(server._track_names([entry]), ["ai-zh"])

    def test_danmaku_only_reports_no_subtitle(self):
        entry = {
            "subtitles": {"danmaku": [{"ext": "xml", "url": "https://comment.bilibili.com/1.xml"}]},
            "automatic_captions": {},
        }
        text, lang, reasons = server._download_subtitle([entry], {})
        self.assertEqual((text, lang, reasons), ("", "", []))
        self.assertEqual(server._track_names([entry]), [])

    def test_protocol_relative_url_fallback(self):
        srt = "1\n00:00:00,000 --> 00:00:01,000\nhi\n\n"
        entry = {"subtitles": {"en": [{"ext": "srt", "url": "//i0.hdslb.com/a.srt"}]}}
        with mock.patch.object(server.requests, "get") as get:
            get.return_value.raise_for_status.return_value = None
            get.return_value.text = srt
            text, lang, reasons = server._download_subtitle([entry], {})
        self.assertEqual(text, srt)
        self.assertEqual(get.call_args[0][0], "https://i0.hdslb.com/a.srt")


if __name__ == "__main__":
    unittest.main()
