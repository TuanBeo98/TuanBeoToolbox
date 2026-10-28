@echo off
setlocal
cd /d "%~dp0"
title [ADMIN-04] Quan Ly Ma Tran Phan Quyen - TB-Toolbox
chcp 65001 >nul 2>&1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "..\\..\\00-Admin_Security\\Manage-PermissionMatrix.ps1"
if errorlevel 1 pause
exit /b %errorlevel%
