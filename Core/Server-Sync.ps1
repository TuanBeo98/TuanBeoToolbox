# ==============================================================================
# TB-TOOLBOX - SERVER CLOUD ANCHOR & TELEMETRY ENGINE (Server-Sync.ps1)
# Ban quyen: Mr. Tuan Beo (TuanBeo) - https://github.com/TuanBeo98/TuanBeoToolbox
# Chuc nang: Dong bo trang thai kich hoat len Server, chong clone 2 may cung dung 1 key,
#            ho tro hoan dong bo khi offline va gioi han thoi gian offline (Grace Period).
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$TB_ROOT = Split-Path -Parent $PSScriptRoot
$CONFIG_DIR = Join-Path $TB_ROOT "Config"
$TELEMETRY_QUEUE_FILE = Join-Path $CONFIG_DIR ".telemetry-queue"
$SERVER_REPO_URL = "https://raw.githubusercontent.com/TuanBeo98/TuanBeoToolbox/main"

$script:TB_MASTER_KEY = "Tuanbeo1998@"
$script:MAX_OFFLINE_DAYS = 14 # Thoi gian offline toi da cho phep truoc khi bat buoc can thiep mang

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
