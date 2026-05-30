# ccc — Compiler Command Center

**ccc** is a smart compiler wrapper that automatically selects the right compiler or interpreter for your source files based on their extension or shebang line.

Stop remembering `gcc`, `clang++`, `rustc`, `go build`, `python3`, `node`, and dozens of other commands — just use `c`.

## Installation

```bash
git clone https://github.com/0xA672/ccc.git
cd ccc
c3c build
ln -sf $(pwd)/build/ccc ~/.local/bin/c
```

**Requires:** [C3 compiler](https://c3-lang.org/) ≥ 0.7.x

## Usage

```bash
# Auto-detect and compile/run
c main.c          # → gcc / clang
c main.cpp        # → g++ / clang++
c main.rs         # → rustc
c main.go         # → go build
c main.py         # → python3
c main.js         # → node
c main.java       # → javac + java
c main.c3         # → c3c
c main.zig        # → zig
c main.nim        # → nim c
c main.ts         # → deno

# Detect language only (don't execute)
c --detect main.go

# Pass extra flags
c main.c -O2 -Wall
```

## Supported Languages

| Language | Extension(s)       | Compiler / Interpreter                    |
|----------|-------------------|-------------------------------------------|
| C        | `.c`              | `gcc`, `clang`, `cc`, `zig cc`           |
| C++      | `.cpp` `.cc` `.cxx` `.hpp` | `g++`, `clang++`, `c++`         |
| Rust     | `.rs`             | `rustc`                                   |
| Go       | `.go`             | `go build` (handles directory structure)   |
| Nim      | `.nim`            | `nim c`                                   |
| C3       | `.c3`             | `c3c`                                     |
| Zig      | `.zig`            | `zig`                                     |
| Python   | `.py`             | `python3`                                 |
| Java     | `.java`           | `javac + java`                            |
| D        | `.d`              | `dmd`, `ldc2`, `gdc`                      |
| Mojo     | `.mojo`           | `mojo`                                    |
| Node.js  | `.js`             | `node`, `deno`, `bun`                     |
| Deno     | `.ts`             | `deno`, `bun`                             |

## How It Works

1. The target file's extension is checked against a known table.
2. If the extension is unrecognized, the file's first line is parsed for a `#!` (shebang).
3. Once identified, the corresponding compiler/interpreter is located via `$PATH`.
4. The tool constructs and executes the appropriate build/run command.

## How to Contribute

Add support for more languages by editing `src/main.c3`:

- Add a new `Lg` enum member.
- Add its candidate paths to the lookup table.
- Add the extension mapping in `e()` and the compiler command in `b0()`/`b1()`.

Pull requests welcome!

## License

MIT — see [LICENSE](./LICENSE).
