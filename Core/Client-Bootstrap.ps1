# ==============================================================================
# TB-TOOLBOX - CLIENT BOOTSTRAP & ACTIVATION ENGINE (Client-Bootstrap.ps1)
# Ban quyen: Mr. Tuan Beo (TuanBeo) - https://github.com/TuanBeo98/TuanBeoToolbox
# Chuc nang: Bo cai dat phia Client ho tro ca 2 hinh thuc:
#            1. Hinh thuc Tuong tac (Self-Enrollment: Nhap key/file key.txt)
#            2. Hinh thuc Dong goi san (Pre-Packaged / Zero-Touch: Tu dong Apply Key,
#               Canh bao chu DO, Khoa cung may dau tien First-Run HWID Lock,
#               chong copy sang may khac va hoat dong hoan hao Offline).
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$TB_ROOT = Split-Path -Parent $PSScriptRoot
$CORE_DIR = Join-Path $TB_ROOT "Core"
$CONFIG_DIR = Join-Path $TB_ROOT "Config"
$BAT_DIR = Join-Path $TB_ROOT "@File-BAT"
$LICENSE_KEY_FILE = Join-Path $CONFIG_DIR "license.key"

# Dot-source cac thu vien can thiet
. (Join-Path $CORE_DIR "Common-UI.ps1")
. (Join-Path $CORE_DIR "Feature-Registry.ps1")
. (Join-Path $CORE_DIR "License-Engine.ps1")

# ==============================================================================
# 1. CAP PHAT LAUNCHER @File-BAT DONG THEO QUYEN (DYNAMIC MODULE HYDRATION)
# ==============================================================================

function Sync-ClientLaunchers {
    param ([object]$AuthorizedFeatures)

    if (-not (Test-Path $BAT_DIR)) { New-Item -ItemType Directory -Path $BAT_DIR -Force | Out-Null }
    $featuresDict = @{}

    if ($AuthorizedFeatures -is [System.Management.Automation.PSCustomObject]) {
        foreach ($p in $AuthorizedFeatures.PSObject.Properties) {
            $featuresDict[$p.Name] = [int]$p.Value
        }
    } elseif ($AuthorizedFeatures -is [System.Collections.IDictionary]) {
        $featuresDict = $AuthorizedFeatures
    }

    # Module F01: Don dep bo nho tam
    $cleanerBat = Join-Path $BAT_DIR "[01]-Don-Dep-Bo-Nho-Tam-He-Thong.bat"
    if ($featuresDict["F01_CLEANER"] -eq 1) {
        if (-not (Test-Path $cleanerBat)) {
            $cleanerContent = "@echo off`r`nsetlocal`r`ncd /d `"%~dp0`"`r`ntitle [01] Don Dep Bo Nho Tam He Thong - TuanBeo Toolbox`r`nchcp 65001 >nul 2>&1`r`n`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"`..\\Core\\Engine-Cleaner.ps1`"`r`nexit /b`r`n"
            [System.IO.File]::WriteAllText($cleanerBat, $cleanerContent, [System.Text.Encoding]::ASCII)
        }
    } else {
        # Neu bi thu hoi / khong duoc cap -> Tu dong thu hoi / xoa file launcher
        if (Test-Path $cleanerBat) { Remove-Item $cleanerBat -Force -ErrorAction SilentlyContinue }
    }
}

# ==============================================================================
# 2. XU LY HINH THUC 2: PRE-PACKAGED / ZERO-TOUCH
# ==============================================================================

function Process-PrePackagedFlow {
    Show-HeaderBanner -SubTitle "KICH HOAT BAN QUYEN DONG GOI SAN (PRE-PACKAGED)"

    # Hien thi Canh bao chu DO nghiem ngat
    Show-PrePackagedWarningBanner

    Write-Host " He thong dang tien hanh kiem tra va kich hoat ban quyen cho thiet bi..." -ForegroundColor Cyan
    $currentHWID = Get-MachineHWID

    # Thuc hien First-Run HWID Lock
    $lockRes = Lock-PrePackagedKeyToCurrentMachine -KeyFilePath $LICENSE_KEY_FILE -CurrentHWID $currentHWID

    if ($lockRes.Success) {
        Write-Host "`n [OK] $($lockRes.Message)" -ForegroundColor Green
        Write-Host ("      Nguoi so huu : {0}" -f $lockRes.Payload.fullName) -ForegroundColor Cyan
        Write-Host ("      HWID May     : {0}" -f $currentHWID) -ForegroundColor DarkGray
        Write-Host ("      Thoi han     : {0}" -f $lockRes.Payload.expiresAt) -ForegroundColor Yellow

        # Dong bo cac file launcher theo danh sach tinh nang duoc cap
        Sync-ClientLaunchers -AuthorizedFeatures $lockRes.Payload.features

        Write-Host "`n ================================================================================" -ForegroundColor Green
        Write-Host "                      CAI DAT & KICH HOAT HOAN TAT!                             " -ForegroundColor Green
        Write-Host " ================================================================================" -ForegroundColor Green
        Write-Host " Ban da co the su dung cac cong cu duoc cap phep trong thu muc @File-BAT." -ForegroundColor Yellow
        Write-Host "================================================================================`n" -ForegroundColor DarkGray
    } else {
        Write-Host "`n [X] THAT BAI: $($lockRes.Message)" -ForegroundColor Red
        Write-Host " Ban quyen khong hop le hoac tap tin nay da bi mang sang may tinh khac su dung." -ForegroundColor Red
        Write-Host " Vui long lien he Admin Tuan Beo de duoc ho tro cap lai key!`n" -ForegroundColor Yellow
    }

    Wait-ForUserExit -Message " Nhan phim bat ky de dong..."
}

# ==============================================================================
# 3. XU LY HINH THUC 1: SELF-ENROLLMENT / TUONG TAC
# ==============================================================================

function Process-InteractiveActivationFlow {
    Show-HeaderBanner -SubTitle "KICH HOAT BAN QUYEN TB-TOOLBOX"

    $currentHWID = Get-MachineHWID
    Write-Host " Ma dinh danh phan cung (HWID) cua may ban:" -ForegroundColor Yellow
    Write-Host " >> $currentHWID <<" -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [1] Nhap chuoi Ma Key truc tiep" -ForegroundColor Cyan
    Write-Host " [2] Nap tu tap tin key.txt co san" -ForegroundColor Cyan
    Write-Host " [3] Gui yeu cau cap Key moi len Admin Tuan Beo" -ForegroundColor Cyan
    Write-Host " [0] Thoat`n" -ForegroundColor DarkGray

    $opt = Read-Host " Chon thao tac [0-3]"
    $inputKeyString = ""

    switch ($opt) {
        "1" {
            $inputKeyString = Read-Host "`n Dan chuoi Ma Key cua ban vao day"
        }
        "2" {
            $filePath = Read-Host "`n Nhap duong dan tap tin key (Mac dinh: key.txt)"
            if ([string]::IsNullOrWhiteSpace($filePath)) { $filePath = "key.txt" }
            if (Test-Path $filePath) {
                $inputKeyString = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8).Trim()
            } else {
                Write-Host " Khong tim thay tap tin tai: $filePath" -ForegroundColor Red
                Wait-ForUserExit
                return
            }
        }
        "3" {
            Show-HeaderBanner -SubTitle "DANG KY CAP BAN QUYEN MOI"
            $name = Read-Host " Ho va ten cua ban"
            $email = Read-Host " Email hoac So dien thoai"
            $note = Read-Host " Nhu cau su dung (de trong de cap mac dinh)"

            if ([string]::IsNullOrWhiteSpace($name)) {
                Write-Host " Ho ten khong duoc de trong!" -ForegroundColor Red
                Wait-ForUserExit
                return
            }

            # Ghi vao hang doi yeu cau cho (pending-requests)
            $reqFile = Join-Path $CONFIG_DIR "pending-requests.json"
            $reqStore = Read-JsonWithBom -Path $reqFile
            if ($null -eq $reqStore -or -not $reqStore.requests) {
                $reqStore = [PSCustomObject]@{
                    metadata = [PSCustomObject]@{ system = "TB-Toolbox Requests Queue"; lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
                    requests = @()
                }
            }

            $newReq = [PSCustomObject]@{
                hwid        = $currentHWID
                fullName    = $name
                email       = $email
                note        = $note
                submittedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                status      = 0 # 0 = Cho duyet
            }
            $reqStore.requests += $newReq
            Save-JsonWithBom -Path $reqFile -Data $reqStore | Out-Null

            Write-Host "`n [OK] Da ghi nhan yeu cau thanh cong!" -ForegroundColor Green
            Write-Host " Vui long gui ma HWID cua ban cho Admin Tuan Beo de duoc phe duyet:`n" -ForegroundColor Yellow
            Write-Host " HWID: $currentHWID" -ForegroundColor Cyan
            Write-Host "`n Sau khi nhan duoc file key.txt, ban mo lai chuong trinh de kich hoat.`n" -ForegroundColor DarkGray
            Wait-ForUserExit
            return
        }
        default { return }
    }

    if ([string]::IsNullOrWhiteSpace($inputKeyString)) {
        Write-Host " Ma Key khong duoc de trong!" -ForegroundColor Red
        Wait-ForUserExit
        return
    }

    # Kiem tra tinh hop le cua Key
    $verify = Verify-LicenseKey -LicenseKeyString $inputKeyString -CurrentHWID $currentHWID
    if ($verify.IsValid) {
        # Luu va khoa chat 3 neo phan cung (File + DPAPI + Registry)
        Save-LicenseTripleAnchor -KeyString $inputKeyString -Payload $verify.Payload -CurrentHWID $currentHWID

        Write-Host "`n [OK] KICH HOAT BAN QUYEN THANH CONG!" -ForegroundColor Green
        Write-Host ("      Nguoi dung : {0}" -f $verify.Payload.fullName) -ForegroundColor Cyan
        Write-Host ("      Thoi han   : {0}" -f $verify.Payload.expiresAt) -ForegroundColor Yellow

        # Sinh launcher cho cac chuc nang hop le
        Sync-ClientLaunchers -AuthorizedFeatures $verify.Payload.features

        Write-Host "`n Ban da co the su dung cac cong cu trong thu muc @File-BAT.`n" -ForegroundColor Green
    } else {
        Write-Host "`n [X] KICH HOAT THAT BAI: $($verify.Error)" -ForegroundColor Red
    }

    Wait-ForUserExit
}

# ==============================================================================
# 4. ENTRY POINT
# ==============================================================================

function Start-ClientBootstrap {
    # Neu da co san file Config/license.key -> Xu ly tu dong theo Pre-Packaged flow
    if (Test-Path $LICENSE_KEY_FILE) {
        Process-PrePackagedFlow
    } else {
        # Neu chua co key -> Xu ly theo Interactive flow
        Process-InteractiveActivationFlow
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-ClientBootstrap
}
