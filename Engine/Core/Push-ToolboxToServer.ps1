<#
================================================================================
 TB-TOOLBOX - GIT SYNCHRONIZATION ENGINE (Push-ToolboxToServer.ps1)
 Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)
 Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com
 Mô tả: Động cơ đồng bộ lên Máy chủ Trung tâm an toàn, 100% Tiếng Việt có dấu,
        thanh tiến trình siêu mượt, đối soát SHA và bảo mật mã nguồn
================================================================================
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$Host.UI.RawUI.WindowTitle = "[ADMIN-001] ĐẨY MÃ NGUỒN LÊN MÁY CHỦ BẢO MẬT - MR. ĐÀO XUÂN TUẤN (TUẤN BEO)"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ToolboxRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
Set-Location $ToolboxRoot

# Dot-source các module phụ trợ nếu có
$commonUiPath = Join-Path $ScriptDir "Common-UI.ps1"
if (Test-Path $commonUiPath) { . $commonUiPath }

$integrityPath = Join-Path $ScriptDir "Integrity-Guard.ps1"
if (Test-Path $integrityPath) { . $integrityPath }

function Get-ProgressBarString {
    param ([int]$Percent, [int]$Width = 25)
    $filled = [int](($Percent / 100) * $Width)
    $empty = $Width - $filled
    $fullChar = [char]0x2588  # █
    $emptyChar = [char]0x2500 # ─
    return ("$fullChar" * $filled) + ("$emptyChar" * $empty)
}

Clear-Host
Write-Host "========================================================================================" -ForegroundColor Cyan
Write-Host "              [ADMIN-001] ĐẨY TB-TOOLBOX LÊN MÁY CHỦ BẢO MẬT                            " -ForegroundColor Green
Write-Host "            Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)                            " -ForegroundColor DarkGray
Write-Host "        Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com                     " -ForegroundColor DarkGray
Write-Host "========================================================================================" -ForegroundColor Cyan

# Kiểm tra kho Git
$gitRoot = ""
try {
    $gitRoot = (git rev-parse --show-toplevel 2>$null)
} catch {}

if ([string]::IsNullOrWhiteSpace($gitRoot) -or (-not (Test-Path (Join-Path $ToolboxRoot ".git")))) {
    Write-Host "`n[LỖI NGHIÊM TRỌNG] Không tìm thấy thư mục quản lý Git (.git)!" -ForegroundColor Red
    Write-Host "Thư mục làm việc hiện tại: $ToolboxRoot" -ForegroundColor Yellow
    Write-Host "TIẾN TRÌNH: [-------------------------]   0% - THẤT BẠI [Thiếu thư mục .git]" -ForegroundColor Red
    pause
    exit 1
}

# Lấy thông tin nhánh hiện tại
$currentBranch = (git rev-parse --abbrev-ref HEAD 2>$null)
if ([string]::IsNullOrWhiteSpace($currentBranch)) { $currentBranch = "main" }

Write-Host "  * Thư mục làm việc  : " -NoNewline -ForegroundColor Cyan
Write-Host $ToolboxRoot -ForegroundColor White
Write-Host "  * Nhánh Git hiện tại: " -NoNewline -ForegroundColor Cyan
Write-Host $currentBranch -ForegroundColor Yellow
Write-Host "========================================================================================`n" -ForegroundColor Cyan

# -------------------------------------------------------------------------------------------------
# BƯỚC 1: QUÉT VÀ NẠP DANH SÁCH TỆP TIN THAY ĐỔI
# -------------------------------------------------------------------------------------------------
Write-Host "[1/4] ĐANG QUÉT VÀ NẠP DANH SÁCH TỆP TIN THAY ĐỔI..." -ForegroundColor Cyan

$statusLines = @(git status --porcelain 2>$null)
$totalFiles = $statusLines.Count

if ($totalFiles -gt 0) {
    Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  TÌM THẤY " -NoNewline -ForegroundColor Cyan
    Write-Host "$totalFiles" -NoNewline -ForegroundColor Yellow
    Write-Host " TỆP TIN THAY ĐỔI - ĐANG NẠP VÀO HỆ THỐNG..." -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor DarkGray

    $idx = 0
    foreach ($line in $statusLines) {
        $idx++
        $tag = $line.Substring(0, 2).Trim()
        $fn = $line.Substring(2).Trim()

        $tagLabel = "[CHỈNH SỬA]"
        $tagColor = "Yellow"
        if ($tag -eq "??") { $tagLabel = "[THÊM MỚI ]"; $tagColor = "Green" }
        elseif ($tag -eq "D")  { $tagLabel = "[ĐÃ XÓA   ]"; $tagColor = "Red" }
        elseif ($tag -eq "R")  { $tagLabel = "[ĐỔI TÊN  ]"; $tagColor = "Magenta" }

        Write-Host "  [$idx/$totalFiles] " -NoNewline -ForegroundColor Cyan
        Write-Host "$tagLabel " -NoNewline -ForegroundColor $tagColor
        Write-Host "$fn " -NoNewline -ForegroundColor White
        Write-Host "[ĐÃ NẠP]" -ForegroundColor Green
    }

    $bar100 = Get-ProgressBarString -Percent 100
    Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  TIẾN TRÌNH NẠP: [$bar100] 100% - ĐÃ NẠP TRỌN VẸN $totalFiles/$totalFiles TỆP TIN" -ForegroundColor Green
    Write-Host "========================================================================================`n" -ForegroundColor Cyan
} else {
    # Kiểm tra xem có commit local nào chưa push không
    $unpushed = git log "origin/$currentBranch..HEAD" --oneline 2>$null
    if (-not $unpushed) {
        Write-Host "========================================================================================" -ForegroundColor Cyan
        Write-Host "  [---] THÔNG BÁO: KHÔNG CÓ BẤT KỲ TỆP TIN NÀO THAY ĐỔI CẦN COMMIT." -ForegroundColor Cyan
        Write-Host "        Hệ thống đã đồng bộ 100% với GitHub từ trước. Không cần push!" -ForegroundColor White
        Write-Host "========================================================================================" -ForegroundColor Cyan
        $barClean = Get-ProgressBarString -Percent 100
        Write-Host "  TIẾN TRÌNH: [$barClean] 100% - HỆ THỐNG ĐÃ ĐỒNG BỘ SẴN" -ForegroundColor Green
        Write-Host "========================================================================================`n" -ForegroundColor Cyan
        pause
        exit 0
    } else {
        Write-Host "[*] Không có tệp mới thay đổi, nhưng phát hiện commit ở Local chưa đẩy lên GitHub." -ForegroundColor Yellow
    }
}

# -------------------------------------------------------------------------------------------------
# BƯỚC 2: ĐƯA TỆP VÀO HÀNG ĐỢI (GIT ADD)
# -------------------------------------------------------------------------------------------------
if ($totalFiles -gt 0) {
    # Trước khi commit, tự động niêm phong mã nguồn nếu có Integrity Guard
    if (Get-Command Seal-Codebase -ErrorAction SilentlyContinue) {
        Write-Host "[*] Đang tự động niêm phong mã nguồn (.integrity.seal) trước khi commit..." -ForegroundColor DarkCyan
        Seal-Codebase -ToolboxRoot $ToolboxRoot | Out-Null
    }

    Write-Host "[2/4] ĐANG ĐƯA TỆP VÀO HÀNG ĐỢI (git add -A)..." -ForegroundColor Cyan
    git add -A

    $bar50 = Get-ProgressBarString -Percent 50
    Write-Host "  TIẾN TRÌNH: [$bar50]  50% - Đã đưa vào hàng đợi [Staging xong]`n" -ForegroundColor Yellow

    # -------------------------------------------------------------------------------------------------
    # BƯỚC 3: NHẬP GHI CHÚ COMMIT & CỔNG XÁC NHẬN [1] TIẾP TỤC / [0] HỦY BỎ
    # -------------------------------------------------------------------------------------------------
    Write-Host "========================================================================================" -ForegroundColor DarkYellow
    Write-Host " [3/4] NHẬP GHI CHÚ COMMIT (COMMIT MESSAGE)" -ForegroundColor Yellow
    Write-Host "       * Nhấn [ENTER] để lấy ghi chú mặc định theo ngày giờ" -ForegroundColor DarkGray
    Write-Host "========================================================================================`n" -ForegroundColor DarkYellow

    $defaultMsg = "TB-tuandx: Cập nhật bộ công cụ TB-Toolbox (" + (Get-Date).ToString("yyyy-MM-dd HH:mm") + ")"
    Write-Host ">> Nhập ghi chú commit: " -NoNewline -ForegroundColor Magenta
    $userMsg = Read-Host
    $commitMsg = if ([string]::IsNullOrWhiteSpace($userMsg)) { $defaultMsg } else { $userMsg.Trim() }

    # Cổng xác nhận an toàn [1/0]
    Write-Host "`n========================================================================================" -ForegroundColor Cyan
    Write-Host "                      XÁC NHẬN TIẾN HÀNH COMMIT & PUSH                                  " -ForegroundColor Cyan
    Write-Host "========================================================================================" -ForegroundColor Cyan
    Write-Host "  * Ghi chú commit đã chọn: " -NoNewline -ForegroundColor White
    Write-Host """$commitMsg""" -ForegroundColor Yellow
    Write-Host "  * Số lượng tệp thay đổi : " -NoNewline -ForegroundColor White
    Write-Host "$totalFiles tệp tin" -ForegroundColor Magenta
    Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [1] TIẾP TỤC  - Tiến hành tạo Commit và Đẩy lên Máy chủ ngay" -ForegroundColor Green
    Write-Host "  [0] HỦY BỎ    - Dừng lại, giữ nguyên tệp tin để tiếp tục làm thêm rồi commit sau" -ForegroundColor Red
    Write-Host "========================================================================================`n" -ForegroundColor Cyan

    Write-Host ">> Lựa chọn của bạn [1: Tiếp tục / 0: Hủy bỏ] (Mặc định 1): " -NoNewline -ForegroundColor Magenta
    $confirm = Read-Host

    if ($confirm -eq "0" -or $confirm -eq "h" -or $confirm -eq "huy" -or $confirm -eq "H") {
        git restore --staged . 2>$null
        Write-Host "`n========================================================================================" -ForegroundColor DarkYellow
        Write-Host "               [---] ĐÃ HỦY BỎ THAO TÁC COMMIT THEO YÊU CẦU                            " -ForegroundColor Yellow
        Write-Host "========================================================================================" -ForegroundColor DarkYellow
        Write-Host "  * Trạng thái        : ĐÃ HỦY ĐỒNG BỘ [CHƯA TẠO COMMIT]" -ForegroundColor Yellow
        Write-Host "  * Toàn bộ tệp tin   : ĐƯỢC GIỮ NGUYÊN VẸN 100% TRÊN MÁY ĐỂ BẠN LÀM THÊM" -ForegroundColor Green
        Write-Host "  * Bạn có thể tiếp tục sửa code rồi chạy lại script [ADMIN-001] bất kỳ lúc nào." -ForegroundColor White
        $barHalt = Get-ProgressBarString -Percent 50
        Write-Host "  TIẾN TRÌNH: [$barHalt]  50% - ĐÃ TẠM DỪNG THEO LỆNH NGƯỜI DÙNG" -ForegroundColor Yellow
        Write-Host "========================================================================================`n" -ForegroundColor DarkYellow
        pause
        exit 0
    }

    Write-Host "`n[*] Đang tạo commit: ""$commitMsg""..." -ForegroundColor Cyan
    git commit -m "$commitMsg"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[THẤT BẠI] Lỗi trong quá trình tạo commit!" -ForegroundColor Red
        pause
        exit 1
    }

    $bar75 = Get-ProgressBarString -Percent 75
    Write-Host "  TIẾN TRÌNH: [$bar75]  75% - Đã lưu vết commit Local thành công`n" -ForegroundColor Yellow
}

# -------------------------------------------------------------------------------------------------
# BƯỚC 4: ĐẨY COMMIT LÊN GITHUB SERVER & ĐỐI SOÁT SHA 100%
# -------------------------------------------------------------------------------------------------
$localSha = (git rev-parse HEAD 2>$null)
if (-not $commitMsg) {
    $commitMsg = (git log -1 --pretty=format:%s 2>$null)
}

Write-Host "[4/4] ĐANG ĐẨY COMMIT LÊN MÁY CHỦ BẢO MẬT (origin $currentBranch)..." -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor DarkGray

git push origin $currentBranch
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n========================================================================================" -ForegroundColor Red
    Write-Host "                 [XXX] KẾT QUẢ: THẤT BẠI - KHÔNG THỂ ĐẨY COMMIT LÊN MÁY CHỦ             " -ForegroundColor Red
    Write-Host "========================================================================================" -ForegroundColor Red
    Write-Host "   * CÁC NGUYÊN NHÂN CHÍNH CẦN KIỂM TRA:" -ForegroundColor Yellow
    Write-Host "     1. MẤT KẾT NỐI INTERNET hoặc mạng nội bộ chặn kết nối máy chủ." -ForegroundColor White
    Write-Host "     2. HẾT HẠN QUYỀN TRUY CẬP hoặc không có quyền ghi [Permission Denied / 403]." -ForegroundColor White
    Write-Host "     3. XUNG ĐỘT MÃ NGUỒN: Trên máy chủ có commit mới hơn chưa được tải về." -ForegroundColor White
    Write-Host "========================================================================================`n" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[*] Đang gửi yêu cầu xác minh SHA trực tiếp từ Máy chủ..." -ForegroundColor Cyan

$remoteSha = ""
$lsRemoteOutput = git ls-remote origin "refs/heads/$currentBranch" 2>$null
if ($lsRemoteOutput) {
    $remoteSha = ($lsRemoteOutput -split '\s+')[0]
}

Write-Host ""
if ($localSha -and $remoteSha -and ($localSha -eq $remoteSha)) {
    Write-Host "========================================================================================" -ForegroundColor Green
    Write-Host "               [✓✓✓] KẾT QUẢ: ĐẨY LÊN MÁY CHỦ BẢO MẬT THÀNH CÔNG 100%!                  " -ForegroundColor Green
    Write-Host "========================================================================================" -ForegroundColor Green
    Write-Host "   * Trạng thái       : " -NoNewline -ForegroundColor White
    Write-Host "HOÀN TẤT VÀ ĐỒNG BỘ HOÀN TOÀN" -ForegroundColor Green
    Write-Host "   * Nhánh Git        : " -NoNewline -ForegroundColor White
    Write-Host $currentBranch -ForegroundColor Cyan
    Write-Host "   * Mã Commit Local  : " -NoNewline -ForegroundColor White
    Write-Host $localSha -ForegroundColor DarkGray
    Write-Host "   * Mã Commit Server : " -NoNewline -ForegroundColor White
    Write-Host "$remoteSha  [TRÙNG KHỚP 100%]" -ForegroundColor Green
    Write-Host "   * Ghi chú Commit   : " -NoNewline -ForegroundColor White
    Write-Host $commitMsg -ForegroundColor Yellow
    Write-Host "========================================================================================" -ForegroundColor Green
    $barFinal = Get-ProgressBarString -Percent 100
    Write-Host "  TIẾN TRÌNH: [$barFinal] 100% - ĐỒNG BỘ MÁY CHỦ HOÀN TẤT XUẤT SẮC!" -ForegroundColor Green
    Write-Host "========================================================================================`n" -ForegroundColor Green
} else {
    Write-Host "========================================================================================" -ForegroundColor Yellow
    Write-Host "       [?] CẢNH BÁO: Push thành công nhưng server phản hồi chậm hoặc chưa khớp SHA.     " -ForegroundColor Yellow
    Write-Host "           Local SHA : $localSha" -ForegroundColor White
    Write-Host "           Remote SHA: $remoteSha" -ForegroundColor White
    Write-Host "========================================================================================`n" -ForegroundColor Yellow
}

pause
exit 0