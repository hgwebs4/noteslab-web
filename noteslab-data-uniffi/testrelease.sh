#!/usr/bin/env bash

set -e

echo "=== TEST RELEASE (ARM64 ONLY, CACHED) ==="

GIT_COMMIT_HASH=$(git rev-parse --verify HEAD | tr -d '\n')

# -------------------------
# Rust optimization flags
# -------------------------
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

export RUSTFLAGS="--cfg uuid_unstable"
export RUSTFLAGS="$RUSTFLAGS --remap-path-prefix=$HOME/.cargo/=/.cargo/"
export RUSTFLAGS="$RUSTFLAGS --remap-path-prefix=$PWD/=/noteslab-data-uniffi/$GIT_COMMIT_HASH/"

# Faster rebuilds
export CARGO_INCREMENTAL=1

# Optional: faster linking (safe for CI)
export RUSTFLAGS="$RUSTFLAGS -C link-arg=-Wl,--gc-sections"

# Debian workaround (same as original)
OS_RELEASE_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
if [ "$OS_RELEASE_ID" = "debian" ]; then
    export RUSTFLAGS="$RUSTFLAGS -C link-args=-Wl,--hash-style=gnu"
fi

echo "RUSTFLAGS: $RUSTFLAGS"

# -------------------------
# Android NDK setup
# -------------------------
ANDROID_NDK_TOOLCHAIN_BIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin
export AR=$ANDROID_NDK_TOOLCHAIN_BIN/llvm-ar

# -------------------------
# FORCE ARM64 ONLY
# -------------------------
ANDROID_ABI="arm64-v8a"
RUST_TARGET="aarch64-linux-android"

export CC=$ANDROID_NDK_TOOLCHAIN_BIN/aarch64-linux-android28-clang
export CXX=$ANDROID_NDK_TOOLCHAIN_BIN/aarch64-linux-android28-clang++
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=$ANDROID_NDK_TOOLCHAIN_BIN/aarch64-linux-android28-clang

echo "Target: $RUST_TARGET (ARM64 ONLY)"

# -------------------------
# SMART FETCH (skip if cached)
# -------------------------
if [ ! -d "$HOME/.cargo/registry" ]; then
    echo "Fetching dependencies..."
    cargo fetch
else
    echo "Cargo cache found, skipping fetch"
fi

# -------------------------
# BUILD (incremental + cached)
# -------------------------
cargo build \
    --target $RUST_TARGET \
    --release \
    --locked \
    --frozen \
    --verbose

# -------------------------
# COPY OUTPUT
# -------------------------
OUTPUT_DIR="../uniffi/src/main/jniLibs/$ANDROID_ABI"
mkdir -p "$OUTPUT_DIR"

cp target/$RUST_TARGET/release/libuniffi_noteslab.so "$OUTPUT_DIR"

echo "✅ Build complete (ARM64 only)"