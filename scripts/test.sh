#!/usr/bin/env bash
# ccc test runner
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CCC="$SCRIPT_DIR/build/ccc"
PASS=0
FAIL=0

green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }

check() {
    local desc="$1" cmd="$2" expect="$3"
    echo -n "  $desc ... "
    if out=$($cmd 2>&1); then
        if echo "$out" | grep -qF "$expect"; then
            green "PASS"
            PASS=$((PASS + 1))
        else
            red "FAIL (output didn't match '$expect')"
            echo "    got: $out"
            FAIL=$((FAIL + 1))
        fi
    else
        red "FAIL (exit code $?, output: $out)"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== ccc test suite ==="
cd "$SCRIPT_DIR"

# Build first
c3c build 2>/dev/null || { red "Build failed"; exit 1; }

# Detection tests
check "C detection"    "$CCC --detect test/inputs/hello.c"    "gcc"
check "C++ detection"  "$CCC --detect test/inputs/hello.cpp"  "g++"
check "Python detect"  "$CCC --detect test/inputs/hello.py"   "python"
check "Node.js detect" "$CCC --detect test/inputs/hello.js"   "node"
check "Go detection"   "$CCC --detect test/inputs/hello.go"   "go build"
check "Rust detection" "$CCC --detect test/inputs/hello.rs"   "rustc"

# Shebang fallback
check "Shebang sh"     "$CCC --detect test/inputs/hello.sh"   "sh"
check "Shebang py"     "$CCC --detect test/inputs/shebang.py" "python"

# Force language (-x)
check "-x c"           "$CCC -x c test/inputs/hello.txt"      "gcc"
check "-x c++"         "$CCC -x c++ test/inputs/hello.txt"    "c++"

# Custom compiler (-c)
check "-c clang"       "$CCC -c clang --detect test/inputs/hello.c" "clang"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
