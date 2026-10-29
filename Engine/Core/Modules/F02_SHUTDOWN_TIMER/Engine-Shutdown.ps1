<#
================================================================================
 TB-TOOLBOX - MODULE F02 SHUTDOWN TIMER LAUNCHER (Engine-Shutdown.ps1)
 Bản quyền: Kỹ sư Đào Xuân Tuấn (Mr. Tuấn Beo)
 Mô tả: Điểm tiếp nhận Module F02_SHUTDOWN_TIMER, điều hướng tới Engine-PowerManager
================================================================================
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$coreDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$targetEngine = Join-Path $coreDir "Engine-PowerManager.ps1"

if (Test-Path $targetEngine) {
    & $targetEngine
} else {
    Write-Host "[X] Khong tim thay dong co: $targetEngine" -ForegroundColor Red
    pause
}
