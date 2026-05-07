#ifndef SYNTECT_H
#define SYNTECT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct SyntectCtx Syn/**
 * Creates a new highlighter context loaded with the built-in syntax and theme sets.
 *
 * The caller owns the returned pointer and must destroy it with syntect_free() when done.
 */
SyntectCtx *syntect_new(void);

/**
 * Destroys a context created by syntect_new() and frees all associated memory.
 *
 * Safe to call with a null pointer.
 */
void syntect_free(SyntectCtx *ctx);

/**
 * Highlights code and returns a heap-allocated, null-terminated ANSI 24-bit color string.
 *
 * The syntax is selected by matching extension (e.g. "c", "rs", "py"). If no syntax
 * matches the extension, plain-text is used as a fallback.
 *
 * @param ctx        Highlighter context created by syntect_new().
 * @param code       Null-terminated source code string to highlight.
 * @param extension  File extension used to detect the syntax (without leading dot).
 * @param theme_name Name of the theme to apply (see syntect_list_themes()).
 * @return           Heap-allocated ANSI string, or NULL on error (null argument,
 *                   unknown theme, invalid UTF-8). Must be freed with syntect_free_string().
 */
char *syntect_highlight(const SyntectCtx *ctx,
                           const char *code,
                           const char *extension,
                           const char *theme_name);

/**
 * Frees a string returned by syntect_highlight().
 *
 * Safe to call with a null pointer.
 */
void syntect_free_string(char *s);

/**
 * Writes a newline-separated, sorted list of available theme names into buf.
 *
 * buf_len must include space for the null terminator.
 *
 * @param ctx     Highlighter context created by syntect_new().
 * @param buf     Caller-supplied output buffer.
 * @param buf_len Size of buf in bytes (must fit the result plus null terminator).
 * @return        Number of bytes written (excluding null terminator) on success,
 *                or -1 if ctx or buf is null, or if the buffer is too small.
 */
int64_t syntect_list_themes(const SyntectCtx *ctx,
                             char *buf, size_t buf_len);

/**
 * Writes a newline-separated, sorted, deduplicated list of all supported file extensions
 * into buf.
 *
 * buf_len must include space for the null terminator.
 *
 * @param ctx     Highlighter context created by syntect_new().
 * @param buf     Caller-supplied output buffer.
 * @param buf_len Size of buf in bytes (must fit the result plus null terminator).
 * @return        Number of bytes written (excluding null terminator) on success,
 *                or -1 if ctx or buf is null, or if the buffer is too small.
 */
int64_t syntect_list_extensions(const SyntectCtx *ctx, char *buf, size_t buf_len);

#ifdef __cplusplus
}
#endif

#endif /* SYNTECT_H */
