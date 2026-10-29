<#
================================================================================
 TB-TOOLBOX - CONFIG MANAGER MODULE (Config-Manager.ps1)
 Bản quyền: Mr. Tuấn Beo (TuanBeo)
 Mô tả: Đọc, ghi và quản lý trạng thái công tắc [0/1] cho TB-Cleaner
================================================================================
#>

function Get-CleanerConfigPath {
    $scriptRoot = Split-Path -Parent $PSScriptRoot
    $cfgDir = Join-Path $scriptRoot "Config"
    if (-not (Test-Path $cfgDir)) {
        New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
    }
    return Join-Path $cfgDir "cleaner-config.json"
}

function Get-CleanerConfig {
    $path = Get-CleanerConfigPath
    if (Test-Path $path) {
        try {
            $raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
            $cfg = $raw | ConvertFrom-Json
            if ($cfg -and $cfg.Categories) {
                return $cfg
            }
        }
        catch {
            # Nếu file lỗi thì tái tạo cấu hình chuẩn
        }
    }

    # Cấu hình mặc định: CHỈ BẬT temp [1], còn lại TẮT [0]
    $defaultCfg = [PSCustomObject]@{
        Version = "1.0.0"
        Categories = [PSCustomObject]@{
            temp = [PSCustomObject]@{ Name = "Xóa bộ nhớ tạm (User & System Temp)"; Enabled = 1; Description = "Thư mục %TEMP% và C:\Windows\Temp" }
            prefetch = [PSCustomObject]@{ Name = "Xóa bộ nhớ đệm Prefetch"; Enabled = 0; Description = "Thư mục C:\Windows\Prefetch" }
            update_cache = [PSCustomObject]@{ Name = "Xóa tệp tải Windows Update cũ"; Enabled = 0; Description = "Thư mục C:\Windows\SoftwareDistribution\Download và CBS Logs" }
            crash_dumps = [PSCustomObject]@{ Name = "Xóa file báo cáo sự cố sập ứng dụng (Crash Dumps)"; Enabled = 0; Description = "%LOCALAPPDATA%\CrashDumps và C:\Windows\Minidump" }
            delivery_optimization = [PSCustomObject]@{ Name = "Xóa cache tối ưu tải Windows Store (Delivery)"; Enabled = 0; Description = "C:\Windows\SoftwareDistribution\DeliveryOptimization" }
            thumbnail_cache = [PSCustomObject]@{ Name = "Xóa bộ nhớ đệm ảnh thu nhỏ (Thumbnails)"; Enabled = 0; Description = "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" }
            recycle_bin = [PSCustomObject]@{ Name = "Dọn sạch Thùng rác (Recycle Bin)"; Enabled = 0; Description = "Dọn sạch toàn bộ file trong Thùng rác mọi ổ đĩa" }
            browser_cache = [PSCustomObject]@{ Name = "Xóa cache trình duyệt (Chrome, Edge)"; Enabled = 0; Description = "Chỉ xóa cache web, giữ nguyên 100% Mật khẩu, Cookie và Lịch sử" }
            dev_nuget_cache = [PSCustomObject]@{ Name = "Xóa cache thư viện .NET (NuGet Packages)"; Enabled = 0; Description = "Thư mục %userprofile%\.nuget\packages" }
        }
    }

    Save-CleanerConfig -Config $defaultCfg
    return $defaultCfg
}

function Save-CleanerConfig {
    param ([PSCustomObject]$Config)
    $path = Get-CleanerConfigPath
    $json = $Config | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($path, $json, [System.Text.Encoding]::UTF8)
}

function Set-AllCategories {
    param (
        [PSCustomObject]$Config,
        [int]$Status # 1 = Bật hết, 0 = Tắt hết
    )
    foreach ($prop in $Config.Categories.PSObject.Properties) {
        $prop.Value.Enabled = $Status
    }
    Save-CleanerConfig -Config $Config
}
