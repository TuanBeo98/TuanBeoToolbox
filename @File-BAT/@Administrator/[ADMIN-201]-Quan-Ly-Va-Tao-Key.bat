@echo off
setlocal
cd /d "%~dp0"
title [ADMIN-201] Quan Ly & Tao Key Ban Quyen TB-Toolbox - Mr. Tuan Beo
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\..\Engine\Core\Admin-KeyManager.ps1"
exit /b
