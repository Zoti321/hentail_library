# Flutter 3.47 迁移清单（`chore/flutter-3.47`）

目标：将仓库 CI 与本地开发基线从 **Flutter 3.38.5** 提升到 **3.47.8**（Dart **3.13.7**），在 Gate 全绿后合并 `main`。

参考：Kazumi 生产版本为 3.47.x。  
**范围**：本迁移只做 SDK / Gate / 依赖矩阵；**不做** MCU 0.11→0.13 色板视觉回归。色板、token 与 **Material 3 Expressive（MD3E）** 代码迁移另立里程碑（可跟踪 Issue #332 调研，不与本 PR 绑定）。
**官方升级流程与 breaking 索引**：[`research/flutter-official-upgrade-3.38-to-3.47.md`](research/flutter-official-upgrade-3.38-to-3.47.md)。

## 1. CI / 工具链（必做）— 已完成

| 项 | 目标 | 文件 |
| --- | --- | --- |
| `FLUTTER_VERSION` **3.47.8** | gate / nightly / release / watch / manual-build-android / manual-build-ios |
| FRB codegen **2.13.0** | 与各 workflow + `app/pubspec` + `core/crates/flutter/Cargo.toml` |

## 2. Dart / pubspec（必做）— 已完成

| 项 | 说明 |
| --- | --- |
| `environment.sdk` | `^3.13.0` |
| `material_color_utilities` | `^0.13.0` |
| 依赖栈 | freezed 4、riverpod_generator 4、theme_tailor 4、go_router 18 等；Riverpod lint 走 `plugins: riverpod_lint`（无需 `custom_lint`） |

验证：`cd app && flutter pub get` · `./scripts/run-gate.sh`

## 3. 文档与说明 — 已完成

| 项 | 说明 |
| --- | --- |
| `README.md` | §工具链：3.47.8 / lock 下限 |
| `docs/engineering/gate.md` | 工具链与 `CI=true` analyze |
| `design-system/.../03-flutter-implementation.md` | §2 基线 3.47 + MCU 0.13 |
| `design-system/hentai-library/MASTER.md` | MCU 0.13.0 文案；色板数值待 MD3E 迁移时统一 |
| `scripts/setup-dev.sh` | 打印 `flutter --version` 与迁移文档链 |

## 4. 平台 / 构建（升级后验证）

| 平台 | 状态 / 关注点 |
| --- | --- |
| **Windows** | 已 smoke：`flutter run -d windows`。迁移 SDK 路径后若 NuGet 报错，执行 `flutter clean` 清掉 CMake 里旧的 `nuget.exe` 缓存 |
| **Android** | `gradle.properties` 过渡项；发版前 `flutter build apk` |
| **iOS / macOS** | `flutter pub get` 再生本地 ephemeral（gitignore） |
| **Linux** | CI ubuntu + pdfium 路径不变 |

## 5. 依赖后续（专用 PR）

见 §8 backlog。

## 6. 明确不在本 PR 范围

- UI 全面 M3 Expressive / 组件重写
- Kazumi 依赖整包迁入
- 恢复 `dev` 分支

## 7. 合并检查表

- [x] 六个 workflow 的 `FLUTTER_VERSION` 已更新
- [x] `app/pubspec.yaml` + `pubspec.lock` 可在 3.47.8 下 `pub get`
- [x] PR CI Gate 全绿
- [x] Windows smoke：`flutter run -d windows`
- [ ] Release / Watch / manual-build（若近期发版）在 Actions 试跑

## 8. 工程侧后续升级 backlog

| 类别 | 项 | 说明 |
| --- | --- | --- |
| **pub** | `file_picker` 11→13、`flutter_secure_storage` 10→11、`package_info_plus` 9→10 | major 单独 PR |
| **pub** | `freezed` 4.0.3、`build_runner` 2.17.1、`test` 1.33、`material_color_utilities` 0.13.1 | 注意 code gen 矩阵 |
| **工具** | `riverpod_lint` | pub 已保留；Gate 未挂 `plugins`（存量规则债）；**不**使用 `custom_lint` |
| **Android** | AGP 9 / built-in Kotlin | 去掉过渡 `gradle.properties` 后验 apk |
| **平台** | iOS UIScene、桌面 Impeller | 3.47 发行说明；不做专项视觉回归 |
| **CI** | `manual-build-*`、`release.yml`、`watch.yml` | 发版链试跑 |
| **产品 / 设计（MD3E）** | 色板重生成、`dynamic_color`、Expressive 组件与 `app/` 主题迁移 | **后续专项**；SDK 3.47 不挡合并 |
| **调研底稿** | `05-color-directions.md`、`08-tone-based-surfaces.md` 内 0.11.1 引用 | 历史证据；交付数值在 MD3E 里程碑与 MASTER 一并更新 |
