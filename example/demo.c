#include <stdio.h>
#include <stdlib.h>
#include "syntect.h"

static void section(const char *t) { printf("\n\033[1;36m=== %s ===\033[0m\n", t); }
static void print_item(const char *item, void *userdata) { (void)userdata; puts(item); }

static const char *C_CODE =
    "#include <stdio.h>\n"
    "long factorial(int n) {\n"
    "    if (n <= 1) return 1;\n"
    "    return n * factorial(n - 1);\n"
    "}\n"
    "int main(void) {\n"
    "    for (int i = 0; i < 10; i++)\n"
    "        printf(\"  %d! = %ld\\n\", i, factorial(i));\n"
    "    return 0;\n"
    "}\n";

static const char *PY_CODE =
    "def fibonacci(n):\n"
    "    a, b = 0, 1\n"
    "    result = []\n"
    "    for _ in range(n):\n"
    "        result.append(a)\n"
    "        a, b = b, a + b\n"
    "    return result\n"
    "print(fibonacci(10))\n";

int main(void) {
    SyntectCtx *ctx = syntect_new();
    if (!ctx) { fputs("syntect_new() failed\n", stderr); return 1; }

    section("Available themes");
    syntect_list_themes(ctx, print_item, NULL);

    section("C — base16-ocean.dark");
    char *hl = syntect_highlight(ctx, C_CODE, "c", "base16-ocean.dark");
    if (hl) { fputs(hl, stdout); syntect_free_string(hl); }

    section("Python — Solarized (dark)");
    hl = syntect_highlight(ctx, PY_CODE, "py", "Solarized (dark)");
    if (hl) { fputs(hl, stdout); syntect_free_string(hl); }

    section("Error cases");
    hl = syntect_highlight(ctx, "x=1\n", "unknownext", "base16-ocean.dark");
    printf("Unknown ext => %s\n", hl ? "plain text fallback" : "NULL");
    if (hl) syntect_free_string(hl);

    hl = syntect_highlight(ctx, "x=1\n", "py", "no-such-theme");
    printf("Bad theme   => %s\n", hl ? "non-null (unexpected)" : "NULL (correct)");

    syntect_free(ctx);
    puts("\n\033[1;32mDone.\033[0m");
    return 0;
}
