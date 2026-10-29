# ==============================================================================
# TB-TOOLBOX - CODE INTEGRITY GUARD (Integrity-Guard.ps1)
# Bản quyền thuộc về: Mr. Tuấn Beo (TuanBeoToolbox)
# Chuc nang: Niem phong ma nguon bang SHA256 & Chu ky so bat doi xung RSA-2048 bit.
#            Ngan chan nguoi am hieu CNTT mo script .ps1 ra sua code/bypass verify.
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$ENGINE_DIR = Split-Path -Parent $PSScriptRoot
$TB_ROOT = Split-Path -Parent $ENGINE_DIR
$CORE_DIR = $PSScriptRoot
$CONFIG_DIR = Join-Path $ENGINE_DIR "Config"
$SEAL_FILE = Join-Path $CONFIG_DIR ".integrity.seal"

# Dot-source Crypto-RSA neu chua co
if (Test-Path (Join-Path $CORE_DIR "Crypto-RSA.ps1")) {
    . (Join-Path $CORE_DIR "Crypto-RSA.ps1")
}

function Get-FileSha256 {
    param ([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha.ComputeHash($bytes)
        return [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
    } catch {
        return $null
    }
}

function Seal-Codebase {
    <#
    .SYNOPSIS
        Admin chay ham nay de niem phong toan bo cac script loi cua Toolbox.
        Moi tap tin deu duoc băm SHA256 va ky so boi RSA Private Key.
    #>
    if (-not (Test-Path $CONFIG_DIR)) { New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null }

    $targetFiles = @(
        "Engine\Core\Common-UI.ps1",
        "Engine\Core\Crypto-RSA.ps1",
        "Engine\Core\License-Engine.ps1",
        "Engine\Core\Feature-Registry.ps1",
        "Engine\Core\Config-Manager.ps1",
        "Engine\Core\Engine-Cleaner.ps1",
        "Engine\Core\Client-Bootstrap.ps1",
        "Engine\Core\Server-Sync.ps1",
        "Engine\Core\Push-ToolboxToServer.ps1"
    )

    $fileHashes = [ordered]@{}
    foreach ($rel in $targetFiles) {
        $fullPath = Join-Path $TB_ROOT $rel
        if (Test-Path $fullPath) {
            $hash = Get-FileSha256 -FilePath $fullPath
            $fileHashes[$rel] = $hash
        }
    }

    $manifest = [PSCustomObject]@{
        sealedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        author   = "Mr. Tuan Beo (TuanBeo)"
        version  = "2.0.0-RSA"
        files    = $fileHashes
    }

    $json = $manifest | ConvertTo-Json -Depth 5
    $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
    
    # Ky so bang RSA-2048 Private Key
    $sig = Sign-DataRSA -Data $base64
    if ([string]::IsNullOrWhiteSpace($sig)) {
        Write-Error "Khong the ky so ma nguon bang RSA!"
        return $false
    }

    $sealContent = "TBSEAL-RSA.$base64.$sig"
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($SEAL_FILE, $sealContent, $utf8WithBom)

    return $true
}

function Test-CodeIntegrity {
    <#
    .SYNOPSIS
        Kiem tra tinh toan ven cua ma nguon bang Public Key RSA-2048.
        Neu phat hien bat ky tap tin nao bi sua doi -> Tu choi ngay lap tuc!
    #>
    if (-not (Test-Path $SEAL_FILE)) {
        return [PSCustomObject]@{
            IsValid = $false
            Error   = "Không tìm thấy dấu niêm phong mã nguồn (.integrity.seal)! Hệ thống có thể đã bị can thiệp."
        }
    }

    try {
        $raw = [System.IO.File]::ReadAllText($SEAL_FILE, [System.Text.Encoding]::UTF8).Trim()
        $parts = $raw.Split('.')
        if ($parts.Length -ne 3 -or $parts[0] -ne "TBSEAL-RSA") {
            return [PSCustomObject]@{
                IsValid = $false
                Error   = "Dấu niêm phong hệ thống không đúng định dạng RSA!"
            }
        }

        $base64 = $parts[1]
        $receivedSig = $parts[2]

        # Kiểm tra chữ ký RSA-2048 với Public Key
        $isSigValid = Verify-DataRSA -Data $base64 -SignatureBase64 $receivedSig
        if (-not $isSigValid) {
            return [PSCustomObject]@{
                IsValid = $false
                Error   = "Chữ ký niêm phong RSA không hợp lệ! Tệp niêm phong đã bị giả mạo hoặc can thiệp."
            }
        }

        # Giải mã nội dung seal
        $jsonBytes = [Convert]::FromBase64String($base64)
        $jsonStr = [System.Text.Encoding]::UTF8.GetString($jsonBytes)
        $manifest = $jsonStr | ConvertFrom-Json

        # So sánh từng file trên ổ đĩa với hash niêm phong
        if ($manifest.files) {
            foreach ($prop in $manifest.files.PSObject.Properties) {
                $relPath = $prop.Name
                $expectedHash = $prop.Value
                $fullPath = Join-Path $TB_ROOT $relPath

                if (-not (Test-Path $fullPath)) {
                    return [PSCustomObject]@{
                        IsValid = $false
                        Error   = "Phát hiện tập tin hệ thống bị thiếu: $relPath"
                    }
                }

                $currentHash = Get-FileSha256 -FilePath $fullPath
                if ($currentHash.ToLower() -ne $expectedHash.ToLower()) {
                    return [PSCustomObject]@{
                        IsValid = $false
                        Error   = "CẢNH BÁO XÂM PHẠM: Mã nguồn tập tin '$relPath' đã bị can thiệp hoặc sửa đổi trái phép!"
                    }
                }
            }
        }

        return [PSCustomObject]@{
            IsValid = $true
            Error   = ""
        }
    } catch {
        return [PSCustomObject]@{
            IsValid = $false
            Error   = "Loi khi kiem tra tinh toan ven ma nguon: $($_.Exception.Message)"
        }
    }
}
