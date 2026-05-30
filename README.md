# ccc — Compiler Command Center

**ccc** is a smart compiler wrapper that automatically selects the right compiler or interpreter for your source files based on their extension or shebang line.

Stop remembering `gcc`, `clang++`, `rustc`, `go build`, `python3`, `node`, and dozens of other commands — just use `ccc` (or `c` if you prefer a shorter alias).

## Installation

```bash
git clone https://github.com/0xA672/ccc.git
cd ccc
c3c build
mkdir -p ~/.local/bin
ln -sf $(pwd)/build/ccc ~/.local/bin/ccc
ln -sf ~/.local/bin/ccc ~/.local/bin/c    # short alias — lazy friendly
```

**Requires:** [C3 compiler](https://c3-lang.org/) ≥ 0.7.x

## Usage

```bash
# Auto-detect and compile/run
ccc main.c          # → gcc / clang
ccc main.cpp        # → g++ / clang++
ccc main.rs         # → rustc
ccc main.go         # → go build
ccc main.py         # → python3
ccc main.js         # → node
ccc main.java       # → javac + java
ccc main.c3         # → c3c
ccc main.zig        # → zig
ccc main.nim        # → nim c
ccc main.ts         # → deno

# Detect language only (don't execute)
ccc --detect main.go

# Pass extra flags
ccc main.c -O2 -Wall
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
