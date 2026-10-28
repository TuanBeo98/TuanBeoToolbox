# ==============================================================================
# TB-TOOLBOX - ADMIN KEY MANAGER & LICENSING CONSOLE (Admin-KeyManager.ps1)
# Ban quyen: Mr. Tuan Beo (TuanBeo) - https://github.com/TuanBeo98/TuanBeoToolbox
# Chuc nang: Tiep nhan yeu cau, tao key, dong goi client pre-packaged va quan ly so cai.
# Chi danh rieng cho Admin Tuan Beo (Bao ve boi MasterKey & Admin Whitelist).
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$TB_ROOT = Split-Path -Parent $PSScriptRoot
$CORE_DIR = Join-Path $TB_ROOT "Core"
$CONFIG_DIR = Join-Path $TB_ROOT "Config"
$DIST_DIR = Join-Path $TB_ROOT "Dist"

# Dot-source cac thu vien nen tang
. (Join-Path $CORE_DIR "Common-UI.ps1")
. (Join-Path $CORE_DIR "Crypto-RSA.ps1")
. (Join-Path $CORE_DIR "Feature-Registry.ps1")
. (Join-Path $CORE_DIR "License-Engine.ps1")

$WHITELIST_FILE = Join-Path $CONFIG_DIR "admin-whitelist.json"
$LEDGER_FILE = Join-Path $CONFIG_DIR "key-ledger.json"
$REQUESTS_FILE = Join-Path $CONFIG_DIR "pending-requests.json"

if (-not (Test-Path $DIST_DIR)) { New-Item -ItemType Directory -Path $DIST_DIR -Force | Out-Null }

# ==============================================================================
# 0. CONG XAC THUC ADMIN TOI CAO (SECURITY GATE)
# ==============================================================================

function Authenticate-Admin {
    $currentHWID = Get-MachineHWID
    $whitelistData = Read-JsonWithBom -Path $WHITELIST_FILE

    $isWhitelisted = $false
    if ($whitelistData -and $whitelistData.trustedAdmins) {
        $found = $whitelistData.trustedAdmins | Where-Object { $_.hwid -eq $currentHWID }
        if ($found) { $isWhitelisted = $true }
    }

    if ($isWhitelisted) {
        return $true
    }

    # Neu thiet bi moi chua trong whitelist -> Yeu cau nhap MasterKey
    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "          [!] CANH BAO: PHAT HIEN THIET BI ADMIN MOI CHUA DANG KY               " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host " Thiet bi: $env:COMPUTERNAME | HWID: $currentHWID" -ForegroundColor DarkGray
    Write-Host " Vui long nhap Ma Khoa Chu Toi Cao (MasterKey) hoac nhap 'RECOVERY' neu quen mat khau:`n" -ForegroundColor Yellow

    $attempts = 0
    while ($attempts -lt 3) {
        $attempts++
        $inputKey = Read-Host " MasterKey (Lan $attempts/3)"
        
        # Truong hop quen mat khau -> Dung Ma Cuu Ho Khan Cap
        if ($inputKey -eq "RECOVERY" -or $inputKey -eq "recovery") {
            Write-Host "`n ================================================================================" -ForegroundColor Yellow
            Write-Host "                   CHE DO CUU HO KHAN CAP (EMERGENCY RECOVERY)                  " -ForegroundColor Yellow
            Write-Host " ================================================================================" -ForegroundColor Yellow
            $recCode = Read-Host " Nhap Ma Cuu Ho Khan Cap (vi du: TB-RECOVERY-XXXX-XXXX-XXXX-2026)"
            if (Verify-EmergencyRecoveryKey -InputKey $recCode) {
                Write-Host "`n [OK] XAC THUC MA CUU HO THANH CONG!" -ForegroundColor Green
                $newPass = Read-Host " Nhap Ma MasterKey moi cua Anh Beo"
                if (-not [string]::IsNullOrWhiteSpace($newPass)) {
                    $script:TB_MASTER_KEY = $newPass.Trim()
                    Write-Host " [OK] Da dat lai MasterKey moi thanh cong!" -ForegroundColor Green
                    
                    # Luu may vao whitelist
                    if (-not $whitelistData) {
                        $whitelistData = [PSCustomObject]@{
                            metadata = [PSCustomObject]@{ author = "Mr. Tuan Beo"; lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
                            trustedAdmins = @()
                        }
                    }
                    $whitelistData.trustedAdmins += [PSCustomObject]@{
                        hwid        = $currentHWID
                        deviceName  = $env:COMPUTERNAME
                        userName    = $env:USERNAME
                        description = "May Admin xac thuc qua Ma Cuu Ho"
                        addedAt     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    }
                    Save-JsonWithBom -Path $WHITELIST_FILE -Data $whitelistData | Out-Null
                    Start-Sleep -Seconds 2
                    return $true
                }
            } else {
                Write-Host " [X] Ma Cuu Ho Khan Cap khong hop le!" -ForegroundColor Red
            }
            continue
        }

        if ($inputKey -eq $script:TB_MASTER_KEY) {
            Write-Host "`n [OK] Xac thuc MasterKey thanh cong! Dang them may vao Danh sach trang..." -ForegroundColor Green
            
            # Luu HWID vao whitelist de lan sau khong can hoi lai
            if (-not $whitelistData) {
                $whitelistData = [PSCustomObject]@{
                    metadata = [PSCustomObject]@{ author = "Mr. Tuan Beo"; lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
                    trustedAdmins = @()
                }
            }
            $whitelistData.trustedAdmins += [PSCustomObject]@{
                hwid        = $currentHWID
                deviceName  = $env:COMPUTERNAME
                userName    = $env:USERNAME
                description = "May Admin xac thuc boi MasterKey"
                addedAt     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            Save-JsonWithBom -Path $WHITELIST_FILE -Data $whitelistData | Out-Null
            Start-Sleep -Seconds 1
            return $true
        } else {
            Write-Host " [X] MasterKey khong chinh xac!" -ForegroundColor Red
        }
    }

    Write-Host "`n Ban da nhap sai qua 3 lan. Tu choi quyen truy cap Admin!`n" -ForegroundColor Red
    Wait-ForUserExit
    exit 1
}

# ==============================================================================
# 1. TIEN ICH GHI SO CAI BAN QUYEN (KEY LEDGER)
# ==============================================================================

function Add-KeyToLedger {
    param (
        [string]$KeyString,
        [PSCustomObject]$Payload
    )
    $ledger = Read-JsonWithBom -Path $LEDGER_FILE
    if ($null -eq $ledger -or -not $ledger.keys) {
        $ledger = [PSCustomObject]@{
            metadata = [PSCustomObject]@{
                system      = "TB-Toolbox License Key Ledger"
                author      = "Mr. Tuan Beo"
                lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            keys = @()
        }
    }

    $stt = "{0:D3}" -f ($ledger.keys.Count + 1)
    $newEntry = [PSCustomObject]@{
        stt          = $stt
        keyId        = $Payload.keyId
        hwid         = $Payload.hwid
        fullName     = $Payload.fullName
        email        = $Payload.email
        groupId      = $Payload.groupId
        mode         = $Payload.mode
        issuedAt     = $Payload.issuedAt
        expiresAt    = $Payload.expiresAt
        isActivated  = if ([string]::IsNullOrWhiteSpace($Payload.hwid)) { 0 } else { 1 }
        keyStatus    = 1 # 1 = Con han / Hoat dong | 0 = Bi thu hoi
        keyString    = $KeyString
    }

    $ledger.keys += $newEntry
    $ledger.metadata.lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Save-JsonWithBom -Path $LEDGER_FILE -Data $ledger | Out-Null
    return $newEntry
}

# ==============================================================================
# 2. XEM VA PHE DUYET YEU CAU CHO (PENDING REQUESTS)
# ==============================================================================

function Show-PendingRequestsMenu {
    $reqData = Read-JsonWithBom -Path $REQUESTS_FILE
    $pending = @()
    if ($reqData -and $reqData.requests) {
        $pending = @($reqData.requests | Where-Object { $_.status -eq 0 })
    }

    Show-HeaderBanner -SubTitle "HANG DOI YEU CAU BAN QUYEN CHO DUYET"

    if ($pending.Count -eq 0) {
        Write-Host " Khong co yeu cau nao dang cho xu ly trong he thong.`n" -ForegroundColor Yellow
        Wait-ForUserExit -Message " Nhap phim bat ky de quay lai menu..."
        return
    }

    Write-Host (" Danh sach co {0} yeu cau dang cho phe duyet:`n" -f $pending.Count) -ForegroundColor Green
    for ($i = 0; $i -lt $pending.Count; $i++) {
        $r = $pending[$i]
        Write-Host (" [{0}] {1,-20} | HWID: {2,-16} | Ngay gui: {3}" -f ($i + 1), $r.fullName, $r.hwid.Substring(0, 16) + "...", $r.submittedAt) -ForegroundColor Cyan
    }

    Write-Host "`n [0] Quay lai" -ForegroundColor DarkGray
    $sel = Read-Host "`n Chon so thu tu yeu cau can cap Key"
    if ($sel -eq "0" -or [string]::IsNullOrWhiteSpace($sel)) { return }

    $idx = [int]$sel - 1
    if ($idx -ge 0 -and $idx -lt $pending.Count) {
        $targetReq = $pending[$idx]
        Process-InteractiveKeyIssue -TargetHWID $targetReq.hwid -TargetName $targetReq.fullName -TargetEmail $targetReq.email
        $targetReq.status = 1
        $targetReq.processedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Save-JsonWithBom -Path $REQUESTS_FILE -Data $reqData | Out-Null
    }
}

# ==============================================================================
# 3. TAO KEY THU CONG (INTERACTIVE KEY GENERATOR)
# ==============================================================================

function Process-InteractiveKeyIssue {
    param (
        [string]$TargetHWID = "",
        [string]$TargetName = "",
        [string]$TargetEmail = ""
    )

    Show-HeaderBanner -SubTitle "CONG CU TAO KEY BAN QUYEN (INTERACTIVE)"

    if ([string]::IsNullOrWhiteSpace($TargetHWID)) {
        $TargetHWID = Read-Host " Nhap Ma HWID cua may can cap (32 ky tu)"
    }
    if ([string]::IsNullOrWhiteSpace($TargetName)) {
        $TargetName = Read-Host " Nhap Ho va ten nguoi su dung"
    }
    if ([string]::IsNullOrWhiteSpace($TargetEmail)) {
        $TargetEmail = Read-Host " Nhap Email / Don vi phong ban"
    }

    if ([string]::IsNullOrWhiteSpace($TargetHWID) -or [string]::IsNullOrWhiteSpace($TargetName)) {
        Write-Host " Thieu thong tin bat buoc! Huy tao Key." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Chon Nhom chuc nang
    $matrix = Sync-FeatureMatrix
    Write-Host "`n Danh sach goi chuc nang san co:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $matrix.Groups.Count; $i++) {
        $g = $matrix.Groups[$i]
        Write-Host (" [{0}] {1} ({2})" -f ($i + 1), $g.groupName, $g.groupId) -ForegroundColor Cyan
    }
    $grpChoice = Read-Host " Chon goi nhom (Mac dinh: 1)"
    if ([string]::IsNullOrWhiteSpace($grpChoice)) { $grpChoice = "1" }
    $selectedGroup = $matrix.Groups[[int]$grpChoice - 1]
    if (-not $selectedGroup) { $selectedGroup = $matrix.Groups[0] }

    # Chon Thoi han
    Write-Host "`n Thiet lap thoi han su dung:" -ForegroundColor Yellow
    Write-Host " [1] 30 ngay"
    Write-Host " [2] 90 ngay (3 thang)"
    Write-Host " [3] 365 ngay (1 nam)"
    Write-Host " [4] Vo thoi han (LIFETIME)"
    Write-Host " [5] Tu nhap so ngay cu the"
    $durChoice = Read-Host " Chon thoi han (Mac dinh: 4 - LIFETIME)"
    $days = 0
    switch ($durChoice) {
        "1" { $days = 30 }
        "2" { $days = 90 }
        "3" { $days = 365 }
        "5" { 
            $customDays = Read-Host " Nhap so ngay su dung"
            $days = [int]$customDays
        }
        default { $days = 0 }
    }

    # Chuyen doi features sang hashtable
    $featuresDict = @{}
    if ($selectedGroup.features -is [System.Management.Automation.PSCustomObject]) {
        foreach ($p in $selectedGroup.features.PSObject.Properties) {
            $featuresDict[$p.Name] = [int]$p.Value
        }
    } elseif ($selectedGroup.features -is [System.Collections.IDictionary]) {
        $featuresDict = $selectedGroup.features
    }

    # Cong xac nhan truoc khi tao (Confirmation Gate)
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host "                     THONG TIN TOM TAT TRUOC KHI TAO KEY                        " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host (" Nguoi duoc cap : {0} ({1})" -f $TargetName, $TargetEmail)
    Write-Host (" Ma HWID may    : {0}" -f $TargetHWID)
    Write-Host (" Goi ban quyen  : {0} ({1})" -f $selectedGroup.groupName, $selectedGroup.groupId)
    Write-Host (" Thoi han       : {0}" -f (if ($days -eq 0) { "Vo thoi han (LIFETIME)" } else { "$days ngay" }))
    Write-Host "================================================================================" -ForegroundColor Cyan

    $confirm = Read-Host " Ban co chac chan muon tao Key nay? [Y/N] (Mac dinh: Y)"
    if ($confirm -ne "" -and $confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host " Da huy thao tac tao Key." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }

    # Tien hanh tao Key
    $newKey = Create-LicenseKey -HWID $TargetHWID -FullName $TargetName -Email $TargetEmail `
                                -GroupId $selectedGroup.groupId -Features $featuresDict `
                                -DurationDays $days -Mode "INTERACTIVE"

    $verify = Verify-LicenseKey -LicenseKeyString $newKey -CurrentHWID $TargetHWID
    $entry = Add-KeyToLedger -KeyString $newKey -Payload $verify.Payload

    # Xuat ra file key.txt trong Dist/Keys/
    $keysDir = Join-Path $DIST_DIR "Keys"
    if (-not (Test-Path $keysDir)) { New-Item -ItemType Directory -Path $keysDir -Force | Out-Null }
    $cleanName = ($TargetName -replace '[\\/:*?"<>| ]', '_')
    $outFile = Join-Path $keysDir "$($entry.stt)_$cleanName.key.txt"
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($outFile, $newKey, $utf8WithBom)

    Write-Host "`n [OK] TAO KEY THANH CONG!" -ForegroundColor Green
    Write-Host " Ma Key: $newKey" -ForegroundColor Yellow
    Write-Host " Da xuat file tai: $outFile" -ForegroundColor Cyan
    Write-Host " Da ghi vao So cai ban quyen (STT: $($entry.stt))`n" -ForegroundColor DarkGray

    Wait-ForUserExit -Message " Nhap phim bat ky de tiep tuc..."
}

# ==============================================================================
# 4. DONG GOI SAN CHO NGUOI DUNG (BUILD PRE-PACKAGED / ZERO-TOUCH CLIENT)
# ==============================================================================

function Build-PrePackagedClientBundle {
    Show-HeaderBanner -SubTitle "DONG GOI SAN CHO NGUOI DUNG (ZERO-TOUCH PRE-PACKAGE)"

    Write-Host " Che do nay tao mot thu muc cai dat doc lap nhung san Key." -ForegroundColor Yellow
    Write-Host " Nguoi dung chi can mo file Cai-Dat la tu dong kich hoat va KHOA CUNG vao may dau tien." -ForegroundColor Yellow
    Write-Host " Hoat dong 100% tren may Offline noi bo khong co Internet!`n" -ForegroundColor Yellow

    $TargetName = Read-Host " Nhap Ho va ten nguoi nhan goi cai dat"
    $TargetEmail = Read-Host " Nhap Email / Don vi phong ban"
    if ([string]::IsNullOrWhiteSpace($TargetName)) {
        Write-Host " Ten nguoi nhan khong duoc de trong!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    # Chon Nhom chuc nang
    $matrix = Sync-FeatureMatrix
    Write-Host "`n Danh sach goi chuc nang:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $matrix.Groups.Count; $i++) {
        $g = $matrix.Groups[$i]
        Write-Host (" [{0}] {1}" -f ($i + 1), $g.groupName) -ForegroundColor Cyan
    }
    $grpChoice = Read-Host " Chon goi nhom (Mac dinh: 1)"
    if ([string]::IsNullOrWhiteSpace($grpChoice)) { $grpChoice = "1" }
    $selectedGroup = $matrix.Groups[[int]$grpChoice - 1]
    if (-not $selectedGroup) { $selectedGroup = $matrix.Groups[0] }

    # Tao Key dang PRE_PACKAGED (HWID de trong, se tu khoa tren may chay dau tien)
    $featuresDict = @{}
    if ($selectedGroup.features -is [System.Management.Automation.PSCustomObject]) {
        foreach ($p in $selectedGroup.features.PSObject.Properties) {
            $featuresDict[$p.Name] = [int]$p.Value
        }
    } elseif ($selectedGroup.features -is [System.Collections.IDictionary]) {
        $featuresDict = $selectedGroup.features
    }

    $preKey = Create-LicenseKey -HWID "" -FullName $TargetName -Email $TargetEmail `
                                -GroupId $selectedGroup.groupId -Features $featuresDict `
                                -DurationDays 0 -Mode "PRE_PACKAGED"

    # Duong dan xuat goi
    $cleanName = ($TargetName -replace '[\\/:*?"<>| ]', '_')
    $bundleDir = Join-Path $DIST_DIR "TB-Toolbox-PrePackaged-$cleanName"
    if (Test-Path $bundleDir) { Remove-Item $bundleDir -Recurse -Force }

    $bundleBatDir = Join-Path $bundleDir "@File-BAT"
    $bundleCoreDir = Join-Path $bundleDir "Core"
    $bundleConfigDir = Join-Path $bundleDir "Config"
    $bundleLogsDir = Join-Path $bundleDir "Logs"

    New-Item -ItemType Directory -Path $bundleBatDir -Force | Out-Null
    New-Item -ItemType Directory -Path $bundleCoreDir -Force | Out-Null
    New-Item -ItemType Directory -Path $bundleConfigDir -Force | Out-Null
    New-Item -ItemType Directory -Path $bundleLogsDir -Force | Out-Null

    # Chep cac file he thong cot loi
    Copy-Item (Join-Path $CORE_DIR "Common-UI.ps1") $bundleCoreDir -Force
    Copy-Item (Join-Path $CORE_DIR "Crypto-RSA.ps1") $bundleCoreDir -Force
    Copy-Item (Join-Path $CORE_DIR "License-Engine.ps1") $bundleCoreDir -Force
    Copy-Item (Join-Path $CORE_DIR "Integrity-Guard.ps1") $bundleCoreDir -Force
    Copy-Item (Join-Path $CORE_DIR "Server-Sync.ps1") $bundleCoreDir -Force
    Copy-Item (Join-Path $CORE_DIR "Feature-Registry.ps1") $bundleCoreDir -Force
    Copy-Item (Join-Path $CORE_DIR "Client-Bootstrap.ps1") $bundleCoreDir -Force
    if (Test-Path (Join-Path $CONFIG_DIR ".integrity.seal")) {
        Copy-Item (Join-Path $CONFIG_DIR ".integrity.seal") $bundleConfigDir -Force
    }
    if (Test-Path (Join-Path $CONFIG_DIR "tb-public.rsa")) {
        Copy-Item (Join-Path $CONFIG_DIR "tb-public.rsa") $bundleConfigDir -Force
    }

    # Chep cac Engine cua cac chuc nang duoc phep bat (= 1)
    if ($featuresDict["F01_CLEANER"] -eq 1) {
        Copy-Item (Join-Path $CORE_DIR "Config-Manager.ps1") $bundleCoreDir -Force
        Copy-Item (Join-Path $CORE_DIR "Engine-Cleaner.ps1") $bundleCoreDir -Force
        Copy-Item (Join-Path $CONFIG_DIR "cleaner-config.json") $bundleConfigDir -Force -ErrorAction SilentlyContinue
        Copy-Item (Join-Path $TB_ROOT "@File-BAT\[01]-Don-Dep-Bo-Nho-Tam-He-Thong.bat") $bundleBatDir -Force
    }

    # Ghi file Key nhung san vao Config/license.key
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText((Join-Path $bundleConfigDir "license.key"), $preKey, $utf8WithBom)

    # Sinh file cai dat [00]-Cai-Dat-TB-Toolbox.bat cho Client
    $clientBatContent = @"
@echo off
setlocal
cd /d "%~dp0"
title Cai Dat & Kich Hoat TB-Toolbox
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Core\Client-Bootstrap.ps1"
exit /b
"@
    # Ghi file BAT khong co BOM
    $asciiEnc = [System.Text.Encoding]::ASCII
    [System.IO.File]::WriteAllText((Join-Path $bundleDir "[00]-Cai-Dat-TB-Toolbox.bat"), $clientBatContent, $asciiEnc)

    # Luu vao So cai
    $verify = Verify-LicenseKey -LicenseKeyString $preKey -CurrentHWID ""
    $entry = Add-KeyToLedger -KeyString $preKey -Payload $verify.Payload

    Write-Host "`n================================================================================" -ForegroundColor Green
    Write-Host "                [OK] DA DONG GOI THANH CONG CLIENT PRE-PACKAGED                 " -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host " Thu muc goi cai dat: $bundleDir" -ForegroundColor Cyan
    Write-Host " STT So cai: $($entry.stt) | KeyId: $($entry.keyId)" -ForegroundColor DarkGray
    Write-Host " Huong dan ban giao: Chi can nen thu muc nay gui cho khach hang/nhan vien." -ForegroundColor Yellow
    Write-Host " Khi mo [00]-Cai-Dat-TB-Toolbox.bat, chuong trinh se:" -ForegroundColor Yellow
    Write-Host "   1. Hien thi Canh bao chu DO can de chia se." -ForegroundColor Red
    Write-Host "   2. Tu dong khoa ban quyen vao HWID may dau tien (First-Run HWID Lock)." -ForegroundColor Yellow
    Write-Host "   3. Khoa ngay lap tuc neu bi copy sang may khac!" -ForegroundColor Yellow
    Write-Host "================================================================================`n" -ForegroundColor Green

    Wait-ForUserExit -Message " Nhap phim bat ky de tiep tuc..."
}

# ==============================================================================
# 5. SO CAI BAN QUYEN (KEY LEDGER VIEWER)
# ==============================================================================

function Show-KeyLedgerViewer {
    $ledger = Read-JsonWithBom -Path $LEDGER_FILE
    Show-HeaderBanner -SubTitle "SO CAI QUAN LY BAN QUYEN (KEY LEDGER)"

    if ($null -eq $ledger -or -not $ledger.keys -or $ledger.keys.Count -eq 0) {
        Write-Host " So cai chua co Key nao duoc tao.`n" -ForegroundColor Yellow
        Wait-ForUserExit
        return
    }

    Write-Host (" Tong so Key da cap: {0}`n" -f $ledger.keys.Count) -ForegroundColor Green
    $header = " {0,-4} | {1,-20} | {2,-16} | {3,-12} | {4,-10} | {5,-12}" -f "STT", "NGUOI NHAN", "HWID", "GOI", "TRANG THAI", "HET HAN"
    Write-Host $header -ForegroundColor Green
    Write-Host ("-" * 85) -ForegroundColor DarkGray

    foreach ($k in $ledger.keys) {
        $hwidShort = if ([string]::IsNullOrWhiteSpace($k.hwid)) { "[Chua bind]" } else { $k.hwid.Substring(0, 10) + "..." }
        $sttStr = if ($k.keyStatus -eq 1) { "HIEU LUC" } else { "THU HOI" }
        $row = " {0,-4} | {1,-20} | {2,-16} | {3,-12} | {4,-10} | {5,-12}" -f $k.stt, $k.fullName, $hwidShort, $k.groupId, $sttStr, $k.expiresAt.Substring(0, [math]::Min(10, $k.expiresAt.Length))
        Write-Host $row
    }

    Write-Host ("-" * 85) -ForegroundColor DarkGray
    Write-Host "`n [T] Thu hoi Key | [G] Gia han Key | [0] Quay lai" -ForegroundColor Yellow
    $action = Read-Host " Chon thao tac"
    if ($action -eq "T" -or $action -eq "t") {
        $targetStt = Read-Host " Nhap STT Key muon thu hoi (vi du: 001)"
        $entry = $ledger.keys | Where-Object { $_.stt -eq $targetStt }
        if ($entry) {
            $entry.keyStatus = 0
            Save-JsonWithBom -Path $LEDGER_FILE -Data $ledger | Out-Null
            Write-Host " [OK] Da thu hoi Key cua $($entry.fullName) thanh cong!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

function Manage-SecurityAndRecovery {
    Show-HeaderBanner -SubTitle "QUAN LY MAT KHAU & CUU HO KHAN CAP"
    $recKey = Get-EmergencyRecoveryKey
    
    Write-Host " [1] Xem Ma Cuu Ho Khan Cap (Emergency Recovery Key)" -ForegroundColor Cyan
    Write-Host " [2] Doi Ma MasterKey quan tri moi" -ForegroundColor Cyan
    Write-Host " [3] Tao lai Ma Cuu Ho moi (Key Rotation)" -ForegroundColor Cyan
    Write-Host " [0] Quay lai`n" -ForegroundColor DarkGray

    $subChoice = Read-Host " Nhap lua chon [0-3]"
    switch ($subChoice) {
        "1" {
            Write-Host "`n ================================================================================" -ForegroundColor Green
            Write-Host "                   MA CUU HO KHAN CAP DANG HOAT DONG                            " -ForegroundColor Yellow
            Write-Host " ================================================================================" -ForegroundColor Green
            Write-Host " Ma cua Anh Beo: $recKey" -ForegroundColor Green
            Write-Host " Luu y: Anh Beo hay luu ma nay vao Ghi chu dien thoai hoac Zalo ca nhan." -ForegroundColor Yellow
            Write-Host " Neu quen MasterKey tren bat ky may tinh nao, chi can nhap ma nay de mo khoa!" -ForegroundColor Yellow
            Write-Host " ================================================================================`n" -ForegroundColor Green
            Wait-ForUserExit
        }
        "2" {
            $oldKey = Read-Host " Nhap MasterKey hien tai"
            if ($oldKey -eq $script:TB_MASTER_KEY) {
                $newKey = Read-Host " Nhap MasterKey moi muon doi"
                if (-not [string]::IsNullOrWhiteSpace($newKey)) {
                    $script:TB_MASTER_KEY = $newKey.Trim()
                    Write-Host " [OK] Da doi MasterKey thanh cong!" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
            } else {
                Write-Host " [X] Mat khau cu khong dung!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        "3" {
            $confirm = Read-Host " Ban co chac chan muon tao Ma Cuu Ho moi? [Y/N]"
            if ($confirm -eq "Y" -or $confirm -eq "y") {
                Initialize-RSAKeyPair -ForceRegenerate | Out-Null
                $newRec = Get-EmergencyRecoveryKey
                Write-Host " [OK] Da tao Ma Cuu Ho moi: $newRec" -ForegroundColor Green
                Wait-ForUserExit
            }
        }
    }
}

# ==============================================================================
# 6. MENU CHINH CUA ADMIN CONSOLE
# ==============================================================================

function Start-AdminConsole {
    if (-not (Authenticate-Admin)) { return }

    while ($true) {
        Show-HeaderBanner -SubTitle "TRUNG TAM QUAN TRI BAN QUYEN & HE THONG (ADMIN)"

        Write-Host " [1] Xem & Phe duyet yeu cau cap Key (Pending Requests)" -ForegroundColor Cyan
        Write-Host " [2] Tao Key ban quyen moi (Interactive Key Generator)" -ForegroundColor Cyan
        Write-Host " [3] Dong goi san cho nguoi dung (Build Pre-Packaged / Zero-Touch Client)" -ForegroundColor Green
        Write-Host " [4] Kiem tra & Tuy bien quyen nguoi dung (User Permission Override)" -ForegroundColor Cyan
        Write-Host " [5] So cai quan ly Key (Key Ledger - Xem, Thu hoi, Gia han)" -ForegroundColor Cyan
        Write-Host " [6] Bang ma tran tinh nang & Nhom ban quyen (Feature Matrix)" -ForegroundColor Cyan
        Write-Host " [7] Quan ly Mat khau & Cuu ho (Doi MasterKey / Xem Ma Cuu Ho)" -ForegroundColor Yellow
        Write-Host " [0] Thoat chuong trinh`n" -ForegroundColor DarkGray

        $choice = Read-Host " Nhap lua chon cua Anh Beo [0-7]"
        switch ($choice) {
            "1" { Show-PendingRequestsMenu }
            "2" { Process-InteractiveKeyIssue }
            "3" { Build-PrePackagedClientBundle }
            "4" { 
                Show-HeaderBanner -SubTitle "TUY BIEN QUYEN RIENG TUNG NGUOI DUNG"
                $uid = Read-Host " Nhap Identifier / HWID / Email nguoi dung can tuy bien"
                if (-not [string]::IsNullOrWhiteSpace($uid)) {
                    $eff = Get-EffectiveUserPermissions -UserIdentifier $uid
                    Write-Host "`n Che do hien tai: $($eff.Mode)" -ForegroundColor Yellow
                    $eff.Features | Out-String
                    $fId = Read-Host " Nhap Ma tinh nang muon thay doi (vi du: F03_NETWORK_TOOLS)"
                    $state = Read-Host " Nhap trang thai moi [0 = TAT, 1 = BAT]"
                    if ($fId -and ($state -eq "0" -or $state -eq "1")) {
                        Set-UserFeatureOverride -UserIdentifier $uid -GroupId "GRP_DEFAULT" -FeatureOverrides @{ $fId = [int]$state }
                        Write-Host " [OK] Da cap nhat quyen rieng thanh cong!" -ForegroundColor Green
                        Start-Sleep -Seconds 1
                    }
                }
            }
            "5" { Show-KeyLedgerViewer }
            "6" { 
                Show-FeatureMatrixTable
                Wait-ForUserExit -Message " Nhap phim bat ky de quay lai menu..."
            }
            "7" { Manage-SecurityAndRecovery }
            "0" { break }
            default { Write-Host " Lua chon khong hop le!" -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# Khoi chay Admin Console khi chay truc tiep (khong dot-source)
if ($MyInvocation.InvocationName -ne '.') {
    Start-AdminConsole
}
