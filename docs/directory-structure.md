# ccc — 编译器命令中心

## 目录结构

```
ccc/
├── docs/          # 文档
├── lib/           # C3 库模块
├── resources/     # 资源文件
├── scripts/       # 构建/安装/测试脚本
├── src/           # 源码 (main.c3)
├── test/          # C3 单元测试 + 测试输入文件
├── project.json   # C3 项目配置
└── README.md      # 项目说明
```

## docs/

包含使用文档、man page、架构说明等。

## lib/

C3 库依赖搜索路径 (`dependency-search-paths` 配置指向此处)。
可放入复用的 C3 模块，供 `src/` 引用。

## resources/

项目相关的资源文件：logo、配置样例、样例源码等。

## scripts/

辅助脚本：
- `scripts/install.sh` — 安装 ccc 到系统路径
- `scripts/test.sh` — 运行完整测试套件
- `scripts/format.sh` — 格式化代码

## test/

C3 测试源码 (由 `project.json` 的 `test-sources` 配置)。
子目录 `test/inputs/` 包含各种语言的测试输入文件，用于集成测试。
