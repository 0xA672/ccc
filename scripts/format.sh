#!/usr/bin/env bash
# Format C3 source code
set -eu
cd "$(dirname "$0")/.."

if command -v c3fmt &>/dev/null; then
    c3fmt -w src/main.c3
    echo "Formatted src/main.c3"
else
    echo "c3fmt not found; install it with: c3c tools --install c3fmt"
fi
