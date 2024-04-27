#!/bin/bash

export PROJECT_ROOT="$(pwd)"
if [ ! -f "$PROJECT_ROOT/Cargo.toml" ] || [ ! -f "$PROJECT_ROOT/scripts/musl-cross-build.sh" ]; then
    echo "Please run this script at project root (the directory containing Cargo.toml)" >&2
    exit 1
fi

for folder in dist/*; do
    if [ ! -d $folder ]; then
        echo "Skipping $folder as it is not a directory"
        continue
    fi
    arch=$(basename $folder)
    tar -cvf - -C $folder . | zstd -19 > dist/rqotdd-$arch.tar.zst
done
