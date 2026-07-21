fn main() {
    // Watch the whole vendored UnRAR tree so additions/removals trigger a rebuild.
    println!("cargo:rerun-if-changed=vendor/unrar");

    // IMPORTANT: use *target* OS, not host `cfg!(windows)`. Cross-compiling from
    // Windows to Android/iOS must not pull Windows-only translation units or link
    // Windows system libraries.
    let target_os = std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    let target_vendor = std::env::var("CARGO_CFG_TARGET_VENDOR").unwrap_or_default();
    let is_windows = target_os == "windows";
    let is_android = target_os == "android";

    if is_windows {
        println!("cargo:rustc-flags=-lpowrprof");
        println!("cargo:rustc-link-lib=shell32");
        println!("cargo:rustc-link-lib=advapi32");
        if std::env::var("CARGO_CFG_TARGET_ENV").unwrap_or_default() == "gnu" {
            println!("cargo:rustc-link-lib=pthread");
        }
    } else if !is_android {
        // Android uses Bionic; do not force libpthread.
        println!("cargo:rustc-link-lib=pthread");
    }

    let mut names = vec![
        "strlist",
        "strfn",
        "pathfn",
        "smallfn",
        "global",
        "file",
        "filefn",
        "filcreat",
        "archive",
        "arcread",
        "unicode",
        "system",
        "crypt",
        "crc",
        "rawread",
        "encname",
        "match",
        "timefn",
        "rdwrfn",
        "consio",
        "options",
        "errhnd",
        "rarvm",
        "secpassword",
        "rijndael",
        "getbits",
        "sha1",
        "sha256",
        "blake2s",
        "hash",
        "extinfo",
        "extract",
        "volume",
        "list",
        "find",
        "unpack",
        "headers",
        "threadpool",
        "rs16",
        "cmddata",
        "ui",
        "filestr",
        "scantree",
        "dll",
        "qopen",
        "largepage",
    ];
    if is_windows {
        names.push("isnt");
        names.push("motw");
    }

    let files: Vec<String> = names
        .iter()
        .map(|&s| format!("vendor/unrar/{s}.cpp"))
        .collect();

    let mut build = cc::Build::new();
    build
        .cpp(true)
        .opt_level(2)
        .std("c++14")
        .cpp_link_stdlib(None)
        .warnings(false)
        .extra_warnings(false)
        .flag_if_supported("-stdlib=libc++")
        .flag_if_supported("-fPIC")
        .flag_if_supported("-Wno-switch")
        .flag_if_supported("-Wno-parentheses")
        .flag_if_supported("-Wno-macro-redefined")
        .flag_if_supported("-Wno-dangling-else")
        .flag_if_supported("-Wno-logical-op-parentheses")
        .flag_if_supported("-Wno-unused-parameter")
        .flag_if_supported("-Wno-unused-variable")
        .flag_if_supported("-Wno-unused-function")
        .flag_if_supported("-Wno-missing-braces")
        .flag_if_supported("-Wno-unknown-pragmas")
        .flag_if_supported("-Wno-deprecated-declarations")
        .define("_FILE_OFFSET_BITS", Some("64"))
        .define("_LARGEFILE_SOURCE", None)
        .define("RAR_SMP", None)
        .define("RARDLL", None);

    if is_android {
        // Bionic lacks lutimes on many API levels; our vendored ulinks.cpp
        // falls back when this is defined.
        build.define("UNRAR_NG_ANDROID", None);
    }

    let feature_linux_batch_extract_utf8 =
        std::env::var("CARGO_FEATURE_LINUX_BATCH_EXTRACT_UTF8").is_ok();
    let force_utf8 = feature_linux_batch_extract_utf8
        && target_os != "windows"
        && target_vendor != "apple";
    if force_utf8 {
        build.define("UNRAR_NG_FORCE_UTF8", None);
    }

    build.files(&files).compile("libunrar.a");
}
