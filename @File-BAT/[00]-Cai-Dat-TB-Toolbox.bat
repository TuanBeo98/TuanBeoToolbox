@echo off
setlocal
cd /d "%~dp0"
title [00] Cai Dat & Kich Hoat TB-Toolbox
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\Core\Client-Bootstrap.ps1"
exit /b
