#Requires -Version 5.1
# Link app/rust_builder/rust to core/crates/flutter for Cargokit / FRB builds.
$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Junction = Join-Path $RepoRoot "app\rust_builder\rust"
$Target = Join-Path $RepoRoot "core\crates\flutter"

if (-not (Test-Path (Join-Path $Target "Cargo.toml"))) {
    throw "Cargo.toml not found: $Target\Cargo.toml"
}

if (Test-Path $Junction) {
    Remove-Item $Junction -Force -Recurse
}

$TargetResolved = Resolve-Path $Target
New-Item -ItemType Junction -Path $Junction -Target $TargetResolved | Out-Null
Write-Host "Linked $Junction -> core/crates/flutter"