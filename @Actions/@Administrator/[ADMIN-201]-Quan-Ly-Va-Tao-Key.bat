:: [TUANBEO-ADMIN-GATEKEEPER]
@echo off
:: ==============================================================================
:: Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)
:: Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com
:: ==============================================================================
setlocal
cd /d "%~dp0"
title [ADMIN-201] Quan Ly Va Tao Key Ban Quyen - Mr. DAO XUAN TUAN (Tuan Beo)
chcp 65001 >nul 2>&1
cls

:: [BẢO VỆ ĐẶC QUYỀN ADMIN]: Xác thực Mật khẩu Admin hiện tại
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { . '..\..\Engine\Core\Admin-PasswordManager.ps1'; if (-not (Confirm-AdminAccess -ActionTitle '[ADMIN-201] QUẢN LÝ VÀ TẠO KEY BẢN QUYỀN')) { exit 1 } }"
if errorlevel 1 exit /b 1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\..\Engine\Core\Admin-KeyManager.ps1"
if errorlevel 1 pause
exit /b