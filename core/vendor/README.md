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

**RAR/CBR**：经 `unrar` crate 静态编译 rarlab 解压库（仅 list/extract，无压缩 API）。

**7z/CB7**：`sevenz-rust` 纯 Rust，无需本目录。

## 获取依赖

```bash
# Linux / macOS / Git Bash
./core/vendor/fetch-native-deps.sh

# Windows PowerShell
./core/vendor/fetch-native-deps.ps1
```

脚本从 [bblanchon/pdfium-binaries](https://github.com/bblanchon/pdfium-binaries/releases) 下载与 `manifest.json` 对齐的版本。

若目标平台目录缺失或不含 pdfium 动态库，`cargo build` 将**失败**（不会静默跳过）。

## Flutter 桌面构建

Windows 构建需将 `pdfium.dll` 复制到可执行文件旁。`app/rust_builder/windows/CMakeLists.txt` 已配置 bundling。

## 环境变量

- `HENTAI_VENDOR_DIR`：覆盖默认 `core/vendor/<platform>` 路径（用于 CI/本地调试）。
