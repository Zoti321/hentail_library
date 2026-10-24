# Flutter 官方升级调研：3.38.x → 3.47.x（Dart 3.13）

> **仓库内执行清单**：请先阅读并配合 [`docs/engineering/flutter-3.47-migration.md`](../flutter-3.47-migration.md)（CI、`pubspec`、Gate、平台 smoke 等本仓库必做项）。本文仅汇总 **Flutter 官方** 对跨多个 stable 大版本升级的流程与变更说明，不替代仓库迁移清单。

**调研范围**：从已在 **Flutter 3.38.x** stable 上的应用，升级到 **Flutter 3.47.x**（随 SDK 捆绑 **Dart 3.13.x**）。  
**信息来源**：仅使用 [docs.flutter.dev](https://docs.flutter.dev)、[flutter.dev 博客](https://flutter.dev/blog)、[breaking changes 索引](https://docs.flutter.dev/release/breaking-changes)、[release notes 索引](https://docs.flutter.dev/release/release-notes)、[Dart changelog](https://dart.dev/changelog)。

---

## 摘要

| 维度 | 官方结论（工程师视角） |
| --- | --- |
| **渠道** | 生产应用推荐 **stable**；用 `flutter upgrade` 拉取当前渠道最新 SDK（见 [Upgrade Flutter](https://docs.flutter.dev/install/upgrade)）。 |
| **Stable 版本序列** | 官方 stable 索引在 3.38 与 3.47 之间为 **3.41 → 3.44 → 3.47**，无 3.39、3.40、3.42、3.43 等独立 stable 条目（见 [Flutter release notes](https://docs.flutter.dev/release/release-notes)）。 |
| **依赖** | SDK 升级与 **pub 依赖** 分开：`flutter pub upgrade` / `flutter pub outdated` / 可选 `--major-versions`（同上 + [Dependency management](https://docs.flutter.dev/packages-and-plugins/dependency-management)）。 |
| **破坏性变更** | 按目标 release 查阅 [breaking changes 索引](https://docs.flutter.dev/release/breaking-changes)；升级后优先 `flutter analyze`，并用 `dart fix --dry-run` / `dart fix --apply`（[Breaking changes](https://docs.flutter.dev/release/breaking-changes)、[dart fix](https://dart.dev/tools/dart-fix)、[Flutter fix](https://docs.flutter.dev/tools/flutter-fix)）。 |
| **3.47 主题** | **可选**迁移至独立 `material_ui` / `cupertino_ui`；桌面 **Impeller 默认开启**；Android 工具链与 **built-in Kotlin / AGP 9** 对齐；iOS 最低版本与 **UIScene / Xcode 27** 准备（[3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)）。 |
| **非必须** | 官方 **不要求** 为升级而做全量 UI 重设计；`material_ui` 解耦为 **opt-in**（框架内 `package:flutter/material.dart` 在 3.47 仍可用，后续 stable 才计划正式弃用，见 [material-ui 迁移指南](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)）。 |

---

## 官方推荐升级流程

以下步骤均来自 [Upgrade Flutter](https://docs.flutter.dev/install/upgrade) 与 [Flutter CLI 参考](https://docs.flutter.dev/reference/flutter-cli)，并按大版本跳跃的常见工程实践排序。

### 1. 确认渠道与目标版本

```bash
flutter channel          # 查看当前渠道
flutter channel stable   # 生产推荐 stable
flutter upgrade          # 获取当前渠道最新 SDK
flutter --version        # 确认 Flutter / Dart 版本
```

- **Stable**：官方推荐新用户与生产发布；约每季度更新，可能含高影响 hotfix（[Upgrade Flutter — stable](https://docs.flutter.dev/install/upgrade)）。
- **Beta**：文档描述为「最新已通过重度测试的 release」，更新频率高于 stable；stable 更新时会对齐到当时的 beta（同上）。
- **钉死版本**：在 SDK 目录 `git checkout <tag>`（[Switch to a specific Flutter version](https://docs.flutter.dev/install/upgrade)）；本仓库目标为 **3.47.8** 量级时与 `flutter-3.47-migration.md` 一致即可。

Windows 上 `flutter upgrade` 若遇 `Filename too long`，官方建议缩短 SDK 路径或启用 Git/系统长路径（[Upgrade Flutter — Windows](https://docs.flutter.dev/install/upgrade)）。

### 2. 升级应用依赖（与 SDK 分开）

```bash
cd <app_package>   # 例如本仓库 app/
flutter pub get
flutter pub upgrade
flutter pub outdated                    # 查看可升级项与建议
# 可选：允许 major 并改写 pubspec 约束
flutter pub upgrade --major-versions
```

说明见 [Upgrade packages](https://docs.flutter.dev/install/upgrade) 与 [Resolve dependency conflicts](https://docs.flutter.dev/packages-and-plugins/dependency-management)。

### 3. 处理分析与破坏性变更

1. 打开 [breaking changes 索引](https://docs.flutter.dev/release/breaking-changes)，**按你经过的每个 stable**（3.41、3.44、3.47）逐项核对是否影响代码。
2. 运行静态分析（官方 CLI 文档推荐在 Flutter 工程中使用 `flutter analyze` 而非 `dart analyze`：[flutter analyze](https://docs.flutter.dev/reference/flutter-cli)）。
3. 自动化修复：

```bash
dart fix --dry-run
dart fix --apply
# 3.47 可选 Material/Cupertino 解耦（见下文）
dart fix --apply --code=migrate_design_widgets
```

索引页明确：升级后遇 Dart 分析错误可考虑 `dart fix`；并非所有 breaking change 都有自动修复（[Breaking changes](https://docs.flutter.dev/release/breaking-changes)）。

### 4. 验证与发布前检查

```bash
flutter doctor -v
flutter test
# 各目标平台至少一次构建/运行（与项目相关）
flutter build apk    # 或 ios / windows / ...
```

`flutter doctor` 用于检查工具链（Android licenses、Xcode 等）（[flutter doctor](https://docs.flutter.dev/reference/flutter-cli)）。破坏性变更政策与迁移指南关系见 [Compatibility policy](https://docs.flutter.dev/release/compatibility-policy)。

---

## Stable 版本说明（3.38 → 3.47 区间）

官方 [release notes 列表](https://docs.flutter.dev/release/release-notes) 在 **3.38.0** 之后、**3.47.0** 之前的 stable 为：

- [3.41.0](https://docs.flutter.dev/release/release-notes/release-notes-3.41.0)
- [3.44.0](https://docs.flutter.dev/release/release-notes/release-notes-3.44.0)
- [3.47.0](https://docs.flutter.dev/release/release-notes/release-notes-3.47.0)

因此下文「逐版要点」覆盖 **3.41 / 3.44 / 3.47**（及你起点 **3.38** 上已落地、在更高版本仍相关的项）。**不存在**官方 stable 发布说明中的 3.39、3.40、3.42、3.43 条目；若需中间变更，应查 beta 归档或逐版 changelog（[Release notes 页 Note](https://docs.flutter.dev/release/release-notes)）。

### 起点：Flutter 3.38（你已在该线时）

官方 [3.38 breaking changes](https://docs.flutter.dev/release/breaking-changes) 条目包括（节选，典型 Material 应用可能已遇到）：

| 主题 | 官方文档 |
| --- | --- |
| Android 默认页面转场为 `PredictiveBackPageTransitionBuilder` | [索引 — 3.38](https://docs.flutter.dev/release/breaking-changes) |
| `SnackBar` 带 action 时不再自动消失 | 同上 |
| `UISceneDelegate` 采用（iOS） | [UIScene adoption](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate) |
| 语义、`OverlayPortal`、`CupertinoDynamicColor` 等 | [索引 — 3.38](https://docs.flutter.dev/release/breaking-changes) |

自 **3.41** 起，`UIScene` 为 iOS 默认，未改动的 `AppDelegate` 可由 CLI 在 `flutter run` / `flutter build ios` 时自动迁移（[UIScene adoption](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)）。

### Flutter 3.41（2026-02 stable）

**发布说明**：[release-notes-3.41.0](https://docs.flutter.dev/release/release-notes/release-notes-3.41.0)  
**博客**：[What's new in Flutter 3.41](https://flutter.dev/blog/whats-new-in-flutter-3-41)

官方博客强调的工程/平台方向（非完整 changelog）：

- **公开 release 窗口**（分支 cutoff 与 2026 年 stable 节奏，含 3.41 / 3.44 / 3.47 / 3.50）（[3.41 博客 — Public Release Windows](https://flutter.dev/blog/whats-new-in-flutter-3-41)）。
- **Material / Cupertino 向独立包解耦**（长期路线；3.47 才提供 1.0 独立包与 `dart fix`，见下）（[3.41 博客 — Decoupling](https://flutter.dev/blog/whats-new-in-flutter-3-41)）。
- **Fragment shader**：同步图像解码、`decodeImageFromPixelsSync` 等（[3.41 博客](https://flutter.dev/blog/whats-new-in-flutter-3-41)）。

**3.41 breaking changes**（[索引 — 3.41](https://docs.flutter.dev/release/breaking-changes)）：

| 项 | 迁移/说明 |
| --- | --- |
| Linux 合并线程 | [索引 — Merged threads on Linux](https://docs.flutter.dev/release/breaking-changes) |
| `FontWeight` 影响可变字体 weight 轴 | 同上 |
| `containsSemantics` → `isSemantics` | 同上 |
| `findChildIndexCallback` → `findItemIndexCallback`（`ListView` / `SliverList` separated） | 同上 |
| Material 3 tokens / **Material Color Utilities** | [Material Color Utilities update](https://docs.flutter.dev/release/breaking-changes/material-color-utilities)、[Material 3 tokens update](https://docs.flutter.dev/release/breaking-changes/material-design-3-token-update) |

### Flutter 3.44（2026-05 stable，Dart 3.12）

**发布说明**：[release-notes-3.44.0](https://docs.flutter.dev/release/release-notes/release-notes-3.44.0)  
**博客**：[What's new in Flutter 3.44](https://flutter.dev/blog/whats-new-in-flutter-3-44)  
**文档站摘要**：[What's new in the docs — 3.44](https://docs.flutter.dev/release/whats-new)

官方博客/platform 要点（节选）：

- **Swift Package Manager** 成为 iOS/macOS **默认**依赖管理；仍依赖 CocoaPods 的插件会回退并告警（[3.44 博客](https://flutter.dev/blog/whats-new-in-flutter-3-44)）。
- **Hybrid Composition++（Android）**：opt-in（`--enable-hcpp` 或 `AndroidManifest` meta-data）（[3.44 博客](https://flutter.dev/blog/whats-new-in-flutter-3-44)）。
- Material/Cupertino 解耦架构推进；**3.44 起冻结**框架内 Material/Cupertino 贡献，为独立包过渡（[material-ui 迁移指南 — Background](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)）。

**3.44 breaking changes**（[索引 — 3.44](https://docs.flutter.dev/release/breaking-changes)）：

| 项 | 说明 |
| --- | --- |
| **Migrating Flutter Android projects to built-in Kotlin** | 总览：[migrate-to-built-in-kotlin](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin)；**3.44** 起支持 AGP 9 + `android.builtInKotlin=false` 过渡 |
| `IconData` 标记为 `final` | [索引](https://docs.flutter.dev/release/breaking-changes) |
| `cacheExtent` / `cacheExtentStyle` 弃用 | 同上 |
| `onReorder`、`TextInputConnection.setStyle` 等弃用 | 同上 |
| `ListTile` 在彩色父组件外 debug 报错 | 同上 |
| Page transition builders 重组 | 同上 |

### Flutter 3.47（2026-08 stable，Dart 3.13）

**发布说明**：[release-notes-3.47.0](https://docs.flutter.dev/release/release-notes/release-notes-3.47.0)  
**博客**：[What's new in Flutter 3.47](https://flutter.dev/blog/whats-new-in-flutter-3-47)  
**文档站摘要**：[What's new in the docs — 3.47](https://docs.flutter.dev/release/whats-new)

官方博客/engine 要点（节选）：

| 主题 | 官方表述要点 | 来源 |
| --- | --- | --- |
| **`material_ui` / `cupertino_ui` 1.0** | 可选独立包；`dart fix --code=migrate_design_widgets`；框架内库计划后续 stable 正式弃用 | [3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)、[迁移指南](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui) |
| **桌面 Impeller 默认** | macOS / Windows / Linux；未来移除 opt-out | [3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)、[Impeller](https://docs.flutter.dev/perf/impeller) |
| **Apple 工具链** | iOS 最低 **15**、macOS 最低 **12**；Xcode 27 / UIScene 强制场景 | [3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)、[UIScene](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate) |
| **Android 验证矩阵** | Java **17**；KGP **2.4.0**；AGP **9.1.0**；Gradle **9.3.1**；默认 `compileSdk`/`targetSdk` **36**、`minSdk` **24** | [3.47 博客 — Android dependency matrix](https://flutter.dev/blog/whats-new-in-flutter-3-47) |
| **Widget Previews** | stable | [3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)、[What's new in the docs](https://docs.flutter.dev/release/whats-new) |

**3.47 breaking changes**（[索引 — 3.47](https://docs.flutter.dev/release/breaking-changes)）：

| 项 | 文档 |
| --- | --- |
| 移除 `describeEnum` | [remove-describeEnum](https://docs.flutter.dev/release/breaking-changes/remove-describeEnum) |
| iOS/Android 语义 header / `headingLevel` 行为 | [索引 — 3.47](https://docs.flutter.dev/release/breaking-changes) |
| OpenGL ES render-to-texture 坐标 | [索引 — 3.47](https://docs.flutter.dev/release/breaking-changes)（博客指向 OpenGLES breaking change 页） |

**Dart 3.13**（与 3.47 同日发布）：主构造函数、类型提升规则调整、`dart:io` 部分 breaking 等见 [Dart changelog — 3.13](https://dart.dev/changelog)。

---

## 专题：Material / Cupertino 解耦（3.38–3.47 相关）

| 阶段 | 官方说明 |
| --- | --- |
| 3.41+ | 博客阐述解耦动机与路线（[3.41 博客](https://flutter.dev/blog/whats-new-in-flutter-3-41)） |
| 3.44 | 冻结框架内 Material/Cupertino 贡献；独立包与冻结代码对齐（[material-ui 迁移指南](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)） |
| 3.47 | `material_ui` / `cupertino_ui` **1.0**，**opt-in**；`MaterialUiCompatibilityBridge` 用于依赖尚未迁移的插件；本地化委托迁移（[迁移指南](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)、[3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)） |

**官方未要求**在 3.47 升级 PR 中必须完成解耦；索引中「Migrate to standalone material_ui and cupertino_ui」列在 **Not yet released to stable** 与 3.47 已发布项并存时，以 [breaking changes 索引](https://docs.flutter.dev/release/breaking-changes) 当前分类为准。工程师应：**升级 SDK 与修 analyze 优先**；解耦可作为独立里程碑。

---

## 专题：桌面 Impeller（3.47）

- **默认开启**：macOS、Windows、Linux 自 **Flutter 3.47** 起（[Impeller — macOS / Linux / Windows](https://docs.flutter.dev/perf/impeller)）。
- **调试关闭**：`flutter run --no-enable-impeller`（同上）。
- **发布关闭**（临时）：各平台 runner 配置见 [Impeller](https://docs.flutter.dev/perf/impeller) 与 [3.47 博客 — Modern graphics](https://flutter.dev/blog/whats-new-in-flutter-3-47)；文档注明未来会移除 opt-out。
- **桌面抗锯齿**：桌面默认 4x MSAA，桌面默认 SDF（[Impeller anti-aliasing](https://docs.flutter.dev/perf/antialiasing)）。
- **问题反馈**：Impeller 问题以 `[Impeller]` 为标题前缀提交 GitHub issue（[Impeller — Bugs](https://docs.flutter.dev/perf/impeller)）。

---

## 专题：Android Gradle / Kotlin（3.44–3.47）

1. **总览**：[Migrating Flutter Android projects to built-in Kotlin](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin)  
   - AGP 9+ 默认 **built-in Kotlin**；仍使用 `kotlin-android`（KGP）的项目必须迁移或过渡。  
   - **3.44**：可在 `gradle.properties` 使用 `android.builtInKotlin=false`（及 `android.newDsl=false`）与 AGP 9 共存。  
   - **3.47**：可在应用与**全部**相关插件迁移后设 `android.builtInKotlin=true`（[for-app-developers](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers)）。

2. **应用开发者步骤**（仅当已使用 KGP）：见 [Built-in Kotlin migration for app developers](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers)（移除 `kotlin-android`、使用 `kotlin { compilerOptions { jvmTarget = ... } }` 等）。

3. **3.47 博客验证矩阵**（与 Flutter CI 对齐的参考值）：Java 17、KGP 2.4.0、AGP 9.1.0、Gradle 9.3.1、API 36/24（[3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)）。

4. **未使用 KGP 的应用**：官方明确 **不要** 迁移到 built-in Kotlin，仅需 `android.newDsl=false` 等标志（[for-app-developers — Warning](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers)）。

`flutter run` / `flutter build apk` 可在缺少标志时自动写入 `gradle.properties`（同上）。

---

## 破坏性变更核对清单（典型 Material 桌面 + 移动应用）

按官方 [breaking changes 索引](https://docs.flutter.dev/release/breaking-changes) 自 **3.41 → 3.44 → 3.47** 浏览；下列为跨版本常见命中项（**非穷尽**）。

### 主题 / Material 3

- [ ] **MCU 0.11 → 0.13** 与 `ColorScheme.fromSeed` 等生成色变化（[material-color-utilities](https://docs.flutter.dev/release/breaking-changes/material-color-utilities)）— 本仓库见 `flutter-3.47-migration.md`。
- [ ] M3 token 导致的 `on*Container`、Chip 边框等视觉差（[material-design-3-token-update](https://docs.flutter.dev/release/breaking-changes/material-design-3-token-update)）。
- [ ] 弃用 API：`onReorder`、`cacheExtent`、`ListTile` 父级着色 debug 断言等（[索引 — 3.44](https://docs.flutter.dev/release/breaking-changes)）。

### 框架 / 语义 / 工具

- [ ] `describeEnum` 已移除 → 使用 `.name`（[remove-describeEnum](https://docs.flutter.dev/release/breaking-changes/remove-describeEnum)）。
- [ ] `containsSemantics` → `isSemantics`；`findChildIndexCallback` → `findItemIndexCallback`（[索引 — 3.41](https://docs.flutter.dev/release/breaking-changes)）。
- [ ] 自定义 `IconData` 子类（`IconData` 现为 `final`）（[索引 — 3.44](https://docs.flutter.dev/release/breaking-changes)）。

### iOS / macOS

- [ ] **UIScene**（3.38+ 文档，3.41+ 默认）：自定义 `AppDelegate` / 插件生命周期（[uiscenedelegate](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)）。
- [ ] 3.47+ 最低 iOS 15 / macOS 12（[3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)）。
- [ ] SwiftPM 默认（3.44+）；未迁移插件的 CocoaPods 回退（[3.44 博客](https://flutter.dev/blog/whats-new-in-flutter-3-44)）。

### Android

- [ ] AGP 9 / built-in Kotlin 过渡或完整迁移（[migrate-to-built-in-kotlin](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin)）。
- [ ] 可选 HCPP（[3.44 博客](https://flutter.dev/blog/whats-new-in-flutter-3-44)）。

### 桌面（本仓库 Windows 等）

- [ ] **Impeller 默认** 后的渲染/文本差异；必要时按文档临时禁用并提 issue（[Impeller](https://docs.flutter.dev/perf/impeller)）。

### 可选 / 后续里程碑

- [ ] `material_ui` / `cupertino_ui` + `migrate_design_widgets`（[material-ui-and-cupertino-ui](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)）。
- [ ] Web Wasm / `package:web`（若维护 Web 目标）（[3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)）。

### Dart 3.13

- [ ] 阅读 [Dart 3.13 changelog](https://dart.dev/changelog) 中与 `dart:io`、类型提升、语言版本相关的 **Breaking** 项；将 `environment.sdk` 提高到与团队一致的下限（本仓库建议见 `flutter-3.47-migration.md`）。

---

## 本地建议执行的命令

| 目的 | 命令 | 官方依据 |
| --- | --- | --- |
| 工具链健康 | `flutter doctor -v` | [CLI — doctor](https://docs.flutter.dev/reference/flutter-cli) |
| Android 许可 | `flutter doctor --android-licenses` | 同上（doctor 子命令） |
| 依赖解析 | `flutter pub get` / `flutter pub upgrade` | [Upgrade Flutter](https://docs.flutter.dev/install/upgrade) |
| 过时依赖 | `flutter pub outdated` | 同上 |
| 静态分析 | `flutter analyze` | [CLI — analyze](https://docs.flutter.dev/reference/flutter-cli) |
| 自动迁移 | `dart fix --dry-run` → `dart fix --apply` | [dart fix](https://dart.dev/tools/dart-fix)、[Flutter fix](https://docs.flutter.dev/tools/flutter-fix) |
| 单元/组件测试 | `flutter test` | [CLI — test](https://docs.flutter.dev/reference/flutter-cli) |
| 本仓库门禁 | `./scripts/run-gate.sh` | 见 `flutter-3.47-migration.md` |

升级后若分析器报错增多，官方建议优先尝试 `dart fix`（[Breaking changes 页首](https://docs.flutter.dev/release/breaking-changes)）。

---

## Flutter 官方 **不要求** 的事项

以下均基于官方文档表述，避免与升级混淆：

| 误解 | 官方事实 |
| --- | --- |
| 必须迁移到 `material_ui` / `cupertino_ui` 才能用 3.47 | 3.47 为 **opt-in**；框架内 Material/Cupertino 仍随 SDK 提供，正式弃用计划在 **后续** stable（[迁移指南 Summary](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)、[3.47 博客](https://flutter.dev/blog/whats-new-in-flutter-3-47)）。 |
| 必须做 Material 3 Expressive / 全应用 UI 重写 | 无此升级前提；M3 默认自 3.16 起已讨论多年，升级是增量修 breaking/deprecation（[material-3-default](https://docs.flutter.dev/release/breaking-changes/material-3-default)）。 |
| 必须启用 built-in Kotlin | 仅 **已使用 KGP** 的项目需要按指南迁移；否则不要启用 built-in Kotlin（[migrate-to-built-in-kotlin — Warning](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin)）。 |
| 必须关闭 Impeller | 相反，桌面默认开启；仅在遇到问题时按文档 **临时** opt-out 并反馈（[Impeller](https://docs.flutter.dev/perf/impeller)）。 |
| 必须一次跳过所有中间 stable | 官方未规定逐步升级命令，但 breaking 索引 **按 release 归档**；从 3.38 直跳 3.47 时，应合并核对 3.41、3.44、3.47 三节（[breaking changes](https://docs.flutter.dev/release/breaking-changes)）。 |

---

## 参考链接（主索引）

| 资源 | URL |
| --- | --- |
| 升级 Flutter | https://docs.flutter.dev/install/upgrade |
| Breaking changes 索引 | https://docs.flutter.dev/release/breaking-changes |
| Release notes 索引 | https://docs.flutter.dev/release/release-notes |
| Flutter 兼容性政策 | https://docs.flutter.dev/release/compatibility-policy |
| Impeller | https://docs.flutter.dev/perf/impeller |
| Dart changelog | https://dart.dev/changelog |
| 3.41 博客 | https://flutter.dev/blog/whats-new-in-flutter-3-41 |
| 3.44 博客 | https://flutter.dev/blog/whats-new-in-flutter-3-44 |
| 3.47 博客 | https://flutter.dev/blog/whats-new-in-flutter-3-47 |

---

*文档类型：工程调研（官方来源）；与仓库 PR `chore/flutter-3.47` 配套使用。*
