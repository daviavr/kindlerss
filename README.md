# kindlerss — Project Plan & Design Document

## 1. What is this project?

`kindlerss` is a native RSS reader for the Amazon Kindle. It is being written in
**Vala**, cross-compiled for ARM with the existing `arm-kindlehf-linux-gnueabihf`
toolchain, and uses GTK+ 2.0 for the user interface because that is what the
Kindle runtime already provides.

This project is also a **learning exercise**. The goal is not only to ship a
working application, but to understand the tools and concepts along the way:

- The **Vala** programming language and how it compiles to C.
- **FFI** (Foreign Function Interface) and how Vala talks to C libraries.
- **Static vs. shared libraries** and why that matters for cross-compilation.
- **Cross-compilation** and how Meson handles it.
- **Window manager integration** on the Kindle (AwesomeWM fork).

---

## 2. High-level goals

1. Replace the C++/GTK2 skeleton with a Vala/C codebase.
2. Keep the existing Meson build system and cross-file workflow.
3. Use only libraries already present in the Kindle sysroot:
   `gtk+-2.0`, `glib-2.0`, `gio-2.0`, `libxml-2.0`, `sqlite3`, `libcurl`, `cjson`,
   `lipc`.
4. Cache feeds and articles locally in SQLite for offline reading.
5. Support the **FreshRSS** Google Reader API for feed sync.
6. Provide a fallback RSS/Atom parser for non-FreshRSS feeds.
7. Respect Kindle window-manager conventions.
8. Build and run natively on the host for fast development, then cross-compile
   for the Kindle for final testing.

---

## 3. Why Vala?

Vala is a modern, object-oriented language that feels similar to C# or Java but compiles to plain C. That makes it ideal for GTK/GObject projects because:

- It has first-class support for GObject, signals, and GTK.
- The generated C code can be compiled with any C compiler, including our ARM cross-compiler.
- We do not need a runtime on the target device beyond the normal GLib/GTK libraries that are already there.

The Vala compiler (`valac`) is a **transpiler**: it reads `.vala` files and emits `.c` files. Those `.c` files are then compiled and linked by the C compiler.

---

## 4. What is an FFI?

**FFI** stands for **Foreign Function Interface**. It is a mechanism that allows
code written in one language to call functions written in another language.

In this project, Vala needs to call functions from C libraries that do not have
official Vala bindings. To do that, we write a small **Vala API file** (`.vapi`)
that tells the Vala compiler:

- The C function names and signatures.
- The C types used by the library.
- How Vala types map to C types.

For example, if a C library has this function:

```c
int my_c_function(const char* name, int count);
```

We can expose it to Vala with a `.vapi` entry:

```vala
[CCode (cname = "my_c_function")]
int my_c_function (string name, int count);
```

When `valac` sees this, it generates C code that calls the real
`my_c_function()` from the library. The C linker then resolves that symbol either from a shared library (`.so`) or a static archive (`.a`).

### Why do we need FFI in kindlerss?

The following libraries are present in the Kindle sysroot but do **not** come with Vala bindings on the host, so we must write them ourselves:

| Library | Why we bind it |
|---------|----------------|
| **libcurl** | HTTP client for fetching feeds and talking to FreshRSS. |
| **cjson** | JSON parser for FreshRSS API responses. |
| **lipc** | Amazon Kindle IPC library for screen refresh and power hints. |

Libraries like GTK, GLib, GIO, SQLite, and libxml already have official `.vapi` files on the host, so we can use them directly.

---

## 5. Static libraries vs. shared libraries

When a program uses a library, the linker can combine them in two ways:

### Shared libraries (`.so` on Linux)

- The library file is loaded at runtime, not copied into the executable.
- The executable stays small.
- Multiple programs can share the same library in memory.
- The target device must have the library installed.
- On the Kindle, GTK, GLib, and libcurl are shared libraries already provided by the system.

### Static libraries (`.a` on Linux)

- The linker copies the required object code directly into the final executable.
- The executable becomes larger.
- The executable does not depend on the library being present at runtime.
- Useful for libraries you want to ship with the application.

### What will kindlerss use?

- **Shared linking** for system libraries (GTK, GLib, SQLite, libcurl, cjson, libxml) because they are already on the Kindle and shipping duplicates would waste space.
- The `kindlerss` binary itself will be a dynamic executable that resolves its dependencies at runtime.

Because Vala compiles to C, the linking step is identical to a normal C program.
Meson will call the cross-compiler's linker and use the `.pc` files from the Kindle sysroot to find the correct shared libraries.

---

## 6. Cross-compilation strategy

Meson has built-in support for Vala cross-compilation:

1. `valac` runs on the **host** (x86_64) and turns `.vala` files into `.c` files.
2. The **ARM cross GCC** (`arm-kindlehf-linux-gnueabihf-gcc`) compiles those `.c` files into ARM machine code.
3. Meson uses the cross-file to find the right compiler, linker, sysroot, and `pkg-config` library path.

The sysroot at
`/home/davi/Projects/kindle-stuff/x-tools/arm-kindlehf-linux-gnueabihf/arm-kindlehf-linux-gnueabihf/sysroot`
contains the Kindle headers and `.pc` files. Meson will use those instead of the host libraries.

### Native builds for development

During development, we build on the host so we can test quickly without copying anything to the Kindle. The host has `valac`, GTK2 headers, and now the `libcurl4-openssl-dev` and `libcjson-dev` packages installed. The same Meson project will produce a native `kindlerss` binary when no cross-file is provided.

---

## 7. Dependencies

### Build-time (host)

| Package | Purpose |
|---------|---------|
| `valac` | Vala compiler that emits C code. |
| `libgtk2.0-dev` | GTK+ 2.0 headers and `.pc` file. |
| `libglib2.0-dev` | GLib/GObject headers. |
| `libsqlite3-dev` | SQLite headers. |
| `libxml2-dev` | libxml2 headers. |
| `libcurl4-openssl-dev` | libcurl headers. |
| `libcjson-dev` | cJSON headers. |

### Run-time (Kindle sysroot)

| Library | Version in sysroot | Purpose |
|---------|-------------------|---------|
| `gtk+-2.0` | 2.24.33 | User interface. |
| `glib-2.0` | 2.82.4 | GObject, main loop, data structures. |
| `gio-2.0` | (part of GLib) | File I/O, networking helpers. |
| `sqlite3` | (available) | Local article cache. |
| `libxml-2.0` | (available) | RSS/Atom fallback parsing. |
| `libcurl` | 7.86.0 | HTTP client. |
| `cjson` | (available) | JSON parsing for FreshRSS API. |
| `lipc` | (available) | Kindle IPC for screen refresh/power. |

---

## 8. AwesomeWM window title hint

The Kindle uses a fork of AwesomeWM. Every window must have a title in a specific key-value format. The keys are separated by underscores.

For `kindlerss`, the main window title will be:

```
L:A_N:application_PC:N_ID:org.kindlerss.rssreader
```

Breakdown:

| Key | Value | Meaning |
|-----|-------|---------|
| `L` | `A` | APP layer (normal application window). |
| `N` | `application` | Window role: application. |
| `PC` | `N` | No persistent chrome; maximizes e-ink screen space. |
| `ID` | `org.kindlerss.rssreader` | Application identifier. |

See `KINDLE-WM.md` for the full specification.

---

## 9. Application architecture

```
src/
├── main.vala                  # Entry point, command-line / config init
├── application.vala           # Application lifecycle, settings
├── config.vala                # FreshRSS URL, credentials, sync policy
├── kindle/
│   ├── wm_hints.vala          # Build and set the AwesomeWM title
│   └── lipc.vala              # FFI wrapper for Kindle LIPC
├── net/
│   ├── curl.vala              # libcurl FFI wrapper (GET/POST)
│   └── freshrss_client.vala   # FreshRSS Google Reader API client
├── parse/
│   ├── rss_parser.vala        # RSS/Atom fallback parser using libxml2
│   └── json_models.vala       # Map cjson data to Vala objects
├── store/
│   ├── database.vala          # SQLite schema and queries
│   ├── feed.vala              # Feed model
│   └── article.vala           # Article model
└── ui/
    ├── main_window.vala       # Main GTK2 window
    ├── feed_list.vala         # Feed list sidebar
    ├── article_list.vala      # Article list
    └── article_view.vala      # Article reading pane
```

---

## 10. FreshRSS API overview

FreshRSS implements the **Google Reader API**. The client will follow this flow:

1. **Login**
   - `POST /api/greader.php/accounts/ClientLogin`
   - Body: `Email=<user>&Passwd=<api_password>`
   - Response contains `Auth=<token>`.

2. **Authenticated requests**
   - Add header: `Authorization: GoogleLogin auth=<token>`.

3. **List feeds**
   - `GET /api/greader.php/reader/api/0/subscription/list?output=json`

4. **Fetch unread articles**
   - `GET /api/greader.php/reader/api/0/stream/contents/reading-list?output=json&n=50&xt=user/-/state/com.google/read`

5. **Mark as read / starred**
   - `POST /api/greader.php/reader/api/0/edit-tag`

All JSON responses are parsed with **cjson** through our FFI binding.

---

## 11. Implementation phases

| Phase | Goal | What we learn |
|-------|------|---------------|
| **0** | Rename project, convert Meson to Vala/C, build a hello-GTK2 Vala binary on the host. | Vala build basics, Meson language setup. |
| **1** | Write a minimal libcurl FFI and fetch a raw URL. | FFI mechanics, C header mapping. |
| **2** | Write a minimal cjson FFI and parse FreshRSS login response. | Nested C structs, memory ownership. |
| **3** | Design SQLite schema and store feeds/articles. | GObject + SQLite, offline cache. |
| **4** | Implement FreshRSS client: login, list feeds, fetch articles. | API design, async/sync network code. |
| **5** | Write RSS/Atom fallback parser with libxml2. | XML parsing, fallback strategy. |
| **6** | Build GTK2 UI: feed list, article list, article reader. | GTK2 in Vala, e-ink UI considerations. |
| **7** | Add Kindle WM hints and LIPC screen refresh. | Target-specific integration. |
| **8** | Cross-compile with `builddir_kindlehf` and test on the Kindle. | Full cross-compilation flow. |

---

## 12. Build commands

### Native development build

```bash
meson setup builddir
meson compile -C builddir ./builddir/kindlerss
```

### Kindle cross-compilation build

```bash
meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_kindlehf
meson compile -C builddir_kindlehf
```

---

## 13. Educational checkpoints

Throughout development, the following concepts should be explicitly understood:

- **Vala compilation pipeline**: `.vala` → `.c` → `.o` → executable.
- **VAPI files**: how they bridge Vala and C.
- **C memory management**: who owns strings and structs returned by C libraries.
- **pkg-config**: how Meson finds headers and libraries.
- **Sysroot**: why cross-compilation needs a separate root filesystem.
- **Dynamic linking**: why the Kindle binary is small but needs libraries at runtime.
- **Static linking option**: when and why we might choose it instead.

---

## 14. Next step

Start **Phase 0**: update `meson.build` to use Vala/C, rename the project to
`kindlerss`, and create a minimal `src/main.vala` that opens a GTK2 window.
