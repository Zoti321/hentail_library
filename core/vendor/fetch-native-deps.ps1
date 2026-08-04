#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$VendorRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManifestPath = Join-Path $VendorRoot "manifest.json"
$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

$PdfiumVersion = $Manifest.pdfium.version -replace "/", "%2F"

function Get-HostPlatformKey {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { return "windows-aarch64" }
    return "windows-x86_64"
}

function Get-PdfiumLibraryFilter {
    param([string]$PlatformKey)
    if ($PlatformKey -like "windows-*") { return "pdfium.dll" }
    if ($PlatformKey -like "macos-*") { return "libpdfium.dylib" }
    return "libpdfium.so"
}

function Fetch-PdfiumForPlatform {
    param([Parameter(Mandatory = $true)][string]$PlatformKey)

    $Artifact = $Manifest.pdfium.artifacts.$PlatformKey
    if (-not $Artifact) {
        throw "manifest.json 中无平台产物: $PlatformKey"
    }

    $OutDir = Join-Path $VendorRoot $PlatformKey
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

    $Url = "https://github.com/bblanchon/pdfium-binaries/releases/download/$PdfiumVersion/$Artifact"
    $TempArchive = Join-Path $env:TEMP "hentai-pdfium-$Artifact"

    Write-Host "下载 $Url ..."
    $attempt = 0
    while ($true) {
        $attempt++
        try {
            Invoke-WebRequest -Uri $Url -OutFile $TempArchive -UseBasicParsing
            break
        } catch {
            if ($attempt -ge 5) { throw }
            Write-Host "下载失败 (尝试 $attempt/5): $_ ；2 秒后重试..."
            Start-Sleep -Seconds 2
        }
    }

    $TempExtract = Join-Path $env:TEMP "hentai-pdfium-extract-$PlatformKey"
    if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $TempExtract | Out-Null

    try {
        if ($Artifact.EndsWith(".tgz")) {
            $WindowsTar = Join-Path $env:SystemRoot "System32/tar.exe"
            if (-not (Test-Path $WindowsTar)) {
                throw "未找到 Windows tar.exe，无法解压 $Artifact"
            }
            & $WindowsTar -xzf $TempArchive -C $TempExtract
        } else {
            Expand-Archive -Path $TempArchive -DestinationPath $TempExtract -Force
        }

        $Filter = Get-PdfiumLibraryFilter -PlatformKey $PlatformKey
        $Lib = Get-ChildItem -Path $TempExtract -Recurse -Filter $Filter | Select-Object -First 1
        if (-not $Lib) {
            throw "解压后未找到 $Filter ($PlatformKey)"
        }

        $Dest = Join-Path $OutDir $Filter
        Copy-Item $Lib.FullName $Dest -Force
        Write-Host "已写入 $Dest"
    } finally {
        Remove-Item $TempArchive -Force -ErrorAction SilentlyContinue
        Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$Platforms = @()
foreach ($arg in $args) {
    if ($arg -eq "--android") {
        $Platforms += @("android-arm", "android-arm64", "android-x86", "android-x64")
    } elseif ($arg -eq "--host") {
        $Platforms += Get-HostPlatformKey
    } elseif ($arg.StartsWith("--platform=")) {
        $Platforms += ($arg.Substring("--platform=".Length) -split ",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    } else {
        throw "Unknown arg: $arg (supported: --host, --android, --platform=key[,key...])"
    }
}

if ($Platforms.Count -eq 0) {
    $Platforms = @(Get-HostPlatformKey)
}

$Platforms = $Platforms | Select-Object -Unique
foreach ($platform in $Platforms) {
    Fetch-PdfiumForPlatform -PlatformKey $platform
}
