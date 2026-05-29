# ccc 使用指南

## 基本用法

```bash
# 自动检测并编译/运行
ccc hello.c          # C → gcc
ccc hello.cpp        # C++ → g++
ccc hello.py         # Python → python3
ccc hello.js         # Node.js → node
ccc hello.go         # Go → go build
ccc hello.rs         # Rust → rustc

# 仅检测语言
ccc --detect hello.c

# 传递额外参数
ccc hello.c -O2 -Wall
ccc hello.cpp -std=c++20

# 强制指定语言 (-x)
ccc -x c hello.txt
ccc -x c++ hello.txt

# 运行模式
ccc run hello.py     # 编译/解释后立即运行
ccc run hello.c      # 编译并执行

# 编译器选择
ccc -c gcc hello.c   # 强制使用 gcc
ccc -c clang hello.c # 强制使用 clang
```

## 支持的语言

| 语言 | 扩展名 | 编译器/解释器 |
|------|--------|---------------|
| C | .c | gcc, clang, cc |
| C++ | .cpp .cc .cxx .c++ | g++, clang++, c++ |
| Rust | .rs | rustc |
| Go | .go | go build |
| Nim | .nim | nim c |
| C3 | .c3 | c3c |
| Zig | .zig | zig |
| Python | .py | python3 |
| Java | .java | javac + java |
| D | .d | dmd, ldc2 |
| Mojo | .mojo | mojo |
| JavaScript | .js | node |
| TypeScript | .ts | deno |
| Shell | .sh | sh |

## 缓存机制

ccc 会缓存编译器查找结果到 `~/.config/ccc/cache`，
避免每次运行都执行 `which` 查找。

缓存格式：每行一个 `L=path` 条目，其中 L 是语言代码字符。
