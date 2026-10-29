# ==============================================================================
# TUANBEO SYSTEM - PERMISSION MATRIX MANAGEMENT ENGINE (Manage-PermissionMatrix.ps1)
# Bản quyền: Kỹ sư Đào Xuân Tuấn (Mr. Tuấn Beo)
# Mô tả: Công cụ quản lý ma trận phân quyền tương tác, tự động đồng bộ file mới/xóa,
#        bảo toàn cấu hình, cập nhật tức thời 03_PERM_MATRIX.md chuẩn UTF-8
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$Host.UI.RawUI.WindowTitle = "HỆ THỐNG QUẢN LÝ MA TRẬN PHÂN QUYỀN - TUANBEO SYSTEM"

$WorkDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$GroupsFile   = Join-Path $WorkDir "01_ROLE_GROUPS.md"
$FuncsFile    = Join-Path $WorkDir "02_FUNCTIONS.md"
$MatrixFile   = Join-Path $WorkDir "03_PERM_MATRIX.md"
$AccountsFile = Join-Path $WorkDir "04_USER_ACCOUNTS.md"

# -------------------------------------------------------------------------------------------------
# 1. HÀM ĐỌC DANH MỤC NHÓM TỪ 01_ROLE_GROUPS.md
# -------------------------------------------------------------------------------------------------
function Get-RoleGroups {
    if (-not (Test-Path $GroupsFile)) { return @() }
    $lines = Get-Content -LiteralPath $GroupsFile -Encoding UTF8
    $groups = @()
    foreach ($line in $lines) {
        if ($line.Trim().StartsWith("|") -and $line -match 'GF\d{4}') {
            $parts = $line.Split('|') | ForEach-Object { $_.Trim() }
            if ($parts.Length -ge 6) {
                $code = ($parts[1] -replace '\*','').Trim()
                $name = $parts[2]
                $tier = $parts[3]
                $status = $parts[4]
                $desc = $parts[5]
                $groups += [PSCustomObject]@{
                    Code   = $code
                    Name   = $name
                    Tier   = $tier
                    Status = $status
                    Desc   = $desc
                }
            }
        }
    }
    return $groups
}

# -------------------------------------------------------------------------------------------------
# 2. HÀM ĐỌC DANH MỤC CHỨC NĂNG TỪ 02_FUNCTIONS.md
# -------------------------------------------------------------------------------------------------
function Get-FunctionsList {
    if (-not (Test-Path $FuncsFile)) { return @() }
    $lines = Get-Content -LiteralPath $FuncsFile -Encoding UTF8
    $funcs = @()
    foreach ($line in $lines) {
        if ($line.Trim().StartsWith("|") -and $line -match 'FN\d{4}') {
            $parts = $line.Split('|') | ForEach-Object { $_.Trim() }
            if ($parts.Length -ge 6) {
                $code = ($parts[1] -replace '\*','').Trim()
                $name = $parts[2]
                $fileRel = ($parts[3] -replace '`','').Trim()
                $module = $parts[4]
                $status = $parts[5]
                $funcs += [PSCustomObject]@{
                    Code   = $code
                    Name   = $name
                    File   = $fileRel
                    Module = $module
                    Status = $status
                }
            }
        }
    }
    return $funcs
}

# -------------------------------------------------------------------------------------------------
# 3. HÀM ĐỌC & GHI MA TRẬN PHÂN QUYỀN TỪ 03_PERM_MATRIX.md
# -------------------------------------------------------------------------------------------------
function Get-PermissionMatrix {
    if (-not (Test-Path $MatrixFile)) { return @{} }
    $lines = Get-Content -LiteralPath $MatrixFile -Encoding UTF8
    $matrix = [ordered]@{}
    foreach ($line in $lines) {
        if ($line.Trim().StartsWith("|") -and $line -match 'GF\d{4}') {
            $parts = $line.Split('|') | ForEach-Object { $_.Trim() }
            if ($parts.Length -ge 4) {
                $grpCode = ($parts[1] -replace '\*','').Trim()
                $fnRaw = ($parts[3] -replace '`','').Trim()
                $fnList = @()
                if ($fnRaw -match 'TOÀN BỘ' -or $fnRaw -match 'TẤT CẢ') {
                    $fnList = @("ALL")
                } else {
                    $fnList = ($fnRaw -split ',\s*') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                }
                $matrix[$grpCode] = $fnList
            }
        }
    }
    return $matrix
}

function Save-PermissionMatrix {
    param ([System.Collections.IDictionary]$Matrix, [array]$Groups, [array]$Functions)

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# MA TRẬN PHÂN QUYỀN NHÓM - CHỨC NĂNG (03_PERM_MATRIX.md)')
    [void]$sb.AppendLine('> 📁 **VỊ TRÍ:** `00-Admin_Security/03_PERM_MATRIX.md`  ')
    [void]$sb.AppendLine('> 🛡️ **NGUYÊN TẮC:** 1 Nhóm (`GFxxxx`) quản lý N Chức năng (`FNxxxx`).  ')
    [void]$sb.AppendLine('> Trạng thái: `[1] = ĐƯỢC PHÉP` | `[0] = BỊ KHÓA / KHÔNG TẢI VỀ`.  ')
    [void]$sb.AppendLine('> *Cập nhật lần cuối: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + "*`n")
    [void]$sb.AppendLine('| Mã Nhóm | Tên Nhóm Gói | Danh Sách Chức Năng Được Mở Khóa (`1`) |')
    [void]$sb.AppendLine('| :---: | :--- | :--- |')

    foreach ($g in $Groups) {
        $gCode = $g.Code
        $fnAllowed = $Matrix[$gCode]
        
        $fnString = ""
        if ($gCode -eq "GF9999") {
            $fnString = '**TOÀN BỘ 100% TẤT CẢ CHỨC NĂNG** (Bao gồm `FN9999` Quản trị Tối cao)'
        } elseif ($fnAllowed -contains "ALL") {
            $fnString = '**TOÀN BỘ 100% TẤT CẢ CHỨC NĂNG**'
        } elseif (-not $fnAllowed -or $fnAllowed.Count -eq 0) {
            $fnString = "*(Chưa cấp phép chức năng nào)*"
        } else {
            $validFns = $Functions | Where-Object { $fnAllowed -contains $_.Code } | ForEach-Object { $_.Code }
            $formatted = $validFns | ForEach-Object { ('`' + $_ + '`') }
            $fnString = $formatted -join ", "
        }

        [void]$sb.AppendLine("| **$gCode** | $($g.Name) | $fnString |")
    }

    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($MatrixFile, $sb.ToString(), $utf8Bom)
}

# -------------------------------------------------------------------------------------------------
# 4. HÀM TỰ ĐỘNG BÙ KHUYẾT & DỌN DẸP (LIFECYCLE AUTO-SYNC)
# -------------------------------------------------------------------------------------------------
function Sync-FunctionsLifecycle {
    param ([array]$Groups, [array]$Functions, [System.Collections.IDictionary]$Matrix)
    
    $changed = $false
    # 1. Đảm bảo mọi nhóm đều có mặt trong ma trận
    foreach ($g in $Groups) {
        if (-not $Matrix.Contains($g.Code)) {
            if ($g.Code -eq "GF9999") { $Matrix[$g.Code] = @("ALL") }
            else { $Matrix[$g.Code] = @() }
            $changed = $true
        }
    }

    # 2. Xóa các mã FN mồ côi (không còn tồn tại trong 02_FUNCTIONS.md)
    $validFnCodes = $Functions | ForEach-Object { $_.Code }
    foreach ($grp in $Matrix.Keys) {
        $curList = @($Matrix[$grp])
        if (-not ($curList -contains "ALL")) {
            $cleaned = $curList | Where-Object { $validFnCodes -contains $_ }
            if ($cleaned.Count -ne $curList.Count) {
                $Matrix[$grp] = @($cleaned)
                $changed = $true
            }
        }
    }

    if ($changed) {
        Save-PermissionMatrix -Matrix $Matrix -Groups $Groups -Functions $Functions
    }
}

# -------------------------------------------------------------------------------------------------
# 5. GIAO DIỆN CẤU HÌNH NHÓM CHI TIẾT (EDIT PERMISSIONS)
# -------------------------------------------------------------------------------------------------
function Edit-GroupPermissions {
    param (
        [object]$SelectedGroup,
        [array]$Functions,
        [System.Collections.IDictionary]$Matrix,
        [array]$AllGroups
    )

    $grpCode = $SelectedGroup.Code
    $isMaster = ($grpCode -eq "GF9999")

    while ($true) {
        Clear-Host
        $curAllowed = @($Matrix[$grpCode])
        $hasAll = ($curAllowed -contains "ALL" -or $isMaster)

        Write-Host "========================================================================================" -ForegroundColor Cyan
        Write-Host "   ĐANG PHÂN QUYỀN CHO: [$grpCode - $($SelectedGroup.Name)]                              " -ForegroundColor Green
        Write-Host "   Phân tầng: $($SelectedGroup.Tier) | Phạm vi: $($SelectedGroup.Desc)                  " -ForegroundColor DarkGray
        Write-Host "========================================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "DANH MỤC TẤT CẢ CHỨC NĂNG:" -ForegroundColor Yellow

        $idx = 0
        foreach ($fn in $Functions) {
            $idx++
            $isAllowed = ($hasAll -or ($curAllowed -contains $fn.Code))
            
            $prefix = "[ ] (0)"
            $color = "DarkGray"
            if ($isAllowed) {
                $prefix = "[X] (1)"
                $color = "Green"
            }

            $idxStr = $idx.ToString().PadLeft(2, ' ')
            Write-Host "  $idxStr. " -NoNewline -ForegroundColor Cyan
            Write-Host "$prefix " -NoNewline -ForegroundColor $color
            Write-Host "$($fn.Code) " -NoNewline -ForegroundColor Yellow
            Write-Host "- $($fn.Name) " -NoNewline -ForegroundColor White
            Write-Host "[$($fn.Module)]" -ForegroundColor DarkCyan
        }

        Write-Host "`n----------------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "TÙY CHỌN THAO TÁC:" -ForegroundColor Cyan
        Write-Host "  * Nhập MÃ FN (VD: FN0101) hoặc SỐ THỨ TỰ (1..$($Functions.Count)) để BẬT / TẮT (Toggle 0 <-> 1)" -ForegroundColor White
        Write-Host "  * Có thể nhập nhiều mã cách nhau bởi dấu phẩy/khoảng trắng (VD: 16, 17 hoặc FN0202 FN0203)" -ForegroundColor White
        Write-Host "  * Nhập [A] để CHỌN TẤT CẢ (Select All)" -ForegroundColor Green
        Write-Host "  * Nhập [C] để HỦY TẤT CẢ (Clear All)" -ForegroundColor Red
        Write-Host "  * Nhập [I] để KẾ THỪA / SAO CHÉP từ nhóm khác" -ForegroundColor Magenta
        Write-Host "  * Nhập [0] để LƯU & QUAY LẠI MENU CHÍNH" -ForegroundColor Yellow
        Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor DarkGray
        
        Write-Host "`n>> Nhập lệnh hoặc mã FN cần thay đổi: " -NoNewline -ForegroundColor Yellow
        $inputCmd = (Read-Host).Trim()

        if ($inputCmd -eq "0" -or $inputCmd -eq "") {
            break
        } elseif ($inputCmd -eq "A" -or $inputCmd -eq "a") {
            $Matrix[$grpCode] = @($Functions | ForEach-Object { $_.Code })
            Save-PermissionMatrix -Matrix $Matrix -Groups $AllGroups -Functions $Functions
            Write-Host "`n[+] Đã BẬT TẤT CẢ chức năng cho nhóm $grpCode!" -ForegroundColor Green
            Start-Sleep -Milliseconds 600
        } elseif ($inputCmd -eq "C" -or $inputCmd -eq "c") {
            $Matrix[$grpCode] = @()
            Save-PermissionMatrix -Matrix $Matrix -Groups $AllGroups -Functions $Functions
            Write-Host "`n[-] Đã HỦY TẤT CẢ chức năng cho nhóm $grpCode!" -ForegroundColor Red
            Start-Sleep -Milliseconds 600
        } elseif ($inputCmd -eq "I" -or $inputCmd -eq "i") {
            Write-Host "`nDanh sách mã nhóm có thể sao chép: $($AllGroups.Code -join ', ')" -ForegroundColor Cyan
            $srcCode = (Read-Host ">> Nhập mã nhóm nguồn muốn sao chép quyền (VD: GF0200)").Trim()
            if ($Matrix.Contains($srcCode)) {
                $Matrix[$grpCode] = @($Matrix[$srcCode])
                Save-PermissionMatrix -Matrix $Matrix -Groups $AllGroups -Functions $Functions
                Write-Host "[+] Đã sao chép toàn bộ quyền từ $srcCode sang $grpCode thành công!" -ForegroundColor Green
                Start-Sleep -Seconds 1
            } else {
                Write-Host "[-] Mã nhóm không tồn tại!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        } else {
            # Tách các input ngăn cách bởi dấu phẩy, chấm phẩy hoặc khoảng trắng
            $tokens = ($inputCmd -split '[,;\s]+') | Where-Object { $_ }
            $hasAnyChange = $false

            Write-Host ""
            foreach ($token in $tokens) {
                $targetFnCode = ""
                if ($token -match '^\d+$') {
                    $num = [int]$token
                    if ($num -ge 1 -and $num -le $Functions.Count) {
                        $targetFnCode = $Functions[$num - 1].Code
                    }
                } elseif ($token.ToUpper().StartsWith("FN")) {
                    $matchFn = $Functions | Where-Object { $_.Code -eq $token.ToUpper() }
                    if ($matchFn) { $targetFnCode = $matchFn.Code }
                }

                if ($targetFnCode) {
                    $curList = [System.Collections.ArrayList]::new()
                    $rawList = @($Matrix[$grpCode])
                    if ($rawList -contains "ALL") {
                        foreach ($f in $Functions) { [void]$curList.Add([string]$f.Code) }
                    } else {
                        foreach ($item in $rawList) {
                            if ($item -and $item -ne "ALL") { [void]$curList.Add([string]$item) }
                        }
                    }

                    $fnObj = $Functions | Where-Object { $_.Code -eq $targetFnCode } | Select-Object -First 1
                    $fnNameText = if ($fnObj) { "$targetFnCode - $($fnObj.Name)" } else { $targetFnCode }

                    if ($curList.Contains($targetFnCode)) {
                        $curList.Remove($targetFnCode)
                        Write-Host "  [-] Đã TẮT (0) chức năng: $fnNameText" -ForegroundColor Red
                    } else {
                        [void]$curList.Add($targetFnCode)
                        Write-Host "  [+] Đã BẬT (1) chức năng: $fnNameText" -ForegroundColor Green
                    }
                    $Matrix[$grpCode] = @($curList)
                    $hasAnyChange = $true
                } else {
                    Write-Host "  [-] Lựa chọn không hợp lệ: '$token'" -ForegroundColor Red
                }
            }

            if ($hasAnyChange) {
                Save-PermissionMatrix -Matrix $Matrix -Groups $AllGroups -Functions $Functions
                Start-Sleep -Milliseconds 700
            } else {
                Start-Sleep -Seconds 1
            }
        }
    }
}

# -------------------------------------------------------------------------------------------------
# 6. VÒNG LẶP CHÍNH (MAIN INTERACTIVE LOOP)
# -------------------------------------------------------------------------------------------------
$groups = Get-RoleGroups
$functions = Get-FunctionsList
$matrix = Get-PermissionMatrix

# Tự động đồng bộ và bảo toàn cấu hình
Sync-FunctionsLifecycle -Groups $groups -Functions $functions -Matrix $matrix

while ($true) {
    Clear-Host
    Write-Host "========================================================================================" -ForegroundColor Cyan
    Write-Host "           HỆ THỐNG QUẢN LÝ MA TRẬN PHÂN QUYỀN - TUANBEO SYSTEM (03_PERM_MATRIX)        " -ForegroundColor Green
    Write-Host "                              KỸ SƯ: ĐÀO XUÂN TUẤN                                      " -ForegroundColor Yellow
    Write-Host "========================================================================================" -ForegroundColor Cyan
    Write-Host "DANH SÁCH CÁC NHÓM BẢN QUYỀN HIỆN CÓ ($($groups.Count) Nhóm | $($functions.Count) Chức năng):" -ForegroundColor White
    Write-Host ""

    $gIdx = 0
    foreach ($g in $groups) {
        $gIdx++
        $curAllowed = @($matrix[$g.Code])
        $countDesc = ""
        if ($g.Code -eq "GF9999" -or ($curAllowed -contains "ALL")) {
            $countDesc = "TOÀN BỘ $($functions.Count)/$($functions.Count)"
        } else {
            $countDesc = "$($curAllowed.Count)/$($functions.Count)"
        }

        $idxPad = $gIdx.ToString().PadLeft(2, ' ')
        Write-Host "  [$idxPad] " -NoNewline -ForegroundColor Cyan
        Write-Host "$($g.Code) " -NoNewline -ForegroundColor Yellow
        Write-Host "- $($g.Name.PadRight(28, ' ')) " -NoNewline -ForegroundColor White
        Write-Host "[$($g.Tier.PadRight(7, ' '))] " -NoNewline -ForegroundColor DarkGray
        Write-Host "[Đã cấp: $countDesc chức năng]" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [0] Thoát chương trình" -ForegroundColor Red
    Write-Host "----------------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "👉 Nhập số thứ tự Nhóm cần cấu hình (1 - $($groups.Count) hoặc 0 để thoát): " -NoNewline -ForegroundColor Yellow
    
    $choice = (Read-Host).Trim()
    if ($choice -eq "0" -or $choice -eq "") {
        Write-Host "`n[*] Đã thoát hệ thống phân quyền. Hẹn gặp lại Anh Beo!" -ForegroundColor Cyan
        break
    }

    if ($choice -match '^\d+$') {
        $cNum = [int]$choice
        if ($cNum -ge 1 -and $cNum -le $groups.Count) {
            $selectedGroup = $groups[$cNum - 1]
            Edit-GroupPermissions -SelectedGroup $selectedGroup -Functions $functions -Matrix $matrix -AllGroups $groups
        } else {
            Write-Host "[-] Số thứ tự không hợp lệ!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    } else {
        Write-Host "[-] Vui lòng nhập số hợp lệ!" -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}
