#!/bin/bash
ARCH_TARGET="$1"

if [ "$(uname)" != "Linux" ]; then
    echo "Not run musl build for non-Linux system (required: Linux, actual: $(uname))" >&2
    exit 0
fi

if [ -z "$ARCH_TARGET" ]; then
    echo "No target architecture specified"
    echo "Usage: $0 <arch>"
    exit 1
fi

export PROJECT_ROOT="$(pwd)"
export PROJECT_NAME="rqotdd"
export PROJECT_DIST="$PROJECT_ROOT/dist/linux-musl-$ARCH_TARGET"
export PROJECT_TOOLCHAINS="$PROJECT_ROOT/toolchains"

export RUST_TARGET="$ARCH_TARGET-unknown-linux-musl"
export RUST_TARGET_TRIPLE=$(echo "$RUST_TARGET" | tr "[:lower:]" "[:upper:]" | tr "-" "_")
export RUST_OUTPUT_BINARY="$PROJECT_ROOT/target/$RUST_TARGET/release/$PROJECT_NAME"

export MUSL_TARGET="$ARCH_TARGET-linux-musl"
export MUSL_TARGET_CROSS="$MUSL_TARGET-cross"
export MUSL_TOOLCHAIN_URL="https://musl.cc/$MUSL_TARGET_CROSS.tgz"
export MUSL_TOOLCHAIN_DIR="$PROJECT_TOOLCHAINS/$MUSL_TARGET_CROSS"
export MUSL_TOOLCHAIN_BIN="$MUSL_TOOLCHAIN_DIR/bin"
export MUSL_TOOLCHAIN_STRIP="$MUSL_TOOLCHAIN_BIN/$MUSL_TARGET-strip"

export CC="$MUSL_TOOLCHAIN_BIN/$MUSL_TARGET-cc"
export CARGO_TARGET_${RUST_TARGET_TRIPLE}_LINKER="$CC"

if [ ! -f "$PROJECT_ROOT/Cargo.toml" ] || [ ! -f "$PROJECT_ROOT/scripts/musl-cross-build.sh" ]; then
    echo "Please run this script at project root (the directory containing Cargo.toml)" >&2
    exit 1
fi

echo "======== musl-cross-build.sh ========"
env | grep --color PROJECT
env | grep --color TARGET
env | grep --color CARGO
env | grep --color RUST
env | grep --color MUSL
env | grep --color CC
echo "====================================="

if [ -d "$MUSL_TOOLCHAIN_DIR" ]; then
    echo "Toolchain '$MUSL_TARGET_CROSS' exists. Skipping download."
else
    echo "Toolchain '$MUSL_TARGET_CROSS' does not exist."
    echo "Download: $MUSL_TOOLCHAIN_URL"
    TMPFILE=$(mktemp)
    curl -fsSL "$MUSL_TOOLCHAIN_URL" > "$TMPFILE"
    if [ $? -ne 0 ]; then
        echo "Failed: $MUSL_TOOLCHAIN_URL"
        exit 1
    fi
    mkdir -p "$PROJECT_TOOLCHAINS"
    tar -xvf "$TMPFILE" -C "$PROJECT_TOOLCHAINS"
    if [ $? -ne 0 ]; then
        echo "Failed to extract: $MUSL_TARGET_CROSS"
        exit 1
    fi
    rm "$TMPFILE"
fi

rustup target add               "$RUST_TARGET"
cargo  build --release --target "$RUST_TARGET"
mkdir  -p "$PROJECT_DIST"
cp     -v "$RUST_OUTPUT_BINARY" "$PROJECT_DIST/$PROJECT_NAME"
$MUSL_TOOLCHAIN_STRIP           "$PROJECT_DIST/$PROJECT_NAME"
