# ==============================================================================
# TB-TOOLBOX - ADMIN KEY MANAGER & LICENSING CONSOLE (Admin-KeyManager.ps1)
# Bản quyền thuộc về: Mr. Tuấn Beo (TuanBeoToolbox)
# Chức năng: Tiếp nhận yêu cầu, tạo key, đóng gói client pre-packaged và quản lý sổ cái.
# Chỉ dành riêng cho Admin Tuấn Beo (Bảo vệ bởi MasterKey & Admin Whitelist).
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$ENGINE_DIR = Split-Path -Parent $PSScriptRoot
$TB_ROOT = Split-Path -Parent $ENGINE_DIR
$CORE_DIR = $PSScriptRoot
$CONFIG_DIR = Join-Path $ENGINE_DIR "Config"
$DIST_DIR = Join-Path $ENGINE_DIR "Dist"

# Dot-source các thư viện nền tảng
. (Join-Path $CORE_DIR "Common-UI.ps1")
. (Join-Path $CORE_DIR "Crypto-RSA.ps1")
. (Join-Path $CORE_DIR "Feature-Registry.ps1")
. (Join-Path $CORE_DIR "License-Engine.ps1")

$WHITELIST_FILE = Join-Path $CONFIG_DIR "admin-whitelist.json"
$LEDGER_FILE = Join-Path $CONFIG_DIR "key-ledger.json"
$REQUESTS_FILE = Join-Path $CONFIG_DIR "pending-requests.json"

if (-not (Test-Path $DIST_DIR)) { New-Item -ItemType Directory -Path $DIST_DIR -Force | Out-Null }

# ==============================================================================
# 0. CỔNG XÁC THỰC ADMIN TỐI CAO (SECURITY GATE)
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

    # Nếu thiết bị mới chưa trong whitelist -> Yêu cầu nhập MasterKey
    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "          [!] CẢNH BÁO: PHÁT HIỆN THIẾT BỊ ADMIN MỚI CHƯA ĐĂNG KÝ               " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host " Thiết bị: $env:COMPUTERNAME | HWID: $currentHWID" -ForegroundColor DarkGray
    Write-Host " Vui lòng nhập Mã Khóa Chủ Tối Cao (MasterKey) hoặc nhập 'RECOVERY' nếu quên mật khẩu`n (hoặc nhập [0] để Thoát):`n" -ForegroundColor Yellow

    $attempts = 0
    while ($attempts -lt 3) {
        $attempts++
        $inputKey = Read-Host " MasterKey (Lần $attempts/3, hoặc [0] để Thoát)"
        if ($inputKey -eq "0" -or $inputKey -eq "q" -or $inputKey -eq "Q") {
            Write-Host "`n Đã hủy xác thực. Đang thoát chương trình..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            exit 0
        }
        
        # Trường hợp quên mật khẩu -> Dùng Mã Cứu Hộ Khẩn Cấp
        if ($inputKey -eq "RECOVERY" -or $inputKey -eq "recovery") {
            Write-Host "`n ================================================================================" -ForegroundColor Yellow
            Write-Host "                   CHẾ ĐỘ CỨU HỘ KHẨN CẤP (EMERGENCY RECOVERY)                  " -ForegroundColor Yellow
            Write-Host " ================================================================================" -ForegroundColor Yellow
            $recCode = Read-Host " Nhập Mã Cứu Hộ Khẩn Cấp (hoặc nhập [0] để Quay lại)"
            if ($recCode -eq "0" -or [string]::IsNullOrWhiteSpace($recCode)) {
                Write-Host " Đã hủy thao tác cứu hộ khẩn cấp." -ForegroundColor Yellow
                continue
            }
            if (Verify-EmergencyRecoveryKey -InputKey $recCode.Trim()) {
                Write-Host "`n [OK] XÁC THỰC MÃ CỨU HỘ THÀNH CÔNG!" -ForegroundColor Green
                $newPass = Read-Host " Nhập Mã MasterKey mới (hoặc [0] để Giữ nguyên)"
                if ($newPass -eq "0" -or [string]::IsNullOrWhiteSpace($newPass)) {
                    Write-Host " Giữ nguyên MasterKey cũ." -ForegroundColor Yellow
                } else {
                    $script:TB_MASTER_KEY = $newPass.Trim()
                    Write-Host " [OK] Đã đặt lại MasterKey mới thành công!" -ForegroundColor Green
                }
                
                # Lưu máy vào whitelist
                if (-not $whitelistData) {
                    $whitelistData = [PSCustomObject]@{
                        metadata = [PSCustomObject]@{ author = "Mr. Tuấn Beo"; lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
                        trustedAdmins = @()
                    }
                }
                $whitelistData.trustedAdmins += [PSCustomObject]@{
                    hwid        = $currentHWID
                    deviceName  = $env:COMPUTERNAME
                    userName    = $env:USERNAME
                    description = "Máy Admin xác thực qua Mã Cứu Hộ"
                    addedAt     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }
                Save-JsonWithBom -Path $WHITELIST_FILE -Data $whitelistData | Out-Null
                Start-Sleep -Seconds 1
                return $true
            } else {
                Write-Host " [X] Mã Cứu Hộ Khẩn Cấp không hợp lệ!" -ForegroundColor Red
            }
            continue
        }

        if ($inputKey -eq $script:TB_MASTER_KEY) {
            Write-Host "`n [OK] Xác thực MasterKey thành công! Đang thêm máy vào Danh sách trắng..." -ForegroundColor Green
            
            # Lưu HWID vào whitelist để lần sau không cần hỏi lại
            if (-not $whitelistData) {
                $whitelistData = [PSCustomObject]@{
                    metadata = [PSCustomObject]@{ author = "Mr. Tuấn Beo"; lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
                    trustedAdmins = @()
                }
            }
            $whitelistData.trustedAdmins += [PSCustomObject]@{
                hwid        = $currentHWID
                deviceName  = $env:COMPUTERNAME
                userName    = $env:USERNAME
                description = "Máy Admin xác thực bởi MasterKey"
                addedAt     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            Save-JsonWithBom -Path $WHITELIST_FILE -Data $whitelistData | Out-Null
            Start-Sleep -Seconds 1
            return $true
        } else {
            Write-Host " [X] MasterKey không chính xác!" -ForegroundColor Red
        }
    }

    Write-Host "`n Bạn đã nhập sai quá 3 lần. Từ chối quyền truy cập Admin!`n" -ForegroundColor Red
    Wait-ForUserExit -Message " Nhấn phím bất kỳ để thoát..."
    exit 1
}

# ==============================================================================
# 1. TIỆN ÍCH GHI SỔ CÁI BẢN QUYỀN (KEY LEDGER)
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
                author      = "Mr. Tuấn Beo"
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
        keyStatus    = 1 # 1 = Còn hạn / Hoạt động | 0 = Bị thu hồi
        keyString    = $KeyString
    }

    $ledger.keys += $newEntry
    $ledger.metadata.lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Save-JsonWithBom -Path $LEDGER_FILE -Data $ledger | Out-Null
    return $newEntry
}

# ==============================================================================
# 2. XEM VÀ PHÊ DUYỆT YÊU CẦU CHỜ (PENDING REQUESTS)
# ==============================================================================

function Show-PendingRequestsMenu {
    $reqData = Read-JsonWithBom -Path $REQUESTS_FILE
    $pending = @()
    if ($reqData -and $reqData.requests) {
        $pending = @($reqData.requests | Where-Object { $_.status -eq 0 })
    }

    Show-HeaderBanner -SubTitle "HÀNG ĐỢI YÊU CẦU BẢN QUYỀN CHỜ DUYỆT"

    if ($pending.Count -eq 0) {
        Write-Host " Không có yêu cầu nào đang chờ xử lý trong hệ thống.`n" -ForegroundColor Yellow
        Wait-ForUserExit -Message " Nhấn phím bất kỳ để quay lại menu..."
        return
    }

    Write-Host (" Danh sách có {0} yêu cầu đang chờ phê duyệt:`n" -f $pending.Count) -ForegroundColor Green
    for ($i = 0; $i -lt $pending.Count; $i++) {
        $r = $pending[$i]
        Write-Host (" [{0}] {1,-20} | HWID: {2,-16} | Ngày gửi: {3}" -f ($i + 1), $r.fullName, $r.hwid.Substring(0, [math]::Min(16, $r.hwid.Length)) + "...", $r.submittedAt) -ForegroundColor Cyan
    }

    Write-Host "`n [0] Quay lại" -ForegroundColor DarkGray
    $sel = Read-Host "`n Chọn số thứ tự yêu cầu cần cấp Key (hoặc nhấn [0] để Quay lại)"
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
# 3. TẠO KEY THỦ CÔNG (INTERACTIVE KEY GENERATOR)
# ==============================================================================

function Process-InteractiveKeyIssue {
    param (
        [string]$TargetHWID = "",
        [string]$TargetName = "",
        [string]$TargetEmail = ""
    )

    Show-HeaderBanner -SubTitle "CÔNG CỤ TẠO KEY BẢN QUYỀN (TƯƠNG TÁC)"

    if ([string]::IsNullOrWhiteSpace($TargetHWID)) {
        $TargetHWID = Read-Host " Nhập Mã HWID của máy cần cấp (32 ký tự, hoặc nhấn [0] để Hủy)"
        if ($TargetHWID -eq "0" -or [string]::IsNullOrWhiteSpace($TargetHWID)) {
            Write-Host " Đã hủy thao tác tạo Key." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            return
        }
    }
    if ([string]::IsNullOrWhiteSpace($TargetName)) {
        $TargetName = Read-Host " Nhập Họ và tên người sử dụng (hoặc nhấn [0] để Hủy)"
        if ($TargetName -eq "0" -or [string]::IsNullOrWhiteSpace($TargetName)) {
            Write-Host " Đã hủy thao tác tạo Key." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            return
        }
    }
    if ([string]::IsNullOrWhiteSpace($TargetEmail)) {
        $TargetEmail = Read-Host " Nhập Email / Đơn vị phòng ban (hoặc nhấn [0] để Bỏ qua/Hủy)"
        if ($TargetEmail -eq "0") {
            Write-Host " Đã hủy thao tác tạo Key." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            return
        }
        if ([string]::IsNullOrWhiteSpace($TargetEmail)) {
            $TargetEmail = "Chưa cung cấp"
        }
    }

    # Chọn Nhóm chức năng
    $matrix = Sync-FeatureMatrix
    Write-Host "`n Danh sách gói chức năng sẵn có:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $matrix.Groups.Count; $i++) {
        $g = $matrix.Groups[$i]
        Write-Host (" [{0}] {1} ({2})" -f ($i + 1), $g.groupName, $g.groupId) -ForegroundColor Cyan
    }
    Write-Host " [0] Hủy bỏ và Quay lại" -ForegroundColor DarkGray
    $grpChoice = Read-Host "`n Chọn gói nhóm [1-$($matrix.Groups.Count)] (Mặc định: 1, [0] để Hủy)"
    if ($grpChoice -eq "0") {
        Write-Host " Đã hủy thao tác tạo Key." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }
    if ([string]::IsNullOrWhiteSpace($grpChoice)) { $grpChoice = "1" }
    $selectedGroup = $matrix.Groups[[int]$grpChoice - 1]
    if (-not $selectedGroup) { $selectedGroup = $matrix.Groups[0] }

    # Chọn Thời hạn
    Write-Host "`n Thiết lập thời hạn sử dụng:" -ForegroundColor Yellow
    Write-Host " [1] 30 ngày"
    Write-Host " [2] 90 ngày (3 tháng)"
    Write-Host " [3] 365 ngày (1 năm)"
    Write-Host " [4] Vô thời hạn (LIFETIME)"
    Write-Host " [5] Tự nhập số ngày cụ thể"
    Write-Host " [0] Hủy bỏ và Quay lại" -ForegroundColor DarkGray
    $durChoice = Read-Host "`n Chọn thời hạn (Mặc định: 4 - LIFETIME, [0] để Hủy)"
    if ($durChoice -eq "0") {
        Write-Host " Đã hủy thao tác tạo Key." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }
    $days = 0
    switch ($durChoice) {
        "1" { $days = 30 }
        "2" { $days = 90 }
        "3" { $days = 365 }
        "5" { 
            $customDays = Read-Host " Nhập số ngày sử dụng (hoặc [0] để Hủy)"
            if ($customDays -eq "0" -or [string]::IsNullOrWhiteSpace($customDays)) {
                Write-Host " Đã hủy thao tác tạo Key." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                return
            }
            $days = [int]$customDays
        }
        default { $days = 0 }
    }

    # Chuyển đổi features sang hashtable
    $featuresDict = @{}
    if ($selectedGroup.features -is [System.Management.Automation.PSCustomObject]) {
        foreach ($p in $selectedGroup.features.PSObject.Properties) {
            $featuresDict[$p.Name] = [int]$p.Value
        }
    } elseif ($selectedGroup.features -is [System.Collections.IDictionary]) {
        $featuresDict = $selectedGroup.features
    }

    # Cổng xác nhận trước khi tạo (Confirmation Gate)
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host "                     THÔNG TIN TÓM TẮT TRƯỚC KHI TẠO KEY                        " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host (" Người được cấp : {0} ({1})" -f $TargetName, $TargetEmail)
    Write-Host (" Mã HWID máy    : {0}" -f $TargetHWID)
    Write-Host (" Gói bản quyền  : {0} ({1})" -f $selectedGroup.groupName, $selectedGroup.groupId)
    Write-Host (" Thời hạn       : {0}" -f (if ($days -eq 0) { "Vô thời hạn (LIFETIME)" } else { "$days ngày" }))
    Write-Host "================================================================================" -ForegroundColor Cyan

    $confirm = Read-Host " Bạn có chắc chắn muốn tạo Key này? [Y/N] (Mặc định: Y, [0/N] để Hủy)"
    if ($confirm -eq "0" -or $confirm -eq "N" -or $confirm -eq "n") {
        Write-Host " Đã hủy thao tác tạo Key." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }

    # Tiến hành tạo Key
    $newKey = Create-LicenseKey -HWID $TargetHWID -FullName $TargetName -Email $TargetEmail `
                                -GroupId $selectedGroup.groupId -Features $featuresDict `
                                -DurationDays $days -Mode "INTERACTIVE"

    $verify = Verify-LicenseKey -LicenseKeyString $newKey -CurrentHWID $TargetHWID
    $entry = Add-KeyToLedger -KeyString $newKey -Payload $verify.Payload

    # Xuất ra file key.txt trong Dist/Keys/
    $keysDir = Join-Path $DIST_DIR "Keys"
    if (-not (Test-Path $keysDir)) { New-Item -ItemType Directory -Path $keysDir -Force | Out-Null }
    $cleanName = ($TargetName -replace '[\\/:*?"<>| ]', '_')
    $outFile = Join-Path $keysDir "$($entry.stt)_$cleanName.key.txt"
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($outFile, $newKey, $utf8WithBom)

    Write-Host "`n [OK] TẠO KEY THÀNH CÔNG!" -ForegroundColor Green
    Write-Host " Mã Key: $newKey" -ForegroundColor Yellow
    Write-Host " Đã xuất tệp tại: $outFile" -ForegroundColor Cyan
    Write-Host " Đã ghi vào Sổ cái bản quyền (STT: $($entry.stt))`n" -ForegroundColor DarkGray

    Wait-ForUserExit -Message " Nhấn phím bất kỳ để tiếp tục..."
}

# ==============================================================================
# 4. ĐÓNG GÓI SẴN CHO NGƯỜI DÙNG (BUILD PRE-PACKAGED / ZERO-TOUCH CLIENT)
# ==============================================================================

function Build-PrePackagedClientBundle {
    Show-HeaderBanner -SubTitle "ĐÓNG GÓI SẴN CHO NGƯỜI DÙNG (ZERO-TOUCH PRE-PACKAGE)"

    Write-Host " Chế độ này tạo một thư mục cài đặt độc lập nhúng sẵn Key." -ForegroundColor Yellow
    Write-Host " Người dùng chỉ cần mở file Cài Đặt là tự động kích hoạt và KHÓA CỨNG vào máy đầu tiên." -ForegroundColor Yellow
    Write-Host " Hoạt động 100% trên máy Offline nội bộ không cần Internet!`n" -ForegroundColor Yellow

    $TargetName = Read-Host " Nhập Họ và tên người nhận gói cài đặt (hoặc nhấn [0] để Hủy)"
    if ($TargetName -eq "0" -or [string]::IsNullOrWhiteSpace($TargetName)) {
        Write-Host " Đã hủy thao tác đóng gói." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }

    $TargetEmail = Read-Host " Nhập Email / Đơn vị phòng ban (hoặc nhấn [0] để Hủy)"
    if ($TargetEmail -eq "0") {
        Write-Host " Đã hủy thao tác đóng gói." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }
    if ([string]::IsNullOrWhiteSpace($TargetEmail)) { $TargetEmail = "Chưa cung cấp" }

    # Chọn Nhóm chức năng
    $matrix = Sync-FeatureMatrix
    Write-Host "`n Danh sách gói chức năng:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $matrix.Groups.Count; $i++) {
        $g = $matrix.Groups[$i]
        Write-Host (" [{0}] {1}" -f ($i + 1), $g.groupName) -ForegroundColor Cyan
    }
    Write-Host " [0] Hủy bỏ và Quay lại" -ForegroundColor DarkGray
    $grpChoice = Read-Host "`n Chọn gói nhóm [1-$($matrix.Groups.Count)] (Mặc định: 1, [0] để Hủy)"
    if ($grpChoice -eq "0") {
        Write-Host " Đã hủy thao tác đóng gói." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }
    if ([string]::IsNullOrWhiteSpace($grpChoice)) { $grpChoice = "1" }
    $selectedGroup = $matrix.Groups[[int]$grpChoice - 1]
    if (-not $selectedGroup) { $selectedGroup = $matrix.Groups[0] }

    # Tạo Key dạng PRE_PACKAGED (HWID để trống, sẽ tự khóa trên máy chạy đầu tiên)
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

    # Đường dẫn xuất gói
    $cleanName = ($TargetName -replace '[\\/:*?"<>| ]', '_')
    $bundleDir = Join-Path $DIST_DIR "TB-Toolbox-PrePackaged-$cleanName"
    if (Test-Path $bundleDir) { Remove-Item $bundleDir -Recurse -Force }

    $bundleBatDir = Join-Path $bundleDir "@Actions"
    $bundleCoreDir = Join-Path $bundleDir "Core"
    $bundleConfigDir = Join-Path $bundleDir "Config"
    $bundleLogsDir = Join-Path $bundleDir "Logs"

    New-Item -ItemType Directory -Path $bundleBatDir -Force | Out-Null
    New-Item -ItemType Directory -Path $bundleCoreDir -Force | Out-Null
    New-Item -ItemType Directory -Path $bundleConfigDir -Force | Out-Null
    New-Item -ItemType Directory -Path $bundleLogsDir -Force | Out-Null

    # Chép các file hệ thống cốt lõi
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

    # Chép các Engine của các chức năng được phép bật (= 1)
    if ($featuresDict["F01_CLEANER"] -eq 1) {
        Copy-Item (Join-Path $CORE_DIR "Config-Manager.ps1") $bundleCoreDir -Force
        Copy-Item (Join-Path $CORE_DIR "Engine-Cleaner.ps1") $bundleCoreDir -Force
        Copy-Item (Join-Path $CONFIG_DIR "cleaner-config.json") $bundleConfigDir -Force -ErrorAction SilentlyContinue
        Copy-Item (Join-Path $TB_ROOT "@Actions\[500]-Don-Dep-Bo-Nho-Tam-He-Thong.bat") $bundleBatDir -Force
    }

    # Ghi file Key nhúng sẵn vào Config/license.key
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText((Join-Path $bundleConfigDir "license.key"), $preKey, $utf8WithBom)

    # Sinh file cài đặt [001]-Cai-Dat-TB-Toolbox.bat cho Client
    $clientBatContent = @"
@echo off
setlocal
cd /d "%~dp0"
title Cai Dat & Kich Hoat TB-Toolbox
chcp 65001 >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Core\Client-Bootstrap.ps1"
exit /b
"@
    # Ghi file BAT không có BOM
    $asciiEnc = [System.Text.Encoding]::ASCII
    [System.IO.File]::WriteAllText((Join-Path $bundleDir "[001]-Cai-Dat-TB-Toolbox.bat"), $clientBatContent, $asciiEnc)

    # Lưu vào Sổ cái
    $verify = Verify-LicenseKey -LicenseKeyString $preKey -CurrentHWID ""
    $entry = Add-KeyToLedger -KeyString $preKey -Payload $verify.Payload

    Write-Host "`n================================================================================" -ForegroundColor Green
    Write-Host "                [OK] ĐÃ ĐÓNG GÓI THÀNH CÔNG CLIENT PRE-PACKAGED                 " -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host " Thư mục gói cài đặt: $bundleDir" -ForegroundColor Cyan
    Write-Host " STT Sổ cái: $($entry.stt) | KeyId: $($entry.keyId)" -ForegroundColor DarkGray
    Write-Host " Hướng dẫn bàn giao: Chỉ cần nén thư mục này gửi cho khách hàng/nhân viên." -ForegroundColor Yellow
    Write-Host " Khi mở [001]-Cai-Dat-TB-Toolbox.bat, chương trình sẽ:" -ForegroundColor Yellow
    Write-Host "   1. Hiển thị Cảnh báo chữ ĐỎ răn đe chia sẻ." -ForegroundColor Red
    Write-Host "   2. Tự động khóa bản quyền vào HWID máy đầu tiên (First-Run HWID Lock)." -ForegroundColor Yellow
    Write-Host "   3. Khóa ngay lập tức nếu bị copy sang máy khác!" -ForegroundColor Yellow
    Write-Host "================================================================================`n" -ForegroundColor Green

    Wait-ForUserExit -Message " Nhấn phím bất kỳ để tiếp tục..."
}

# ==============================================================================
# 5. SỔ CÁI BẢN QUYỀN (KEY LEDGER VIEWER)
# ==============================================================================

function Show-KeyLedgerViewer {
    $ledger = Read-JsonWithBom -Path $LEDGER_FILE
    Show-HeaderBanner -SubTitle "SỔ CÁI QUẢN LÝ BẢN QUYỀN (KEY LEDGER)"

    if ($null -eq $ledger -or -not $ledger.keys -or $ledger.keys.Count -eq 0) {
        Write-Host " Sổ cái chưa có Key nào được tạo.`n" -ForegroundColor Yellow
        Wait-ForUserExit -Message " Nhấn phím bất kỳ để quay lại..."
        return
    }

    Write-Host (" Tổng số Key đã cấp: {0}`n" -f $ledger.keys.Count) -ForegroundColor Green
    $header = " {0,-4} | {1,-20} | {2,-16} | {3,-12} | {4,-10} | {5,-12}" -f "STT", "NGƯỜI NHẬN", "HWID", "GÓI", "TRẠNG THÁI", "HẾT HẠN"
    Write-Host $header -ForegroundColor Green
    Write-Host ("-" * 85) -ForegroundColor DarkGray

    foreach ($k in $ledger.keys) {
        $hwidShort = if ([string]::IsNullOrWhiteSpace($k.hwid)) { "[Chưa bind]" } else { $k.hwid.Substring(0, [math]::Min(10, $k.hwid.Length)) + "..." }
        $sttStr = if ($k.keyStatus -eq 1) { "HIỆU LỰC" } else { "THU HỒI" }
        $expShort = if ($k.expiresAt) { $k.expiresAt.Substring(0, [math]::Min(10, $k.expiresAt.Length)) } else { "N/A" }
        $row = " {0,-4} | {1,-20} | {2,-16} | {3,-12} | {4,-10} | {5,-12}" -f $k.stt, $k.fullName, $hwidShort, $k.groupId, $sttStr, $expShort
        Write-Host $row
    }

    Write-Host ("-" * 85) -ForegroundColor DarkGray
    Write-Host "`n [T] Thu hồi Key | [0] Quay lại" -ForegroundColor Yellow
    $action = Read-Host " Chọn thao tác (hoặc nhấn [0] để Quay lại)"
    if ($action -eq "0" -or [string]::IsNullOrWhiteSpace($action)) { return }
    if ($action -eq "T" -or $action -eq "t") {
        $targetStt = Read-Host " Nhập STT Key muốn thu hồi (ví dụ: 001, hoặc [0] để Hủy)"
        if ($targetStt -eq "0" -or [string]::IsNullOrWhiteSpace($targetStt)) {
            Write-Host " Đã hủy thao tác thu hồi." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            return
        }
        $entry = $ledger.keys | Where-Object { $_.stt -eq $targetStt }
        if ($entry) {
            $entry.keyStatus = 0
            Save-JsonWithBom -Path $LEDGER_FILE -Data $ledger | Out-Null
            Write-Host " [OK] Đã thu hồi Key của $($entry.fullName) thành công!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        } else {
            Write-Host " Không tìm thấy Key có STT: $targetStt" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

# ==============================================================================
# 6. QUẢN LÝ MẬT KHẨU & CỨU HỘ KHẨN CẤP
# ==============================================================================

function Manage-SecurityAndRecovery {
    Show-HeaderBanner -SubTitle "QUẢN LÝ MẬT KHẨU & CỨU HỘ KHẨN CẤP"
    $recKey = Get-EmergencyRecoveryKey
    
    Write-Host " [1] Xem Mã Cứu Hộ Khẩn Cấp (Emergency Recovery Key)" -ForegroundColor Cyan
    Write-Host " [2] Đổi Mã MasterKey quản trị mới" -ForegroundColor Cyan
    Write-Host " [3] Tạo lại Mã Cứu Hộ mới (Key Rotation)" -ForegroundColor Cyan
    Write-Host " [0] Quay lại`n" -ForegroundColor DarkGray

    $subChoice = Read-Host " Nhập lựa chọn [0-3]"
    switch ($subChoice) {
        "1" {
            Write-Host "`n ================================================================================" -ForegroundColor Green
            Write-Host "                   MÃ CỨU HỘ KHẨN CẤP ĐANG HOẠT ĐỘNG                            " -ForegroundColor Yellow
            Write-Host " ================================================================================" -ForegroundColor Green
            Write-Host " Mã cứu hộ của bạn: $recKey" -ForegroundColor Green
            Write-Host " Lưu ý: Hãy lưu mã này vào Ghi chú điện thoại hoặc nơi an toàn." -ForegroundColor Yellow
            Write-Host " Nếu quên MasterKey trên bất kỳ máy tính nào, chỉ cần nhập mã này để mở khóa!" -ForegroundColor Yellow
            Write-Host " ================================================================================`n" -ForegroundColor Green
            Wait-ForUserExit -Message " Nhấn phím bất kỳ để quay lại..."
        }
        "2" {
            $oldKey = Read-Host " Nhập MasterKey hiện tại (hoặc [0] để Hủy)"
            if ($oldKey -eq "0" -or [string]::IsNullOrWhiteSpace($oldKey)) {
                Write-Host " Đã hủy thao tác đổi MasterKey." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                return
            }
            if ($oldKey -eq $script:TB_MASTER_KEY) {
                $newKey = Read-Host " Nhập MasterKey mới muốn đổi (hoặc [0] để Hủy)"
                if ($newKey -eq "0" -or [string]::IsNullOrWhiteSpace($newKey)) {
                    Write-Host " Đã hủy thao tác đổi MasterKey." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                    return
                }
                $script:TB_MASTER_KEY = $newKey.Trim()
                Write-Host " [OK] Đã đổi MasterKey thành công!" -ForegroundColor Green
                Start-Sleep -Seconds 1
            } else {
                Write-Host " [X] Mật khẩu cũ không chính xác!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        "3" {
            $confirm = Read-Host " Bạn có chắc chắn muốn tạo lại Mã Cứu Hộ mới? [Y/N] (Mặc định: N, [0/N] để Hủy)"
            if ($confirm -eq "Y" -or $confirm -eq "y") {
                Initialize-RSAKeyPair -ForceRegenerate | Out-Null
                $newRec = Get-EmergencyRecoveryKey
                Write-Host " [OK] Đã tạo Mã Cứu Hộ mới: $newRec" -ForegroundColor Green
                Wait-ForUserExit -Message " Nhấn phím bất kỳ để tiếp tục..."
            } else {
                Write-Host " Đã hủy tạo mới Mã Cứu Hộ." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
        default { return }
    }
}

# ==============================================================================
# 7. MENU CHÍNH CỦA ADMIN CONSOLE
# ==============================================================================

function Start-AdminConsole {
    if (-not (Authenticate-Admin)) { return }

    while ($true) {
        Show-HeaderBanner -SubTitle "TRUNG TÂM QUẢN TRỊ BẢN QUYỀN & HỆ THỐNG (ADMIN)"

        Write-Host " [1] Xem & Phê duyệt yêu cầu cấp Key (Pending Requests)" -ForegroundColor Cyan
        Write-Host " [2] Tạo Key bản quyền mới (Interactive Key Generator)" -ForegroundColor Cyan
        Write-Host " [3] Đóng gói sẵn cho người dùng (Build Pre-Packaged / Zero-Touch Client)" -ForegroundColor Green
        Write-Host " [4] Kiểm tra & Tùy biến quyền người dùng (User Permission Override)" -ForegroundColor Cyan
        Write-Host " [5] Sổ cái quản lý Key (Key Ledger - Xem, Thu hồi)" -ForegroundColor Cyan
        Write-Host " [6] Bảng ma trận tính năng & Nhóm bản quyền (Feature Matrix)" -ForegroundColor Cyan
        Write-Host " [7] Quản lý Mật khẩu & Cứu hộ (Đổi MasterKey / Xem Mã Cứu Hộ)" -ForegroundColor Yellow
        Write-Host " [0] Thoát chương trình`n" -ForegroundColor DarkGray

        $choice = Read-Host " Mời bạn chọn chức năng [0-7]"
        switch ($choice) {
            "1" { Show-PendingRequestsMenu }
            "2" { Process-InteractiveKeyIssue }
            "3" { Build-PrePackagedClientBundle }
            "4" { 
                Show-HeaderBanner -SubTitle "TÙY BIẾN QUYỀN RIÊNG TỪNG NGƯỜI DÙNG"
                $uid = Read-Host " Nhập Identifier / HWID / Email người dùng cần tùy biến (hoặc [0] để Hủy)"
                if ($uid -eq "0" -or [string]::IsNullOrWhiteSpace($uid)) {
                    Write-Host " Đã hủy thao tác." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                    continue
                }
                $eff = Get-EffectiveUserPermissions -UserIdentifier $uid
                Write-Host "`n Chế độ hiện tại: $($eff.Mode)" -ForegroundColor Yellow
                $eff.Features | Out-String
                $fId = Read-Host " Nhập Mã tính năng muốn thay đổi (ví dụ: F01_CLEANER, hoặc [0] để Hủy)"
                if ($fId -eq "0" -or [string]::IsNullOrWhiteSpace($fId)) {
                    Write-Host " Đã hủy thao tác." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                    continue
                }
                $state = Read-Host " Nhập trạng thái mới [0 = TẮT, 1 = BẬT, Q = HỦY]"
                if ($state -eq "0" -or $state -eq "1") {
                    Set-UserFeatureOverride -UserIdentifier $uid -GroupId "GRP_DEFAULT" -FeatureOverrides @{ $fId = [int]$state }
                    Write-Host " [OK] Đã cập nhật quyền riêng thành công!" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                } else {
                    Write-Host " Đã hủy cập nhật trạng thái." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                }
            }
            "5" { Show-KeyLedgerViewer }
            "6" { 
                Show-FeatureMatrixTable
                Wait-ForUserExit -Message " Nhấn phím bất kỳ để quay lại menu..."
            }
            "7" { Manage-SecurityAndRecovery }
            "0" { 
                Write-Host "`n [OK] Đang thoát chương trình quản trị. Tạm biệt!`n" -ForegroundColor Green
                return 
            }
            default { Write-Host " Lựa chọn không hợp lệ!" -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# Khởi chạy Admin Console khi chạy trực tiếp (không dot-source)
if ($MyInvocation.InvocationName -ne '.') {
    Start-AdminConsole
}
