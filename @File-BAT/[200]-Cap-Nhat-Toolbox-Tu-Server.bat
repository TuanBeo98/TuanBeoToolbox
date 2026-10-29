@echo off
setlocal
cd /d "%~dp0"
title [200] Cap Nhat TB-Toolbox Tu Server - Mr. Tuan Beo
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\Engine\Core\Server-Sync.ps1"
if errorlevel 1 pause
exit /b