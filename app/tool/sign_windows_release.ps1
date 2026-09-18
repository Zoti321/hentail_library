# Signs Windows release binaries with Authenticode.
#
# Default: generate an ephemeral self-signed code-signing certificate (CI-friendly).
# Optional: set WINDOWS_CODESIGN_PFX_BASE64 + WINDOWS_CODESIGN_PFX_PASSWORD to reuse
# the same self-signed (or other) PFX across runs via GitHub Secrets.
#
# Usage:
#   pwsh app/tool/sign_windows_release.ps1 -Files path\to\app.exe, path\to\Setup.exe

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]] $Files
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-SignTool {
    $candidates = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe",
        "${env:ProgramFiles}\Windows Kits\10\bin\*\x64\signtool.exe"
    )
    foreach ($pattern in $candidates) {
        $match = Get-Item -Path $pattern -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName } -Descending |
            Select-Object -First 1
        if ($null -ne $match) {
            return $match.FullName
        }
    }
    throw 'signtool.exe not found. Install Windows SDK (signtool) on the runner.'
}

function Import-CodeSigningCertificate {
    if ([string]::IsNullOrWhiteSpace($env:WINDOWS_CODESIGN_PFX_BASE64)) {
        Write-Host 'No WINDOWS_CODESIGN_PFX_BASE64; creating ephemeral self-signed certificate.'
        $cert = New-SelfSignedCertificate `
            -Type CodeSigningCert `
            -Subject 'CN=Hentai Library (Self-Signed)' `
            -CertStoreLocation 'Cert:\CurrentUser\My' `
            -HashAlgorithm SHA256 `
            -KeyExportPolicy Exportable `
            -NotAfter (Get-Date).AddDays(825)
        return $cert.Thumbprint
    }

    if ([string]::IsNullOrWhiteSpace($env:WINDOWS_CODESIGN_PFX_PASSWORD)) {
        throw 'WINDOWS_CODESIGN_PFX_PASSWORD is required when WINDOWS_CODESIGN_PFX_BASE64 is set.'
    }

    Write-Host 'Importing code-signing certificate from WINDOWS_CODESIGN_PFX_BASE64.'
    $pfxPath = Join-Path $env:RUNNER_TEMP 'hentai_library_codesign.pfx'
    $pfxBytes = [Convert]::FromBase64String($env:WINDOWS_CODESIGN_PFX_BASE64)
    [IO.File]::WriteAllBytes($pfxPath, $pfxBytes)
    $securePassword = ConvertTo-SecureString $env:WINDOWS_CODESIGN_PFX_PASSWORD -AsPlainText -Force
    $imported = Import-PfxCertificate `
        -FilePath $pfxPath `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -Password $securePassword `
        -Exportable
    Remove-Item -LiteralPath $pfxPath -Force -ErrorAction SilentlyContinue
    return $imported.Thumbprint
}

function Sign-ReleaseFile {
    param(
        [string] $SignTool,
        [string] $Thumbprint,
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "File to sign not found: $Path"
    }

    Write-Host "Signing: $Path"
    & $SignTool sign `
        /fd sha256 `
        /td sha256 `
        /tr http://timestamp.digicert.com `
        /sha1 $Thumbprint `
        $Path

    & $SignTool verify /pa $Path
    if ($LASTEXITCODE -ne 0) {
        throw "Signature verification failed for: $Path"
    }
}

$signTool = Resolve-SignTool
Write-Host "Using signtool: $signTool"

$thumbprint = Import-CodeSigningCertificate

foreach ($file in $Files) {
    $resolved = $file.Trim()
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        continue
    }
    Sign-ReleaseFile -SignTool $signTool -Thumbprint $thumbprint -Path $resolved
}

Write-Host 'All files signed successfully.'
