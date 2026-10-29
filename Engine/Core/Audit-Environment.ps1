<#
================================================================================
 TB-TOOLBOX - AUDIT ENVIRONMENT SCRIPT (Audit-Environment.ps1)
 Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)
 Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com
 Mô tả: Kiểm tra môi trường, gỡ bỏ cờ chặn Unblock-File, cấu hình RemoteSigned
================================================================================
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "[000] KIỂM TRA MÔI TRƯỜNG & GIẢI PHÓNG CHẶN - TB-TOOLBOX"

$coreDir = $PSScriptRoot
$engineDir = Split-Path -Parent $coreDir
$rootDir = Split-Path -Parent $engineDir

Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "   TB-TOOLBOX - BỘ CÔNG CỤ TIỆN ÍCH HỆ THỐNG" -ForegroundColor Yellow
Write-Host "   Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo) | Hotline: 0987.1987.92" -ForegroundColor DarkGray
Write-Host "   Email: tuanbeo.technology@gmail.com" -ForegroundColor DarkGray
Write-Host "   TIỂU TRÌNH KIỂM TRA MÔI TRƯỜNG & GIẢI PHÓNG CHẶN TỆP TIN (ENVIRONMENT AUDIT)" -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Đang mở khóa tệp tin tải về từ Internet (Unblock-File)..." -ForegroundColor Cyan
try {
    Get-ChildItem -Path $rootDir -Recurse | Unblock-File -ErrorAction SilentlyContinue
    Write-Host " [OK] Đã gỡ bỏ thành công cờ chặn Mark-of-the-Web (Zone.Identifier)!" -ForegroundColor Green
} catch {
    Write-Host " [!] Không thể mở khóa một số tệp (có thể do quyền hạn)." -ForegroundColor Yellow
}
Write-Host ""

Write-Host "[2/3] Đang cấu hình chính sách thực thi PowerShell an toàn (RemoteSigned)..." -ForegroundColor Cyan
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue
    Write-Host " [OK] Đã kích hoạt chính sách RemoteSigned cho người dùng hiện tại!" -ForegroundColor Green
} catch {
    Write-Host " [!] Chính sách thực thi PowerShell có thể bị quản lý bởi Domain Admin." -ForegroundColor Yellow
}
Write-Host ""

Write-Host "[3/4] Kiểm tra phiên bản PowerShell..." -ForegroundColor Cyan
Write-Host (" [OK] PowerShell Version: " + $PSVersionTable.PSVersion.ToString()) -ForegroundColor Green
Write-Host ""

Write-Host "[4/4] Khởi tạo biểu tượng phím tắt thông minh TB-Toolbox..." -ForegroundColor Cyan
try {
    $wsh = New-Object -ComObject WScript.Shell
    $sc = $wsh.CreateShortcut((Join-Path $rootDir "TB-Toolbox.lnk"))
    $sc.TargetPath = Join-Path $rootDir "TB-Toolbox.bat"
    $sc.WorkingDirectory = $rootDir
    $sc.Description = "TB-Toolbox - Bộ Công Cụ Tiện Ích Hệ Thống | Bản quyền: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)"
    $icon = "$env:SystemRoot\System32\shell32.dll"
    if (Test-Path $icon) { $sc.IconLocation = "$icon, 27" }
    $sc.Save()
    Write-Host " [OK] Đã tạo thành công biểu tượng 'TB-Toolbox' tại thư mục gốc!" -ForegroundColor Green
} catch {
    Write-Host " [!] Không thể tạo shortcut (bỏ qua bước này)." -ForegroundColor Yellow
}
Write-Host ""

Write-Host "================================================================================" -ForegroundColor Green
Write-Host "   🎉 CHÚC MỪNG: MÔI TRƯỜNG MÁY TÍNH ĐÃ SẴN SÀNG SỬ DỤNG TB-TOOLBOX!" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "   Bạn có thể mở và sử dụng các công cụ tại thư mục @Actions/:" -ForegroundColor White
Write-Host "   - [500]-Don-Dep-Bo-Nho-Tam-He-Thong.bat" -ForegroundColor Cyan
Write-Host ""
Write-Host "(*) Gợi ý: Nếu Windows Defender SmartScreen hiển thị cảnh báo xanh:" -ForegroundColor DarkGray
Write-Host "    Hãy bấm vào chữ More info (Xem thêm) -> Bấm Run anyway (Vẫn chạy)." -ForegroundColor DarkGray
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""