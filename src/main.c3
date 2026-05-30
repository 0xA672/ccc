module ccc;
import std::io;
import std::io::file;
import std::os::process;
import std::os::env;
import std::core::mem::alloc;
import std::core::mem::allocators;

enum Lg
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
						Lg lg = U;
						switch (line[0])
						{
							case 'C': lg = C; case 'X': lg = X; case 'R': lg = R;
							case 'G': lg = G; case 'N': lg = N; case 'M': lg = M;
							case 'Z': lg = Z; case 'P': lg = P; case 'J': lg = J;
							case 'T': lg = D; case 'V': lg = K; case 'O': lg = O;
							case 'D': lg = L; default: continue;
						}
						String val = line[(eq2 + 1)..].trim();
						if (val.len == 0) continue;
						if (!_is_safe_path(val)) continue;
						int idx = (int)lg;
						if (idx >= 0 && idx < CACHE_SIZE)
						{
							char[] copy = alloc::alloc_array(mem, char, val.len);
							for (sz k = 0; k < val.len; k++) copy[k] = val[k];
							_cc_cache[idx] = (String)copy;
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
		// Build output buffer
		sz total = 0;
		for (int i = 0; i < CACHE_SIZE; i++)
		{
			if (_cc_cache[i].len > 0) total += _cc_cache[i].len + 3;
		}
		if (total == 0) return;
		char[] buf = alloc::alloc_array(mem, char, total);
		sz off = 0;
		for (int i = 0; i < CACHE_SIZE; i++)
		{
			if (_cc_cache[i].len == 0) continue;
			char c;
			switch ((Lg)i)
			{
				case C: c = 'C'; case X: c = 'X'; case R: c = 'R';
				case G: c = 'G'; case N: c = 'N'; case M: c = 'M';
				case Z: c = 'Z'; case P: c = 'P'; case J: c = 'J';
				case D: c = 'T'; case K: c = 'V'; case O: c = 'O';
				case L: c = 'D'; default: c = '?';
			}
			buf[off++] = c;
			buf[off++] = '=';
			String sv = _cc_cache[i];
			for (sz j = 0; j < sv.len; j++) buf[off++] = sv[j];
			buf[off++] = '\n';
		}
		(void)file::save(cfp, buf);
	}
}


const String[] C0  = { "gcc", "clang", "cc", "zig" };
const String[] C1  = { "g++", "clang++", "c++" };
const String[] C2  = { "rustc" };
const String[] C3  = { "go" };
const String[] C4  = { "nim" };
const String[] C5  = { "c3c" };
const String[] C6  = { "zig" };
const String[] C7  = { "python3" };
const String[] C8  = { "node" };
const String[] C9  = { "tsc" };
const String[] C10 = { "javac" };
const String[] C11 = { "mojo" };
const String[] C12 = { "dmd", "ldc2", "gdc" };




const String[] R0  = { };
const String[] R1  = { "vix" };
const String[] R2  = { };
const String[] R3  = { "go" };
const String[] R4  = { "nim" };
const String[] R5  = { "c3c" };
const String[] R6  = { "zig" };
const String[] R7  = { "python3" };
const String[] R8  = { "node", "deno", "bun" };
const String[] R9  = { "deno", "bun" };
const String[] R10 = { "java" };
const String[] R11 = { "mojo" };
const String[] R12 = { };



fn bool h(String p)
{
	if (p.contains("/"))
	{
		return file::exists(p);
	}
	char[256] buf;
	if (try r = process::run_capture_stdout(buf[..], { "which", p }))
	{
		return r.len > 0;
	}
	return false;
}


fn String f(String[] v)
{
	for (sz i = 0; i < v.len; i++)
	{
		if (h(v[i])) return v[i];
	}
	return "";
}


fn Lg e(String n)
{
	if (try d = n.rindex_of_char('.'))
	{
		String x = n[d..];
		switch (x)
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


fn String r(String n)
{
	if (try ct = file::load_temp(n))
	{
		String txt = (String)ct;
		if (try nl = txt.index_of_char('\n'))
		{
			String fl = txt[0..nl];
			if (!fl.starts_with("#!")) return "";
			return fl[2..].trim();
		}
		else
		{
			String fl = txt;
			if (!fl.starts_with("#!")) return "";
			return fl[2..].trim();
		}
	}
	return "";
}


fn Lg s(String b)
{
	if (b.contains("gcc") || b.contains("clang") || b.contains("/cc") || b.contains("tcc")) return C;
	if (b.contains("g++") || b.contains("clang++") || b.contains("c++")) return X;
	if (b.contains("rustc")) return R;
	if (b.contains("go")) return G;
	if (b.contains("nim")) return N;
	if (b.contains("c3c")) return M;
	if (b.contains("zig")) return Z;
	if (b.contains("python") || b.contains("python3")) return P;
	if (b.contains("node")) return J;
	if (b.contains("deno")) return D;
	if (b.contains("javac") || b.contains("java")) return K;
	if (b.contains("mojo")) return O;
	if (b.contains("dmd") || b.contains("ldc2") || b.contains("gdc")) return L;
	return U;
}


fn String[] b0(String co, String[] ua, String sf)
{
	String[] ca = alloc::alloc_array(mem, String, 2 + ua.len);
	ca[0] = co;
	for (sz i = 0; i < ua.len; i++) ca[1 + i] = ua[i];
	ca[1 + ua.len] = sf;
	return ca;
}


fn String[] b1(String co, String[] ua, String sf)
{
	String[] ca = alloc::alloc_array(mem, String, 3 + ua.len);
	ca[0] = co;
	ca[1] = "run";
	for (sz i = 0; i < ua.len; i++) ca[2 + i] = ua[i];
	ca[2 + ua.len] = sf;
	return ca;
}


fn String fc(Lg l)
{
	int idx = (int)l;
	if (idx >= 0 && idx < CACHE_SIZE && _cc_cache[idx].len > 0)
	{
		String cached = _cc_cache[idx];
		if (_is_safe_path(cached)) return cached;
		_cc_cache[idx] = "";
	}
	String found;
	switch (l)
	{
		case C: found = f(C0); break;
		case X: found = f(C1); break;
		case R: found = f(C2); break;
		case G: found = f(C3); break;
		case N: found = f(C4); break;
		case M: found = f(C5); break;
		case Z: found = f(C6); break;
		case P: found = f(C7); break;
		case J: found = f(C8); break;
		case D: found = f(C9); break;
		case K: found = f(C10); break;
		case O: found = f(C11); break;
		case L: found = f(C12); break;
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


fn String fr(Lg l)
{
	switch (l)
	{
		case C: return f(R0);
		case X: return f(R1);
		case R: return f(R2);
		case G: return f(R3);
		case N: return f(R4);
		case M: return f(R5);
		case Z: return f(R6);
		case P: return f(R7);
		case J: return f(R8);
		case D: return f(R9);
		case K: return f(R10);
		case O: return f(R11);
		case L: return f(R12);
		case U: return "";
	}
}



fn bool nr(Lg l)
{
	switch (l)
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



fn bool dr(Lg l)
{
	switch (l)
	{
		case G:
		case N:
		case M:
		case Z:
		case O:
		case P:
		case J:
		case D: return true;
		case X: return f(R1).len > 0;
		default: return false;
	}
}



fn void er(Lg l)
{
	switch (l)
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

fn void er_runtime(Lg l)
{
	switch (l)
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

fn void u()
{
	io::printn("ccc — compiler command center v0.1");
	io::printn("");
	io::printn("Usage: c <source-file> [compiler-args...]");
	io::printn("       c run <source-file> [args...]     # run instead of compile");
	io::printn("       c -x <lang> <source-file> [...]   # force language");
	io::printn("       c run -x <lang> <source-file> [...]");
	io::printn("       c --detect <source-file>          # detect language only");
	io::printn("       c --help                          # show this help");
	io::printn("       c --version                       # show version info");
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
	io::printn("Environment variables (planned):");
	io::printn("  CC, CXX, RUSTC — override compiler path");
}





fn int compile_and_run(String cc, Lg lg, String[] ua, String sf)
{
	String out = "/tmp/ccc_a.out";


	String[] ca;
	if (lg == L)
	{

		if (cc.contains("gdc"))
		{
			ca = alloc::alloc_array(mem, String, 4);
			ca[0] = cc;
			ca[1] = "-o";
			ca[2] = out;
			ca[3] = sf;
		}
		else
		{

			ca = alloc::alloc_array(mem, String, 3);
			ca[0] = cc;
			ca[1] = "-of".tconcat(out);
			ca[2] = sf;
		}
	}
	else if (lg == C && cc == "zig")
	{
		ca = alloc::alloc_array(mem, String, 5);
		ca[0] = "zig";
		ca[1] = "cc";
		ca[2] = "-o";
		ca[3] = out;
		ca[4] = sf;
	}
	else
	{
		ca = alloc::alloc_array(mem, String, 4);
		ca[0] = cc;
		ca[1] = "-o";
		ca[2] = out;
		ca[3] = sf;
	}


	io::eprint("ccc: ");
	for (sz i = 0; i < ca.len; i++)
	{
		if (i > 0)
		{
			io::eprint(" ");
		}
		io::eprint(ca[i]);
	}
	io::eprintn("");

	int? cr = process::run(ca, options: SpawnOptions.INHERIT_STDIO | SpawnOptions.INHERIT_ENV);
	if ((cr ?? 0) != 0) return cr ?? 1;


	String[] ra = alloc::alloc_array(mem, String, 1 + ua.len);
	ra[0] = out;
	for (sz i = 0; i < ua.len; i++) ra[1 + i] = ua[i];

	io::eprint("ccc: ");
	for (sz i = 0; i < ra.len; i++)
	{
		if (i > 0)
		{
			io::eprint(" ");
		}
		io::eprint(ra[i]);
	}
	io::eprintn("");

	int? rr = process::run(ra, options: SpawnOptions.INHERIT_STDIO | SpawnOptions.INHERIT_ENV);
	return rr ?? 0;
}



fn Lg parse_lang(String x)
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



fn int exec_cmd(String[] cm)
{
	io::eprint("ccc: ");
	for (sz i = 0; i < cm.len; i++)
	{
		if (i > 0)
		{
			io::eprint(" ");
		}
		io::eprint(cm[i]);
	}
	io::eprintn("");
	return process::run(cm, options: SpawnOptions.INHERIT_STDIO | SpawnOptions.INHERIT_ENV) ?? 3;
}



fn int main(String[] a)
{
	String[] ra = a[1..];

	if (ra.len == 0)
	{
		u();
		return 0;
	}


	bool run_mode    = false;
	Lg lang_override = U;
	sz ai            = 0;


	if (ai < ra.len && ra[ai] == "run")
	{
		run_mode = true;
		ai++;
	}


	if (ai < ra.len && ra[ai] == "-x")
	{
		if (ai + 1 >= ra.len)
		{
			io::eprintn("ccc: -x requires a language name");
			io::eprintn("  try: c -x c++ file.txt");
			return 1;
		}
		lang_override = parse_lang(ra[ai + 1]);
		if (lang_override == U)
		{
			io::eprintf("ccc: unknown language: %s\n", ra[ai + 1]);
			return 1;
		}
		ai += 2;
	}


	// Load cached compiler paths
	_load_cache();

	String[] pa = { };
	if (ai < ra.len) pa = ra[ai..];


	if (!run_mode && lang_override == U && pa.len > 0)
	{
		String fst = pa[0];
		if (fst == "--help" || fst == "-h")
		{
			u();
			return 0;
		}
		if (fst == "--version" || fst == "-V")
		{
			io::printn("ccc v0.1 — compiler command center / C3");
			return 0;
		}
		if (fst == "--detect")
		{
			if (pa.len < 2)
			{
				io::eprintn("ccc: --detect requires a source file");
				return 1;
			}
			String t = pa[1];
			if (!file::exists(t))
			{
				io::eprintf("ccc: file not found: %s\n", t);
				return 1;
			}
			Lg lg = e(t);
			if (lg == U)
			{
				String sb = r(t);
				if (sb.len > 0)
				{
					lg = s(sb);
					if (lg != U)
					{
						io::printf("ccc: %s → %d (via shebang: %s)\n", t, (int)lg, sb);
						return 0;
					}
				}
				io::printf("ccc: %s → unknown\n", t);
				return 2;
			}
			io::printf("ccc: %s → %d\n", t, (int)lg);
			return 0;
		}
	}


	if (pa.len == 0)
	{
		io::eprintn("ccc: missing source file");
		io::eprintn("  try: c main.c3");
		return 1;
	}

	String sf = pa[0];

	if (!file::exists(sf))
	{
		io::eprintf("ccc: file not found: %s\n", sf);
		return 1;
	}


	Lg lg = lang_override;
	if (lg == U)
	{
		lg = e(sf);
		if (lg == U)
		{
			String sb = r(sf);
			if (sb.len > 0) lg = s(sb);
		}
	}

	if (lg == U)
	{
		io::eprintf("ccc: unrecognized file type: %s\n", sf);
		io::eprintn("hint: use c -x <lang> to force, or c --help for supported formats");
		return 1;
	}


	String[] ua = { };
	if (pa.len > 1) ua = pa[1..];


	if (run_mode)
	{

		if (dr(lg))
		{
			String rt = fr(lg);
			if (rt.len == 0)
			{
				er_runtime(lg);
				return 2;
			}

			String[] cm;
			if (nr(lg))
			{
				cm = b1(rt, ua, sf);
			}
			else
			{
				cm = b0(rt, ua, sf);
			}
			return exec_cmd(cm);
		}


		String cc = fc(lg);
		if (cc.len == 0)
		{
			er(lg);
			return 2;
		}
		return compile_and_run(cc, lg, ua, sf);
	}


	String cc = fc(lg);
	if (cc.len == 0)
	{
		_save_cache();
		er(lg);
		return 2;
	}



	bool compiled_kind = true;
	switch (lg)
	{
		case P:
		case J: compiled_kind = false; break;
		default: break;
	}

	String[] cm;
	if (lg == C && cc == "zig")
	{
		cm = alloc::alloc_array(mem, String, 2 + ua.len);
		cm[0] = "zig";
		cm[1] = "cc";
		for (sz i = 0; i < ua.len; i++) cm[2 + i] = ua[i];
		cm[2 + ua.len] = sf;
	}
	else if (compiled_kind)
	{
		cm = b0(cc, ua, sf);
	}
	else
	{

		cm = b0(cc, ua, sf);
	}

	_save_cache();
	return exec_cmd(cm);
}
