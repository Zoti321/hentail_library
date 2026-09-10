# Patches vendored cargokit resolve_symlinks.ps1 copies under PUB_CACHE.
# Needed until upstream ships https://github.com/irondash/cargokit/pull/119
# (Get-Item without -Force fails on Hidden path segments such as %AppData%).
#
# Run after `flutter pub get` on Windows:
#   powershell -ExecutionPolicy Bypass -File tool/patch_cargokit_resolve_symlinks.ps1

$ErrorActionPreference = 'Stop'

function Get-PubCacheRoot {
    if ($env:PUB_CACHE -and (Test-Path -LiteralPath $env:PUB_CACHE)) {
        return (Resolve-Path -LiteralPath $env:PUB_CACHE).Path
    }
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    $default = Join-Path $localAppData 'Pub\Cache'
    if (-not (Test-Path -LiteralPath $default)) {
        throw "PUB_CACHE not found. Set PUB_CACHE or run flutter pub get first. Looked at: $default"
    }
    return $default
}

$needle = '$item = Get-Item $realPath'
$replacement = '$item = Get-Item -Force $realPath'
$pubCache = Get-PubCacheRoot
$hosted = Join-Path $pubCache 'hosted'

$targets = @()
if (Test-Path -LiteralPath $hosted) {
    foreach ($hostDir in Get-ChildItem -LiteralPath $hosted -Directory) {
        foreach ($pkg in Get-ChildItem -LiteralPath $hostDir.FullName -Directory) {
            $candidate = Join-Path $pkg.FullName 'cargokit\cmake\resolve_symlinks.ps1'
            if (Test-Path -LiteralPath $candidate) {
                $targets += Get-Item -LiteralPath $candidate
            }
        }
    }
}

if (-not $targets) {
    Write-Host "No cargokit resolve_symlinks.ps1 under $pubCache"
    exit 0
}

$patched = 0
$skipped = 0
foreach ($file in $targets) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    if ($text.Contains($replacement)) {
        Write-Host "OK (already patched): $($file.FullName)"
        $skipped++
        continue
    }
    if (-not $text.Contains($needle)) {
        Write-Host "SKIP (unexpected content): $($file.FullName)"
        $skipped++
        continue
    }
    $updated = $text.Replace($needle, $replacement)
    Set-Content -LiteralPath $file.FullName -Value $updated -NoNewline
    Write-Host "Patched: $($file.FullName)"
    $patched++
}

Write-Host "Done. patched=$patched skipped=$skipped"
