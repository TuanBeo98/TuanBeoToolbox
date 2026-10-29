@echo off
setlocal
cd /d "%~dp0"
title [ADMIN-001] Day TB-Toolbox Len Server GitHub - TuanBeo
chcp 65001 >nul 2>&1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\..\Engine\Core\Push-ToolboxToServer.ps1"
if errorlevel 1 pause
exit /b %errorlevel%