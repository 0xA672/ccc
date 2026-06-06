# ccc CLI Reference

**ccc** (compiler command center) is a unified front-end that auto-selects the right compiler or interpreter for a source file. This document covers the stable CLI interface.

---

## Synopsis

```
ccc <source-file> [compiler-args...]
ccc run <source-file> [args...]
ccc -x <lang> <source-file> [compiler-args...]
ccc run -x <lang> <source-file> [args...]
ccc --detect <source-file>
ccc --help
ccc --version
```

---

## Modes

### Compile mode (default)

```
ccc <source-file> [compiler-args...]
```

Detects the language from the file extension (or shebang), finds a compiler, and invokes it. Any extra arguments after the source file are forwarded verbatim to the compiler.

```sh
ccc hello.c
ccc hello.c -O2 -Wall
ccc hello.rs
```

### Run mode

```
ccc run <source-file> [args...]
```

Compiles (if necessary) and immediately executes the result. For interpreted languages (Python, JavaScript) this invokes the interpreter directly. Arguments after the source file are passed to the program, not the compiler.

Compiled binaries are cached under `~/.config/ccc/runcache/` keyed by source path and mtime; a cache hit skips recompilation.

```sh
ccc run hello.py arg1 arg2
ccc run hello.c
ccc run hello.go
```

### Language override (`-x`)

```
ccc -x <lang> <source-file> [...]
ccc run -x <lang> <source-file> [...]
```

Forces a specific language regardless of file extension. Useful for files with non-standard extensions or no extension.

```sh
ccc -x c++ mystery.txt
ccc run -x python script
```

Accepted values for `<lang>`:

| Language | Accepted values |
|----------|----------------|
| C | `c` |
| C++ | `c++`, `cpp`, `cxx`, `cc` |
| Rust | `rust`, `rs` |
| Go | `go` |
| Nim | `nim` |
| C3 | `c3` |
| Zig | `zig` |
| Python | `python`, `py` |
| JavaScript | `js`, `javascript`, `node` |
| TypeScript | `ts`, `typescript`, `deno` |
| Java | `java` |
| Mojo | `mojo` |
| D | `d`, `dlang` |

### Detect mode

```
ccc --detect <source-file>
```

Prints the detected language for a file without compiling or running anything. Useful for debugging why a file is (or isn't) being recognized.

Exit codes: `0` = recognized, `1` = file not found / missing argument, `2` = unrecognized.

```sh
ccc --detect main.c3
# ccc: main.c3 → c3

ccc --detect script
# ccc: script → python  (via shebang: /usr/bin/env python3)
```

### Help and version

```
ccc --help    # or -h
ccc --version # or -V
```

---

## Language detection

ccc resolves the language in this order:

1. **File extension** — matched against the table below.
2. **Shebang line** (`#!`) — read from the first line of the file if extension is unrecognized.
3. **`-x` override** — always wins when provided.

### Extension table

| Extension(s) | Language | Default compiler candidates |
|---|---|---|
| `.c` | C | `gcc`, `clang`, `cc`, `zig cc` |
| `.cpp`, `.cc`, `.cxx`, `.hpp` | C++ | `g++`, `clang++`, `c++` |
| `.rs` | Rust | `rustc` |
| `.go` | Go | `go` |
| `.nim` | Nim | `nim` |
| `.c3` | C3 | `c3c` |
| `.zig` | Zig | `zig` |
| `.py` | Python | `python3` |
| `.js` | JavaScript | `node` |
| `.ts` | TypeScript | `tsc` |
| `.java` | Java | `javac` |
| `.mojo` | Mojo | `mojo` |
| `.d` | D | `dmd`, `ldc2`, `gdc` |

### Run-mode runtime table

| Language | Runtime used in `run` mode |
|---|---|
| C | compile → run binary |
| C++ | `vix` (if available), else compile → run binary |
| Rust | compile → run binary |
| Go | `go run` |
| Nim | `nim run` |
| C3 | `c3c run` |
| Zig | `zig run` |
| Python | `python3` |
| JavaScript | `node` / `deno` / `bun` |
| TypeScript | `deno` / `bun` |
| Java | `javac` → `java` |
| Mojo | `mojo run` |
| D | compile → run binary |

---

## Environment variables

Set these to override the compiler or interpreter path for a language. The value must be a valid filesystem path or a command name on `PATH`.

| Variable | Language |
|----------|----------|
| `CC` | C |
| `CXX` | C++ |
| `RUSTC` | Rust |
| `GO` | Go |
| `NIMC` | Nim |
| `C3C` | C3 |
| `ZIG` | Zig |
| `PYTHON` | Python |
| `NODE` | JavaScript |
| `TSC` | TypeScript |
| `JAVAC` | Java |
| `MOJO` | Mojo |
| `DC` | D |

Environment variable values take priority over both the PATH search and the compiler cache.

---

## Compiler cache

Resolved compiler paths are persisted to `~/.config/ccc/cache` in `key=value` format (one entry per language). This avoids repeated `which` lookups on subsequent invocations. The cache is invalidated if an environment variable override is set.

Compiled run-mode binaries are cached under `~/.config/ccc/runcache/<hash>/bin` where `<hash>` is a FNV-1a hash of the source file path. A cached binary is used when its recorded mtime matches the current source file mtime.

---

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Usage error (missing argument, unrecognized language, file not found) |
| `2` | Compiler or runtime not found |
| `3` | Process spawn failure |
| other | Exit code forwarded from the compiler or the compiled program |

---

## Diagnostic output

All `ccc` diagnostic messages are written to **stderr**. The invoked compiler command is always printed before execution, e.g.:

```
ccc: gcc -o /home/user/.config/ccc/runcache/1a2b3c4d/bin hello.c
ccc: [cached]
```

Program stdout/stdin/stderr are inherited unchanged.
