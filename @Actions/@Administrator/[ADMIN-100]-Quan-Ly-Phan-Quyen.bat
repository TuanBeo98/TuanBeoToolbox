:: [TUANBEO-ADMIN-GATEKEEPER]
@echo off
:: ==============================================================================
:: Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)
:: Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com
:: ==============================================================================
setlocal
cd /d "%~dp0"
title [ADMIN-100] Quan Ly Ma Tran Phan Quyen - TB-Toolbox
chcp 65001 >nul 2>&1
cls

:: [BẢO VỆ ĐẶC QUYỀN ADMIN]: Xác thực Mật khẩu Admin hiện tại
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { . '..\..\Engine\Core\Admin-PasswordManager.ps1'; if (-not (Confirm-AdminAccess -ActionTitle '[ADMIN-100] QUẢN LÝ MA TRẬN PHÂN QUYỀN')) { exit 1 } }"
if errorlevel 1 exit /b 1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\..\TB-AI-Rule\00-Admin_Security\Manage-PermissionMatrix.ps1"
if errorlevel 1 pause
exit /b %errorlevel%