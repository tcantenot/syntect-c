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
char *hl = syntect_highlight(ctx, code, "c", "Monokai Mod");
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
| `syntect_list_themes(ctx, cb, userdata)` | Call `cb` once per available theme name, in case-insensitive sorted order. Returns 1 on success, 0 if `ctx` or `cb` is NULL. |
| `syntect_load_theme(ctx, path, name)` | Load a `.tmTheme` file from disk and register it as `name` for use in `syntect_highlight()`. Returns 1 on success, 0 on failure. |
| `syntect_load_theme_str(ctx, xml, name)` | Parse a `.tmTheme` XML string in memory and register it as `name`. Returns 1 on success, 0 on failure. |

### Syntax discovery

| Function | Description |
|---|---|
| `syntect_list_extensions(ctx, cb, userdata)` | Call `cb` once per supported file extension, in sorted, deduplicated order. Returns 1 on success, 0 if `ctx` or `cb` is NULL. |

### Callback-based iteration

`syntect_list_themes` and `syntect_list_extensions` deliver items one at a time via a
caller-supplied callback. The `item` pointer is only valid for the duration of the call —
copy it if you need to store it.

```c
typedef void (*syntect_item_callback)(const char *item, void *userdata);
```

```c
// Simple: print each item
static void print_item(const char *item, void *userdata) {
    (void)userdata;
    puts(item);
}
syntect_list_themes(ctx, print_item, NULL);

// Collect into a dynamic array
static void collect(const char *item, void *userdata) {
    MyArray *arr = userdata;
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
