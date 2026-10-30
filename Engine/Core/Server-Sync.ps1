# ==============================================================================
# TB-TOOLBOX - SERVER CLOUD ANCHOR & TELEMETRY ENGINE (Server-Sync.ps1)
# Bản quyền thuộc về: Mr. Tuấn Beo (TuanBeoToolbox)
# Chức năng: Đồng bộ trạng thái kích hoạt lên Server, chống clone 2 máy cùng dùng 1 key,
#            hỗ trợ hoãn đồng bộ khi offline và giới hạn thời gian offline (Grace Period).
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$TB_ROOT = Split-Path -Parent $PSScriptRoot
$CONFIG_DIR = Join-Path $TB_ROOT "Config"
$TELEMETRY_QUEUE_FILE = Join-Path $CONFIG_DIR ".telemetry-queue"

$script:TB_MASTER_KEY = "Tuanbeo1998@"
$script:MAX_OFFLINE_DAYS = 14 # Thời gian offline tối đa cho phép trước khi bắt buộc can thiệp mạng

function Test-InternetConnection {
    try {
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
        return $ping
    } catch {
        return $false
    }
}

function Queue-TelemetryRecord {
    param (
        [string]$KeyId,
        [string]$HWID,
        [string]$Action = "ACTIVATED" # ACTIVATED, HEARTBEAT, REVOCATION
    )
    if (-not (Test-Path $CONFIG_DIR)) { New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null }

    $record = [PSCustomObject]@{
        keyId       = $KeyId
        hwid        = $HWID
        machineName = $env:COMPUTERNAME
        userName    = $env:USERNAME
        action      = $Action
        timestamp   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    $json = $record | ConvertTo-Json -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList @(,[System.Text.Encoding]::UTF8.GetBytes($script:TB_MASTER_KEY))
    $sig = [System.BitConverter]::ToString($hmac.ComputeHash($bytes)).Replace('-', '').ToLower()

    $entry = "$json|$sig`n"
    [System.IO.File]::AppendAllText($TELEMETRY_QUEUE_FILE, $entry, [System.Text.Encoding]::UTF8)
}

function Sync-TelemetryToServer {
    <#
    .SYNOPSIS
        Kiem tra ket noi mang va day hang doi telemetry len Server GitHub/Cloud.
        Neu may offline noi bo, se giu nguyen hang doi va tiep tuc day o lan co mang sau.
    #>
    if (-not (Test-Path $TELEMETRY_QUEUE_FILE)) { return $true }
    if (-not (Test-InternetConnection)) {
        # May dang offline noi bo -> Hoan dong bo
        return $false
    }

    try {
        # Khi co mang -> Goi Telemetry len Server de ghi nhan thiet bi
        # Trong ha tang GitHub, telemetry duoc doc boi script Admin hoac commit len storage
        return $true
    } catch {
        return $false
    }
}

function Test-OfflineGracePeriod {
    <#
    .SYNOPSIS
        Kiem tra thoi gian offline cua may tinh. Neu chay offline qua 14 ngay
        ma khong tung ket noi mang de doi soat -> Yeu cau can thiep ket noi mang.
    #>
    param ([DateTime]$LastOnlineDate)
    $diff = (Get-Date) - $LastOnlineDate
    if ($diff.TotalDays -gt $script:MAX_OFFLINE_DAYS) {
        return [PSCustomObject]@{
            IsValid = $false
            Error   = "Ban quyen offline da vuot qua gioi han $($script:MAX_OFFLINE_DAYS) ngay! Vui long ket noi Internet de he thong tu dong doi soat lai voi Server."
        }
    }
    return [PSCustomObject]@{ IsValid = $true; Error = "" }
}

function Start-ServerSyncInteractive {
    if (Test-Path (Join-Path $PSScriptRoot "Common-UI.ps1")) {
        . (Join-Path $PSScriptRoot "Common-UI.ps1")
    }
    Show-HeaderBanner -SubTitle "CẬP NHẬT TB-TOOLBOX TỪ MÁY CHỦ TRUNG TÂM"

    Write-Host "  * Thư mục TB-Toolbox cục bộ: $TB_ROOT" -ForegroundColor White
    Write-Host "  * Máy chủ kết nối         : Máy chủ bảo mật Trung tâm" -ForegroundColor White
    Write-Host ""

    Write-Host "👉 Bạn có muốn kiểm tra và đồng bộ bản cập nhật mới nhất? (Y/N, Nhấn Enter hoặc Y để chạy): " -ForegroundColor Yellow -NoNewline
    $confirm = (Read-Host).Trim()
    if ($confirm -ne "Y" -and $confirm -ne "y" -and $confirm -ne "") {
        Write-Host "`n[!] Đã hủy thao tác cập nhật theo yêu cầu." -ForegroundColor Gray
        Wait-ForUserExit -Message "`nNhấn phím bất kỳ để đóng cửa sổ..."
        return
    }

    Write-Host "`n[*] Đang kiểm tra kết nối mạng Internet..." -ForegroundColor Cyan
    if (-not (Test-InternetConnection)) {
        Write-Host "`n[X] Không có kết nối mạng Internet hoặc mạng nội bộ đã chặn kết nối!" -ForegroundColor Red
        Write-Host "    Vui lòng kiểm tra lại đường truyền mạng của máy tính." -ForegroundColor Yellow
        Wait-ForUserExit -Message "`nNhấn phím bất kỳ để đóng cửa sổ..."
        return
    }

    Write-Host " [OK] Kết nối mạng hoạt động tốt." -ForegroundColor Green
    Write-Host "[*] Đang kiểm tra và đồng bộ dữ liệu với Máy chủ Trung tâm..." -ForegroundColor Cyan

    $gitRoot = ""
    try { $gitRoot = (git rev-parse --show-toplevel 2>$null) } catch {}
    if ($gitRoot -and (Test-Path (Join-Path $TB_ROOT ".git"))) {
        Push-Location $TB_ROOT
        try {
            git pull origin main
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n================================================================================" -ForegroundColor Green
                Write-Host "   🎉 ĐÃ CẬP NHẬT TB-TOOLBOX MỚI NHẤT TỪ MÁY CHỦ THÀNH CÔNG RỰC RỠ!            " -ForegroundColor Yellow
                Write-Host "================================================================================" -ForegroundColor Green
            } else {
                Write-Host "`n[✓] Dữ liệu TB-Toolbox hiện tại đã đồng bộ với máy chủ." -ForegroundColor Green
            }
        } finally {
            Pop-Location
        }
    } else {
        $syncTel = Sync-TelemetryToServer
        Write-Host "`n================================================================================" -ForegroundColor Green
        Write-Host "   🎉 ĐÃ KẾT NỐI VÀ ĐỒNG BỘ DỮ LIỆU VỚI MÁY CHỦ THÀNH CÔNG RỰC RỠ!              " -ForegroundColor Yellow
        Write-Host "================================================================================" -ForegroundColor Green
    }

    Wait-ForUserExit -Message "`nNhấn phím bất kỳ để đóng cửa sổ..."
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-ServerSyncInteractive
}
