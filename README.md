# syntect-c

Pre-built C bindings for [syntect](https://github.com/trishume/syntect).
Consumers need no Rust toolchain — just a C compiler and CMake.

## Supported platforms

| Directory | Target triple | Static | Shared |
|---|---|---|---|
| `lib/linux-x86_64`    | `x86_64-unknown-linux-gnu`   | `libsyntect_c.a` | `libsyntect_c.so` |
| `lib/linux-aarch64`   | `aarch64-unknown-linux-gnu`  | `libsyntect_c.a` | `libsyntect_c.so` |
| `lib/macos-universal` | fat binary (x86_64 + arm64)  | `libsyntect_c.a` | `libsyntect_c.dylib` |
| `lib/windows-x86_64`  | `x86_64-pc-windows-msvc`     | `syntect_c.lib`  | `syntect_c.dll` + `syntect_c.dll.lib` |

Debug symbols are split into separate files alongside each shared library
(`libsyntect_c.so.debug`, `libsyntect_c.dSYM/`, `syntect_c.pdb`).
Static libraries embed debug info directly.

## Using in your C project

### Using git submodule and CMake

```bash
git submodule add <url> third_party/syntect-c
git submodule update --init
```

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/third_party/syntect-c/cmake")
find_package(SyntectC REQUIRED)
target_link_libraries(my_target PRIVATE SyntectC::SyntectC)
```

### Manual setup

Copy in your project the library header (`include/syntect.h`) and the appropriate precompiled binary (`lib/<platform>`) and link against it.


### Code example

```c
#include <stdlib.h>
#include <string.h>
#include "syntect.h"

static void * my_alloc(size_t size, void *userdata) { (void)userdata; return malloc(size); }
static void my_free(void * ptr) { free(ptr); }

SyntectCtx *ctx = syntect_new();
char *hl = syntect_highlight(ctx, code, strlen(code), "c", "Monokai Mod", my_alloc, NULL);
fputs(hl, stdout);
my_free(hl);
syntect_free(ctx);
```

## Building the pre-built libraries

```bash
# Linux / macOS
bash scripts/build-syntect.sh

# Windows (Developer PowerShell)
.\scripts\build-syntect.ps1
```

Or use the GitHub Actions workflow — push to the repo and it builds and
commits all platforms automatically. Trigger the first build manually via
Actions → "Build syntect-c prebuilts" → "Run workflow".

## API

### Lifecycle

| Function | Description |
|---|---|
| `syntect_new()` | Create a highlighter context with built-in syntaxes and themes. Returns an owned pointer — must be freed with `syntect_free()`. |
| `syntect_free(ctx)` | Destroy a context and free its memory. Safe to call with NULL. |

### Highlighting

| Function | Description |
|---|---|
| `syntect_highlight(ctx, code, code_len, ext, theme, alloc, userdata)` | Highlight `code` (UTF-8, `code_len` bytes, null terminator not required) using the syntax for `ext` and the named `theme`. `alloc(size, userdata)` is called exactly once to obtain the output buffer. Returns the pointer from `alloc`, or NULL on error (null argument, `alloc` returned NULL, unknown theme, invalid UTF-8). Falls back to plain text if the extension is not recognised. Caller frees the result with their own allocator. |

### Themes

| Function | Description |
|---|---|
| `syntect_list_themes(ctx, cb, userdata)` | Call `cb` once per available theme name, in case-insensitive sorted order. Returns 1 on success, 0 if `ctx` or `cb` is NULL. |
| `syntect_load_theme(ctx, path, name)` | Load a `.tmTheme` file from disk and register it as `name` for use in `syntect_highlight()`. Returns 1 on success, 0 on failure. |
| `syntect_load_theme_str(ctx, xml, name)` | Parse a `.tmTheme` XML string in memory and register it as `name`. Returns 1 on success, 0 on failure. |

### Syntax discovery

| Function | Description |
|---|---|
| `syntect_list_extensions(ctx, cb, userdata)` | Call `cb` once per supported file extension, in sorted, deduplicated order. Returns 1 on success, 0 if `ctx` or `cb` is NULL. |

### Allocator callback

`syntect_highlight` calls your allocator exactly once with the required buffer size
(including the null terminator), then writes the ANSI string into that buffer and returns it.
You free the pointer with whatever allocator backs `alloc` — no library function needed.

```c
typedef void *(*syntect_alloc_fn)(size_t size, void * userdata);
```

```c
// malloc-backed — free with free()
static void * heap_alloc(size_t size, void * userdata) {
    (void)userdata;
    return malloc(size);
}
char * hl = syntect_highlight(ctx, code, strlen(code), "c", "Monokai Mod", heap_alloc, NULL);
fputs(hl, stdout);
free(hl);

// Arena-backed — no individual free needed
static void * arena_alloc(size_t size, void * userdata) {
    return arena_push((Arena *)userdata, size);
}
char * hl2 = syntect_highlight(ctx, code, code_len, "rs", "InspiredGitHub", arena_alloc, &my_arena);
fputs(hl2, stdout);
// hl2 lives until the arena is reset/freed
```

### Callback-based iteration

`syntect_list_themes` and `syntect_list_extensions` deliver items one at a time via a
caller-supplied callback. The `item` pointer is only valid for the duration of the call —
copy it if you need to store it.

```c
typedef void (*syntect_item_callback)(const char * item, void * userdata);
```

```c
// Simple: print each item
static void print_item(const char * item, void * userdata) {
    (void)userdata;
    puts(item);
}
syntect_list_themes(ctx, print_item, NULL);

// Collect into a dynamic array
static void collect(const char *item, void *userdata) {
    MyArray * arr = userdata;
    array_push(arr, strdup(item));
}
MyArray themes = {0};
syntect_list_themes(ctx, collect, &themes);
```

### Embedded themes
* `base16-eighties.dark`
* `base16-mocha.dark`
* `base16-ocean.dark`
* `base16-ocean.light`
* `GitHub`
* `Heroku`
* `InspiredGitHub`
* `Lowlight`
* `minimal Theme`
* `Monokai`
* `Monokai Dark`
* `Monokai Mod`
* `Resesif`
* `Solarized (dark)`
* `Solarized (light)`
* `Tomorrow`
* `Tomorrow Night`
* `Tomorrow-Night-Eighties`

## License

`syntect-c` is licensed under the MIT License.
<br/>See `License.txt` and `licenses` folder.
