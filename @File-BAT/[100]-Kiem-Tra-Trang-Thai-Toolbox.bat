@echo off
setlocal
cd /d "%~dp0"
title [100] Kiem Tra Trang Thai Toolbox - Mr. Tuan Beo
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\Engine\Core\Client-Bootstrap.ps1" -StatusOnly
if errorlevel 1 pause
exit /b