#!/usr/bin/env bash
# Build pre-compiled syntect-c libraries for Linux and macOS.
# Run when rust/src/lib.rs or rust/Cargo.toml changes, then commit lib/.
#
# Outputs per target:
#   lib/<platform>/libsyntect_c.a         — stripped (for distribution)
#   lib/<platform>/libsyntect_c.a.debug   — debug symbols (DWARF, for debugging)
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

# Save an unstripped copy as <lib>.debug, then strip debug sections from the main copy.
# $4 is the strip binary name (defaults to "strip"); gracefully skips if not found.
strip_and_separate() {
    local src="$1" dest_dir="$2" lib_name="$3" strip_cmd="${4:-strip}"
    local debug_out="$dest_dir/$lib_name.debug"
    local final_out="$dest_dir/$lib_name"

    cp "$src" "$debug_out"
    cp "$src" "$final_out"

    if command -v "$strip_cmd" &>/dev/null; then
        if [[ "$HOST" == "Darwin" ]]; then
            # -S: remove debug symbols only (keeps symbol table needed for linking)
            "$strip_cmd" -S "$final_out"
        else
            # --strip-debug: remove DWARF sections only (keeps symbol table needed for linking)
            "$strip_cmd" --strip-debug "$final_out"
        fi
        green "   $final_out (stripped)"
        green "   $debug_out (debug symbols)"
    else
        # Cross-strip tool absent — ship unstripped, drop the incomplete .debug copy
        yellow "   WARNING: $strip_cmd not found; $final_out is unstripped"
        rm "$debug_out"
    fi
}

build() {
    local triple="$1" out_dir="$2" lib_name="$3" strip_cmd="${4:-strip}"
    yellow "-> Building $triple"
    rustup target add "$triple" 2>/dev/null || true
    cargo build --release --target "$triple" --manifest-path "$MANIFEST"
    mkdir -p "$LIB_OUT/$out_dir"
    strip_and_separate "rust/target/$triple/release/$lib_name" "$LIB_OUT/$out_dir" "$lib_name" "$strip_cmd"
}

if [[ "$HOST" == "Linux" ]]; then
    build x86_64-unknown-linux-gnu  linux-x86_64  libsyntect_c.a strip
    if command -v aarch64-linux-gnu-gcc &>/dev/null; then
        # aarch64-linux-gnu-strip ships with the gcc-aarch64-linux-gnu cross toolchain
        build aarch64-unknown-linux-gnu linux-aarch64 libsyntect_c.a aarch64-linux-gnu-strip
    else
        yellow "Skipping linux-aarch64 (install gcc-aarch64-linux-gnu)"
    fi
fi

if [[ "$HOST" == "Darwin" ]]; then
    build x86_64-apple-darwin  macos-x86_64  libsyntect_c.a strip
    build aarch64-apple-darwin macos-aarch64 libsyntect_c.a strip

    yellow "-> lipo: creating universal binary"
    mkdir -p "$LIB_OUT/macos-universal"

    # Debug universal: combine the unstripped Cargo outputs (before any stripping)
    lipo -create \
        "rust/target/x86_64-apple-darwin/release/libsyntect_c.a" \
        "rust/target/aarch64-apple-darwin/release/libsyntect_c.a" \
        -output "$LIB_OUT/macos-universal/libsyntect_c.a.debug"
    green "   $LIB_OUT/macos-universal/libsyntect_c.a.debug"

    # Stripped universal: combine the already-stripped per-arch outputs
    lipo -create \
        "$LIB_OUT/macos-x86_64/libsyntect_c.a" \
        "$LIB_OUT/macos-aarch64/libsyntect_c.a" \
        -output "$LIB_OUT/macos-universal/libsyntect_c.a"
    green "   $LIB_OUT/macos-universal/libsyntect_c.a (stripped)"
fi

green "Done. Commit the contents of $LIB_OUT/ to your repository."
