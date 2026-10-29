@echo off
:: ==============================================================================
:: Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)
:: Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com
:: ==============================================================================
setlocal
cd /d "%~dp0"
title [ADMIN-100] Quan Ly Ma Tran Phan Quyen - TB-Toolbox
chcp 65001 >nul 2>&1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\\..\\TB-AI-Rule\\00-Admin_Security\\Manage-PermissionMatrix.ps1"
if errorlevel 1 pause
exit /b %errorlevel%
