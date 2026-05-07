#!/usr/bin/env bash
# Build pre-compiled syntect-c libraries for Linux and macOS.
# Run when rust/src/lib.rs or rust/Cargo.toml changes, then commit lib/.
#
# Output per target:
#   lib/<platform>/libsyntect_c.a        — static library with embedded debug info
#   lib/<platform>/libsyntect_c.so       — shared library, stripped  (Linux)
#   lib/<platform>/libsyntect_c.so.debug — split DWARF debug info    (Linux)
#   lib/<platform>/libsyntect_c.dylib    — shared library, stripped  (macOS)
#   lib/<platform>/libsyntect_c.dSYM/    — split debug bundle        (macOS)
#
# Requirements:
#   - Rust toolchain (https://rustup.rs)
#   - Linux: sudo apt install gcc-aarch64-linux-gnu binutils
#   - macOS: Xcode command-line tools
set -euo pipefail

MANIFEST="rust/Cargo.toml"
LIB_OUT="lib"
HOST="$(uname -s)"

green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }

build() {
    local triple="$1" out_dir="$2" static_name="$3" shared_name="$4"
    yellow "-> Building $triple"
    rustup target add "$triple" 2>/dev/null || true
    cargo build --release --target "$triple" --manifest-path "$MANIFEST"
    mkdir -p "$LIB_OUT/$out_dir"
    cp "rust/target/$triple/release/$static_name" "$LIB_OUT/$out_dir/$static_name"
    green "   $LIB_OUT/$out_dir/$static_name"
    cp "rust/target/$triple/release/$shared_name" "$LIB_OUT/$out_dir/$shared_name"
    green "   $LIB_OUT/$out_dir/$shared_name"
}

split_debug_linux() {
    local so="$1"
    local dbg="${so}.debug"
    yellow "-> Splitting debug info: $so"
    objcopy --only-keep-debug "$so" "$dbg"
    objcopy --strip-debug --add-gnu-debuglink="$dbg" "$so"
    green "   $dbg"
    green "   $so (stripped)"
}

split_debug_macos() {
    local dylib="$1"
    local dsym="${dylib%.dylib}.dSYM"
    yellow "-> Splitting debug info: $dylib"
    dsymutil "$dylib" -o "$dsym"
    strip -S "$dylib"
    green "   $dsym"
    green "   $dylib (stripped)"
}

if [[ "$HOST" == "Linux" ]]; then
    build x86_64-unknown-linux-gnu  linux-x86_64  libsyntect_c.a libsyntect_c.so
    split_debug_linux "$LIB_OUT/linux-x86_64/libsyntect_c.so"

    if command -v aarch64-linux-gnu-gcc &>/dev/null; then
        build aarch64-unknown-linux-gnu linux-aarch64 libsyntect_c.a libsyntect_c.so
        split_debug_linux "$LIB_OUT/linux-aarch64/libsyntect_c.so"
    else
        yellow "Skipping linux-aarch64 (install gcc-aarch64-linux-gnu)"
    fi
fi

if [[ "$HOST" == "Darwin" ]]; then
    build x86_64-apple-darwin  macos-x86_64  libsyntect_c.a libsyntect_c.dylib
    build aarch64-apple-darwin macos-aarch64 libsyntect_c.a libsyntect_c.dylib

    yellow "-> lipo: creating universal static binary"
    mkdir -p "$LIB_OUT/macos-universal"
    lipo -create \
        "$LIB_OUT/macos-x86_64/libsyntect_c.a" \
        "$LIB_OUT/macos-aarch64/libsyntect_c.a" \
        -output "$LIB_OUT/macos-universal/libsyntect_c.a"
    green "   $LIB_OUT/macos-universal/libsyntect_c.a"

    yellow "-> lipo: creating universal dynamic binary"
    lipo -create \
        "$LIB_OUT/macos-x86_64/libsyntect_c.dylib" \
        "$LIB_OUT/macos-aarch64/libsyntect_c.dylib" \
        -output "$LIB_OUT/macos-universal/libsyntect_c.dylib"
    green "   $LIB_OUT/macos-universal/libsyntect_c.dylib"

    for dir in macos-x86_64 macos-aarch64 macos-universal; do
        split_debug_macos "$LIB_OUT/$dir/libsyntect_c.dylib"
    done
fi

green "Done. Commit the contents of $LIB_OUT/ to your repository."
