@echo off
:: ==============================================================================
:: Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)
:: Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com
:: ==============================================================================
setlocal
cd /d "%~dp0"
title [ADMIN-201] Quan Ly Va Tao Key Ban Quyen - Mr. DAO XUAN TUAN (Tuan Beo)
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\..\Engine\Core\Admin-KeyManager.ps1"
exit /b
