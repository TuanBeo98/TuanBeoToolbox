@echo off
setlocal
cd /d "%~dp0"
title [000] Kiem Tra Moi Truong & Giai Phong Chan - TB-Toolbox
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\Engine\Core\Audit-Environment.ps1"
if errorlevel 1 pause
exit /b
