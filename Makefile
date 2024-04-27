#!/bin/make
.PHONY: clean db arch cross release all
default: arch

clean:
	cargo clean
	rm -rvf toolchains
	rm -rvf dist

arch: clean
	cargo build

cross: clean \
	dist/linux-musl-x86_64/rqotdd \
	dist/linux-musl-aarch64/rqotdd \
	dist/linux-musl-i686/rqotdd \
	dist/darwin-x86_64/rqotdd \
	dist/darwin-aarch64/rqotdd

release: cross
	./scripts/release.sh

all: release

dist/linux-musl-x86_64/rqotdd:
	./scripts/musl-cross-build.sh x86_64

dist/linux-musl-aarch64/rqotdd:
	./scripts/musl-cross-build.sh aarch64

dist/linux-musl-i686/rqotdd:
	./scripts/musl-cross-build.sh i686

dist/darwin-x86_64/rqotdd:
	./scripts/macos-native-build.sh x86_64

dist/darwin-aarch64/rqotdd:
	./scripts/macos-native-build.sh aarch64
