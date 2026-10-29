@echo off
setlocal
cd /d "%~dp0"
title [501] Hen Gio Tat May Va Quan Ly Nguon - TuanBeo Toolbox
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\Engine\Core\Engine-PowerManager.ps1"
exit /b
