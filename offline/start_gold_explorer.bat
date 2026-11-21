@echo off
title Gold Explorer (offline)
cd /d "%~dp0"
echo Starting Gold Explorer. The browser opens by itself. Close this window to stop it.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
echo.
pause
