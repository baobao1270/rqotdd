#!/bin/bash
ARCH_TARGET="$1"

if [ "$(uname)" != "Darwin" ]; then
    echo "Not run Darwin (macOS) native build for non-Darwin system (required: Darwin, actual: $(uname))" >&2
    exit 0
fi

if [ -z "$ARCH_TARGET" ]; then
    echo "No target architecture specified"
    echo "Usage: $0 <arch>"
    exit 1
fi

CURRENT_ARCH=$(./scripts/native-arch.sh)
if [ "$ARCH_TARGET" != "$CURRENT_ARCH" ]; then
    echo "Current architecture ($CURRENT_ARCH) does not match target architecture ($ARCH_TARGET). Skip build." >&2
    exit 0
fi

export PROJECT_ROOT="$(pwd)"
export PROJECT_NAME="rqotdd"
export PROJECT_DIST="$PROJECT_ROOT/dist/darwin-$ARCH_TARGET"

export RUST_TARGET="$ARCH_TARGET-apple-darwin"
export RUST_OUTPUT_BINARY="$PROJECT_ROOT/target/$RUST_TARGET/release/$PROJECT_NAME"

if [ ! -f "$PROJECT_ROOT/Cargo.toml" ] || [ ! -f "$PROJECT_ROOT/scripts/musl-cross-build.sh" ]; then
    echo "Please run this script at project root (the directory containing Cargo.toml)" >&2
    exit 1
fi

echo "======= macos-native-build.sh ======="
env | grep --color PROJECT
env | grep --color TARGET
env | grep --color CARGO
env | grep --color RUST
env | grep --color CC
echo "====================================="

rustup target add               "$RUST_TARGET"
cargo  build --release --target "$RUST_TARGET"
mkdir  -p "$PROJECT_DIST"
cp     -v "$RUST_OUTPUT_BINARY" "$PROJECT_DIST/$PROJECT_NAME"
