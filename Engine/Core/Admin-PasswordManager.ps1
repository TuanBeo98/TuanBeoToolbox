<#
================================================================================
 TB-TOOLBOX - ADMIN PASSWORD & SECURITY MANAGEMENT MODULE (Admin-PasswordManager.ps1)
 Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)
 Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com
 Chức năng: Mã hóa 1 chiều PBKDF2 (50,000 vòng) + Salt 16-byte ngẫu nhiên + Hardware Pepper,
            Bảo vệ 3 tầng chống Copy sang máy khác (Windows DPAPI + HWID Entropy),
            Tự sinh Mã Cứu Hộ khi đổi mật khẩu (Đuôi 7 số: Năm + Tuần + Thứ),
            Hỗ trợ Cứu hộ khẩn cấp và Test mật khẩu trực quan.
================================================================================
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Security

$Host.UI.RawUI.WindowTitle = "QUẢN LÝ MẬT KHẨU & BẢO MẬT ADMIN - MR. ĐÀO XUÂN TUẤN (TUẤN BEO)"

$CORE_DIR = $PSScriptRoot
$ENGINE_DIR = Split-Path -Parent $CORE_DIR
$CONFIG_DIR = Join-Path $ENGINE_DIR "Config"
$AUTH_VAULT_FILE = Join-Path $CONFIG_DIR ".auth.vault"
$RECOVERY_VAULT_FILE = Join-Path $CONFIG_DIR ".recovery.vault"
$script:DEFAULT_VAULT_SALT = "DkH8nYJt4qNBTDuhsbkBPw==" # Quy Tắc Chung(~17)
$script:DEFAULT_VAULT_HASH = "jmvN1yBaRbe69tKDjFGpIf4HIxNc2N6PpnLVs6cDAaE=" # Quy Tắc Chung(~17)

if (Test-Path (Join-Path $CORE_DIR "Common-UI.ps1")) {
    . (Join-Path $CORE_DIR "Common-UI.ps1")
}

# ==============================================================================
# 1. TRÍCH XUẤT MÃ PHẦN CỨNG LAI (HYBRID HWID - HARDWARE PEPPER)
# ==============================================================================

function Get-MachineHWID {
    try {
        $bb = (Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue).SerialNumber
        if ([string]::IsNullOrWhiteSpace($bb)) { $bb = "BB_GENERIC_DEFAULT" }
    } catch { $bb = "BB_FALLBACK" }

    try {
        $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).ProcessorId
        if ([string]::IsNullOrWhiteSpace($cpu)) { $cpu = "CPU_GENERIC_DEFAULT" }
    } catch { $cpu = "CPU_FALLBACK" }

    try {
        $guid = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name MachineGuid -ErrorAction SilentlyContinue).MachineGuid
        if ([string]::IsNullOrWhiteSpace($guid)) { $guid = "GUID_GENERIC_DEFAULT" }
    } catch { $guid = "GUID_FALLBACK" }

    $combined = "$($bb.Trim())_$($cpu.Trim())_$($guid.Trim())"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($combined))
    return [System.BitConverter]::ToString($hashBytes).Replace('-', '').Substring(0, 32)
}

# ==============================================================================
# 2. CÁC HÀM MẬT MÃ NỀN TẢNG (CRYPTOGRAPHIC CORE - CHỐNG CRACK & CHỐNG COPY)
# ==============================================================================

function Get-RngSalt([int]$Length = 16) {
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] $Length
    $rng.GetBytes($bytes)
    return [Convert]::ToBase64String($bytes)
}

function Compute-Pbkdf2Hash([string]$Password, [string]$SaltBase64, [int]$Iterations = 50000, [int]$HashByteSize = 32) {
    if ([string]::IsNullOrEmpty($Password)) { return "" }
    $hwid = Get-MachineHWID
    $pepperedPassword = "$Password#TB_PEPPER#$hwid"
    $saltBytes = [Convert]::FromBase64String($SaltBase64)
    $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes ($pepperedPassword, $saltBytes, $Iterations)
    $hashBytes = $pbkdf2.GetBytes($HashByteSize)
    return [Convert]::ToBase64String($hashBytes)
}

function Compare-ConstantTime([string]$StrA, [string]$StrB) {
    if ($null -eq $StrA -or $null -eq $StrB) { return $false }
    $bytesA = [System.Text.Encoding]::UTF8.GetBytes($StrA)
    $bytesB = [System.Text.Encoding]::UTF8.GetBytes($StrB)
    if ($bytesA.Length -ne $bytesB.Length) { return $false }
    $diff = 0
    for ($i = 0; $i -lt $bytesA.Length; $i++) {
        $diff = $diff -bor ($bytesA[$i] -bxor $bytesB[$i])
    }
    return ($diff -eq 0)
}

function Protect-VaultBytes([string]$PlainText) {
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $hwid = Get-MachineHWID
    $entropy = [System.Text.Encoding]::UTF8.GetBytes($hwid)
    try {
        return [System.Security.Cryptography.ProtectedData]::Protect(
            $plainBytes,
            $entropy,
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        )
    } catch {
        return $plainBytes
    }
}

function Unprotect-VaultBytes([byte[]]$EncryptedBytes) {
    $hwid = Get-MachineHWID
    $entropy = [System.Text.Encoding]::UTF8.GetBytes($hwid)
    try {
        $decBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
            $EncryptedBytes,
            $entropy,
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        return [System.Text.Encoding]::UTF8.GetString($decBytes)
    } catch {
        return $null
    }
}

# ==============================================================================
# 3. KHỞI TẠO VÀ ĐỌC GHI KÉT SẮT VAULT (.auth.vault & .recovery.vault)
# ==============================================================================

function Generate-EmergencyCode {
    $rand1 = (Get-Random -Minimum 1000 -Maximum 9999).ToString()
    $rand2 = (Get-Random -Minimum 1000 -Maximum 9999).ToString()
    $rand3 = (Get-Random -Minimum 1000 -Maximum 9999).ToString()
    
    # 7 số cuối: Năm (4 số) + Tuần hiện tại (2 số) + Thứ hiện tại (1 số: 1=CN, 2=T2..7=T7)
    $now = Get-Date
    $yearStr = $now.Year.ToString("0000")
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $weekNum = $culture.Calendar.GetWeekOfYear($now, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday)
    $weekStr = $weekNum.ToString("00")
    
    $dayMap = @{
        [DayOfWeek]::Sunday    = 1
        [DayOfWeek]::Monday    = 2
        [DayOfWeek]::Tuesday   = 3
        [DayOfWeek]::Wednesday = 4
        [DayOfWeek]::Thursday  = 5
        [DayOfWeek]::Friday    = 6
        [DayOfWeek]::Saturday  = 7
    }
    $dayVal = $dayMap[$now.DayOfWeek]
    $tail7 = "$yearStr$weekStr$dayVal"

    return "TB-RECOVERY-$rand1-$rand2-$rand3-$tail7"
}

function Initialize-AdminAuthVault {
    if (-not (Test-Path $CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
    }

    # ==============================================================================
    # BẢO MẬT MÃ BĂM MẶC ĐỊNH (ZERO-PLAINTEXT CREDENTIAL)
    # Gợi ý nhận diện: Quy Tắc Chung(~17)
    # ==============================================================================
    $script:DEFAULT_VAULT_SALT = "DkH8nYJt4qNBTDuhsbkBPw==" # Quy Tắc Chung(~17)
    $script:DEFAULT_VAULT_HASH = "jmvN1yBaRbe69tKDjFGpIf4HIxNc2N6PpnLVs6cDAaE=" # Quy Tắc Chung(~17)
    
    if (-not (Test-Path $AUTH_VAULT_FILE)) {
        $salt = $script:DEFAULT_VAULT_SALT
        $hash = $script:DEFAULT_VAULT_HASH
        $authData = [PSCustomObject]@{
            metadata = [PSCustomObject]@{
                author        = "Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)"
                algorithm     = "PBKDF2-HMAC-SHA256-PEPPERED"
                iterations    = 50000
                hint          = "Quy Tắc Chung(~17)"
                hardwareBound = $true
                machineHwid   = (Get-MachineHWID)
                createdAt     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                lastChanged   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            auth = [PSCustomObject]@{
                salt = $salt
                hash = $hash
            }
        }
        $json = $authData | ConvertTo-Json -Depth 5
        $encBytes = Protect-VaultBytes -PlainText $json
        [System.IO.File]::WriteAllBytes($AUTH_VAULT_FILE, $encBytes)
    }

    if (-not (Test-Path $RECOVERY_VAULT_FILE)) {
        $recKey = Generate-EmergencyCode
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $recHash = [System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($recKey))).Replace('-', '').ToLower()
        
        $recData = [PSCustomObject]@{
            metadata = [PSCustomObject]@{
                author = "Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)"
                purpose = "Emergency Recovery Key Vault"
                hardwareBound = $true
                updatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            recovery = [PSCustomObject]@{
                key = $recKey
                hash = $recHash
            }
        }
        $jsonRec = $recData | ConvertTo-Json -Depth 5
        $encRecBytes = Protect-VaultBytes -PlainText $jsonRec
        [System.IO.File]::WriteAllBytes($RECOVERY_VAULT_FILE, $encRecBytes)
    }
}

function Get-AdminAuthData {
    Initialize-AdminAuthVault
    try {
        $bytes = [System.IO.File]::ReadAllBytes($AUTH_VAULT_FILE)
        $json = Unprotect-VaultBytes -EncryptedBytes $bytes
        if ([string]::IsNullOrWhiteSpace($json)) { return $null }
        return ($json | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Get-RecoveryVaultData {
    Initialize-AdminAuthVault
    try {
        $bytes = [System.IO.File]::ReadAllBytes($RECOVERY_VAULT_FILE)
        $json = Unprotect-VaultBytes -EncryptedBytes $bytes
        if ([string]::IsNullOrWhiteSpace($json)) { return $null }
        return ($json | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Test-AdminPassword([string]$InputPassword) {
    if ([string]::IsNullOrEmpty($InputPassword)) { return $false }
    $authObj = Get-AdminAuthData
    if (-not $authObj -or -not $authObj.auth) { return $false }

    $storedSalt = $authObj.auth.salt
    $storedHash = $authObj.auth.hash
    $computedHash = Compute-Pbkdf2Hash -Password $InputPassword -SaltBase64 $storedSalt -Iterations 50000

    return (Compare-ConstantTime -StrA $computedHash -StrB $storedHash)
}

function Verify-AdminRecoveryKey([string]$InputKey) {
    if ([string]::IsNullOrWhiteSpace($InputKey)) { return $false }
    $cleanInput = $InputKey.Trim().ToUpper()
    
    $recObj = Get-RecoveryVaultData
    if ($recObj -and $recObj.recovery -and $recObj.recovery.key) {
        $storedKey = $recObj.recovery.key.Trim().ToUpper()
        if ($cleanInput -eq $storedKey) { return $true }
    }
    
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $inputHash = [System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($cleanInput))).Replace('-', '').ToLower()
    if ($recObj -and $recObj.recovery -and $recObj.recovery.hash) {
        if ($inputHash -eq $recObj.recovery.hash.ToLower()) { return $true }
    }
    
    return $false
}

function Set-AdminPasswordInternal([string]$NewPassword) {
    if ([string]::IsNullOrWhiteSpace($NewPassword) -or $NewPassword.Length -lt 6) {
        return [PSCustomObject]@{ Success = $false; Error = "Mật khẩu phải từ 6 ký tự trở lên!" }
    }

    $newSalt = Get-RngSalt -Length 16
    $newHash = Compute-Pbkdf2Hash -Password $NewPassword -SaltBase64 $newSalt -Iterations 50000

    $authData = [PSCustomObject]@{
        metadata = [PSCustomObject]@{
            author = "Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)"
            algorithm = "PBKDF2-HMAC-SHA256-PEPPERED"
            iterations = 50000
            hardwareBound = $true
            machineHwid = (Get-MachineHWID)
            lastChanged = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            changedBy = "$env:USERNAME on $env:COMPUTERNAME"
        }
        auth = [PSCustomObject]@{
            salt = $newSalt
            hash = $newHash
        }
    }
    $encBytes = Protect-VaultBytes -PlainText ($authData | ConvertTo-Json -Depth 5)
    [System.IO.File]::WriteAllBytes($AUTH_VAULT_FILE, $encBytes)

    $newRecKey = Generate-EmergencyCode
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $recHash = [System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($newRecKey))).Replace('-', '').ToLower()

    $recData = [PSCustomObject]@{
        metadata = [PSCustomObject]@{
            author = "Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)"
            purpose = "Emergency Recovery Key Vault"
            hardwareBound = $true
            updatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            associatedWith = "Password changed on " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        recovery = [PSCustomObject]@{
            key = $newRecKey
            hash = $recHash
        }
    }
    $encRecBytes = Protect-VaultBytes -PlainText ($recData | ConvertTo-Json -Depth 5)
    [System.IO.File]::WriteAllBytes($RECOVERY_VAULT_FILE, $encRecBytes)

    return [PSCustomObject]@{
        Success = $true
        RecoveryKey = $newRecKey
        UpdatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# ==============================================================================
# 4. HÀM NHẬP MẬT KHẨU ẨN KÝ TỰ BẰNG DẤU *
# ==============================================================================

function Read-PasswordMasked([string]$Prompt = ">> Nhập mật khẩu: ") {
    Write-Host -NoNewline $Prompt -ForegroundColor Yellow
    $pass = New-Object System.Text.StringBuilder
    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Enter) {
            Write-Host ""
            break
        } elseif ($key.Key -eq [ConsoleKey]::Backspace) {
            if ($pass.Length -gt 0) {
                [void]$pass.Remove($pass.Length - 1, 1)
                Write-Host -NoNewline "`b `b"
            }
        } elseif ($key.Key -eq [ConsoleKey]::Escape) {
            Write-Host ""
            return ""
        } elseif ($key.KeyChar -ge 32 -and $key.KeyChar -le 126) {
            [void]$pass.Append($key.KeyChar)
            Write-Host -NoNewline "*" -ForegroundColor Cyan
        }
    }
    return $pass.ToString()
}

# ==============================================================================
# 4. CỔNG XÁC THỰC BẢO VỆ ĐẶC QUYỀN ADMIN (GATEKEEPER SECURITY SHIELD)
# ==============================================================================

function Confirm-AdminAccess {
    param (
        [string]$ActionTitle = "TÁC VỤ QUẢN TRỊ ADMIN"
    )
    Initialize-AdminAuthVault

    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "  🔒 BẢO VỆ ĐẶC QUYỀN ADMIN - YÊU CẦU XÁC THỰC BẢO MẬT                          " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host " Tác vụ: $ActionTitle" -ForegroundColor White
    Write-Host " Bạn đang truy cập vào tính năng quản trị tối cao của Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)." -ForegroundColor DarkGray
    Write-Host " Vui lòng nhập Mật Khẩu Admin hiện tại để được cấp quyền thực thi.`n" -ForegroundColor DarkGray

    $maxAttempts = 3
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        $attempt++
        $prompt = if ($maxAttempts -eq 1) { ">> Nhập Mật Khẩu Admin (hoặc Enter để Thoát): " } else { ">> Nhập Mật Khẩu Admin (Lần $attempt/$maxAttempts, hoặc Enter để Thoát): " }
        $inputPass = Read-PasswordMasked -Prompt $prompt
        if ([string]::IsNullOrWhiteSpace($inputPass)) {
            Write-Host "`n[*] Đã hủy thao tác. Quyền truy cập bị đóng!`n" -ForegroundColor Yellow
            Start-Sleep -Milliseconds 600
            return $false
        }

        if (Test-AdminPassword -InputPassword $inputPass) {
            Write-Host "`n  [OK] ✅ XÁC THỰC ADMIN CHÍNH XÁC! ĐANG KHỞI CHẠY TÁC VỤ...`n" -ForegroundColor Green
            Start-Sleep -Milliseconds 400
            return $true
        } else {
            Write-Host "`n  [!] ❌ Mật khẩu Admin không chính xác!" -ForegroundColor Red
            if ($attempt -lt $maxAttempts) {
                Write-Host "  Vui lòng kiểm tra lại phím CapsLock và bộ gõ tiếng Việt.`n" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "`n❌ Bạn đã nhập sai quá $maxAttempts lần! Quyền truy cập bị từ chối.`n" -ForegroundColor Red
    Start-Sleep -Seconds 1
    return $false
}

# ==============================================================================
# 5. GIAO DIỆN BẢNG ĐIỀU KHIỂN BẢO MẬT ADMIN (INTERACTIVE CONSOLE UI)
# ==============================================================================

function Start-AdminPasswordConsole {
    Initialize-AdminAuthVault

    while ($true) {
        Clear-Host
        $authObj = Get-AdminAuthData
        $lastChanged = if ($authObj -and $authObj.metadata.lastChanged) { $authObj.metadata.lastChanged } else { "Chưa cập nhật" }

        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "             TB-TOOLBOX - TRUNG TÂM QUẢN LÝ MẬT KHẨU & BẢO MẬT ADMIN            " -ForegroundColor Yellow
        Write-Host "             Bản quyền thuộc về: Mr. ĐÀO XUÂN TUẤN (Tuấn Beo)                   " -ForegroundColor Green
        Write-Host "        Hotline: 0987.1987.92 | Email: tuanbeo.technology@gmail.com             " -ForegroundColor DarkGray
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  🛡️ TRẠNG THÁI BẢO MẬT HỆ THỐNG:" -ForegroundColor Green
        Write-Host "  - Thuật toán mã hóa: PBKDF2 (50,000 vòng) + Salt ngẫu nhiên + Hardware Pepper" -ForegroundColor White
        Write-Host "  - Cơ chế chống copy: Windows DPAPI + Khóa Entropy theo phần cứng máy tính (HWID)" -ForegroundColor Cyan
        Write-Host "  - Khóa Cứu Hộ: [ĐÃ KÍCH HOẠT & NIÊM PHONG AN TOÀN TRONG KÉT SẮT]" -ForegroundColor Green
        Write-Host "  - Lần cập nhật mật khẩu gần nhất: $lastChanged" -ForegroundColor DarkCyan
        Write-Host ""
        Write-Host "  DANH SÁCH TÁC VỤ QUẢN TRỊ BẢO MẬT:" -ForegroundColor Yellow
        Write-Host "   [1] 🧪 KIỂM TRA (TEST) MẬT KHẨU HIỆN TẠI" -ForegroundColor Cyan
        Write-Host "       -> Nhập mật khẩu để test xem có đúng không (Không thay đổi dữ liệu)." -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [2] 🔑 ĐỔI MẬT KHẨU ADMIN MỚI" -ForegroundColor Yellow
        Write-Host "       -> Nhập mật khẩu cũ -> Mật khẩu mới -> Xác nhận mật khẩu mới." -ForegroundColor DarkGray
        Write-Host "       -> Tự động cấp MÃ CỨU HỘ MỚI (Dùng để khôi phục nếu quên mật khẩu mới)." -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [3] 🚨 CỨU HỘ KHI QUÊN MẬT KHẨU" -ForegroundColor Red
        Write-Host "       -> Nhập Mã Cứu Hộ đã lưu để mở khóa và đặt lại mật khẩu mới an toàn." -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [4] 📜 XEM LẠI MÃ CỨU HỘ ĐANG LƯU (Yêu cầu xác thực Admin)" -ForegroundColor Magenta
        Write-Host "       -> Xem lại Mã Cứu Hộ trong két sắt để ghi nhớ/chụp ảnh cất vào điện thoại." -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   [5] 🛠️  CỨU HỘ BẰNG MẬT KHẨU GỐC (KHI QUÊN MẬT KHẨU & MẤT MÃ DỰ PHÒNG)" -ForegroundColor Green
        Write-Host "       -> Nhập Mật khẩu Gốc theo Quy Tắc Chung(~17) để cấp mật khẩu mới & mã mới ngay." -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "   [0] 🚪 Thoát chương trình" -ForegroundColor Gray
        Write-Host "================================================================================" -ForegroundColor Cyan

        $choice = (Read-Host "👉 Mời bạn chọn chức năng (1 - 5 hoặc 0 để Thoát)").Trim()

        if ($choice -eq "0" -or $choice -eq "q" -or $choice -eq "Q") {
            Write-Host "`nCảm ơn bạn đã sử dụng Trung Tâm Bảo Mật Admin. Tạm biệt!`n" -ForegroundColor Green
            Start-Sleep -Milliseconds 600
            break
        }

        # CHỨC NĂNG 1: TEST MẬT KHẨU HIỆN TẠI
        if ($choice -eq "1") {
            Write-Host "`n================================================================================" -ForegroundColor Cyan
            Write-Host "                  🧪 KIỂM TRA (TEST) MẬT KHẨU ADMIN HIỆN TẠI                   " -ForegroundColor Yellow
            Write-Host "================================================================================" -ForegroundColor Cyan
            Write-Host " Ghi chú: Chức năng này chỉ kiểm tra tính chính xác, không thay đổi mật khẩu.`n" -ForegroundColor DarkGray

            $testPass = Read-PasswordMasked -Prompt ">> Nhập mật khẩu Admin bạn muốn test (hoặc bấm Enter để Hủy): "
            if ([string]::IsNullOrEmpty($testPass)) {
                Write-Host "`n[*] Đã hủy kiểm tra mật khẩu." -ForegroundColor Yellow
            } else {
                Write-Host "`nĐang băm PBKDF2 (50,000 vòng) và đối chiếu Constant-Time với Két Sắt..." -ForegroundColor Cyan
                Start-Sleep -Milliseconds 400
                $isValid = Test-AdminPassword -InputPassword $testPass
                if ($isValid) {
                    Write-Host ""
                    Write-Host "================================================================================" -ForegroundColor Green
                    Write-Host "  ✅ CHÍNH XÁC 100%! MẬT KHẨU ADMIN BẠN VỪA NHẬP HOÀN TOÀN TRÙNG KHỚP!        " -ForegroundColor Green
                    Write-Host "================================================================================" -ForegroundColor Green
                    Write-Host "  Bạn có thể yên tâm sử dụng mật khẩu này để thực hiện mọi tác vụ quản trị.`n" -ForegroundColor White
                } else {
                    Write-Host ""
                    Write-Host "================================================================================" -ForegroundColor Red
                    Write-Host "  ❌ KHÔNG ĐÚNG! MẬT KHẨU VỪA NHẬP KHÔNG KHỚP VỚI HỆ THỐNG!                    " -ForegroundColor Red
                    Write-Host "================================================================================" -ForegroundColor Red
                    Write-Host "  Vui lòng kiểm tra lại phím CapsLock hoặc ký tự gõ tiếng Việt.`n" -ForegroundColor Yellow
                }
            }
            Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại Menu..."
            continue
        }

        # CHỨC NĂNG 2: ĐỔI MẬT KHẨU ADMIN MỚI
        if ($choice -eq "2") {
            Write-Host "`n================================================================================" -ForegroundColor Yellow
            Write-Host "                       🔑 ĐỔI MẬT KHẨU ADMIN QUẢN TRỊ MỚI                       " -ForegroundColor Yellow
            Write-Host "================================================================================" -ForegroundColor Yellow
            Write-Host " Yêu cầu xác thực: Hãy nhập Mật khẩu cũ trước khi đổi mật khẩu mới.`n" -ForegroundColor DarkGray

            $oldPass = Read-PasswordMasked -Prompt ">> [1/3] Nhập Mật khẩu Admin HIỆN TẠI (hoặc Enter để Hủy): "
            if ([string]::IsNullOrEmpty($oldPass)) {
                Write-Host "`n[*] Đã hủy thao tác đổi mật khẩu." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                continue
            }

            if (-not (Test-AdminPassword -InputPassword $oldPass)) {
                Write-Host "`n❌ Mật khẩu hiện tại không chính xác! Thao tác bị từ chối." -ForegroundColor Red
                Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
                continue
            }

            Write-Host " [OK] Xác thực mật khẩu cũ thành công!" -ForegroundColor Green
            Write-Host ""

            $newPass1 = Read-PasswordMasked -Prompt ">> [2/3] Nhập MẬT KHẨU ADMIN MỚI muốn thiết lập : "
            if ([string]::IsNullOrWhiteSpace($newPass1) -or $newPass1.Length -lt 6) {
                Write-Host "`n❌ Mật khẩu mới không hợp lệ! Độ dài tối thiểu phải từ 6 ký tự trở lên." -ForegroundColor Red
                Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
                continue
            }

            if ($newPass1 -eq $oldPass) {
                Write-Host "`n❌ Mật khẩu mới không được trùng với mật khẩu cũ!" -ForegroundColor Red
                Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
                continue
            }

            $newPass2 = Read-PasswordMasked -Prompt ">> [3/3] Nhập LẠI MẬT KHẨU MỚI để xác nhận      : "
            if ($newPass1 -ne $newPass2) {
                Write-Host "`n❌ Mật khẩu xác nhận không trùng khớp! Thao tác đổi mật khẩu thất bại." -ForegroundColor Red
                Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
                continue
            }

            Write-Host "`nĐang băm mã hóa 1 chiều PBKDF2 (50,000 vòng) và niêm phong Két Sắt..." -ForegroundColor Cyan
            Start-Sleep -Milliseconds 600

            $result = Set-AdminPasswordInternal -NewPassword $newPass1
            if ($result.Success) {
                Write-Host ""
                Write-Host "================================================================================" -ForegroundColor Green
                Write-Host "            🎉 CHÚC MỪNG: ĐÃ ĐỔI MẬT KHẨU ADMIN THÀNH CÔNG 100%!                " -ForegroundColor Yellow
                Write-Host "================================================================================" -ForegroundColor Green
                Write-Host "  MẬT KHẨU MỚI: Đã băm PBKDF2 (50,000 vòng) + Neo cứng phần cứng HWID" -ForegroundColor White
                Write-Host "  BẢO VỆ: Chống sao chép sang máy khác (Windows DPAPI + HWID Entropy)" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  MÃ CỨU HỘ MỚI CỦA BẠN (DÙNG ĐỂ KHÔI PHỤC NẾU BỊ QUÊN MẬT KHẨU):" -ForegroundColor Cyan
                Write-Host "  ┌────────────────────────────────────────────────────────────┐" -ForegroundColor Green
                Write-Host "  │   👉  " -NoNewline -ForegroundColor Green
                Write-Host "$($result.RecoveryKey)" -NoNewline -ForegroundColor Yellow
                Write-Host "  👈   │" -ForegroundColor Green
                Write-Host "  └────────────────────────────────────────────────────────────┘" -ForegroundColor Green
                Write-Host ""
                Write-Host "  (*) HƯỚNG DẪN: Hãy chụp ảnh hoặc lưu Mã Cứu Hộ này vào điện thoại/sổ tay!" -ForegroundColor Yellow
                Write-Host "      Sau này nếu lỡ quên mật khẩu mới, bạn chỉ cần nhập mã này tại Menu [3]." -ForegroundColor White
                Write-Host "================================================================================" -ForegroundColor Green
                Write-Host ""
            } else {
                Write-Host "`n❌ Có lỗi khi lưu trữ mật khẩu: $($result.Error)" -ForegroundColor Red
            }
            Wait-ForUserExit -Message "Nhấn phím bất kỳ để hoàn tất và quay lại..."
            continue
        }

        # CHỨC NĂNG 3: CỨU HỘ KHẨN CẤP
        if ($choice -eq "3") {
            Write-Host "`n================================================================================" -ForegroundColor Red
            Write-Host "                    🚨 CỨU HỘ KHI QUÊN MẬT KHẨU ADMIN                           " -ForegroundColor Yellow
            Write-Host "================================================================================" -ForegroundColor Red
            Write-Host " Dành cho trường hợp bạn đã quên mật khẩu Admin hiện tại." -ForegroundColor DarkGray
            Write-Host " Yêu cầu nhập đúng Mã Cứu Hộ của bạn (TB-RECOVERY-xxxx-xxxx-xxxx-xxxxxxx).`n" -ForegroundColor DarkGray

            $recInput = (Read-Host ">> Nhập Mã Cứu Hộ của bạn (hoặc Enter để Hủy)").Trim()
            if ([string]::IsNullOrEmpty($recInput)) {
                Write-Host "`n[*] Đã hủy thao tác cứu hộ." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                continue
            }

            Write-Host "`nĐang đối chiếu Mã Cứu Hộ với Két Sắt Bảo Mật..." -ForegroundColor Cyan
            Start-Sleep -Milliseconds 500

            if (Verify-AdminRecoveryKey -InputKey $recInput) {
                Write-Host " [OK] XÁC THỰC MÃ CỨU HỘ CHÍNH XÁC! QUYỀN ADMIN ĐƯỢC MỞ KHÓA." -ForegroundColor Green
                Write-Host ""

                $resetPass1 = Read-PasswordMasked -Prompt ">> [1/2] Nhập MẬT KHẨU ADMIN MỚI muốn thiết lập : "
                if ([string]::IsNullOrWhiteSpace($resetPass1) -or $resetPass1.Length -lt 6) {
                    Write-Host "`n❌ Mật khẩu phải từ 6 ký tự trở lên! Thao tác bị hủy." -ForegroundColor Red
                    Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
                    continue
                }

                $resetPass2 = Read-PasswordMasked -Prompt ">> [2/2] Nhập LẠI MẬT KHẨU MỚI để xác nhận      : "
                if ($resetPass1 -ne $resetPass2) {
                    Write-Host "`n❌ Mật khẩu xác nhận không khớp! Cứu hộ thất bại." -ForegroundColor Red
                    Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
                    continue
                }

                $resReset = Set-AdminPasswordInternal -NewPassword $resetPass1
                if ($resReset.Success) {
                    Write-Host ""
                    Write-Host "================================================================================" -ForegroundColor Green
                    Write-Host "  🎉 CỨU HỘ THÀNH CÔNG: MẬT KHẨU ADMIN ĐÃ ĐƯỢC THIẾT LẬP LẠI!                   " -ForegroundColor Yellow
                    Write-Host "================================================================================" -ForegroundColor Green
                    Write-Host "  Mã cứu hộ cũ đã được thu hồi và thay thế bằng MÃ CỨU HỘ MỚI:" -ForegroundColor White
                    Write-Host "  👉 $($resReset.RecoveryKey)" -ForegroundColor Cyan
                    Write-Host "================================================================================" -ForegroundColor Green
                    Write-Host ""
                }
            } else {
                Write-Host "`n❌ Mã Cứu Hộ không hợp lệ! Vui lòng kiểm tra lại từng ký tự." -ForegroundColor Red
            }
            Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
            continue
        }

        # CHỨC NĂNG 4: XEM LẠI MÃ CỨU HỘ ĐANG LƯU
        if ($choice -eq "4") {
            Write-Host "`n================================================================================" -ForegroundColor Magenta
            Write-Host "              📜 XEM LẠI MÃ CỨU HỘ ĐANG LƯU TRONG KÉT SẮT                       " -ForegroundColor Yellow
            Write-Host "================================================================================" -ForegroundColor Magenta
            Write-Host " Để bảo vệ an toàn thông tin, vui lòng nhập mật khẩu Admin hiện tại:`n" -ForegroundColor DarkGray

            $authCheck = Read-PasswordMasked -Prompt ">> Nhập Mật khẩu Admin hiện tại (hoặc Enter để Hủy): "
            if ([string]::IsNullOrEmpty($authCheck)) {
                Write-Host "`n[*] Đã hủy thao tác." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                continue
            }

            if (Test-AdminPassword -InputPassword $authCheck) {
                $recData = Get-RecoveryVaultData
                $curKey = if ($recData -and $recData.recovery -and $recData.recovery.key) { $recData.recovery.key } else { "Không xác định" }
                $recUpdate = if ($recData -and $recData.metadata -and $recData.metadata.updatedAt) { $recData.metadata.updatedAt } else { "N/A" }

                Write-Host ""
                Write-Host "================================================================================" -ForegroundColor Green
                Write-Host "  THÔNG TIN KHÓA CỨU HỘ HIỆN TẠI:                                               " -ForegroundColor Yellow
                Write-Host "================================================================================" -ForegroundColor Green
                Write-Host "  MÃ CỨU HỘ: " -NoNewline -ForegroundColor White
                Write-Host "$curKey" -ForegroundColor Yellow
                Write-Host "  Cập nhật lúc: $recUpdate" -ForegroundColor DarkCyan
                Write-Host "  Trạng thái két sắt: Được bảo vệ bởi Windows DPAPI + HWID Entropy & SHA-256" -ForegroundColor DarkGray
                Write-Host "================================================================================" -ForegroundColor Green
                Write-Host ""
            } else {
                Write-Host "`n❌ Mật khẩu Admin không chính xác! Không thể xem Mã Cứu Hộ." -ForegroundColor Red
            }
            Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
            continue
        }

        # CHỨC NĂNG 5: CỨU HỘ BẰNG MẬT KHẨU GỐC (KHI QUÊN MẬT KHẨU & MẤT MÃ DỰ PHÒNG)
        if ($choice -eq "5") {
            Write-Host "`n================================================================================" -ForegroundColor Red
            Write-Host "       🛠️  CỨU HỘ BẰNG MẬT KHẨU GỐC (KHI QUÊN MẬT KHẨU & MẤT MÃ DỰ PHÒNG)       " -ForegroundColor Yellow
            Write-Host "================================================================================" -ForegroundColor Red
            Write-Host " Dành cho tình huống khẩn cấp nhất: Bạn đã quên mật khẩu Admin và mất cả Mã Cứu Hộ." -ForegroundColor DarkGray
            Write-Host " Yêu cầu xác thực bằng Mật Khẩu Gốc Hệ Thống (theo Quy Tắc Chung(~17)).`n" -ForegroundColor DarkGray

            $rootPassInput = Read-PasswordMasked -Prompt ">> Nhập Mật Khẩu Gốc Hệ Thống (hoặc bấm Enter để Hủy): "
            if ([string]::IsNullOrEmpty($rootPassInput)) {
                Write-Host "`n[*] Đã hủy thao tác cứu hộ bằng mật khẩu gốc." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                continue
            }

            Write-Host "`nĐang đối chiếu Mật Khẩu Gốc với Mã Băm PBKDF2 (50,000 vòng)..." -ForegroundColor Cyan
            Start-Sleep -Milliseconds 500

            $computedRootHash = Compute-Pbkdf2Hash -Password $rootPassInput -SaltBase64 $script:DEFAULT_VAULT_SALT -Iterations 50000
            $isRootValid = Compare-ConstantTime -StrA $computedRootHash -StrB $script:DEFAULT_VAULT_HASH

            if ($isRootValid) {
                Write-Host " [OK] XÁC THỰC MẬT KHẨU GỐC CHÍNH XÁC! QUYỀN CHỦ SỞ HỮU ĐƯỢC KÍCH HOẠT." -ForegroundColor Green
                Write-Host ""

                $newPass1 = Read-PasswordMasked -Prompt ">> [1/2] Nhập MẬT KHẨU ADMIN MỚI muốn thiết lập : "
                if ([string]::IsNullOrWhiteSpace($newPass1) -or $newPass1.Length -lt 6) {
                    Write-Host "`n❌ Mật khẩu phải từ 6 ký tự trở lên! Thao tác bị hủy." -ForegroundColor Red
                    Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
                    continue
                }

                $newPass2 = Read-PasswordMasked -Prompt ">> [2/2] Nhập LẠI MẬT KHẨU MỚI để xác nhận      : "
                if ($newPass1 -ne $newPass2) {
                    Write-Host "`n❌ Hai mật khẩu mới không trùng khớp! Thao tác cứu hộ thất bại." -ForegroundColor Red
                    Wait-ForUserExit -Message "Nhấn phím bất kỳ để quay lại..."
                    continue
                }

                Write-Host "`nĐang cập nhật Mật khẩu Admin Mới và cấp Mã Cứu Hộ mới..." -ForegroundColor Cyan
                Start-Sleep -Milliseconds 500

                $resRoot = Set-AdminPasswordInternal -NewPassword $newPass1
                if ($resRoot.Success) {
                    try { Set-Clipboard -Value $resRoot.RecoveryKey -ErrorAction SilentlyContinue } catch {}

                    Write-Host ""
                    Write-Host "================================================================================" -ForegroundColor Green
                    Write-Host "  🎉 CỨU HỘ THÀNH CÔNG: MẬT KHẨU ADMIN MỚI ĐÃ ĐƯỢC THIẾT LẬP VÀ KÍCH HOẠT!       " -ForegroundColor Yellow
                    Write-Host "================================================================================" -ForegroundColor Green
                    Write-Host "  MẬT KHẨU MỚI: Đã niêm phong vào Két Sắt (.auth.vault)" -ForegroundColor White
                    Write-Host "  BẢO VỆ: Chống sao chép sang máy khác (Windows DPAPI + HWID Entropy)" -ForegroundColor Cyan
                    Write-Host ""
                    Write-Host "  MÃ CỨU HỘ MỚI TINH CỦA BẠN (DÙNG ĐỂ KHÔI PHỤC NẾU QUÊN PASS MỚI):" -ForegroundColor Cyan
                    Write-Host "  ┌────────────────────────────────────────────────────────────┐" -ForegroundColor Green
                    Write-Host "  │   👉  " -NoNewline -ForegroundColor Green
                    Write-Host "$($resRoot.RecoveryKey)" -NoNewline -ForegroundColor Yellow
                    Write-Host "  👈   │" -ForegroundColor Green
                    Write-Host "  └────────────────────────────────────────────────────────────┘" -ForegroundColor Green
                    Write-Host "  (Đã tự động sao chép Mã Cứu Hộ vào Clipboard máy tính của bạn!)" -ForegroundColor DarkGray
                    Write-Host ""
                    Write-Host "  (*) HƯỚNG DẪN: Hãy chụp ảnh hoặc dán lưu Mã Cứu Hộ này vào ghi chú an toàn!" -ForegroundColor Yellow
                    Write-Host "      Lần sau nếu quên mật khẩu mới, bạn có thể dùng mã này tại Menu [3]." -ForegroundColor White
                    Write-Host "================================================================================" -ForegroundColor Green
                    Write-Host ""
                } else {
                    Write-Host "`n❌ Có lỗi khi cập nhật mật khẩu mới: $($resRoot.Error)" -ForegroundColor Red
                }
            } else {
                Write-Host "`n❌ MẬT KHẨU GỐC KHÔNG CHÍNH XÁC! TỪ CHỐI THAO TÁC CỨU HỘ." -ForegroundColor Red
            }
            Wait-ForUserExit -Message "Nhấn phím bất kỳ để hoàn tất và quay lại..."
            continue
        }

        Write-Host "`n[!] Lựa chọn '$choice' không hợp lệ. Vui lòng chọn từ 1 đến 5 hoặc 0 để Thoát." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}

if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.InvocationName -ne '&') {
    Start-AdminPasswordConsole
}
