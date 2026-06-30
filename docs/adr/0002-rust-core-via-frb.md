# ADR-0002: Rust 核心层经 FRB 接管数据与 I/O

## Status

Accepted

## Context

Dart 在压缩包、EPUB、PDF 等格式上库支持弱；全库扫描与全量压缩包解析性能不足。计划格式（rar/cbr、7z/cb7、pdf）难以在纯 Dart 路径可靠交付。现有 Drift/SQLite 与用户元数据须保留。

## Decision

将扫描、Library sync、阅读 I/O、缩略图、SQLite 持久化迁入 Rust（`flutter_rust_bridge`），Monorepo 布局：`app/`（Flutter UI + Repository 薄层）、`core/`（`hentai-core` + `hentai-flutter`）。SeaORM 原地接管 `my_database.sqlite`；comicId 仍按 ADR-0001。`settings.json`、应用更新、打开文件管理器留 Dart。移除 R18 路径自动检测功能。

## Consequences

### Positive

- 扫描可增量 + 并行；格式可接 unrar、pdfium 等成熟库。
- 业务边界清晰：Rust 核心 + Flutter 展示。

### Negative

- 构建与 CI 复杂度上升（Rust、vendor 原生库、多平台）。
- 大爆炸切换前须完成全量迁移与 comicId/DB 兼容性验证。

详见 `docs/agents/rust-migration.md` 与 GitHub PRD issue。
