module ccc;
import std::io;
import std::io::file;
import std::os::process;
import std::core::mem::alloc;
import std::core::mem::allocators;

enum Lg
{
	C, X, R, G, N, M, Z, P, J, D, U
}

const String[] C0 = {
	"/usr/local/gcc-16.1/bin/gcc",
	"/home/cero/llvm-install/bin/clang",
	"/usr/bin/gcc",
	"/usr/bin/clang",
	"/usr/bin/cc",
};

const String[] C1 = {
	"/usr/local/gcc-16.1/bin/g++",
	"/home/cero/llvm-install/bin/clang++",
	"/usr/bin/g++",
	"/usr/bin/clang++",
	"/usr/bin/c++",
};

const String[] C2 = { "rustc" };
const String[] C3 = { "go" };
const String[] C4 = { "/home/cero/.nim/bin/nim", "/usr/bin/nim" };
const String[] C5 = { "/home/cero/c3-compiler/c3c", "/usr/bin/c3c", "/home/cero/.local/bin/c3c" };
const String[] C6 = { "/home/cero/llvm-install/bin/zig", "/usr/bin/zig" };
const String[] C7 = { "python3" };
const String[] C8 = { "node" };
const String[] C9 = { "/usr/bin/deno" };

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
			case ".java": return J;
			case ".js": return P;
			case ".d": return D;
			case ".mojo": return M;
			case ".m": return C;
			case ".ts": return D;
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
	if (b.contains("gcc") || b.contains("g++") || b.contains("clang") || b.contains("/cc") || b.contains("tcc")) return C;
	if (b.contains("g++") || b.contains("clang++") || b.contains("c++")) return X;
	if (b.contains("rustc")) return R;
	if (b.contains("go")) return G;
	if (b.contains("nim")) return N;
	if (b.contains("c3c")) return M;
	if (b.contains("zig")) return Z;
	if (b.contains("python") || b.contains("python3")) return P;
	if (b.contains("node")) return J;
	if (b.contains("deno")) return D;
	if (b.contains("java") || b.contains("javac")) return J;
	if (b.contains("mojo")) return M;
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
	String[] ca = alloc::alloc_array(mem, String, 2 + ua.len);
	ca[0] = co;
	ca[1] = "build";
	for (sz i = 0; i < ua.len; i++) ca[2 + i] = ua[i];
	return ca;
}

fn String fc(Lg l)
{
	switch (l)
	{
		case C: return f(C0);
		case X: return f(C1);
		case R: return f(C2);
		case G: return f(C3);
		case N: return f(C4);
		case M: return f(C5);
		case Z: return f(C6);
		case P: return f(C7);
		case J: return f(C8);
		case D: return f(C9);
		case U: return "";
	}
}

fn bool ig(Lg l)
{
	return l == G;
}

fn void er(Lg l)
{
	switch (l)
	{
		case C: io::eprintn("ccc: no C compiler found — install gcc or clang"); break;
		case X: io::eprintn("ccc: no C++ compiler found — install g++ or clang++"); break;
		case R: io::eprintn("ccc: no Rust compiler found — install rustc"); break;
		case G: io::eprintn("ccc: no Go compiler found — install go"); break;
		case N: io::eprintn("ccc: no Nim compiler found — install nim"); break;
		case M: io::eprintn("ccc: no C3 compiler found — install c3c"); break;
		case Z: io::eprintn("ccc: no Zig compiler found — install zig"); break;
		case P: io::eprintn("ccc: no Python interpreter found — install python3"); break;
		case J: io::eprintn("ccc: no Node.js found — install node"); break;
		case D: io::eprintn("ccc: no Deno found — install deno"); break;
		case U: io::eprintn("ccc: unrecognized language"); break;
	}
}

fn void u()
{
	io::printn("ccc — compiler command center v0.1");
	io::printn("");
	io::printn("Usage: c <source-file> [compiler-args...]");
	io::printn("       c --detect <source-file>   # detect language only");
	io::printn("       c --help                   # show this help");
	io::printn("       c --version                # show version info");
	io::printn("");
	io::printn("Auto-selects compiler by file extension (or #! line):");
	io::printn("  .c    → C          (gcc, clang, cc)");
	io::printn("  .cpp  → C++        (g++, clang++, c++)");
	io::printn("  .rs   → Rust       (rustc)");
	io::printn("  .go   → Go         (go)");
	io::printn("  .nim  → Nim        (nim)");
	io::printn("  .c3   → C3         (c3c)");
	io::printn("  .zig  → Zig        (zig)");
	io::printn("  .py   → Python     (python3)");
	io::printn("  .js   → Node.js    (node)");
	io::printn("  .ts   → Deno       (deno)");
	io::printn("");
	io::printn("Environment variables (planned):");
	io::printn("  CC, CXX, RUSTC — override compiler path");
}

fn int main(String[] a)
{
	String[] ra = a[1..];

	if (ra.len == 0)
	{
		u();
		return 0;
	}

	String fst = ra[0];

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
		if (ra.len < 2)
		{
			io::eprintn("ccc: --detect requires a source file");
			return 1;
		}
		String t = ra[1];
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

	String sf = fst;

	if (!file::exists(sf))
	{
		io::eprintf("ccc: file not found: %s\n", sf);
		return 1;
	}

	Lg lg = e(sf);

	if (lg == U)
	{
		String sb = r(sf);
		if (sb.len > 0)
		{
			lg = s(sb);
		}
	}

	if (lg == U)
	{
		io::eprintf("ccc: unrecognized file type: %s\n", sf);
		io::eprintn("hint: use c --help for supported formats");
		return 1;
	}

	String[] ua;
	if (ra.len > 1) {
		ua = ra[1..];
	} else {
		ua = {};
	}

	String cc = fc(lg);
	if (cc.len == 0)
	{
		er(lg);
		return 2;
	}

	String[] cm;
	if (ig(lg)) {
		cm = b1(cc, ua, sf);
	} else {
		cm = b0(cc, ua, sf);
	}

	io::eprint("ccc: ");
	for (sz i = 0; i < cm.len; i++)
	{
		if (i > 0) { io::eprint(" "); }
		io::eprint(cm[i]);
	}
	io::eprintn("");

	int? rc = process::run(cm, options: (SpawnOptions)(1 << 5));
	return rc ?? 3;
}
