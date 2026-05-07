use std::{fs, path::Path};

fn main() {
    let themes_dir = Path::new("../themes");

    let out_dir = std::env::var("OUT_DIR").unwrap();
    let out_path = Path::new(&out_dir).join("themes.rs");

    // Re-run if the themes directory itself changes (files added/removed).
    println!("cargo:rerun-if-changed=../themes");

    let mut entries: Vec<(String, String)> = Vec::new();

    if let Ok(dir) = fs::read_dir(themes_dir) {
        let mut paths: Vec<_> = dir
            .flatten()
            .map(|e| e.path())
            .filter(|p| p.extension().and_then(|e| e.to_str()) == Some("tmTheme"))
            .collect();
        paths.sort();

        for path in paths {
            let name = path.file_stem().unwrap().to_str().unwrap().to_owned();
            let abs  = fs::canonicalize(&path).unwrap();
            // Use forward slashes so the path is valid inside a Rust string literal on all platforms.
            let abs_str = abs.to_string_lossy().replace('\\', "/");
            println!("cargo:rerun-if-changed={}", path.display());
            entries.push((abs_str, name));
        }
    }

    // Generate:
    //   fn load_extra_themes(ts: &mut ThemeSet) { ... }
    let mut code = String::new();
    code.push_str("fn load_extra_themes(ts: &mut ThemeSet) {\n");
    for (path, name) in &entries {
        code.push_str(&format!(
            "    if let Ok(t) = ThemeSet::load_from_reader(\
             &mut std::io::Cursor::new(include_str!(\"{path}\").as_bytes())) \
             {{ ts.themes.insert(\"{name}\".to_owned(), t); }}\n"
        ));
    }
    code.push_str("}\n");

    fs::write(&out_path, &code).unwrap();
}
