# ccc — Compiler Command Center

## Directory Structure

```
ccc/
├── docs/          # Documentation
├── lib/           # C3 library modules
├── resources/     # Resource files
├── scripts/       # Build / install / test scripts
├── src/           # Source code (main.c3)
├── test/          # C3 unit tests + test input files
├── project.json   # C3 project configuration
└── README.md      # Project overview
```

## docs/

Contains usage documentation, man pages, architecture notes, etc.

## lib/

C3 library dependency search path (`dependency-search-paths` in project.json points here).
Reusable C3 modules can be placed here for `src/` to import.

## resources/

Project-related resource files: logo, configuration examples, sample source code, etc.

## scripts/

Helper scripts:
- `scripts/install.sh` — Install ccc to system path
- `scripts/test.sh` — Run the full test suite
- `scripts/format.sh` — Format code

## test/

C3 test source files (configured by `test-sources` in project.json).
The `test/inputs/` subdirectory contains test input files in various languages for integration testing.
