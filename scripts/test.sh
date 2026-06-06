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

check_fail() {
    local desc="$1" cmd="$2" expect="$3"
    echo -n "  $desc ... "
    if out=$($cmd 2>&1); then
        red "FAIL (expected failure, but got exit 0)"
        echo "    got: $out"
        FAIL=$((FAIL + 1))
    else
        if echo "$out" | grep -qF "$expect"; then
            green "PASS"
            PASS=$((PASS + 1))
        else
            red "FAIL (output didn't match '$expect')"
            echo "    got: $out"
            FAIL=$((FAIL + 1))
        fi
    fi
}

echo "=== ccc test suite ==="
cd "$SCRIPT_DIR"

# Build first
c3c build 2>/dev/null || { red "Build failed"; exit 1; }

# Detection tests (--detect outputs language name, not compiler)
check "C detection"    "$CCC --detect test/inputs/hello.c"    "→ c"
check "C++ detection"  "$CCC --detect test/inputs/hello.cpp"  "→ cpp"
check "Python detect"  "$CCC --detect test/inputs/hello.py"   "→ python"
check "Node.js detect" "$CCC --detect test/inputs/hello.js"   "→ javascript"
check "Go detection"   "$CCC --detect test/inputs/hello.go"   "→ go"
check "Rust detection" "$CCC --detect test/inputs/hello.rs"   "→ rust"

# Shebang fallback
check "Shebang py"     "$CCC --detect test/inputs/shebang.py" "→ python"

# Unknown file
check_fail "Unknown file" "$CCC --detect test/inputs/hello.txt" "→ unknown"

# Force language (-x) — verify it compiles the command correctly
check "-x c"           "$CCC -x c test/inputs/hello.c" "gcc"
check "-x c++"         "$CCC -x c++ test/inputs/hello.cpp" "g++"

# Help flag
check "--help"         "$CCC --help" "Usage:"

# Version flag
check "--version"      "$CCC --version" "ccc v0.1"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
