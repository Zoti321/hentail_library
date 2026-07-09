# Rust / FRB 迁移（Agent 指引）

将扫描、Library sync、阅读 I/O、SQLite 持久化等核心能力迁入 `core/`（Rust），Flutter 在 `app/` 仅保留 UI 与 Repository 薄层。完整 PRD 与任务拆分见 GitHub Issues（父 issue：Rust 核心层 FRB 迁移 PRD）。

## 仓库布局（目标态）

| 路径 | 内容 |
|------|------|
| `app/` | Flutter：`lib/ui`、`lib/domain/models`、`lib/data/repositories`（调 FRB） |
| `core/` | Rust workspace：`crates/core`（业务）、`crates/flutter`（FRB cdylib） |
| 根目录 | `README.md`、`AGENTS.md`、`CONTEXT.md`、`docs/`、`.github/` |

开发：clone 后先在仓库根目录执行 `scripts/setup-dev.ps1`（Windows）或 `scripts/setup-dev.sh`（Unix），创建 `app/rust_builder/rust` → `core/crates/flutter` 链接并拉取 pdfium；然后 `cd app && flutter run`、`cd core && cargo test --workspace`。

**Rust 日志（ADR-0003）**：`tracing` 输出至 stderr；开发时可用 `RUST_LOG=hentai_core=debug flutter run` 调整级别（未设置时 debug 构建默认 `hentai_core=debug`）。

## 架构要点

- **无 Dart UseCase**：`sync_library`、`infer_series` 等为 Rust 原子 API。
- **Repository**：`frb.*` + DTO → Entity 映射；无 Drift DAO。
- **筛选**：`LibraryComicProjection` 留 Dart 构 `ComicFilterDto`；查询在 Rust（SeaORM）。
- **设置**：`settings.json` 永久留 Dart（主题、Healthy mode、autoScan 等）。
- **错误**：Rust `HentaiError { code, message, context }` → Dart `AppException` 子类。
- **取消**：`create_sync_handle` / `sync_library` / `cancel_sync`；取消语义对齐原 Dart sync。

## 不可破坏的契约

1. **comicId** 与 ADR-0001 一致；golden：`core/tests/fixtures/comic_id_vectors.json`。
2. **DB 文件** 与 Drift 时代同路径、同 schema v2 列名（snake_case）。
3. **缩略图**：长边 512、JPEG quality 85；封面选取规则见 `series_inference` / thumbnail golden。

## 已移除（勿恢复）

- R18 路径关键词自动检测（`auto_detect_content_rating`）及首页入口。

## 词汇

继续使用 `CONTEXT.md`：Comic、Resource、Library sync、Saved path、Series inference 等。
