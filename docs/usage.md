# ccc Usage Guide

## Basic Usage

```bash
# Auto-detect and compile/run
ccc hello.c          # C → gcc
ccc hello.cpp        # C++ → g++
ccc hello.py         # Python → python3
ccc hello.js         # Node.js → node
ccc hello.go         # Go → go build
ccc hello.rs         # Rust → rustc

# Detect language only
ccc --detect hello.c

# Pass extra arguments
ccc hello.c -O2 -Wall
ccc hello.cpp -std=c++20

# Force language (-x)
ccc -x c hello.txt
ccc -x c++ hello.txt

# Run mode — compile then execute
ccc run hello.py     # Executed directly by interpreter
ccc run hello.c      # Compiled then run (binary is cached)
ccc run hello.go     # go run
```

## Supported Languages

| Language | Extension | Compiler / Interpreter |
|----------|-----------|------------------------|
| C | .c | gcc, clang, cc, zig cc |
| C++ | .cpp .cc .cxx .hpp | g++, clang++, c++ |
| Rust | .rs | rustc |
| Go | .go | go build |
| Nim | .nim | nim |
| C3 | .c3 | c3c |
| Zig | .zig | zig |
| Python | .py | python3 |
| Java | .java | javac |
| D | .d | dmd, ldc2, gdc |
| Mojo | .mojo | mojo |
| JavaScript | .js | node, deno, bun |
| TypeScript | .ts | tsc / deno / bun |

## Caching

ccc caches compiler lookup results to `~/.config/ccc/cache`,
avoiding repeated `which` lookups on each invocation.

In run mode, compiled binaries are cached at `~/.config/ccc/runcache/<hash>/bin`,
using source file mtime to determine whether recompilation is needed.
