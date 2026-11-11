@echo off
rem 启动 B 站素材配套服务（局域网 8787 端口）
cd /d "%~dp0"
"D:\program Files\conda\python.exe" server.py
pause
