# Build pre-compiled syntect-c library for Windows x86_64.
# Run in a Visual Studio Developer PowerShell (or GitHub Actions windows runner).
#
# Output:
#   lib\windows-x86_64\syntect_c.lib      — static library with embedded debug info
#   lib\windows-x86_64\syntect_c.dll      — shared library
#   lib\windows-x86_64\syntect_c.dll.lib  — import library for the DLL
#   lib\windows-x86_64\syntect_c.pdb      — debug symbols (shared + static)
#
# Requirements:
#   - Rust toolchain (https://rustup.rs)
#   - Visual Studio 2019+ with C++ workload
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$triple   = "x86_64-pc-windows-msvc"
$outDir   = "lib\windows-x86_64"
$buildDir = "rust\target\$triple\release"

Write-Host "Adding Rust target $triple ..." -ForegroundColor Yellow
rustup target add $triple

Write-Host "Building ..." -ForegroundColor Yellow
cargo build --release --target $triple --manifest-path rust\Cargo.toml

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Static library
Copy-Item "$buildDir\syntect_c.lib"     "$outDir\syntect_c.lib"     -Force
Write-Host "Static:  $outDir\syntect_c.lib" -ForegroundColor Green

# Shared library + import library
# Note: when crate-type includes both staticlib and cdylib, the MSVC linker names
# the cdylib import library syntect_c.dll.lib to avoid collision with the static .lib.
Copy-Item "$buildDir\syntect_c.dll"     "$outDir\syntect_c.dll"     -Force
Copy-Item "$buildDir\syntect_c.dll.lib" "$outDir\syntect_c.dll.lib" -Force
Write-Host "Shared:  $outDir\syntect_c.dll" -ForegroundColor Green
Write-Host "Import:  $outDir\syntect_c.dll.lib" -ForegroundColor Green

# PDB — present when debug = true (covers both .lib and .dll)
if (Test-Path "$buildDir\syntect_c.pdb") {
    Copy-Item "$buildDir\syntect_c.pdb" "$outDir\syntect_c.pdb" -Force
    Write-Host "PDB:     $outDir\syntect_c.pdb" -ForegroundColor Green
}

Write-Host "Commit $outDir to your repository." -ForegroundColor Green
