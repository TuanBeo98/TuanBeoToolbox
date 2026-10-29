@echo off
setlocal
cd /d "%~dp0"
title [500] Don Dep Bo Nho Tam He Thong - TuanBeo Toolbox
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\Engine\Core\Engine-Cleaner.ps1"
exit /b
