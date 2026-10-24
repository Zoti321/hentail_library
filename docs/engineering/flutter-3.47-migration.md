# Flutter 3.47 迁移清单（`chore/flutter-3.47`）

目标：将仓库 CI 与本地开发基线从 **Flutter 3.38.5** 提升到 **3.47.8**（Dart **3.13.7**），在 Gate 全绿后再合并 `main`。

参考：本机已升级；Kazumi 生产版本为 3.47.x；设计/M3 依赖调研见 Issue #332。  
**官方升级流程与 breaking 索引**（先读再改代码）：[`research/flutter-official-upgrade-3.38-to-3.47.md`](research/flutter-official-upgrade-3.38-to-3.47.md)。

## 1. CI / 工具链（必做）

| 项 | 当前 | 目标 | 文件 |
| --- | --- | --- | --- |
| `FLUTTER_VERSION` | `3.38.5` | `3.47.8` | `.github/workflows/gate.yml` |
| 同上 | | | `.github/workflows/nightly.yml` |
| 同上 | | | `.github/workflows/release.yml` |
| 同上 | | | `.github/workflows/watch.yml` |
| 同上 | | | `.github/workflows/manual-build-android.yml` |
| 同上 | | | `.github/workflows/manual-build-ios.yml` |
| FRB codegen | `2.12.0` | 先保持；升级后跑 Gate，若有 breaking 再评估 | 各 workflow `FRB_CODEGEN_VERSION` + `app/pubspec.yaml` `flutter_rust_bridge` |

`setup-flutter-frb`  composite action 无需改版本字段，仅消费 workflow 传入的 `flutter-version`。

## 2. Dart / pubspec（必做）

| 项 | 说明 |
| --- | --- |
| `environment.sdk` | 当前 `^3.10.4`；建议改为 `^3.13.0`（与 3.47.8 自带 Dart 对齐） |
| `material_color_utilities` | 当前 `^0.11.0`；Flutter 3.47 强制 **0.13.0** → 改为 `^0.13.0` 并跑 `flutter pub get` |
| `pubspec.lock` | 提交解析结果；`sdks.flutter` 下限会从 `>=3.38.0` 变为 `>=3.47.0` 量级 |
| 主题 / 色板代码 | 若 MCU 0.13 行为与 0.11 不一致，对照 `MASTER.md` §2 与 `app/lib/shared/ui/theme/` 做视觉回归 |

`build_runner` 后若 analyze 报 freezed `extraneous_modifier`，在升级到 **freezed 4**（需同步 **riverpod_generator 4** 与 **custom_lint** 矩阵）前执行：`./scripts/patch-freezed-dart313.sh`。

验证命令（合并前）：

```bash
cd app && flutter pub get
./scripts/run-gate.sh
```

## 3. 文档与说明（建议）

| 项 | 说明 |
| --- | --- |
| `README.md` | 可选增加「推荐 Flutter 3.47.x stable」一句（环境未钉版本时） |
| `scripts/setup-dev.sh` | 可选：末尾打印 `flutter --version` 或文档链到本文 |
| `docs/engineering/gate.md` | 若 README 写了版本，Gate 文档可交叉引用 |
| `design-system/research/material-design-3/03-flutter-implementation.md` | 基线段落仍写 3.38；升级后改为 3.47 并补 3.38→3.47 M3/行为差异（按需） |
| `design-system/hentai-library/MASTER.md` | 文中 `material_color_utilities 0.11.1` 改为与 lock 一致 |
| 调研稿中的 `E:\flutter sdk\...` 路径示例 | 非阻塞；可改为 `D:\Dev\flutter` 或泛化为「本机 SDK 根」 |

## 4. 平台 / 构建（升级后验证）

| 平台 | 关注点 |
| --- | --- |
| **Windows** | Impeller 桌面默认；`flutter_acrylic` / `window_manager` 窗口行为 |
| **Android** | 3.47 Gradle/Kotlin 变更；`flutter doctor --android-licenses`；与 `app/android` 模板 diff |
| **iOS / macOS** | `cd app && flutter pub get` 再生 `ios/Flutter/flutter_export_environment.sh`（已 gitignore） |
| **Linux** | CI `ubuntu` job 与 pdfium 路径不变，仅 SDK 版本 bump |

## 5. 依赖「可能」需要跟进（Gate / `pub outdated` 后定）

以下在 **3.47.8** 上不一定立刻失败，但建议在专用 commit 里评估：

- **路由**：`go_router`（当前 ^16.x；与 Flutter 3.47 兼容矩阵）
- **Riverpod 栈**：`flutter_riverpod` / `riverpod_generator` / `custom_lint` / `riverpod_lint`
- **代码生成**：`build_runner`、`freezed`、`json_serializable`、`theme_tailor`
- **桌面**：`flutter_acrylic`、`window_manager`、`super_clipboard`
- **媒体**：`extended_image`、`file_picker`、`permission_handler`
- **M3 后续（Issue #332，可与 SDK PR 分拆）**：`dynamic_color`、`material_new_shapes` 等

## 6. 明确不在本 PR 范围

- UI 全面 M3 Expressive / 组件重写（设计稿仍以 `design-system/hentai-library/MASTER.md` + Figma 为准）
- Kazumi 依赖整包迁入
- 恢复或新建 `dev` 分支

## 7. 合并检查表

- [ ] 六个 workflow 的 `FLUTTER_VERSION` 已更新
- [ ] `app/pubspec.yaml` + `pubspec.lock` 可在 3.47.8 下 `pub get`
- [ ] `./scripts/run-gate.sh` 本地或 PR CI 全绿
- [ ] 关键页面 smoke：`flutter run -d windows`（至少库 / 设置 / 阅读器入口）
- [ ] Release / Watch 工作流（若近期要发版）在 Actions 上试跑或依赖 nightly
