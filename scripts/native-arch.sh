#!/bin/bash

case "$(uname -m)" in
    'x86_64' | 'amd64')
        echo 'x86_64'
        ;;
    'arm64' | 'aarch64' | 'armv8' | 'armv8a')
        echo 'aarch64'
        ;;
    'x86' | 'i386' | 'i586' | 'i686')
        echo 'i686'
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac
