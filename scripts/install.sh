#!/usr/bin/env sh
# ccc install script
set -e

BINDIR="${1:-$HOME/.local/bin}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Building ccc..."
cd "$SCRIPT_DIR"
c3c build

echo "Installing to $BINDIR..."
mkdir -p "$BINDIR"
ln -sf "$SCRIPT_DIR/build/ccc" "$BINDIR/c"
ln -sf "$SCRIPT_DIR/build/ccc" "$BINDIR/ccc"

echo "Done! Make sure $BINDIR is in your PATH."
echo "Now you can run:  c hello.c"
