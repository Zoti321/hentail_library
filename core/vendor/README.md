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
| `ios-device-arm64` | `aarch64-apple-ios` | `libpdfium.dylib` |
| `ios-simulator-arm64` | `aarch64-apple-ios-sim` | `libpdfium.dylib` |
| `ios-simulator-x64` | `x86_64-apple-ios` | `libpdfium.dylib` |

**PDF / Android**：运行时按 soname 加载 `libpdfium.so`（打进 jniLibs）；`build.rs` 在交叉编译时校验 vendor 并写入 `NEEDED`。

**PDF / iOS**：与桌面/Android 共用 `pdf.rs`（无 stub）。三份 `libpdfium.dylib`（真机 arm64 + 模拟器 arm64/x64）由 `build-ios-xcframework.sh` 合并为 `pdfium.xcframework`，经 CocoaPods `vendored_frameworks` 嵌入 App bundle 的 `Frameworks/`；运行时由 `pdfium-render` 按 bundle 路径 `dlopen` 绑定。`build.rs` 对 `apple-ios` 目标仅校验 vendor 存在（fail-fast），不写编译期链接标志。不支持 Mac Catalyst，不引入 Dart 侧 pdfium 插件。

**RAR/CBR**：经 `unrar-ng` crate 静态编译 rarlab 解压库（仅 list/extract，无压缩 API）；Android / iOS 与桌面共用同一实现。

上游 `unrar-ng-sys` 的 `build.rs` 用 host `cfg(windows)` 选择 Windows 专用源文件，导致在 Windows 上交叉编译 Android 时误编 `isnt.cpp` / `motw.cpp`。本仓库以 `[patch.crates-io]` 使用 `core/vendor/crates/unrar-ng-sys`（按 **target OS** 选源，并为 Android 提供 `lutimes` 回退）。

交叉编译验收：`aarch64-linux-android` 的 `cargo check -p hentai-core` 已在 Windows + NDK 上通过；`aarch64-apple-ios` 的 `cargo check` 与 iOS App 打包/运行需在 Mac（Xcode 工具链）上验证。

**7z/CB7**：`sevenz-rust` 纯 Rust，无需本目录。

## 获取依赖

Flutter 本地开发推荐在仓库根目录运行 `scripts/setup-dev.sh`（含链接 `rust_builder` 与本节下载；Windows 可用 Git Bash）。

仅下载 pdfium：

```bash
# Linux / macOS / Git Bash — 默认当前 host（macOS 拉双架构）
./core/vendor/fetch-native-deps.sh

# Android ABI（arm / arm64 / x86 / x64）
./core/vendor/fetch-native-deps.sh --android

# iOS（真机 arm64 + 模拟器 arm64/x64）
./core/vendor/fetch-native-deps.sh --ios

# Windows PowerShell
./core/vendor/fetch-native-deps.ps1
./core/vendor/fetch-native-deps.ps1 --android
./core/vendor/fetch-native-deps.ps1 --ios
```

也可 `--platform=android-arm64,ios-device-arm64` 精确指定。

## iOS：打包 pdfium.xcframework（仅 macOS）

拉取 iOS 三份 dylib 后，在 **macOS**（需 Xcode 工具链）上生成 App 可嵌入的 XCFramework：

```bash
./core/vendor/fetch-native-deps.sh --ios
./core/vendor/build-ios-xcframework.sh   # 产物：app/rust_builder/ios/pdfium.xcframework
```

脚本会：合并模拟器 arm64+x64 为 fat dylib、统一 `install_name` 为 `@rpath/libpdfium.dylib`、`xcodebuild -create-xcframework` 输出到 iOS podspec 同级目录。`hentai_flutter.podspec` 以 `vendored_frameworks` 嵌入并代签，运行时由 `pdfium-render` `dlopen`。产物未提交（随 vendor 二进制 gitignore）。仓库根 `scripts/setup-dev.sh` 在 macOS 上会自动执行以上两步（检测到 `xcodebuild` 时）。

脚本从 [bblanchon/pdfium-binaries](https://github.com/bblanchon/pdfium-binaries/releases) 下载与 `manifest.json` 对齐的版本。

若目标平台目录缺失或不含 pdfium 动态库，`cargo build` 将**失败**（不会静默跳过）。

## Flutter 桌面构建

Windows 构建需将 `pdfium.dll` 复制到可执行文件旁。`app/rust_builder/windows/CMakeLists.txt` 已配置 bundling。

Android 构建由 `app/rust_builder/android/build.gradle` 在 cargokit 之后把对应 ABI 的 `libpdfium.so` 拷入 jniLibs。

iOS 构建由 `app/rust_builder/ios/hentai_flutter.podspec` 以 `vendored_frameworks = 'pdfium.xcframework'` 嵌入并代签 `libpdfium.dylib`（构建前需先运行 `build-ios-xcframework.sh` 生成该 XCFramework）。

## 环境变量

- `HENTAI_VENDOR_DIR`：覆盖默认 `core/vendor/<platform>` 路径（用于 CI/本地调试）。
