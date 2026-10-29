# ==============================================================================
# TB-TOOLBOX - CLIENT BOOTSTRAP & ACTIVATION ENGINE (Client-Bootstrap.ps1)
# Bản quyền thuộc về: Mr. Tuấn Beo (TuanBeoToolbox)
# Chức năng: Bộ cài đặt phía Client hỗ trợ cả 2 hình thức:
#            1. Hình thức Tương tác (Self-Enrollment: Nhập key/tệp key.txt)
#            2. Hình thức Đóng gói sẵn (Pre-Packaged / Zero-Touch: Tự động Apply Key,
#               Cảnh báo chữ ĐỎ, Khóa cứng máy đầu tiên First-Run HWID Lock,
#               chống sao chép sang máy khác và hoạt động hoàn hảo Offline).
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$ENGINE_DIR = Split-Path -Parent $PSScriptRoot
$TB_ROOT = Split-Path -Parent $ENGINE_DIR
$CORE_DIR = $PSScriptRoot
$CONFIG_DIR = Join-Path $ENGINE_DIR "Config"
$BAT_DIR = Join-Path $TB_ROOT "@File-BAT"
$LICENSE_KEY_FILE = Join-Path $CONFIG_DIR "license.key"

# Dot-source các thư viện cần thiết
. (Join-Path $CORE_DIR "Common-UI.ps1")
. (Join-Path $CORE_DIR "Feature-Registry.ps1")
. (Join-Path $CORE_DIR "License-Engine.ps1")

# ==============================================================================
# 1. CẤP PHÁT LAUNCHER @File-BAT ĐỘNG THEO QUYỀN (DYNAMIC MODULE HYDRATION)
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

    # Module F01: Dọn dẹp bộ nhớ tạm
    $cleanerBat = Join-Path $BAT_DIR "[500]-Don-Dep-Bo-Nho-Tam-He-Thong.bat"
    if ($featuresDict["F01_CLEANER"] -eq 1 -or $featuresDict["FN0001"] -eq 1) {
        if (-not (Test-Path $cleanerBat)) {
            $cleanerContent = "@echo off`r`nsetlocal`r`ncd /d `"%~dp0`"`r`ntitle [500] Don Dep Bo Nho Tam He Thong - TuanBeo Toolbox`r`nchcp 65001 >nul 2>&1`r`n`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"`..\\Core\\Engine-Cleaner.ps1`"`r`nexit /b`r`n"
            [System.IO.File]::WriteAllText($cleanerBat, $cleanerContent, [System.Text.Encoding]::ASCII)
        }
    } else {
        # Nếu bị thu hồi / không được cấp -> Tự động thu hồi / xóa file launcher
        if (Test-Path $cleanerBat) { Remove-Item $cleanerBat -Force -ErrorAction SilentlyContinue }
    }

    # Module F02: Hẹn giờ tắt máy & Quản lý nguồn điện
    $powerBat = Join-Path $BAT_DIR "[501]-Hen-Gio-Tat-May-Va-Quan-Ly-Nguon.bat"
    if ($featuresDict["F02_SHUTDOWN_TIMER"] -eq 1 -or $featuresDict["FN0002"] -eq 1) {
        if (-not (Test-Path $powerBat)) {
            $powerContent = "@echo off`r`nsetlocal`r`ncd /d `"%~dp0`"`r`ntitle [501] Hen Gio Tat May Va Quan Ly Nguon - TuanBeo Toolbox`r`nchcp 65001 >nul 2>&1`r`n`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"`..\\Core\\Engine-PowerManager.ps1`"`r`nexit /b`r`n"
            [System.IO.File]::WriteAllText($powerBat, $powerContent, [System.Text.Encoding]::ASCII)
        }
    } else {
        # Nếu bị thu hồi / không được cấp -> Tự động thu hồi / xóa file launcher
        if (Test-Path $powerBat) { Remove-Item $powerBat -Force -ErrorAction SilentlyContinue }
    }
}

# ==============================================================================
# 2. XỬ LÝ HÌNH THỨC 2: PRE-PACKAGED / ZERO-TOUCH
# ==============================================================================

function Process-PrePackagedFlow {
    Show-HeaderBanner -SubTitle "KÍCH HOẠT BẢN QUYỀN ĐÓNG GÓI SẴN (PRE-PACKAGED)"

    # Hiển thị Cảnh báo chữ ĐỎ nghiêm ngặt
    Show-PrePackagedWarningBanner

    Write-Host " Hệ thống đang tiến hành kiểm tra và kích hoạt bản quyền cho thiết bị..." -ForegroundColor Cyan
    $currentHWID = Get-MachineHWID

    # Thực hiện First-Run HWID Lock
    $lockRes = Lock-PrePackagedKeyToCurrentMachine -KeyFilePath $LICENSE_KEY_FILE -CurrentHWID $currentHWID

    if ($lockRes.Success) {
        Write-Host "`n [OK] $($lockRes.Message)" -ForegroundColor Green
        Write-Host ("      Người sở hữu : {0}" -f $lockRes.Payload.fullName) -ForegroundColor Cyan
        Write-Host ("      HWID Máy     : {0}" -f $currentHWID) -ForegroundColor DarkGray
        Write-Host ("      Thời hạn     : {0}" -f $lockRes.Payload.expiresAt) -ForegroundColor Yellow

        # Đồng bộ các file launcher theo danh sách tính năng được cấp
        Sync-ClientLaunchers -AuthorizedFeatures $lockRes.Payload.features

        Write-Host "`n ================================================================================" -ForegroundColor Green
        Write-Host "                      CÀI ĐẶT & KÍCH HOẠT HOÀN TẤT!                             " -ForegroundColor Green
        Write-Host " ================================================================================" -ForegroundColor Green
        Write-Host " Bạn đã có thể sử dụng các công cụ được cấp phép trong thư mục @File-BAT." -ForegroundColor Yellow
        Write-Host "================================================================================`n" -ForegroundColor DarkGray
    } else {
        Write-Host "`n [X] THẤT BẠI: $($lockRes.Message)" -ForegroundColor Red
        Write-Host " Bản quyền không hợp lệ hoặc thư mục này đã bị sao chép sang máy tính khác sử dụng." -ForegroundColor Red
        Write-Host " Vui lòng liên hệ Admin Tuấn Beo để được hỗ trợ cấp lại Key!`n" -ForegroundColor Yellow
    }

    Wait-ForUserExit -Message " Nhấn phím bất kỳ để đóng..."
}

# ==============================================================================
# 3. XỬ LÝ HÌNH THỨC 1: SELF-ENROLLMENT / TƯƠNG TÁC
# ==============================================================================

function Process-InteractiveActivationFlow {
    Show-HeaderBanner -SubTitle "KÍCH HOẠT BẢN QUYỀN TB-TOOLBOX"

    $currentHWID = Get-MachineHWID
    Write-Host " Mã định danh phần cứng (HWID) của máy bạn:" -ForegroundColor Yellow
    Write-Host " >> $currentHWID <<" -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [1] Nhập chuỗi Mã Key trực tiếp" -ForegroundColor Cyan
    Write-Host " [2] Nạp từ tệp key.txt có sẵn" -ForegroundColor Cyan
    Write-Host " [3] Gửi yêu cầu cấp Key mới lên Admin Tuấn Beo" -ForegroundColor Cyan
    Write-Host " [0] Thoát chương trình`n" -ForegroundColor DarkGray

    $opt = Read-Host " Chọn thao tác [0-3]"
    if ($opt -eq "0" -or [string]::IsNullOrWhiteSpace($opt)) { return }
    $inputKeyString = ""

    switch ($opt) {
        "1" {
            $inputKeyString = Read-Host "`n Dán chuỗi Mã Key của bạn vào đây (hoặc nhấn [0] để Quay lại)"
            if ($inputKeyString -eq "0" -or [string]::IsNullOrWhiteSpace($inputKeyString)) {
                Write-Host " Đã hủy thao tác nhập Key." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                return
            }
        }
        "2" {
            $filePath = Read-Host "`n Nhập đường dẫn tệp key (Mặc định: key.txt, hoặc nhấn [0] để Quay lại)"
            if ($filePath -eq "0") {
                Write-Host " Đã hủy thao tác." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                return
            }
            if ([string]::IsNullOrWhiteSpace($filePath)) { $filePath = "key.txt" }
            if (Test-Path $filePath) {
                $inputKeyString = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8).Trim()
            } else {
                Write-Host " Không tìm thấy tệp tại: $filePath" -ForegroundColor Red
                Wait-ForUserExit -Message " Nhấn phím bất kỳ để quay lại..."
                return
            }
        }
        "3" {
            Show-HeaderBanner -SubTitle "ĐĂNG KÝ CẤP BẢN QUYỀN MỚI"
            $name = Read-Host " Họ và tên của bạn (hoặc nhấn [0] để Hủy)"
            if ($name -eq "0" -or [string]::IsNullOrWhiteSpace($name)) {
                Write-Host " Đã hủy thao tác đăng ký." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                return
            }
            $email = Read-Host " Email hoặc Số điện thoại (hoặc nhấn [0] để Hủy)"
            if ($email -eq "0") {
                Write-Host " Đã hủy thao tác đăng ký." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                return
            }
            if ([string]::IsNullOrWhiteSpace($email)) { $email = "Chưa cung cấp" }

            $note = Read-Host " Nhu cầu sử dụng (để trống để cấp mặc định, hoặc [0] để Hủy)"
            if ($note -eq "0") {
                Write-Host " Đã hủy thao tác đăng ký." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                return
            }

            # Ghi vào hàng đợi yêu cầu chờ (pending-requests)
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
                status      = 0 # 0 = Chờ duyệt
            }
            $reqStore.requests += $newReq
            Save-JsonWithBom -Path $reqFile -Data $reqStore | Out-Null

            Write-Host "`n [OK] ĐÃ GHI NHẬN YÊU CẦU THÀNH CÔNG!" -ForegroundColor Green
            Write-Host " Vui lòng gửi mã HWID của bạn cho Admin Tuấn Beo để được phê duyệt:`n" -ForegroundColor Yellow
            Write-Host " HWID: $currentHWID" -ForegroundColor Cyan
            Write-Host "`n Sau khi nhận được tệp key.txt, bạn mở lại chương trình để kích hoạt.`n" -ForegroundColor DarkGray
            Wait-ForUserExit -Message " Nhấn phím bất kỳ để tiếp tục..."
            return
        }
        default { return }
    }

    if ([string]::IsNullOrWhiteSpace($inputKeyString)) {
        Write-Host " Mã Key không được để trống!" -ForegroundColor Red
        Wait-ForUserExit -Message " Nhấn phím bất kỳ để tiếp tục..."
        return
    }

    # Kiểm tra tính hợp lệ của Key
    $verify = Verify-LicenseKey -LicenseKeyString $inputKeyString -CurrentHWID $currentHWID
    if ($verify.IsValid) {
        # Lưu và khóa chặt 3 neo phần cứng (File + DPAPI + Registry)
        Save-LicenseTripleAnchor -KeyString $inputKeyString -Payload $verify.Payload -CurrentHWID $currentHWID

        Write-Host "`n [OK] KÍCH HOẠT BẢN QUYỀN THÀNH CÔNG!" -ForegroundColor Green
        Write-Host ("      Người dùng : {0}" -f $verify.Payload.fullName) -ForegroundColor Cyan
        Write-Host ("      Thời hạn   : {0}" -f $verify.Payload.expiresAt) -ForegroundColor Yellow

        # Sinh launcher cho các chức năng hợp lệ
        Sync-ClientLaunchers -AuthorizedFeatures $verify.Payload.features

        Write-Host "`n Bạn đã có thể sử dụng các công cụ trong thư mục @File-BAT.`n" -ForegroundColor Green
    } else {
        Write-Host "`n [X] KÍCH HOẠT THẤT BẠI: $($verify.Error)" -ForegroundColor Red
    }

    Wait-ForUserExit -Message " Nhấn phím bất kỳ để hoàn tất..."
}

# ==============================================================================
# 4. ENTRY POINT
# ==============================================================================

function Start-ClientBootstrap {
    # Nếu đã có sẵn file Config/license.key -> Xử lý tự động theo Pre-Packaged flow
    if (Test-Path $LICENSE_KEY_FILE) {
        Process-PrePackagedFlow
    } else {
        # Nếu chưa có key -> Xử lý theo Interactive flow
        Process-InteractiveActivationFlow
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-ClientBootstrap
}
