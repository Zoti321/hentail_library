use std::env;
use std::path::{Path, PathBuf};

fn needs_pdfium_vendor(target: &str) -> bool {
    // iOS remains on the mobile_pdf stub until a dedicated packaging pass.
    !target.contains("apple-ios")
}

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR"));
    let vendor_root = manifest_dir.join("../../vendor");
    let target = env::var("TARGET").expect("TARGET");
    if !needs_pdfium_vendor(&target) {
        return;
    }
    let platform_dir = resolve_vendor_dir(&vendor_root, &target);

    if !platform_dir.is_dir() {
        panic!(
            "缺少原生依赖目录: {}。请先运行 core/vendor/fetch-native-deps（Android 需加 --android）。",
            platform_dir.display()
        );
    }

    let pdfium_lib = find_pdfium_library(&platform_dir);
    if pdfium_lib.is_none() {
        panic!(
            "在 {} 中未找到 pdfium 动态库（pdfium.dll / libpdfium.so / libpdfium.dylib）。",
            platform_dir.display()
        );
    }

    let lib_dir = platform_dir
        .canonicalize()
        .unwrap_or(platform_dir)
        .display()
        .to_string();

    println!("cargo:rerun-if-changed={}", vendor_root.join("manifest.json").display());
    println!("cargo:rerun-if-env-changed=TARGET");
    println!("cargo:rerun-if-env-changed=HENTAI_VENDOR_DIR");

    if target.contains("android") {
        // Device load path ≠ host vendor path: verify + link NEEDED, bind by soname at runtime.
        println!("cargo:rustc-link-search=native={lib_dir}");
        println!("cargo:rustc-link-lib=dylib=pdfium");
        return;
    }

    println!("cargo:rustc-env=HENTAI_PDFIUM_LIB_DIR={lib_dir}");
}

fn resolve_vendor_dir(vendor_root: &Path, target: &str) -> PathBuf {
    if let Ok(dir) = env::var("HENTAI_VENDOR_DIR") {
        return PathBuf::from(dir);
    }
    let folder = if target.contains("android") {
        if target.contains("x86_64") {
            "android-x64"
        } else if target.contains("i686") {
            "android-x86"
        } else if target.contains("aarch64") {
            "android-arm64"
        } else if target.contains("arm") {
            "android-arm"
        } else {
            panic!("不支持的 Android 目标平台 triple: {target}");
        }
    } else if target.contains("windows") {
        if target.contains("aarch64") {
            "windows-aarch64"
        } else {
            "windows-x86_64"
        }
    } else if target.contains("linux") {
        if target.contains("aarch64") {
            "linux-aarch64"
        } else {
            "linux-x86_64"
        }
    } else if target.contains("apple") && target.contains("darwin") {
        if target.contains("aarch64") {
            "macos-aarch64"
        } else {
            "macos-x86_64"
        }
    } else {
        panic!("不支持的目标平台 triple: {target}");
    };
    vendor_root.join(folder)
}

fn find_pdfium_library(dir: &Path) -> Option<PathBuf> {
    for name in ["pdfium.dll", "libpdfium.so", "libpdfium.dylib"] {
        let candidate = dir.join(name);
        if candidate.is_file() {
            return Some(candidate);
        }
    }
    None
}
