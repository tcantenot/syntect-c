#ifndef SYNTECT_H
#define SYNTECT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct SyntectCtx SyntectCtx;

/**
 * Creates a new highlighter context loaded with the built-in syntax and theme sets.
 *
 * The caller owns the returned pointer and must destroy it with syntect_free() when done.
 */
SyntectCtx * syntect_new(void);

/**
 * Destroys a context created by syntect_new() and frees all associated memory.
 *
 * Safe to call with a null pointer.
 */
void syntect_free(SyntectCtx * ctx);

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
char * syntect_highlight(const SyntectCtx * ctx,
                        const char * code,
                        const char * extension,
                        const char * theme_name);

/**
 * Frees a string returned by syntect_highlight().
 *
 * Safe to call with a null pointer.
 */
void syntect_free_string(char * s);

/**
 * Callback invoked once per item during syntect_list_themes() / syntect_list_extensions().
 *
 * @param item     Null-terminated string (theme name or file extension).
 *                 Valid only for the duration of the callback — copy if needed.
 * @param userdata Opaque pointer forwarded unchanged from the list call.
 */
typedef void (*syntect_item_callback)(const char * item, void * userdata);

/**
 * Calls cb once for each available theme name, in case-insensitive sorted order.
 *
 * @param ctx      Highlighter context created by syntect_new().
 * @param cb       Callback invoked once per theme name.
 * @param userdata Forwarded to cb unchanged; may be NULL.
 * @return         1 on success, 0 if ctx or cb is null.
 */
int syntect_list_themes(const SyntectCtx * ctx,
                        syntect_item_callback cb,
                        void * userdata);

/**
 * Loads a .tmTheme file from disk and registers it under theme_name.
 *
 * theme_path may be an absolute or relative path to the .tmTheme file.
 * After a successful call, theme_name can be passed to syntect_highlight().
 *
 * @param ctx        Highlighter context created by syntect_new().
 * @param theme_path Path to the .tmTheme file.
 * @param theme_name Name to register the theme under for use in syntect_highlight().
 * @return           1 on success, 0 on failure (null argument, file not found, invalid format, etc.)
 */
int syntect_load_theme(SyntectCtx * ctx,
                       const char * theme_path,
                       const char * theme_name);

/**
 * Parses a .tmTheme XML string and registers it under theme_name.
 *
 * The theme is parsed entirely in memory — no file I/O is performed.
 * After a successful call, theme_name can be passed to syntect_highlight().
 *
 * @param ctx        Highlighter context created by syntect_new().
 * @param theme_xml  Null-terminated string containing the full .tmTheme XML content.
 * @param theme_name Name to register the theme under for use in syntect_highlight().
 * @return           1 on success, 0 on failure (null argument, invalid XML, bad format, etc.)
 */
int syntect_load_theme_str(SyntectCtx * ctx,
                           const char * theme_xml,
                           const char * theme_name);

/**
 * Calls cb once for each supported file extension, in sorted, deduplicated order.
 *
 * @param ctx      Highlighter context created by syntect_new().
 * @param cb       Callback invoked once per extension.
 * @param userdata Forwarded to cb unchanged; may be NULL.
 * @return         1 on success, 0 if ctx or cb is null.
 */
int syntect_list_extensions(const SyntectCtx * ctx,
                            syntect_item_callback cb,
                            void * userdata);

#ifdef __cplusplus
}
#endif

#endif /* SYNTECT_H */
