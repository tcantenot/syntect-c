# Build pre-compiled syntect-c library for Windows x86_64.
# Run in a Visual Studio Developer PowerShell.
#
# Outputs:
#   lib\windows-x86_64\syntect_c.lib   — static library (for distribution)
#   lib\windows-x86_64\syntect_c.pdb   — debug symbols (PDB, for debugging)
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
# With debug = true in Cargo.toml the MSVC linker emits a PDB alongside the .lib.
# The .lib itself holds only a small CodeView reference to the PDB, not the symbols.
$pdbSrc  = "rust\target\$triple\release\syntect_c.pdb"
$pdbDst  = "$outDir\syntect_c.pdb"

Write-Host "Adding Rust target $triple ..." -ForegroundColor Yellow
rustup target add $triple

Write-Host "Building ..." -ForegroundColor Yellow
cargo build --release --target $triple --manifest-path rust\Cargo.toml

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Copy-Item $libSrc $libDst -Force
Write-Host "Done: $libDst" -ForegroundColor Green

if (Test-Path $pdbSrc) {
    Copy-Item $pdbSrc $pdbDst -Force
    Write-Host "Debug symbols: $pdbDst" -ForegroundColor Green
} else {
    Write-Host "Warning: $pdbSrc not found; debug symbols not copied." -ForegroundColor Yellow
}

Write-Host "Commit $outDir to your repository." -ForegroundColor Green
