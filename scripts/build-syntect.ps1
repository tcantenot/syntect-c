# Build pre-compiled syntect-c library for Windows x86_64.
# Run in a Visual Studio Developer PowerShell (or GitHub Actions windows runner).
#
# Outputs:
#   lib\windows-x86_64\syntect_c.lib   — static library (for distribution)
#   lib\windows-x86_64\syntect_c.pdb   — debug symbols (PDB format)
#
# split-debuginfo=packed in Cargo.toml switches MSVC from /Z7 (debug info
# embedded in the .lib's .obj members) to /Zi, which writes all debug info to
# a separate .pdb and keeps the .lib small. With codegen-units=1 exactly one
# .pdb is produced.
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
$pdbDst  = "$outDir\syntect_c.pdb"

Write-Host "Adding Rust target $triple ..." -ForegroundColor Yellow
rustup target add $triple

Write-Host "Building ..." -ForegroundColor Yellow
cargo build --release --target $triple --manifest-path rust\Cargo.toml

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Copy-Item $libSrc $libDst -Force
Write-Host "Library:       $libDst" -ForegroundColor Green

# With codegen-units=1 rustc emits exactly one .pdb. It lands in release/
# directly or in deps/ with a hash suffix depending on the Rust version.
$pdbSrc = "rust\target\$triple\release\syntect_c.pdb"
if (-not (Test-Path $pdbSrc)) {
    $found = Get-ChildItem "rust\target\$triple\release\deps\syntect_c-*.pdb" `
             -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime | Select-Object -Last 1
    if ($found) { $pdbSrc = $found.FullName }
}

if (Test-Path $pdbSrc) {
    Copy-Item $pdbSrc $pdbDst -Force
    Write-Host "Debug symbols: $pdbDst" -ForegroundColor Green
} else {
    Write-Warning "PDB not found after build; check RUSTFLAGS or Rust version"
}

Write-Host "Commit $outDir to your repository." -ForegroundColor Green
