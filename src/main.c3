module ccc;
import std::io;
import std::io::file;
import std::os::process;
import std::os::env;
import std::core::mem::alloc;
import std::core::mem::allocators;

enum Language
{
	C,
	X,
	R,
	G,
	N,
	M,
	Z,
	P,
	J,
	D,
	K,
	O,
	L,
	U
}

struct LangEntry {
    String lang;
    String env;
}

// SINGLE SOURCE OF TRUTH
// Add a new case here (+ an enum member in Language) when adding a language.
macro LangEntry lang_entry($idx)
{
    $switch ($idx):
        $case 0: return { "c", "CC" };
        $case 1: return { "cpp", "CXX" };
        $case 2: return { "rust", "RUSTC" };
        $case 3: return { "go", "GO" };
        $case 4: return { "nim", "NIMC" };
        $case 5: return { "c3", "C3C" };
        $case 6: return { "zig", "ZIG" };
        $case 7: return { "python", "PYTHON" };
        $case 8: return { "javascript", "NODE" };
        $case 9: return { "typescript", "TSC" };
        $case 10: return { "java", "JAVAC" };
        $case 11: return { "mojo", "MOJO" };
        $case 12: return { "d", "DC" };
        $default: return { "", "" };
    $endswitch
}

const LangEntry[] _LANG_TABLE = {
    lang_entry(0),  lang_entry(1),  lang_entry(2),  lang_entry(3),
    lang_entry(4),  lang_entry(5),  lang_entry(6),  lang_entry(7),
    lang_entry(8),  lang_entry(9),  lang_entry(10), lang_entry(11),
    lang_entry(12)
};

const int CACHE_SIZE = 13;
String[CACHE_SIZE] _cc_cache;
bool _cache_loaded;
char[1024] _cache_buf;


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
	}
	return true;
}


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
						for (int i = 0; i < CACHE_SIZE; i++)
						{
							if (key == _LANG_TABLE[i].lang)
							{
								char[] copy = alloc::alloc_array(mem, char, val.len);
								for (sz k = 0; k < val.len; k++) copy[k] = val[k];
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
			int? mkres = process::run({ "mkdir", "-p", ccc_dir }, options: SpawnOptions.INHERIT_ENV);
		}
		sz total = 0;
		for (int i = 0; i < CACHE_SIZE; i++)
		{
			if (_cc_cache[i].len > 0) {
				total += _LANG_TABLE[i].lang.len + 1 + _cc_cache[i].len + 1;
			}
		}
		if (total == 0) return;
		char[] buf = alloc::alloc_array(mem, char, total);
		sz off = 0;
		for (int i = 0; i < CACHE_SIZE; i++)
		{
			if (_cc_cache[i].len == 0) continue;
			String name = _LANG_TABLE[i].lang;
			for (sz j = 0; j < name.len; j++) buf[off++] = name[j];
			buf[off++] = '=';
			String sv = _cc_cache[i];
			for (sz j = 0; j < sv.len; j++) buf[off++] = sv[j];
			buf[off++] = '\n';
		}
		(void)file::save(cfp, buf);
	}
}


const String[] COMPILER_CANDIDATES_C   = { "gcc", "clang", "cc", "zig" };
const String[] COMPILER_CANDIDATES_CPP = { "g++", "clang++", "c++" };
const String[] COMPILER_CANDIDATES_RS  = { "rustc" };
const String[] COMPILER_CANDIDATES_GO  = { "go" };
const String[] COMPILER_CANDIDATES_NIM = { "nim" };
const String[] COMPILER_CANDIDATES_C3  = { "c3c" };
const String[] COMPILER_CANDIDATES_ZIG = { "zig" };
const String[] COMPILER_CANDIDATES_PY  = { "python3" };
const String[] COMPILER_CANDIDATES_JS  = { "node" };
const String[] COMPILER_CANDIDATES_TS  = { "tsc" };
const String[] COMPILER_CANDIDATES_JAVA = { "javac" };
const String[] COMPILER_CANDIDATES_MOJO = { "mojo" };
const String[] COMPILER_CANDIDATES_D   = { "dmd", "ldc2", "gdc" };


const String[] RUNTIME_CANDIDATES_C    = { };
const String[] RUNTIME_CANDIDATES_CPP  = { "vix" };
const String[] RUNTIME_CANDIDATES_RS   = { };
const String[] RUNTIME_CANDIDATES_GO   = { "go" };
const String[] RUNTIME_CANDIDATES_NIM  = { "nim" };
const String[] RUNTIME_CANDIDATES_C3   = { "c3c" };
const String[] RUNTIME_CANDIDATES_ZIG  = { "zig" };
const String[] RUNTIME_CANDIDATES_PY   = { "python3" };
const String[] RUNTIME_CANDIDATES_JS   = { "node", "deno", "bun" };
const String[] RUNTIME_CANDIDATES_TS   = { "deno", "bun" };
const String[] RUNTIME_CANDIDATES_JAVA = { "java" };
const String[] RUNTIME_CANDIDATES_MOJO = { "mojo" };
const String[] RUNTIME_CANDIDATES_D    = { };



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


fn Language detect_lang_by_ext(String filename)
{
	if (try dot = filename.rindex_of_char('.'))
	{
		String ext = filename[dot..];
		switch (ext)
		{
			case ".c": return C;
			case ".cpp": return X;
			case ".cc": return X;
			case ".cxx": return X;
			case ".hpp": return X;
			case ".rs": return R;
			case ".go": return G;
			case ".nim": return N;
			case ".c3": return M;
			case ".zig": return Z;
			case ".py": return P;
			case ".js": return J;
			case ".ts": return D;
			case ".java": return K;
			case ".mojo": return O;
			case ".d": return L;
			default: return U;
		}
	}
	return U;
}


fn String read_shebang(String filename)
{
	if (try ct = file::load_temp(filename))
	{
		String txt = (String)ct;
		if (try nl = txt.index_of_char('\n'))
		{
			String first_line = txt[0..nl];
			if (!first_line.starts_with("#!")) return "";
			return first_line[2..].trim();
		}
		else
		{
			String first_line = txt;
			if (!first_line.starts_with("#!")) return "";
			return first_line[2..].trim();
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


fn String find_compiler(Language lang)
{
	int idx = (int)lang;

	if (idx >= 0 && idx < CACHE_SIZE)
	{
		if (try env_val = env::tget_var(_LANG_TABLE[idx].env))
		{
			if (env_val.len > 0 && _is_safe_path(env_val) && exists_on_path(env_val))
			{
				char[] copy = alloc::alloc_array(mem, char, env_val.len);
				for (sz k = 0; k < env_val.len; k++) copy[k] = env_val[k];
				_cc_cache[idx] = (String)copy;
				return env_val;
			}
		}
	}

	if (idx >= 0 && idx < CACHE_SIZE && _cc_cache[idx].len > 0)
	{
		String cached = _cc_cache[idx];
		if (_is_safe_path(cached)) return cached;
		_cc_cache[idx] = "";
	}
	String found;
	switch (lang)
	{
		case C: found = find_first_available(COMPILER_CANDIDATES_C); break;
		case X: found = find_first_available(COMPILER_CANDIDATES_CPP); break;
		case R: found = find_first_available(COMPILER_CANDIDATES_RS); break;
		case G: found = find_first_available(COMPILER_CANDIDATES_GO); break;
		case N: found = find_first_available(COMPILER_CANDIDATES_NIM); break;
		case M: found = find_first_available(COMPILER_CANDIDATES_C3); break;
		case Z: found = find_first_available(COMPILER_CANDIDATES_ZIG); break;
		case P: found = find_first_available(COMPILER_CANDIDATES_PY); break;
		case J: found = find_first_available(COMPILER_CANDIDATES_JS); break;
		case D: found = find_first_available(COMPILER_CANDIDATES_TS); break;
		case K: found = find_first_available(COMPILER_CANDIDATES_JAVA); break;
		case O: found = find_first_available(COMPILER_CANDIDATES_MOJO); break;
		case L: found = find_first_available(COMPILER_CANDIDATES_D); break;
		case U: return "";
	}
	if (found.len > 0 && idx >= 0 && idx < CACHE_SIZE)
	{
		char[] copy = alloc::alloc_array(mem, char, found.len);
		for (sz k = 0; k < found.len; k++) copy[k] = found[k];
		_cc_cache[idx] = (String)copy;
	}
	return found;
}


fn String find_runtime(Language lang)
{
	switch (lang)
	{
		case C: return find_first_available(RUNTIME_CANDIDATES_C);
		case X: return find_first_available(RUNTIME_CANDIDATES_CPP);
		case R: return find_first_available(RUNTIME_CANDIDATES_RS);
		case G: return find_first_available(RUNTIME_CANDIDATES_GO);
		case N: return find_first_available(RUNTIME_CANDIDATES_NIM);
		case M: return find_first_available(RUNTIME_CANDIDATES_C3);
		case Z: return find_first_available(RUNTIME_CANDIDATES_ZIG);
		case P: return find_first_available(RUNTIME_CANDIDATES_PY);
		case J: return find_first_available(RUNTIME_CANDIDATES_JS);
		case D: return find_first_available(RUNTIME_CANDIDATES_TS);
		case K: return find_first_available(RUNTIME_CANDIDATES_JAVA);
		case O: return find_first_available(RUNTIME_CANDIDATES_MOJO);
		case L: return find_first_available(RUNTIME_CANDIDATES_D);
		case U: return "";
	}
}



fn bool needs_run_subcmd(Language lang)
{
	switch (lang)
	{
		case G:
		case N:
		case M:
		case Z:
		case O:
		case D: return true;
		default: return false;
	}
}



fn bool has_direct_runtime(Language lang)
{
	switch (lang)
	{
		case G:
		case N:
		case M:
		case Z:
		case O:
		case P:
		case J:
		case D: return true;
		case X: return find_first_available(RUNTIME_CANDIDATES_CPP).len > 0;
		default: return false;
	}
}



fn void print_compiler_error(Language lang)
{
	switch (lang)
	{
		case C: io::eprintn("ccc: no C compiler found — install gcc, clang, cc, or zig"); break;
		case X: io::eprintn("ccc: no C++ compiler found — install g++ or clang++"); break;
		case R: io::eprintn("ccc: no Rust compiler found — install rustc"); break;
		case G: io::eprintn("ccc: no Go compiler found — install go"); break;
		case N: io::eprintn("ccc: no Nim compiler found — install nim"); break;
		case M: io::eprintn("ccc: no C3 compiler found — install c3c"); break;
		case Z: io::eprintn("ccc: no Zig compiler found — install zig"); break;
		case P: io::eprintn("ccc: no Python interpreter found — install python3"); break;
		case J: io::eprintn("ccc: no Node.js found — install node"); break;
		case D: io::eprintn("ccc: no TypeScript compiler found — install tsc"); break;
		case K: io::eprintn("ccc: no Java compiler found — install javac"); break;
		case O: io::eprintn("ccc: no Mojo compiler found — install mojo"); break;
		case L: io::eprintn("ccc: no D compiler found — install dmd or ldc2"); break;
		case U: io::eprintn("ccc: unrecognized language"); break;
	}
}

fn void print_runtime_error(Language lang)
{
	switch (lang)
	{
		case D: io::eprintn("ccc: no TypeScript runtime found — install deno or bun"); break;
		case X: io::eprintn("ccc: no C++ interpreter found — install vix, or use default compile mode"); break;
		case P: io::eprintn("ccc: no Python interpreter found — install python3"); break;
		case J: io::eprintn("ccc: no JavaScript runtime found — install node, deno or bun"); break;
		case G: io::eprintn("ccc: no Go compiler found — install go"); break;
		case N: io::eprintn("ccc: no Nim compiler found — install nim"); break;
		case M: io::eprintn("ccc: no C3 compiler found — install c3c"); break;
		case Z: io::eprintn("ccc: no Zig compiler found — install zig"); break;
		case O: io::eprintn("ccc: no Mojo compiler found — install mojo"); break;
		default: io::eprintn("ccc: no runtime available for this language"); break;
	}
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
	io::printn("       ccc --help                          # show this help");
	io::printn("       ccc --version                       # show version info");
	io::printn("");
	io::printn("Auto-selects compiler by file extension (or #! line):");
	io::printn("  .c    → C          (gcc, clang, cc, zig cc)  run: compile + run");
	io::printn("  .cpp  → C++        (g++, clang++, c++)       run: vix / compile+run");
	io::printn("  .rs   → Rust       (rustc)                   run: compile + run");
	io::printn("  .go   → Go         (go build)                run: go run");
	io::printn("  .nim  → Nim        (nim)                     run: nim run");
	io::printn("  .c3   → C3         (c3c)                     run: c3c run");
	io::printn("  .zig  → Zig        (zig)                     run: zig run");
	io::printn("  .py   → Python     (python3)                 run: python3");
	io::printn("  .js   → Node.js    (node)                    run: node / deno / bun");
	io::printn("  .ts   → TSC        (tsc)                     run: deno / bun");
	io::printn("  .java → Java       (javac)                   run: java");
	io::printn("  .mojo → Mojo       (mojo)                    run: mojo run");
	io::printn("  .d    → D          (dmd, ldc2, gdc)          run: compile + run");
	io::printn("");
	io::printn("Languages for -x: c, c++/cpp, rust/rs, go, nim, c3, zig,");
	io::printn("  python/py, js/node, ts/deno, java, mojo, d/dlang");
	io::printn("");
	io::printn("Environment variables (override compiler/interpreter path):");
	io::printn("  CC, CXX, RUSTC, GO, NIMC, C3C, ZIG");
	io::printn("  PYTHON, NODE, TSC, JAVAC, MOJO, DC");
}





fn uint _fnv1a(String s)
{
	uint h = 2166136261u;
	for (sz i = 0; i < s.len; i++)
	{
		h ^= (uint)(s[i]);
		h *= 16777619u;
	}
	return h;
}

fn String _hex(Allocator alloc, uint v)
{
	char[] buf = alloc::alloc_array(alloc, char, 8);
	for (int i = 7; i >= 0; i--)
	{
		char c = (char)('0' + (v & 0xF));
		if (c > '9') c = (char)(c + 39);
		buf[i] = c;
		v >>= 4;
	}
	return (String)buf;
}

fn int compile_and_run(String compiler, Language lang, String[] user_args, String source_file)
{
	bool skip_cache = (lang == M);
	String runcache_bin;
	String runcache_dir;
	String mtime_path;
	uint cache_key = _fnv1a(source_file);

	if (!skip_cache)
	{
		if (try config_dir = env::get_config_dir(mem))
		{
			String key_str = _hex(mem, cache_key);
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
		io::eprintn("ccc: [cached]");
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
		if (lang == M)
		{
			compile_args = alloc::alloc_array(mem, String, 3 + user_args.len);
			compile_args[0] = "c3c";
			compile_args[1] = "run";
			compile_args[2] = "--";
			for (sz i = 0; i < user_args.len; i++) compile_args[3 + i] = user_args[i];
		}
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
		else if (lang == C && compiler == "zig")
		{
			compile_args = alloc::alloc_array(mem, String, 5);
			compile_args[0] = "zig";
			compile_args[1] = "cc";
			compile_args[2] = "-o";
			compile_args[3] = out;
			compile_args[4] = source_file;
		}
		else
		{
			compile_args = alloc::alloc_array(mem, String, 4);
			compile_args[0] = compiler;
			compile_args[1] = "-o";
			compile_args[2] = out;
			compile_args[3] = source_file;
		}

		io::eprint("ccc: ");
		for (sz i = 0; i < compile_args.len; i++)
		{
			if (i > 0) io::eprint(" ");
			io::eprint(compile_args[i]);
		}
		io::eprintn("");

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

	io::eprint("ccc: ");
	for (sz i = 0; i < run_args.len; i++)
	{
		if (i > 0) io::eprint(" ");
		io::eprint(run_args[i]);
	}
	io::eprintn("");

	int? run_result = process::run(run_args, options: SpawnOptions.INHERIT_STDIO | SpawnOptions.INHERIT_ENV);
	return run_result ?? 0;
}



fn Language parse_lang(String x)
{
	switch (x)
	{
		case "c": return C;
		case "c++":
		case "cpp":
		case "cxx":
		case "cc": return X;
		case "rust":
		case "rs": return R;
		case "go": return G;
		case "nim": return N;
		case "c3": return M;
		case "zig": return Z;
		case "python":
		case "py": return P;
		case "js":
		case "javascript":
		case "node": return J;
		case "ts":
		case "typescript":
		case "deno": return D;
		case "java": return K;
		case "mojo": return O;
		case "d":
		case "dlang": return L;
		default: return U;
	}
}



fn int exec_cmd(String[] cmd)
{
	io::eprint("ccc: ");
	for (sz i = 0; i < cmd.len; i++)
	{
		if (i > 0)
		{
			io::eprint(" ");
		}
		io::eprint(cmd[i]);
	}
	io::eprintn("");
	return process::run(cmd, options: SpawnOptions.INHERIT_STDIO | SpawnOptions.INHERIT_ENV) ?? 3;
}



fn int main(String[] args)
{
	String[] rest_args = args[1..];

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
					io::printf("ccc: %s → %s (via shebang: %s)\n", target, _LANG_TABLE[(int)lang].lang, shebang);
					return 0;
				}
			}
			io::printf("ccc: %s → unknown\n", target);
			return 2;
		}
		io::printf("ccc: %s → %s\n", target, _LANG_TABLE[(int)lang].lang);
		return 0;
	}


	bool run_mode    = false;
	Language lang_override = U;
	sz arg_idx            = 0;


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


	String compiler = find_compiler(lang);
	if (compiler.len == 0)
	{
		print_compiler_error(lang);
		return 2;
	}



	bool compiled_kind = true;
	switch (lang)
	{
		case P:
		case J: compiled_kind = false; break;
		default: break;
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
	else if (compiled_kind)
	{
		cmd = build_compile_cmd(compiler, user_args, source_file);
	}
	else
	{

		cmd = build_compile_cmd(compiler, user_args, source_file);
	}

	return exec_cmd(cmd);
}
