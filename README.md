# syntect-c

Pre-built C bindings for [syntect](https://github.com/trishume/syntect).
Consumers need no Rust toolchain — just a C compiler and CMake.

## Supported platforms

| Directory | Target triple |
|---|---|
| `lib/linux-x86_64`    | `x86_64-unknown-linux-gnu` |
| `lib/linux-aarch64`   | `aarch64-unknown-linux-gnu` |
| `lib/macos-universal` | fat binary (x86_64 + arm64) |
| `lib/windows-x86_64`  | `x86_64-pc-windows-msvc` |

## Using in your C project

```bash
git submodule add <url> third_party/syntect-c
git submodule update --init
```

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/third_party/syntect-c/cmake")
find_package(SyntectC REQUIRED)
target_link_libraries(my_target PRIVATE SyntectC::SyntectC)
```

```c
#include "syntect.h"
SyntectCtx *ctx = syntect_new();
char *hl = syntect_highlight(ctx, code, "c", "base16-ocean.dark");
fputs(hl, stdout);
syntect_free_string(hl);
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
| `syntect_highlight(ctx, code, ext, theme)` | Highlight `code` using the syntax for `ext` and the named `theme`. Returns a heap-allocated ANSI 24-bit color string, or NULL on error. Falls back to plain text if the extension is not recognised. Must be freed with `syntect_free_string()`. |
| `syntect_free_string(s)` | Free a string returned by `syntect_highlight()`. Safe to call with NULL. |

### Themes

| Function | Description |
|---|---|
| `syntect_list_themes(ctx, buf, len)` | Write a newline-separated, sorted list of available theme names into `buf`. Returns bytes written or -1 on error/overflow. |
| `syntect_load_theme(ctx, path, name)` | Load a `.tmTheme` file from disk and register it as `name` for use in `syntect_highlight()`. Returns 1 on success, 0 on failure. |
| `syntect_load_theme_str(ctx, xml, name)` | Parse a `.tmTheme` XML string in memory and register it as `name`. Returns 1 on success, 0 on failure. |

### Syntax discovery

| Function | Description |
|---|---|
| `syntect_list_extensions(ctx, buf, len)` | Write a newline-separated, sorted, deduplicated list of all supported file extensions into `buf`. Returns bytes written or -1 on error/overflow. |

### Buffer-based functions

`syntect_list_themes` and `syntect_list_extensions` write into a caller-supplied buffer.
Pass a buffer large enough for the output plus a null terminator. If the buffer is too
small, the function returns -1 and leaves the buffer unchanged. A good starting size is
4096 bytes; allocate more if you get -1.

```c
char buf[4096];
int64_t n = syntect_list_themes(ctx, buf, sizeof(buf));
if (n >= 0) puts(buf);
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
