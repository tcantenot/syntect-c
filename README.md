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

| Function | Description |
|---|---|
| `syntect_new()` | Create a highlighter context |
| `syntect_free(ctx)` | Destroy a context |
| `syntect_highlight(ctx, code, ext, theme)` | Highlight code, returns ANSI string |
| `syntect_free_string(s)` | Free a highlighted string |
| `syntect_list_themes(ctx, buf, len)` | List available theme names |
| `syntect_list_extensions(ctx, buf, len)` | List supported file extensions |

Built-in themes: `base16-ocean.dark`, `base16-ocean.light`,
`base16-eighties.dark`, `base16-mocha.dark`, `InspiredGitHub`,
`Solarized (dark)`, `Solarized (light)`.
