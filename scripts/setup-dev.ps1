#Requires -Version 5.1
# First-time local dev setup: Rust link + native dependencies.
param(
    [switch]$SkipRustLink,
    [switch]$SkipNativeDeps
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if (-not $SkipRustLink) {
    & (Join-Path $PSScriptRoot "link-rust-builder.ps1")
}

if (-not $SkipNativeDeps) {
    & (Join-Path $RepoRoot "core\vendor\fetch-native-deps.ps1")
}

Write-Host "Dev setup complete."
Write-Host "Next: cd app; flutter pub get; flutter run -d windows"