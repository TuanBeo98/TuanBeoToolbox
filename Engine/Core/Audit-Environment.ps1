<#
================================================================================
 TB-TOOLBOX - AUDIT ENVIRONMENT SCRIPT (Audit-Environment.ps1)
 Bản quyền: Mr. Tuấn Beo (TuanBeo)
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
Write-Host "   TB-TOOLBOX - BỘ CÔNG CỤ TIỆN ÍCH HỆ THỐNG (MR. TUẤN BEO)" -ForegroundColor Yellow
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

Write-Host "[3/3] Kiểm tra phiên bản PowerShell..." -ForegroundColor Cyan
Write-Host (" [OK] PowerShell Version: " + $PSVersionTable.PSVersion.ToString()) -ForegroundColor Green
Write-Host ""

Write-Host "================================================================================" -ForegroundColor Green
Write-Host "   🎉 CHÚC MỪNG: MÔI TRƯỜNG MÁY TÍNH ĐÃ SẴN SÀNG SỬ DỤNG TB-TOOLBOX!" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "   Bạn có thể mở và sử dụng các công cụ tại thư mục @File-BAT/:" -ForegroundColor White
Write-Host "   - [500]-Don-Dep-Bo-Nho-Tam-He-Thong.bat" -ForegroundColor Cyan
Write-Host ""
Write-Host "(*) Gợi ý: Nếu Windows Defender SmartScreen hiển thị cảnh báo xanh:" -ForegroundColor DarkGray
Write-Host "    Hãy bấm vào chữ More info (Xem thêm) -> Bấm Run anyway (Vẫn chạy)." -ForegroundColor DarkGray
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""