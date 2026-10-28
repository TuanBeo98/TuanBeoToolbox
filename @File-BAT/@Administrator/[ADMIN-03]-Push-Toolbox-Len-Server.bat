@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion
title [ADMIN-03] Push TB-Toolbox To Server GitHub - TuanBeo

:: ========================================================================================
:: 0. KHOI TAO MA MAU ANSI
:: ========================================================================================
set "ESC="
set "C_RESET=%ESC%[0m"
set "C_BLUE=%ESC%[96m"
set "C_ORANGE=%ESC%[38;5;208m"
set "C_YELLOW=%ESC%[93m"
set "C_GREEN=%ESC%[92m"
set "C_RED=%ESC%[91m"
set "C_WHITE=%ESC%[97m"
set "C_GRAY=%ESC%[90m"

:: Mau sac doc ton sieu noi bat danh rieng cho vung Nguoi dung nhap lieu (Neon Magenta & Electric Gold)
set "C_INPUT_PROMPT=%ESC%[1;38;2;255;0;255m"
set "C_INPUT_TEXT=%ESC%[1;38;2;255;255;0m"

:: ========================================================================================
:: 1. CHUYEN VE THU MUC CHUA FILE BAT VA TIM GOC REPO GIT
:: ========================================================================================
cd /d "%~dp0"

for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do (
    cd /d "%%i"
)

if not exist ".git" goto :CHECK_PARENT_GIT
goto :GIT_ROOT_OK

:CHECK_PARENT_GIT
if exist "%~dp0..\..\.git" (
    cd /d "%~dp0..\.."
    goto :GIT_ROOT_OK
)
if exist "%~dp0..\.git" (
    cd /d "%~dp0.."
    goto :GIT_ROOT_OK
)
cls
echo %C_RED%========================================================================================%C_RESET%
echo %C_RED%         [XXX] LOI NGHIEM TRONG: KHONG TIM THAY THU MUC GIT [.git]%C_RESET%
echo %C_ORANGE%               Thu muc hien tai: %CD%%C_RESET%
echo %C_RED%========================================================================================%C_RESET%
echo %C_RED%  TIEN TRINH: [-------------------------]   0%% - THAT BAI [Thieu thu muc .git]%C_RESET%
echo %C_RED%========================================================================================%C_RESET%
echo.
pause
exit /b 1

:GIT_ROOT_OK
:: Tu dong them thu muc vao safe.directory
git config --global --add safe.directory "%CD%" 2>nul

:: Lay ten nhanh hien tai
for /f "tokens=*" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%b"
if "!CURRENT_BRANCH!"=="" set "CURRENT_BRANCH=main"

cls
echo %C_BLUE%========================================================================================%C_RESET%
echo %C_BLUE%                      [ADMIN-03] PUSH TB-TOOLBOX LEN SERVER GITHUB (TuanBeoToolbox)%C_RESET%
echo %C_BLUE%========================================================================================%C_RESET%
echo %C_BLUE%  * Thu muc lam viec  : %C_WHITE%%CD%%C_RESET%
echo %C_BLUE%  * Nhanh Git hien tai: %C_WHITE%!CURRENT_BRANCH!%C_RESET%
echo %C_BLUE%========================================================================================%C_RESET%
echo.

:: ========================================================================================
:: 2. QUET VA NAP TEP TIN THAY DOI (LOAD FILE ANIMATION & TASKBAR 25%)
:: ========================================================================================
echo %C_BLUE%[1/4] DANG QUET VA NAP DANH SACH TEP TIN THAY DOI...%C_RESET%

set "TOTAL_FILES=0"
for /f "delims=" %%c in ('git status --porcelain 2^>nul') do (
    set /a TOTAL_FILES+=1
)

if %TOTAL_FILES% equ 0 goto :CHECK_EXISTING_COMMITS

echo %C_GRAY%----------------------------------------------------------------------------------------%C_RESET%
echo %C_BLUE%  TIM THAY %C_ORANGE%!TOTAL_FILES!%C_BLUE% TEP TIN THAY DOI - DANG NAP VAO HE THONG...%C_RESET%
echo %C_GRAY%----------------------------------------------------------------------------------------%C_RESET%

set "CURR_INDEX=0"
for /f "tokens=1,* delims= " %%a in ('git status -s 2^>nul') do (
    set /a CURR_INDEX+=1
    set "FILE_TAG=%%a"
    set "FILE_NAME=%%b"
    
    set "TAG_NAME=%C_ORANGE%[CHINH SUA]%C_RESET%"
    if "!FILE_TAG!"=="??" set "TAG_NAME=%C_GREEN%[THEM MOI ]%C_RESET%"
    if "!FILE_TAG!"=="D"  set "TAG_NAME=%C_RED%[DA XOA   ]%C_RESET%"
    if "!FILE_TAG!"=="R"  set "TAG_NAME=%C_YELLOW%[DOI TEN  ]%C_RESET%"
    
    echo  %C_BLUE% [!CURR_INDEX!/!TOTAL_FILES!]%C_RESET% !TAG_NAME! %C_WHITE%!FILE_NAME!%C_RESET% %C_GREEN%[DA NAP]%C_RESET%
)

echo %C_GRAY%----------------------------------------------------------------------------------------%C_RESET%
echo %C_GREEN%  TIEN TRINH NAP: [?????????????????????????] 100%% - DA NAP TRON VEN !TOTAL_FILES!/!TOTAL_FILES! TEP TIN%C_RESET%
echo %C_BLUE%========================================================================================%C_RESET%
echo.
goto :PROCESS_STAGING

:CHECK_EXISTING_COMMITS
git log origin/!CURRENT_BRANCH!..HEAD --oneline 2>nul | findstr /R "." >nul
if errorlevel 1 goto :ALL_CLEAN
echo %C_ORANGE%[*] Khong co tep moi thay doi, nhung co commit o Local chua day len GitHub.%C_RESET%
goto :DO_PUSH

:ALL_CLEAN
echo %C_BLUE%========================================================================================%C_RESET%
echo %C_BLUE% [---] THONG BAO: KHONG CO BAT KY TEP TIN NAO THAY DOI CAN COMMIT.%C_RESET%
echo %C_WHITE%       He thong da dong bo 100%% voi GitHub tu truoc. Khong can push!%C_RESET%
echo %C_BLUE%========================================================================================%C_RESET%
echo %C_GREEN%  TIEN TRINH: [?????????????????????????] 100%% - HE THONG DA DONG BO SAN%C_RESET%
echo %C_BLUE%========================================================================================%C_RESET%
echo.
pause
exit /b 0

:: ========================================================================================
:: 3. DUA TEP VAO HANG DOI (TIEN TRINH 50%)
:: ========================================================================================
:PROCESS_STAGING
echo %C_BLUE%[2/4] DANG DUA TEP VAO HANG DOI (git add -A)...%C_RESET%
git add -A

git diff --cached --quiet
if %errorlevel% equ 0 goto :NO_REAL_DIFF
echo %C_YELLOW%  TIEN TRINH: [????????????-------------]  50%% - Da dua vao hang doi [Staging xong]%C_RESET%
echo.
goto :INPUT_COMMIT

:NO_REAL_DIFF
git log origin/!CURRENT_BRANCH!..HEAD --oneline 2>nul | findstr /R "." >nul
if errorlevel 1 (
    echo %C_BLUE%========================================================================================%C_RESET%
    echo %C_BLUE% [---] THONG BAO: Noi dung cac tep tin giong het commit cu.%C_RESET%
    echo %C_WHITE%       Khong co thay doi noi dung nao thuc su de tao commit moi.%C_RESET%
    echo %C_BLUE%========================================================================================%C_RESET%
    echo %C_GREEN%  TIEN TRINH: [?????????????????????????] 100%% - KHONG CO DIFF THUC TE%C_RESET%
    echo %C_BLUE%========================================================================================%C_RESET%
    echo.
    pause
    exit /b 0
) else (
    echo %C_ORANGE%[*] Phat hien commit co san o Local chua day len GitHub.%C_RESET%
    goto :DO_PUSH
)

:: ========================================================================================
:: 4. KHUNG NHAP GHI CHU COMMIT & XAC NHAN 1/0 (MAU HONG NEON & VANG CHIEU SANG)
:: ========================================================================================
:INPUT_COMMIT
echo %C_ORANGE%========================================================================================%C_RESET%
echo %C_ORANGE% [3/4] NHAP GHI CHU COMMIT (COMMIT MESSAGE)%C_RESET%
echo %C_GRAY%       * Nhan [ENTER] de lay ghi chu mac dinh theo ngay gio%C_RESET%
echo %C_ORANGE%========================================================================================%C_RESET%
echo.
set "commitMsg="
set /p commitMsg="%C_INPUT_PROMPT%>> Nhap ghi chu commit: %C_INPUT_TEXT%"
<nul set /p "=%C_RESET%"

if "!commitMsg!"=="" (
    for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd HH:mm')"') do set currentDt=%%a
    set "commitMsg=TB-tuandx: Khoi tao bo cong cu TB-Toolbox V1.0.0 (!currentDt!)"
)

:: Khung xac nhan 1 Tiep tuc / 0 Huy bo
echo.
echo %C_BLUE%========================================================================================%C_RESET%
echo %C_BLUE%                      XAC NHAN TIEN HANH COMMIT ^& PUSH%C_RESET%
echo %C_BLUE%========================================================================================%C_RESET%
echo %C_WHITE%   * Ghi chu commit da chon: %C_YELLOW%"!commitMsg!"%C_RESET%
echo %C_WHITE%   * So luong tep thay doi : %C_ORANGE%!TOTAL_FILES! tep tin%C_RESET%
echo %C_GRAY%----------------------------------------------------------------------------------------%C_RESET%
echo %C_GREEN%   [1] TIEP TUC  - Tien hanh tao Commit va Day len GitHub ngay%C_RESET%
echo %C_RED%   [0] HUY BO    - Dung lai, giu nguyen tep tin de tiep tuc lam them roi commit sau%C_RESET%
echo %C_BLUE%========================================================================================%C_RESET%
echo.
set "userChoice="
set /p userChoice="%C_INPUT_PROMPT%>> Lua chon cua ban [1: Tiep tuc / 0: Huy bo] (Mac dinh 1): %C_INPUT_TEXT%"
<nul set /p "=%C_RESET%"

if "!userChoice!"=="0" goto :CANCEL_COMMIT
if /i "!userChoice!"=="h" goto :CANCEL_COMMIT
if /i "!userChoice!"=="huy" goto :CANCEL_COMMIT

echo.
echo %C_BLUE%[*] Dang tao commit: "!commitMsg!"...%C_RESET%
<nul set /p "=%C_ORANGE%"
git commit -m "!commitMsg!"
set "COMMIT_ERR=%errorlevel%"
<nul set /p "=%C_RESET%"
if %COMMIT_ERR% neq 0 goto :ERR_COMMIT

echo %C_YELLOW%  TIEN TRINH: [??????????????????-------]  75%% - Da luu vet commit Local thanh cong%C_RESET%
echo.
goto :DO_PUSH

:CANCEL_COMMIT
:: Nha Staging Area ve trang thai ban dau an toan
git restore --staged . >nul 2>&1
echo.
echo %C_ORANGE%========================================================================================%C_RESET%
echo %C_ORANGE%               [---] DA HUY BO THAO TAC COMMIT THEO YEU CAU%C_RESET%
echo %C_ORANGE%========================================================================================%C_RESET%
echo %C_WHITE%   * Trang thai        : %C_YELLOW%DA HUY DONG BO [CHUA TAO COMMIT]%C_RESET%
echo %C_WHITE%   * Toan bo tep tin   : %C_GREEN%DUOC GIU NGUYEN VEN 100%% TREN MAY DE BAN LAM THEM%C_RESET%
echo %C_WHITE%   * Ban co the tiep tuc sua code roi chay lai script [ADMIN-03] nay bat ky luc nao.%C_RESET%
echo %C_ORANGE%========================================================================================%C_RESET%
echo %C_YELLOW%  TIEN TRINH: [????????????-------------]  50%% - DA TAM DUNG THEO LENH NGUOI DUNG%C_RESET%
echo %C_ORANGE%========================================================================================%C_RESET%
echo.
pause
exit /b 0

:ERR_COMMIT
echo.
echo %C_RED%========================================================================================%C_RESET%
echo %C_RED%                 [XXX] KET QUA: THAT BAI - KHONG THE TAO COMMIT.%C_RESET%
echo %C_RED%========================================================================================%C_RESET%
echo %C_RED%  TIEN TRINH: [????????????-------------]  50%% - THAT BAI [Loi tao commit]%C_RESET%
echo %C_RED%========================================================================================%C_RESET%
echo.
pause
exit /b 1

:: ========================================================================================
:: 5. DAY COMMIT LEN GITHUB VA KIEM TRA TIEN TRINH 100%
:: ========================================================================================
:DO_PUSH
for /f "tokens=*" %%h in ('git rev-parse HEAD 2^>nul') do set "LOCAL_SHA=%%h"
if "!commitMsg!"=="" (
    for /f "delims=" %%m in ('git log -1 --pretty=format:%%s 2^>nul') do set "commitMsg=%%m"
)

echo %C_BLUE%[4/4] DANG DAY COMMIT LEN GITHUB SERVER (origin !CURRENT_BRANCH!)...%C_RESET%
echo %C_GRAY%----------------------------------------------------------------------------------------%C_RESET%

<nul set /p "=%C_BLUE%"
git push -u origin !CURRENT_BRANCH!
set "PUSH_ERR=%errorlevel%"
<nul set /p "=%C_RESET%"

if %PUSH_ERR% neq 0 goto :ERR_PUSH

echo %C_GRAY%----------------------------------------------------------------------------------------%C_RESET%
echo %C_BLUE%[*] Dang gui yeu cau xac minh SHA truc tiep tu Server GitHub...%C_RESET%
set "REMOTE_SHA="
for /f "tokens=1" %%s in ('git ls-remote origin refs/heads/!CURRENT_BRANCH! 2^>nul') do (
    set "REMOTE_SHA=%%s"
)

echo.
if "!LOCAL_SHA!"=="!REMOTE_SHA!" goto :PUSH_SUCCESS
if "!REMOTE_SHA!"=="" goto :WARN_REMOTE_TIMEOUT
goto :WARN_SHA_MISMATCH

:PUSH_SUCCESS
echo %C_GREEN%========================================================================================%C_RESET%
echo %C_GREEN%               [???] KET QUA: DAY LEN GITHUB SERVER THANH CONG 100%%.%C_RESET%
echo %C_GREEN%========================================================================================%C_RESET%
echo %C_WHITE%   * Trang thai       : %C_GREEN%HOAN TAT VA DONG BO HOAN TOAN%C_RESET%
echo %C_WHITE%   * Nhanh Git        : %C_BLUE%!CURRENT_BRANCH!%C_RESET%
echo %C_WHITE%   * Ma Commit Local  : %C_GRAY%!LOCAL_SHA!%C_RESET%
echo %C_WHITE%   * Ma Commit Server : %C_GRAY%!REMOTE_SHA!  %C_GREEN%[TRUNG KHOP 100%%]%C_RESET%
echo %C_WHITE%   * Ghi chu Commit   : %C_YELLOW%!commitMsg!%C_RESET%
echo %C_GREEN%========================================================================================%C_RESET%
echo %C_GREEN%  TIEN TRINH: [?????????????????????????] 100%% - DONG BO GITHUB HOAN TAT XUAT SAC%C_RESET%
echo %C_GREEN%========================================================================================%C_RESET%
echo.
pause
exit /b 0

:WARN_REMOTE_TIMEOUT
echo %C_YELLOW%========================================================================================%C_RESET%
echo %C_YELLOW%       [?] CANH BAO: Push thanh cong nhung server khong phan hoi lenh ls-remote.%C_RESET%
echo %C_ORANGE%           Vui long kiem tra lai tren trinh duyet GitHub.%C_RESET%
echo %C_YELLOW%========================================================================================%C_RESET%
echo %C_YELLOW%  TIEN TRINH: [????????????????????-----]  85%% - CAN KIEM TRA TREN TRINH DUYET%C_RESET%
echo %C_YELLOW%========================================================================================%C_RESET%
echo.
pause
exit /b 0

:WARN_SHA_MISMATCH
echo %C_RED%========================================================================================%C_RESET%
echo %C_RED%            [XXX] CANH BAO: Commit Local va Server GitHub chua trung khop.%C_RESET%
echo %C_WHITE%   * Local SHA  : %C_GRAY%!LOCAL_SHA!%C_RESET%
echo %C_WHITE%   * Server SHA : %C_GRAY%!REMOTE_SHA!%C_RESET%
echo %C_RED%========================================================================================%C_RESET%
echo %C_RED%  TIEN TRINH: [??????????????????-------]  75%% - SAI LECH COMMIT SERVER%C_RESET%
echo %C_RED%========================================================================================%C_RESET%
echo.
pause
exit /b 1

:ERR_PUSH
echo.
echo %C_RED%========================================================================================%C_RESET%
echo %C_RED%                 [XXX] KET QUA: THAT BAI - KHONG THE DAY COMMIT LEN GITHUB.%C_RESET%
echo %C_RED%========================================================================================%C_RESET%
echo %C_ORANGE%   * CAC NGUYEN NHAN CHINH CAN KIEM TRA:%C_RESET%
echo %C_WHITE%     1. MAT KET NOI INTERNET hoac mang chan truy cap github.com.%C_RESET%
echo %C_WHITE%     2. HET HAN TOKEN hoac khong co quyen ghi [Permission Denied / 403].%C_RESET%
echo %C_WHITE%     3. XUNG DOT CODE: Tren GitHub co commit moi hon chua duoc Pull ve.%C_RESET%
echo %C_RED%========================================================================================%C_RESET%
echo %C_RED%  TIEN TRINH: [??????????????????-------]  75%% - THAT BAI TAI BUOC PUSH%C_RESET%
echo %C_RED%========================================================================================%C_RESET%
echo.
pause
exit /b 1