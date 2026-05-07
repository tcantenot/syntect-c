use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use syntect::easy::HighlightLines;
use syntect::highlighting::{Style, ThemeSet};
use syntect::parsing::SyntaxSet;
use syntect::util::{as_24_bit_terminal_escaped, LinesWithEndings};

pub struct SyntectCtx { ss: SyntaxSet, ts: ThemeSet }

#[unsafe(no_mangle)]
pub extern "C" fn syntect_new() -> *mut SyntectCtx {
    Box::into_raw(Box::new(SyntectCtx {
        ss: SyntaxSet::load_defaults_newlines(),
        ts: ThemeSet::load_defaults(),
    }))
}

/// Destroys a context created by [`syntect_new`] and frees all associated memory.
///
/// Safe to call with a null pointer.
#[unsafe(no_mangle)]
pub extern "C" fn syntect_free(ctx: *mut SyntectCtx) {
    if !ctx.is_null() { unsafe { drop(Box::from_raw(ctx)) }; }
}

/// Highlights `code` and returns a heap-allocated, null-terminated ANSI 24-bit color string.
///
/// The syntax is selected by matching `extension` (e.g. `"c"`, `"rs"`, `"py"`).
/// If no syntax matches the extension, plain-text is used as a fallback.
///
/// The returned string must be freed with [`syntect_free_string`].
///
/// Returns null on any error: null pointer argument, unknown `theme_name`, or invalid UTF-8.
#[unsafe(no_mangle)]
pub extern "C" fn syntect_highlight(
    ctx: *const SyntectCtx, code: *const c_char,
    extension: *const c_char, theme_name: *const c_char,
) -> *mut c_char {
    if ctx.is_null() || code.is_null() || extension.is_null() || theme_name.is_null() {
        return std::ptr::null_mut();
    }
    let ctx   = unsafe { &*ctx };
    let code  = match unsafe { CStr::from_ptr(code) }.to_str() { Ok(s) => s, Err(_) => return std::ptr::null_mut() };
    let ext   = match unsafe { CStr::from_ptr(extension) }.to_str() { Ok(s) => s, Err(_) => return std::ptr::null_mut() };
    let tname = match unsafe { CStr::from_ptr(theme_name) }.to_str() { Ok(s) => s, Err(_) => return std::ptr::null_mut() };
    let syntax = ctx.ss.find_syntax_by_extension(ext)
        .unwrap_or_else(|| ctx.ss.find_syntax_plain_text());
    let theme = match ctx.ts.themes.get(tname) { Some(t) => t, None => return std::ptr::null_mut() };
    let mut hl = HighlightLines::new(syntax, theme);
    let mut out = String::with_capacity(code.len() * 2);
    for line in LinesWithEndings::from(code) {
        let ranges: Vec<(Style, &str)> = match hl.highlight_line(line, &ctx.ss) {
            Ok(r) => r, Err(_) => return std::ptr::null_mut(),
        };
        out.push_str(&as_24_bit_terminal_escaped(&ranges, false));
    }
    out.push_str("\x1b[0m");
    match CString::new(out) { Ok(s) => s.into_raw(), Err(_) => std::ptr::null_mut() }
}

/// Frees a string returned by [`syntect_highlight`].
///
/// Safe to call with a null pointer.
#[unsafe(no_mangle)]
pub extern "C" fn syntect_free_string(s: *mut c_char) {
    if !s.is_null() { unsafe { drop(CString::from_raw(s)) }; }
}

/// Writes a newline-separated, sorted list of available theme names into `buf`.
///
/// `buf_len` must include space for the null terminator.
///
/// Returns the number of bytes written (excluding the null terminator) on success,
/// or -1 if `ctx` or `buf` is null, or if the buffer is too small.
#[unsafe(no_mangle)]
pub extern "C" fn syntect_list_themes(ctx: *const SyntectCtx, buf: *mut c_char, buf_len: usize) -> i64 {
    if ctx.is_null() || buf.is_null() { return -1; }
    let ctx = unsafe { &*ctx };
    let mut names: Vec<&str> = ctx.ts.themes.keys().map(|s| s.as_str()).collect();
    names.sort_unstable();
    write_buf(names.join("\n").as_bytes(), buf, buf_len)
}


/// Writes a newline-separated, sorted, deduplicated list of all supported file extensions
/// into `buf`.
///
/// `buf_len` must include space for the null terminator.
///
/// Returns the number of bytes written (excluding the null terminator) on success,
/// or -1 if `ctx` or `buf` is null, or if the buffer is too small.
#[unsafe(no_mangle)]
pub extern "C" fn syntect_list_extensions(ctx: *const SyntectCtx, buf: *mut c_char, buf_len: usize) -> i64 {
    if ctx.is_null() || buf.is_null() { return -1; }
    let ctx = unsafe { &*ctx };
    let mut exts: Vec<&str> = ctx.ss.syntaxes().iter()
        .flat_map(|s| s.file_extensions.iter().map(|e| e.as_str())).collect();
    exts.sort_unstable(); exts.dedup();
    write_buf(exts.join("\n").as_bytes(), buf, buf_len)
}

fn write_buf(bytes: &[u8], buf: *mut c_char, buf_len: usize) -> i64 {
    if bytes.len() + 1 > buf_len { return -1; }
    unsafe {
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), buf as *mut u8, bytes.len());
        *buf.add(bytes.len()) = 0;
    }
    bytes.len() as i64
}
