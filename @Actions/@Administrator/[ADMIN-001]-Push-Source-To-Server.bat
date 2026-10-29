@echo off
:: ==============================================================================
:: Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)
:: Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com
:: ==============================================================================
setlocal
cd /d "%~dp0"
title [ADMIN-001] Day TB-Toolbox Len Server - Mr. DAO XUAN TUAN (Tuan Beo)
chcp 65001 >nul 2>&1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\..\Engine\Core\Push-ToolboxToServer.ps1"
if errorlevel 1 pause
exit /b %errorlevel%