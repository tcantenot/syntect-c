#!/usr/bin/env bash
# Build pre-compiled syntect-c libraries for Linux and macOS.
# Run when rust/src/lib.rs or rust/Cargo.toml changes, then commit lib/.
#
# Requirements:
#   - Rust toolchain (https://rustup.rs)
#   - Linux: sudo apt install gcc-aarch64-linux-gnu
#   - macOS: Xcode command-line tools
set -euo pipefail

MANIFEST="rust/Cargo.toml"
LIB_OUT="lib"
HOST="$(uname -s)"

green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }

build() {
    local triple="$1" out_dir="$2" lib_name="$3"
    yellow "-> Building $triple"
    rustup target add "$triple" 2>/dev/null || true
    cargo build --release --target "$triple" --manifest-path "$MANIFEST"
    mkdir -p "$LIB_OUT/$out_dir"
    cp "rust/target/$triple/release/$lib_name" "$LIB_OUT/$out_dir/$lib_name"
    green "   $LIB_OUT/$out_dir/$lib_name"
}

if [[ "$HOST" == "Linux" ]]; then
    build x86_64-unknown-linux-gnu  linux-x86_64  libsyntect_c.a
    if command -v aarch64-linux-gnu-gcc &>/dev/null; then
        build aarch64-unknown-linux-gnu linux-aarch64 libsyntect_c.a
    else
        yellow "Skipping linux-aarch64 (install gcc-aarch64-linux-gnu)"
    fi
fi

if [[ "$HOST" == "Darwin" ]]; then
    build x86_64-apple-darwin  macos-x86_64  libsyntect_c.a
    build aarch64-apple-darwin macos-aarch64 libsyntect_c.a
    yellow "-> lipo: creating universal binary"
    mkdir -p "$LIB_OUT/macos-universal"
    lipo -create \
        "rust/target/x86_64-apple-darwin/release/libsyntect_c.a" \
        "rust/target/aarch64-apple-darwin/release/libsyntect_c.a" \
        -output "$LIB_OUT/macos-universal/libsyntect_c.a"
    green "   $LIB_OUT/macos-universal/libsyntect_c.a"
fi

green "Done. Commit the contents of $LIB_OUT/ to your repository."
