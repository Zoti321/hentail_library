# core/vendor

原生依赖目录，供 `hentai-core` 链接 **pdfium**（PDF 阅读/扫描）。

## Triple 矩阵

| 目录 | Rust TARGET 示例 | pdfium 产物 |
|------|------------------|-------------|
| `windows-x86_64` | `x86_64-pc-windows-msvc` | `pdfium.dll` |
| `windows-aarch64` | `aarch64-pc-windows-msvc` | `pdfium.dll` |
| `linux-x86_64` | `x86_64-unknown-linux-gnu` | `libpdfium.so` |
| `linux-aarch64` | `aarch64-unknown-linux-gnu` | `libpdfium.so` |
| `macos-x86_64` | `x86_64-apple-darwin` | `libpdfium.dylib` |
| `macos-aarch64` | `aarch64-apple-darwin` | `libpdfium.dylib` |
| `android-arm` | `armv7-linux-androideabi` | `libpdfium.so` |
| `android-arm64` | `aarch64-linux-android` | `libpdfium.so` |
| `android-x86` | `i686-linux-android` | `libpdfium.so` |
| `android-x64` | `x86_64-linux-android` | `libpdfium.so` |

**PDF / Android**：运行时按 soname 加载 `libpdfium.so`（打进 jniLibs）；`build.rs` 在交叉编译时校验 vendor 并写入 `NEEDED`。iOS 仍为 stub（`mobile_pdf.rs`）。

**RAR/CBR**：经 `unrar-ng` crate 静态编译 rarlab 解压库（仅 list/extract，无压缩 API）；Android / iOS 与桌面共用同一实现。

上游 `unrar-ng-sys` 的 `build.rs` 用 host `cfg(windows)` 选择 Windows 专用源文件，导致在 Windows 上交叉编译 Android 时误编 `isnt.cpp` / `motw.cpp`。本仓库以 `[patch.crates-io]` 使用 `core/vendor/crates/unrar-ng-sys`（按 **target OS** 选源，并为 Android 提供 `lutimes` 回退）。

交叉编译验收：`aarch64-linux-android` 的 `cargo check -p hentai-core` 已在 Windows + NDK 上通过；`aarch64-apple-ios` 需在 Mac 上补验。

**7z/CB7**：`sevenz-rust` 纯 Rust，无需本目录。

## 获取依赖

Flutter 本地开发推荐在仓库根目录运行 `scripts/setup-dev.ps1` / `scripts/setup-dev.sh`（含链接 `rust_builder` 与本节下载）。

仅下载 pdfium：

```bash
# Linux / macOS / Git Bash — 默认当前 host（macOS 拉双架构）
./core/vendor/fetch-native-deps.sh

# Android ABI（arm / arm64 / x86 / x64）
./core/vendor/fetch-native-deps.sh --android

# Windows PowerShell
./core/vendor/fetch-native-deps.ps1
./core/vendor/fetch-native-deps.ps1 --android
```

也可 `--platform=android-arm64,android-x64` 精确指定。

脚本从 [bblanchon/pdfium-binaries](https://github.com/bblanchon/pdfium-binaries/releases) 下载与 `manifest.json` 对齐的版本。

若目标平台目录缺失或不含 pdfium 动态库，`cargo build` 将**失败**（不会静默跳过）。

## Flutter 桌面构建

Windows 构建需将 `pdfium.dll` 复制到可执行文件旁。`app/rust_builder/windows/CMakeLists.txt` 已配置 bundling。

Android 构建由 `app/rust_builder/android/build.gradle` 在 cargokit 之后把对应 ABI 的 `libpdfium.so` 拷入 jniLibs。

## 环境变量

- `HENTAI_VENDOR_DIR`：覆盖默认 `core/vendor/<platform>` 路径（用于 CI/本地调试）。
