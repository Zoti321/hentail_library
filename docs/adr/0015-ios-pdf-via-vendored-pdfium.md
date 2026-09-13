# ADR-0015: iOS PDF 经 vendored pdfium 一等支持

## Status

Accepted

## Context

PDF 在桌面与 Android 均由 vendored **pdfium**（`bblanchon/pdfium-binaries`，pin 至 `chromium/7825`）经 `pdfium-render` 提供（见 `core/crates/core/src/formats/pdf.rs`、`core/vendor/`）。iOS 此前是编译期 stub（`mobile_pdf.rs`）：`count_pdf_pages` 返回空、打开/翻页返回「当前平台不支持 PDF 格式」，`build.rs` 对 `apple-ios` 提前 return、`Cargo.toml` 以 `cfg(not(target_os = "ios"))` 排除 `pdfium-render`。这使 iOS 与其他平台的 PDF 能力（本地 + WebDAV Remote）出现割裂，`product-positioning.md` 一直挂着「PDF on iOS（Planned）」。

目标：在 iOS（真机 + 模拟器）交付真实 PDF 阅读，且不引入 Dart 侧 pdfium 插件、不支持 Mac Catalyst、不强制 CI iOS 硬门禁。

关键约束与备选：

- pdfium-binaries 为 iOS 提供**动态库** `libpdfium.dylib`，且真机 / 模拟器 / 架构（arm64、x64）各不相同。
- iOS 不能像 Android 那样按 leaf soname 可靠 `dlopen`；动态库须嵌入 App bundle 并代签。
- **静态链接 pdfium**：iOS 无官方静态产物，自编成本高，放弃。
- **每 arch 脚本拷贝 dylib**（类比 Android gradle）：可行但需自行处理 CocoaPods 代签与 fat/thin 选择，脆弱。
- **XCFramework + CocoaPods `vendored_frameworks`**：CocoaPods 自动按 SDK 选片、嵌入并代签，是 Apple 官方多 arch 动态库分发方式。

## Decision

iOS 与桌面/Android **共用** `pdf.rs`，删除 `mobile_pdf.rs` stub；`pdfium-render` 改为无条件依赖。

- **Vendor 管线**：`manifest.json` 增加 `ios-device-arm64` / `ios-simulator-arm64` / `ios-simulator-x64` 三产物（pin 至同一 `chromium/7825`）；`fetch-native-deps.{sh,ps1}` 新增 `--ios`。
- **build.rs**：移除 `apple-ios` 提前 return；对 iOS 目标解析 vendor 目录并校验 `libpdfium.dylib` 存在（fail-fast），但不写编译期链接标志或 `HENTAI_PDFIUM_LIB_DIR`（host 路径在设备上无意义），运行时改用 bundle 路径绑定。
- **打包**：`core/vendor/build-ios-xcframework.sh`（仅 macOS）合并模拟器 arm64+x64、统一 `install_name` 为 `@rpath/libpdfium.dylib`、`xcodebuild -create-xcframework` 输出 `app/rust_builder/ios/pdfium.xcframework`；`hentai_flutter.podspec` 以 `vendored_frameworks` 嵌入并代签。
- **运行时绑定**：`pdf.rs` iOS 分支按 `current_exe()` 旁的 `Frameworks/libpdfium.dylib` `dlopen`，回退 leaf 名。
- 不支持 Mac Catalyst；不引入 Dart pdfium 插件；不新增 CI iOS 硬门禁（Mac 上人工/后续 CI 验证）。

## Consequences

### Positive

- iOS 与其余平台 PDF 能力一致（本地 + Remote），去除平台割裂与 stub 维护。
- pdfium 版本经 `manifest.json` 全平台统一 pin，升级面收敛。
- 采用 CocoaPods 官方 XCFramework 嵌入路径，代签/选片交由工具链，减少自定义脆弱逻辑。

### Negative

- iOS 构建新增前置步骤：`fetch-native-deps.sh --ios` + `build-ios-xcframework.sh`（仅 macOS，需 Xcode）；`setup-dev.sh` 在 macOS 上自动执行。
- 该路径的编译与打包/运行**无法在 Windows/Linux 验证**，需 Mac 补验（`cargo check --target aarch64-apple-ios` 及真机/模拟器运行）。
- App 体积增加一份 `libpdfium.dylib`（每 slice ~3MB）。
