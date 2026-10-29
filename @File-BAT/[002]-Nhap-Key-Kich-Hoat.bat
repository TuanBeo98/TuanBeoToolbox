@echo off
setlocal
cd /d "%~dp0"
title [002] Nhap Key & Kich Hoat Ban Quyen - TB-Toolbox
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\Engine\Core\Client-Bootstrap.ps1"
if errorlevel 1 pause
exit /b