:: [TUANBEO-ADMIN-GATEKEEPER]
@echo off
:: ==============================================================================
:: Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)
:: Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com
:: ==============================================================================
setlocal
cd /d "%~dp0"
title [ADMIN-000] Quan Ly Va Doi Mat Khau Admin - TB-Toolbox
chcp 65001 >nul 2>&1
cls
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\..\Engine\Core\Admin-PasswordManager.ps1"
if errorlevel 1 pause
exit /b %errorlevel%