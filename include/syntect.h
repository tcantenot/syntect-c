#ifndef SYNTECT_H
#define SYNTECT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct SyntectCtx SyntectCtx;

SyntectCtx *syntect_new(void);
void        syntect_free(SyntectCtx *ctx);

char   *syntect_highlight(const SyntectCtx *ctx,
                           const char *code,
                           const char *extension,
                           const char *theme_name);
void    syntect_free_string(char *s);

int64_t syntect_list_themes(const SyntectCtx *ctx,
                             char *buf, size_t buf_len);
int64_t syntect_list_extensions(const SyntectCtx *ctx,
                                 char *buf, size_t buf_len);

#ifdef __cplusplus
}
#endif

#endif /* SYNTECT_H */
