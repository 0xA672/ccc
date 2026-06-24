module ccc;
import std::io;
import std::io::file;
import std::os::process;
import std::os::env;
import std::core::mem::alloc;
import std::hash::fnv32a;

// ── Language definitions (SINGLE SOURCE OF TRUTH) ─────────────────────────

enum Language
{
    C,   // 0
    X,   // 1  C++
    R,   // 2  Rust
    G,   // 3  Go
    N,   // 4  Nim
    M,   // 5  C3
    Z,   // 6  Zig
    P,   // 7  Python
    J,   // 8  JavaScript
    D,   // 9  TypeScript
    K,   // 10 Java
    O,   // 11 Mojo
    L,   // 12 D
    U    // 13 Unknown
}

const int NUM_LANGUAGES = 13;

// Candidate arrays — one definition per language
const String[] _COMP_C   = { "gcc", "clang", "cc", "zig" };
const String[] _COMP_X   = { "g++", "clang++", "c++" };
const String[] _COMP_R   = { "rustc" };
const String[] _COMP_G   = { "go" };
const String[] _COMP_N   = { "nim" };
const String[] _COMP_M   = { "c3c" };
const String[] _COMP_Z   = { "zig" };
const String[] _COMP_P   = { "python3" };
const String[] _COMP_J   = { "node" };
const String[] _COMP_D   = { "tsc" };
const String[] _COMP_K   = { "javac" };
const String[] _COMP_O   = { "mojo" };
const String[] _COMP_L   = { "dmd", "ldc2", "gdc" };

const String[] _RUN_C   = { };
const String[] _RUN_X   = { "vix" };
const String[] _RUN_R   = { };
const String[] _RUN_G   = { "go" };
const String[] _RUN_N   = { "nim" };
const String[] _RUN_M   = { "c3c" };
const String[] _RUN_Z   = { "zig" };
const String[] _RUN_P   = { "python3" };
const String[] _RUN_J   = { "node", "deno", "bun" };
const String[] _RUN_D   = { "deno", "bun" };
const String[] _RUN_K   = { "java" };
const String[] _RUN_O   = { "mojo" };
const String[] _RUN_L   = { };

// Extension → language map.
// Entries are checked in order; first match wins.
const int EXT_COUNT = 17;
const String[] _EXT_STRS = {
    ".c", ".cpp", ".cc", ".cxx", ".hpp",
    ".rs", ".go", ".nim", ".c3", ".zig",
    ".py", ".js", ".ts", ".java", ".mojo", ".d", ".txt"
};
const Language[] _EXT_LANGS = {
    C, X, X, X, X,
    R, G, N, M, Z,
    P, J, D, K, O, L,
    U
};

// -x alias → language map
const int ALIAS_COUNT = 22;
const String[] _ALIAS_STRS = {
    "c", "c++", "cpp", "cxx", "cc",
    "rust", "rs", "go", "nim", "c3", "zig",
    "python", "py", "js", "javascript", "node",
    "ts", "typescript", "deno", "java", "mojo", "d", "dlang"
};
const Language[] _ALIAS_LANGS = {
    C, X, X, X, X,
    R, R, G, N, M, Z,
    P, P, J, J, J,
    D, D, D, K, O, L, L
};

// Per-language metadata — parallel arrays indexed by (int)Language
const String[] _LANG_NAME = {
    "c", "cpp", "rust", "go", "nim", "c3", "zig",
    "python", "javascript", "typescript", "java", "mojo", "d"
};
const String[] _LANG_ENV = {
    "CC", "CXX", "RUSTC", "GO", "NIMC", "C3C", "ZIG",
    "PYTHON", "NODE", "TSC", "JAVAC", "MOJO", "DC"
};
const bool[] _LANG_NEEDS_RUN = {
    false, false, false, true, true, true, true,
    false, false, true, false, true, false
};
const bool[] _LANG_DIRECT_RT = {
    false, false, false, true, true, true, true,
    true, true, true, false, true, false
};
const String[] _ERR_COMPILE = {
    "ccc: no C compiler found — install gcc, clang, cc, or zig",
    "ccc: no C++ compiler found — install g++ or clang++",
    "ccc: no Rust compiler found — install rustc",
    "ccc: no Go compiler found — install go",
    "ccc: no Nim compiler found — install nim",
    "ccc: no C3 compiler found — install c3c",
    "ccc: no Zig compiler found — install zig",
    "ccc: no Python interpreter found — install python3",
    "ccc: no Node.js found — install node",
    "ccc: no TypeScript compiler found — install tsc",
    "ccc: no Java compiler found — install javac",
    "ccc: no Mojo compiler found — install mojo",
    "ccc: no D compiler found — install dmd or ldc2"
};
const String[] _ERR_RUNTIME = {
    "ccc: no runtime available for this language",
    "ccc: no C++ interpreter found — install vix, or use default compile mode",
    "ccc: no runtime available for this language",
    "ccc: no Go compiler found — install go",
    "ccc: no Nim compiler found — install nim",
    "ccc: no C3 compiler found — install c3c",
    "ccc: no Zig compiler found — install zig",
    "ccc: no Python interpreter found — install python3",
    "ccc: no JavaScript runtime found — install node, deno or bun",
    "ccc: no TypeScript runtime found — install deno or bun",
    "ccc: no runtime available for this language",
    "ccc: no Mojo compiler found — install mojo",
    "ccc: no runtime available for this language"
};
const String[] _HELP_COMPILE = {
    "gcc, clang, cc, zig cc", "g++, clang++, c++", "rustc", "go build",
    "nim", "c3c", "zig", "python3", "node", "tsc", "javac", "mojo", "dmd, ldc2, gdc"
};
const String[] _HELP_RUN = {
    "compile + run", "vix / compile+run", "compile + run", "go run",
    "nim run", "c3c run", "zig run", "python3", "node / deno / bun",
    "deno / bun", "java", "mojo run", "compile + run"
};

const String[] _HELP_EXT = {
    ".c", ".cpp", ".rs", ".go", ".nim", ".c3", ".zig",
    ".py", ".js", ".ts", ".java", ".mojo", ".d"
};

// ── Cache ──────────────────────────────────────────────────────────────────

String[13] _cc_cache;
bool _cache_loaded;
bool _quiet_mode;

// ── Path safety ────────────────────────────────────────────────────────────

fn bool _is_safe_path_char(char c)
{
    return (c >= 'A' && c <= 'Z')
        || (c >= 'a' && c <= 'z')
        || (c >= '0' && c <= '9')
        || c == '/' || c == '.' || c == '_' || c == '-'
        || c == ':' || c == '~';
}

fn bool _is_safe_path(String v)
{
    if (v.len == 0 || v.len > 256) return false;
    for (sz i = 0; i < v.len; i++)
    {
        if (!_is_safe_path_char(v[i])) return false;
        if (v[i] == '.' && i + 1 < v.len && v[i + 1] == '.') return false;
    }
    return true;
}

// ── Compiler cache ─────────────────────────────────────────────────────────

fn void _load_cache()
{
    if (try config_dir = env::get_config_dir(mem))
    {
        String cache_dir = config_dir;
        String cfp = cache_dir.tconcat("/ccc/cache");
        if (file::exists(cfp))
        {
            if (try data = file::load_temp(cfp))
            {
                String content = (String)data;
                sz pos = 0;
                while (pos < content.len)
                {
                    sz? nl = content[pos..].index_of_char('\n');
                    sz end;
                    if (try nl2 = nl)
                    {
                        end = pos + nl2;
                    }
                    else
                    {
                        end = content.len;
                    }
                    if (end <= pos) { pos = end + 1; continue; }
                    String line = content[pos..end].trim();
                    pos = end + 1;
                    if (line.len == 0) continue;
                    sz? eq = line.index_of_char('=');
                    if (try eq2 = eq)
                    {
                        if (eq2 < 1) continue;
                        String key = line[0..eq2].trim();
                        String val = line[(eq2 + 1)..].trim();
                        if (val.len == 0) continue;
                        if (!_is_safe_path(val)) continue;
                        for (int i = 0; i < NUM_LANGUAGES; i++)
                        {
                            if (key == _LANG_NAME[i])
                            {
                                char[] copy = alloc::alloc_array(mem, char, val.len + 1);
                                for (sz k = 0; k < val.len; k++) copy[k] = val[k];
                                copy[val.len] = '\0';
                                _cc_cache[i] = (String)copy;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    _cache_loaded = true;
}

fn void _save_cache()
{
    if (!_cache_loaded) return;
    if (try config_dir = env::get_config_dir(mem))
    {
        String dir = config_dir;
        String ccc_dir = dir.tconcat("/ccc");
        String cfp = ccc_dir.tconcat("/cache");
        if (!file::exists(ccc_dir))
        {
            (void)process::run({ "mkdir", "-p", ccc_dir }, options: SpawnOptions.INHERIT_ENV);
        }
        sz total = 0;
        for (int i = 0; i < NUM_LANGUAGES; i++)
        {
            if (_cc_cache[i].len > 0) {
                total += _LANG_NAME[i].len + 1 + _cc_cache[i].len + 1;
            }
        }
        if (total == 0) return;
        char[] buf = alloc::alloc_array(mem, char, total);
        sz off = 0;
        for (int i = 0; i < NUM_LANGUAGES; i++)
        {
            if (_cc_cache[i].len == 0) continue;
            String name = _LANG_NAME[i];
            for (sz j = 0; j < name.len; j++) buf[off++] = name[j];
            buf[off++] = '=';
            String sv = _cc_cache[i];
            for (sz j = 0; j < sv.len; j++) buf[off++] = sv[j];
            buf[off++] = '\n';
        }
        (void)file::save(cfp, buf);
    }
}

// ── PATH lookup ────────────────────────────────────────────────────────────

fn bool exists_on_path(String p)
{
    if (p.contains("/"))
    {
        return file::exists(p);
    }
    char[256] buf;
    if (try r = process::run_capture_stdout(buf[..], { "which", p }, options: SpawnOptions.INHERIT_ENV))
    {
        if (r.len > 0) return true;
    }
    if (try r = process::run_capture_stdout(buf[..], { "where", p }, options: SpawnOptions.INHERIT_ENV))
    {
        return r.len > 0;
    }
    return false;
}

fn String find_first_available(String[] candidates)
{
    for (sz i = 0; i < candidates.len; i++)
    {
        if (exists_on_path(candidates[i])) return candidates[i];
    }
    return "";
}

// ── Language detection ─────────────────────────────────────────────────────

fn Language detect_lang_by_ext(String filename)
{
    if (try dot = filename.rindex_of_char('.'))
    {
        String ext = filename[dot..];
        for (sz i = 0; i < EXT_COUNT; i++)
        {
            if (ext == _EXT_STRS[i]) return _EXT_LANGS[i];
        }
    }
    return U;
}

fn String read_shebang(String filename)
{
    char[256] buf;
    if (try read = file::load_buffer(filename, buf[..]))
    {
        String txt = (String)read;
        if (try nl = txt.index_of_char('\n'))
        {
            String first_line = txt[0..nl];
            if (!first_line.starts_with("#!")) return "";
            return first_line[2..].trim();
        }
        else
        {
            if (!txt.starts_with("#!")) return "";
            return txt[2..].trim();
        }
    }
    return "";
}

fn Language detect_lang_by_shebang(String shebang_line)
{
    if (shebang_line.contains("gcc") || shebang_line.contains("clang") || shebang_line.contains("/cc") || shebang_line.contains("tcc")) return C;
    if (shebang_line.contains("g++") || shebang_line.contains("clang++") || shebang_line.contains("c++")) return X;
    if (shebang_line.contains("rustc")) return R;
    if (shebang_line.contains("go")) return G;
    if (shebang_line.contains("nim")) return N;
    if (shebang_line.contains("c3c")) return M;
    if (shebang_line.contains("zig")) return Z;
    if (shebang_line.contains("python") || shebang_line.contains("python3")) return P;
    if (shebang_line.contains("node")) return J;
    if (shebang_line.contains("deno")) return D;
    if (shebang_line.contains("javac") || shebang_line.contains("java")) return K;
    if (shebang_line.contains("mojo")) return O;
    if (shebang_line.contains("dmd") || shebang_line.contains("ldc2") || shebang_line.contains("gdc")) return L;
    return U;
}

// ── Command builders ───────────────────────────────────────────────────────

fn String[] build_compile_cmd(String compiler, String[] user_args, String source_file)
{
    String[] cmd = alloc::alloc_array(mem, String, 2 + user_args.len);
    cmd[0] = compiler;
    for (sz i = 0; i < user_args.len; i++) cmd[1 + i] = user_args[i];
    cmd[1 + user_args.len] = source_file;
    return cmd;
}

fn String[] build_run_subcmd(String runtime, String[] user_args, String source_file)
{
    String[] cmd = alloc::alloc_array(mem, String, 3 + user_args.len);
    cmd[0] = runtime;
    cmd[1] = "run";
    for (sz i = 0; i < user_args.len; i++) cmd[2 + i] = user_args[i];
    cmd[2 + user_args.len] = source_file;
    return cmd;
}

// ── Find compiler / runtime ────────────────────────────────────────────────

fn String find_compiler(Language lang)
{
    int idx = (int)lang;
    if (idx < 0 || idx >= NUM_LANGUAGES) return "";

    // 1. Environment variable override
    if (try env_val = env::tget_var(_LANG_ENV[idx]))
    {
        if (env_val.len > 0 && _is_safe_path(env_val) && exists_on_path(env_val))
        {
            char[] copy = alloc::alloc_array(mem, char, env_val.len + 1);
            for (sz k = 0; k < env_val.len; k++) copy[k] = env_val[k];
            copy[env_val.len] = '\0';
            _cc_cache[idx] = (String)copy;
            return env_val;
        }
    }

    // 2. Cache hit
    if (_cc_cache[idx].len > 0)
    {
        String cached = _cc_cache[idx];
        if (_is_safe_path(cached)) return cached;
        _cc_cache[idx] = "";
    }

    // 3. Search PATH
    String found;
    switch (lang)
    {
        case C: found = find_first_available(_COMP_C); break;
        case X: found = find_first_available(_COMP_X); break;
        case R: found = find_first_available(_COMP_R); break;
        case G: found = find_first_available(_COMP_G); break;
        case N: found = find_first_available(_COMP_N); break;
        case M: found = find_first_available(_COMP_M); break;
        case Z: found = find_first_available(_COMP_Z); break;
        case P: found = find_first_available(_COMP_P); break;
        case J: found = find_first_available(_COMP_J); break;
        case D: found = find_first_available(_COMP_D); break;
        case K: found = find_first_available(_COMP_K); break;
        case O: found = find_first_available(_COMP_O); break;
        case L: found = find_first_available(_COMP_L); break;
        default: return "";
    }
    if (found.len > 0)
    {
        char[] copy = alloc::alloc_array(mem, char, found.len + 1);
        for (sz k = 0; k < found.len; k++) copy[k] = found[k];
        copy[found.len] = '\0';
        _cc_cache[idx] = (String)copy;
    }
    return found;
}

fn String find_runtime(Language lang)
{
    int idx = (int)lang;
    if (idx < 0 || idx >= NUM_LANGUAGES) return "";
    switch (lang)
    {
        case C: return find_first_available(_RUN_C);
        case X: return find_first_available(_RUN_X);
        case R: return find_first_available(_RUN_R);
        case G: return find_first_available(_RUN_G);
        case N: return find_first_available(_RUN_N);
        case M: return find_first_available(_RUN_M);
        case Z: return find_first_available(_RUN_Z);
        case P: return find_first_available(_RUN_P);
        case J: return find_first_available(_RUN_J);
        case D: return find_first_available(_RUN_D);
        case K: return find_first_available(_RUN_K);
        case O: return find_first_available(_RUN_O);
        case L: return find_first_available(_RUN_L);
        default: return "";
    }
}

fn bool needs_run_subcmd(Language lang)
{
    int idx = (int)lang;
    if (idx < 0 || idx >= NUM_LANGUAGES) return false;
    return _LANG_NEEDS_RUN[idx];
}

fn bool has_direct_runtime(Language lang)
{
    int idx = (int)lang;
    if (idx < 0 || idx >= NUM_LANGUAGES) return false;
    if (_LANG_DIRECT_RT[idx]) return true;
    // C++ special case: vix interpreter
    if (lang == X) return find_first_available(_RUN_X).len > 0;
    return false;
}

// ── Error messages ─────────────────────────────────────────────────────────

fn void print_compiler_error(Language lang)
{
    int idx = (int)lang;
    if (idx >= 0 && idx < NUM_LANGUAGES)
    {
        io::eprintn(_ERR_COMPILE[idx]);
    }
    else
    {
        io::eprintn("ccc: unrecognized language");
    }
}

fn void print_runtime_error(Language lang)
{
    int idx = (int)lang;
    if (idx >= 0 && idx < NUM_LANGUAGES)
    {
        io::eprintn(_ERR_RUNTIME[idx]);
    }
    else
    {
        io::eprintn("ccc: no runtime available for this language");
    }
}

// ── Command printing helper ────────────────────────────────────────────────

fn void print_cmd(String[] cmd)
{
    if (_quiet_mode) return;
    io::eprint("ccc: ");
    for (sz i = 0; i < cmd.len; i++)
    {
        if (i > 0) io::eprint(" ");
        io::eprint(cmd[i]);
    }
    io::eprintn("");
}

// ── Hash utilities ─────────────────────────────────────────────────────────

// ── Compile and run ────────────────────────────────────────────────────────

fn int compile_and_run(String compiler, Language lang, String[] user_args, String source_file)
{
    bool skip_cache = (lang == M);  // C3 uses c3c run directly
    String runcache_bin;
    String runcache_dir;
    String mtime_path;
    uint cache_key = fnv32a::hash(source_file);

    if (!skip_cache)
    {
        if (try config_dir = env::get_config_dir(mem))
        {
            char[8] key_buf;
            String key_str = (String)(io::bprintf(&key_buf, "%08x", cache_key) !!);
            runcache_dir = config_dir.tconcat("/ccc/runcache/").tconcat(key_str);
            runcache_bin = runcache_dir.tconcat("/bin");
            mtime_path   = runcache_dir.tconcat("/mtime");
        }
        else
        {
            skip_cache = true;
        }
    }

    bool cache_hit = false;
    if (!skip_cache)
    {
        if (try src_mtime = file::last_modified(source_file))
        {
            if (file::exists(runcache_bin) && file::exists(mtime_path))
            {
                if (try mtime_data = file::load_temp(mtime_path))
                {
                    String mtime_str = ((String)mtime_data).trim();
                    if (try cached_mtime = mtime_str.to_long())
                    {
                        cache_hit = ((long)cached_mtime == (long)src_mtime);
                    }
                }
            }
        }
    }

    String out;
    if (cache_hit)
    {
        out = runcache_bin;
        if (!_quiet_mode) io::eprintn("ccc: [cached]");
    }
    else
    {
        if (!skip_cache)
        {
            out = runcache_bin;
            if (!file::exists(runcache_dir))
            {
                (void)process::run({ "mkdir", "-p", runcache_dir }, options: SpawnOptions.INHERIT_ENV);
            }
        }
        else
        {
            out = "/tmp/ccc_a.out";
        }
    }

    if (!cache_hit)
    {
        String[] compile_args;

        // C3: use "c3c run --" directly
        if (lang == M)
        {
            compile_args = alloc::alloc_array(mem, String, 3 + user_args.len);
            compile_args[0] = "c3c";
            compile_args[1] = "run";
            compile_args[2] = "--";
            for (sz i = 0; i < user_args.len; i++) compile_args[3 + i] = user_args[i];
        }
        // D: different compilers use different -o syntax
        else if (lang == L)
        {
            if (compiler.contains("gdc"))
            {
                compile_args = alloc::alloc_array(mem, String, 4);
                compile_args[0] = compiler;
                compile_args[1] = "-o";
                compile_args[2] = out;
                compile_args[3] = source_file;
            }
            else
            {
                compile_args = alloc::alloc_array(mem, String, 3);
                compile_args[0] = compiler;
                compile_args[1] = "-of".tconcat(out);
                compile_args[2] = source_file;
            }
        }
        // C with zig: needs "zig cc" subcommand
        else if (lang == C && compiler == "zig")
        {
            compile_args = alloc::alloc_array(mem, String, 5);
            compile_args[0] = "zig";
            compile_args[1] = "cc";
            compile_args[2] = "-o";
            compile_args[3] = out;
            compile_args[4] = source_file;
        }
        // Standard: compiler -o output source
        else
        {
            compile_args = alloc::alloc_array(mem, String, 4);
            compile_args[0] = compiler;
            compile_args[1] = "-o";
            compile_args[2] = out;
            compile_args[3] = source_file;
        }

        print_cmd(compile_args);

        int? compile_result = process::run(compile_args, options: SpawnOptions.INHERIT_STDIO | SpawnOptions.INHERIT_ENV);
        if ((compile_result ?? 0) != 0) return compile_result ?? 1;

        if (!skip_cache)
        {
            if (try src_mtime = file::last_modified(source_file))
            {
                char[32] mtime_buf;
                if (try mtime_str = io::bprintf(&mtime_buf, "%d", src_mtime))
                {
                    file::save(mtime_path, mtime_str)!!;
                }
            }
        }
    }

    String[] run_args = alloc::alloc_array(mem, String, 1 + user_args.len);
    run_args[0] = out;
    for (sz i = 0; i < user_args.len; i++) run_args[1 + i] = user_args[i];

    print_cmd(run_args);

    int? run_result = process::run(run_args, options: SpawnOptions.INHERIT_STDIO | SpawnOptions.INHERIT_ENV);
    return run_result ?? 0;
}

// ── Language parsing (-x flag) ─────────────────────────────────────────────

fn Language parse_lang(String x)
{
    for (sz i = 0; i < ALIAS_COUNT; i++)
    {
        if (x == _ALIAS_STRS[i]) return _ALIAS_LANGS[i];
    }
    return U;
}

// ── Execute command ────────────────────────────────────────────────────────

fn int exec_cmd(String[] cmd)
{
    print_cmd(cmd);
    return process::run(cmd, options: SpawnOptions.INHERIT_STDIO | SpawnOptions.INHERIT_ENV) ?? 3;
}

// ── Main ───────────────────────────────────────────────────────────────────

fn int main(String[] args)
{
    String[] rest_args = args[1..];

    if (rest_args.len > 0 && (rest_args[0] == "--quiet" || rest_args[0] == "-q"))
    {
        _quiet_mode = true;
        rest_args = rest_args[1..];
    }

    if (rest_args.len == 0)
    {
        print_usage();
        return 0;
    }

    String first_arg = rest_args[0];
    if (first_arg == "--help" || first_arg == "-h")
    {
        print_usage();
        return 0;
    }
    if (first_arg == "--version" || first_arg == "-V")
    {
        io::printn("ccc v0.1 — compiler command center / C3");
        return 0;
    }
    if (first_arg == "--list" || first_arg == "-L")
    {
        io::printn("ccc -- supported languages:");
        for (int i = 0; i < NUM_LANGUAGES; i++)
        {
            io::printf("  %-5s  %-14s  %-30s  run: %s\n",
                _HELP_EXT[i], _LANG_NAME[i], _HELP_COMPILE[i], _HELP_RUN[i]);
        }
        return 0;
    }
    if (first_arg == "--detect")
    {
        if (rest_args.len < 2)
        {
            io::eprintn("ccc: --detect requires a source file");
            return 1;
        }
        String target = rest_args[1];
        if (!file::exists(target))
        {
            io::eprintf("ccc: file not found: %s\n", target);
            return 1;
        }
        Language lang = detect_lang_by_ext(target);
        if (lang == U)
        {
            String shebang = read_shebang(target);
            if (shebang.len > 0)
            {
                lang = detect_lang_by_shebang(shebang);
                if (lang != U)
                {
                    io::printf("ccc: %s → %s (via shebang: %s)\n", target, _LANG_NAME[(int)lang], shebang);
                    return 0;
                }
            }
            io::printf("ccc: %s → unknown\n", target);
            return 2;
        }
        io::printf("ccc: %s → %s\n", target, _LANG_NAME[(int)lang]);
        return 0;
    }

    bool run_mode = false;
    Language lang_override = U;
    sz arg_idx = 0;

    if (arg_idx < rest_args.len && rest_args[arg_idx] == "run")
    {
        run_mode = true;
        arg_idx++;
    }

    if (arg_idx < rest_args.len && rest_args[arg_idx] == "-x")
    {
        if (arg_idx + 1 >= rest_args.len)
        {
            io::eprintn("ccc: -x requires a language name");
            io::eprintn("  try: ccc -x c++ file.txt");
            return 1;
        }
        lang_override = parse_lang(rest_args[arg_idx + 1]);
        if (lang_override == U)
        {
            io::eprintf("ccc: unknown language: %s\n", rest_args[arg_idx + 1]);
            return 1;
        }
        arg_idx += 2;
    }

    _load_cache();
    defer _save_cache();

    String[] positional = { };
    if (arg_idx < rest_args.len) positional = rest_args[arg_idx..];

    if (positional.len == 0)
    {
        io::eprintn("ccc: missing source file");
        io::eprintn("  try: c main.c3");
        return 1;
    }

    String source_file = positional[0];

    if (!file::exists(source_file))
    {
        io::eprintf("ccc: file not found: %s\n", source_file);
        return 1;
    }

    Language lang = lang_override;
    if (lang == U)
    {
        lang = detect_lang_by_ext(source_file);
        if (lang == U)
        {
            String shebang = read_shebang(source_file);
            if (shebang.len > 0) lang = detect_lang_by_shebang(shebang);
        }
    }

    if (lang == U)
    {
        io::eprintf("ccc: unrecognized file type: %s\n", source_file);
        io::eprintn("hint: use c -x <lang> to force, or c --help for supported formats");
        return 1;
    }

    String[] user_args = { };
    if (positional.len > 1) user_args = positional[1..];

    if (run_mode)
    {
        if (has_direct_runtime(lang))
        {
            String runtime = find_runtime(lang);
            if (runtime.len == 0)
            {
                print_runtime_error(lang);
                return 2;
            }

            String[] cmd;
            if (needs_run_subcmd(lang))
            {
                cmd = build_run_subcmd(runtime, user_args, source_file);
            }
            else
            {
                cmd = build_compile_cmd(runtime, user_args, source_file);
            }
            return exec_cmd(cmd);
        }

        String compiler = find_compiler(lang);
        if (compiler.len == 0)
        {
            print_compiler_error(lang);
            return 2;
        }
        return compile_and_run(compiler, lang, user_args, source_file);
    }

    // Compile mode (default)
    String compiler = find_compiler(lang);
    if (compiler.len == 0)
    {
        print_compiler_error(lang);
        return 2;
    }

    String[] cmd;
    if (lang == C && compiler == "zig")
    {
        cmd = alloc::alloc_array(mem, String, 2 + user_args.len);
        cmd[0] = "zig";
        cmd[1] = "cc";
        for (sz i = 0; i < user_args.len; i++) cmd[2 + i] = user_args[i];
        cmd[2 + user_args.len] = source_file;
    }
    else if (lang == M)
    {
        cmd = alloc::alloc_array(mem, String, 2);
        cmd[0] = "c3c";
        cmd[1] = "build";
    }
    else
    {
        cmd = build_compile_cmd(compiler, user_args, source_file);
    }

    return exec_cmd(cmd);
}

fn void print_usage()
{
    io::printn("ccc — compiler command center v0.1");
    io::printn("");
    io::printn("Usage: ccc <source-file> [compiler-args...]");
    io::printn("       ccc run <source-file> [args...]     # run instead of compile");
    io::printn("       ccc -x <lang> <source-file> [...]   # force language");
    io::printn("       ccc run -x <lang> <source-file> [...]");
    io::printn("       ccc --detect <source-file>          # detect language only");
    io::printn("       ccc --list                          # list supported languages");
    io::printn("       ccc --quiet <source-file> [...]     # suppress diagnostic output");
    io::printn("       ccc --help                          # show this help");
    io::printn("       ccc --version                       # show version info");
    io::printn("");
    io::printn("Auto-selects compiler by file extension (or #! line):");
    for (int i = 0; i < NUM_LANGUAGES; i++)
    {
        io::printf("  %-8s → %-12s (%s)  run: %s\n",
            _HELP_EXT[i], _LANG_NAME[i], _HELP_COMPILE[i], _HELP_RUN[i]);
    }
    io::printn("");
    io::printn("Languages for -x: c, c++/cpp, rust/rs, go, nim, c3, zig,");
    io::printn("  python/py, js/node, ts/deno, java, mojo, d/dlang");
    io::printn("");
    io::printn("Environment variables (override compiler/interpreter path):");
    io::printn("  CC, CXX, RUSTC, GO, NIMC, C3C, ZIG");
    io::printn("  PYTHON, NODE, TSC, JAVAC, MOJO, DC");
}
