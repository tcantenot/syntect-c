# Build pre-compiled syntect-c library for Windows x86_64.
# Run in a Visual Studio Developer PowerShell.
#
# Requirements:
#   - Rust toolchain (https://rustup.rs)
#   - Visual Studio 2019+ with C++ workload
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$triple  = "x86_64-pc-windows-msvc"
$outDir  = "lib\windows-x86_64"
$libSrc  = "rust\target\$triple\release\syntect_c.lib"
$libDst  = "$outDir\syntect_c.lib"

Write-Host "Adding Rust target $triple ..." -ForegroundColor Yellow
rustup target add $triple

Write-Host "Building ..." -ForegroundColor Yellow
cargo build --release --target $triple --manifest-path rust\Cargo.toml

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Copy-Item $libSrc $libDst -Force

Write-Host "Done: $libDst" -ForegroundColor Green
Write-Host "Commit $outDir to your repository." -ForegroundColor Green
