# Rust / FRB 架构（Agent 指引）

扫描、Library sync、阅读 I/O、SQLite 持久化等核心能力在 `core/`（Rust）；Flutter 在 `app/` 仅保留 UI 与 Repository 薄层。迁移已完成（父 PRD [#11](https://github.com/Zoti321/hentail_library/issues/11) 及 slices #12–#19 均已关闭）。决策背景见 ADR-0002。

## 仓库布局

| 路径 | 内容 |
|------|------|
| `app/` | Flutter：`lib/ui`、`lib/domain/models`、`lib/data/repositories`（调 FRB） |
| `core/` | Rust workspace：`crates/core`（业务）、`crates/flutter`（FRB cdylib） |
| 根目录 | `README.md`、`AGENTS.md`、`CONTEXT.md`、`docs/`、`.github/` |

开发：clone 后在仓库根目录执行 `./scripts/setup-dev.sh`（Windows 可用 Git Bash），创建 `app/rust_builder/rust` → `core/crates/flutter` 链接并拉取 pdfium；然后 `cd app && flutter run`、`cd core && cargo test --workspace`。

**PDF/pdfium**：桌面、Android、iOS 共用 `core/crates/core/src/formats/pdf.rs`（无平台 stub）。各平台的 pdfium 由 `core/vendor/` 管理，绑定/打包策略按平台区分（桌面 host 路径、Android jniLibs soname、iOS 经 Podfile 注入的 Runner script phase 拷 `libpdfium.dylib` 进 bundle 后按路径 dlopen）。iOS 详见 ADR-0015 与 `core/vendor/README.md`。

**Rust 日志（ADR-0003 / ADR-0004）**：`tracing` 输出至 stderr，并在 `configure_rust_log_frb` 后写入 `{app_data}/logs/rust_log.txt`（5MB 轮转）。开发时可用 `RUST_LOG=hentai_core=debug flutter run`；`set_diagnostic_logging_frb` 临时调整级别。用户支持流程见 `docs/agents/log-support.md`。

## 架构要点

- **无 Dart UseCase**：`sync_library`、`infer_series` 等为 Rust 原子 API。
- **Repository**：`frb.*` + DTO → Entity 映射；无 Drift DAO。
- **FRB sync vs async**：UI / I/O 读路径默认 `#[frb]` async（Dart 用 `guardFrb`）；`#[frb(sync)]` 仅留给纯计算或极轻控制面（如 `comic_id_from_path`）。慢查询勿 `runtime::block_on` 堵 Dart UI isolate。写路径可次优先迁 async。
- **筛选**：`LibraryComicProjection` 留 Dart 构 `ComicFilterDto`；查询在 Rust（SeaORM）。
- **设置**：App preference 与 Library browse preference 经 SharedPreferences 留 Dart（ADR-0016）；Library 的 Scan on startup / Scan interval 在 SQLite（每库属性），由 Flutter 编排触发。
- **错误**：Rust `HentaiError { code, message, context }` → Dart `AppException` 子类。
- **取消**：`create_sync_handle` / `sync_library` / `cancel_sync`；取消语义对齐原 Dart sync。

## 不可破坏的契约

1. **comicId** 与 ADR-0001 一致；golden：`core/tests/fixtures/comic_id_vectors.json`。
2. **DB 文件** 与 Drift 时代同路径、同 schema v2 列名（snake_case）。
3. **缩略图**：长边 512、JPEG quality 85；封面选取规则见 `series_inference` / thumbnail golden。

## 已移除（勿恢复）

- R18 路径关键词自动检测（`auto_detect_content_rating`）及首页入口。

## 词汇

继续使用 `CONTEXT.md`：Comic、Resource、Library、Library root、Library sync、Series inference 等。
