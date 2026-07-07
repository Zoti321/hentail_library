# Hentai Library

基于 Flutter 的本地漫画/本子阅读与管理应用，聚焦离线阅读体验与个人库管理。

## 屏幕截图

![alt](static/screenshot/image_1.png)
![alt](static/screenshot/image_2.png)
![alt](static/screenshot/image_3.png)
![alt](static/screenshot/image_4.png)

## 核心功能

### 阅读器

- 资源格式支持: `EPUB`, `ZIP`, `CBZ`
- 图片格式支持: `JPG`、`PNG`、`WebP`
- 多阅读模式：卷轴（Webtoon）、翻页
- 阅读增强：预加载，亮度，自动播放

### 书架与库管理

- 指定路径扫描与导入
- 自定义元数据(作者,标签,内容分级,首发日期)
- 创建系列管理相关漫画
- 自动系列推断

## 支持平台

| 平台    | 支持情况 |
| ------- | -------- |
| Android | ❌       |
| iOS     | ❌       |
| Windows | ✅       |
| macOS   | ❌       |
| Linux   | ❌       |

## 协作建议

本仓库为 **Monorepo**：Flutter 应用在 `app/`，Rust 核心位于 `core/`。

### 首次 / clone 后初始化

Cargokit 通过 `app/rust_builder/rust` 链接到 `core/crates/flutter` 来编译 Rust；该链接不会提交到 Git，需本地创建一次：

```powershell
# Windows PowerShell（仓库根目录）
.\scripts\setup-dev.ps1
```

```bash
# Linux / macOS / Git Bash（仓库根目录）
./scripts/setup-dev.sh
```

脚本会：

1. 创建 `app/rust_builder/rust` → `core/crates/flutter` 的符号链接（Windows 为 junction）
2. 下载 pdfium 等原生依赖到 `core/vendor/`

仅需链接、跳过依赖下载时：`.\scripts\setup-dev.ps1 -SkipNativeDeps` 或 `./scripts/setup-dev.sh --skip-native-deps`。

### 日常开发

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
flutter run -d windows   # 或其他平台
```

- 提交前至少执行：`dart format .`、`flutter analyze`、`flutter test`（均在 `app/` 下）
- 新增模型/DAO/Provider 后同步更新生成代码
- PR 说明建议包含：改动背景、核心改动点、测试方式、截图（UI 改动）
