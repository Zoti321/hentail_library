#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$VendorRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManifestPath = Join-Path $VendorRoot "manifest.json"
$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

$PdfiumVersion = $Manifest.pdfium.version -replace "/", "%2F"

function Get-PlatformKey {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { return "windows-aarch64" }
    return "windows-x86_64"
}

$PlatformKey = Get-PlatformKey
$Artifact = $Manifest.pdfium.artifacts.$PlatformKey
if (-not $Artifact) {
    throw "manifest.json 中无平台产物: $PlatformKey"
}

$OutDir = Join-Path $VendorRoot $PlatformKey
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$Url = "https://github.com/bblanchon/pdfium-binaries/releases/download/$PdfiumVersion/$Artifact"
$TempArchive = Join-Path $env:TEMP "hentai-pdfium-$Artifact"

Write-Host "下载 $Url ..."
Invoke-WebRequest -Uri $Url -OutFile $TempArchive -UseBasicParsing

$TempExtract = Join-Path $env:TEMP "hentai-pdfium-extract"
if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
New-Item -ItemType Directory -Force -Path $TempExtract | Out-Null

if ($Artifact.EndsWith(".tgz")) {
    $WindowsTar = Join-Path $env:SystemRoot "System32/tar.exe"
    if (-not (Test-Path $WindowsTar)) {
        throw "未找到 Windows tar.exe，无法解压 $Artifact"
    }
    & $WindowsTar -xzf $TempArchive -C $TempExtract
} else {
    Expand-Archive -Path $TempArchive -DestinationPath $TempExtract -Force
}

$PdfiumDll = Get-ChildItem -Path $TempExtract -Recurse -Filter "pdfium.dll" | Select-Object -First 1
if (-not $PdfiumDll) {
    throw "解压后未找到 pdfium.dll"
}

Copy-Item $PdfiumDll.FullName (Join-Path $OutDir "pdfium.dll") -Force
Write-Host "已写入 $(Join-Path $OutDir 'pdfium.dll')"

Remove-Item $TempArchive -Force -ErrorAction SilentlyContinue
Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
