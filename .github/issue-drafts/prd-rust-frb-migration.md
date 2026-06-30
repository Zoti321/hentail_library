## Problem Statement

本地漫画库的核心能力（Saved path 扫描、Resource 解析、Library sync、阅读 I/O、SQLite 持久化、缩略图）目前全在 Dart 实现。压缩包 / EPUB / PDF 生态薄弱，大库扫描慢，且 rar/cbr、7z/cb7、pdf 等目标格式无法可靠交付。用户需要更快、更完整的离线 Library sync 与阅读体验，同时保留现有 Comic 元数据、阅读历史与 Series 归属。

## Solution

将核心数据与 I/O 迁入 Rust（`flutter_rust_bridge`），采用 Monorepo：`app/` 保留 Flutter UI 与 Repository 薄适配；`core/` 承载 SeaORM、扫描、同步、阅读、缩略图与系列推断。SeaORM 原地打开现有 Drift SQLite 文件；comicId 仍按路径 SHA1（ADR-0001）。Flutter 继续管理 `settings.json`、应用更新与系统文件管理器；移除 R18 路径关键词自动检测功能。

## User Stories

1. As a 用户，我希望 Library sync 在大库上明显更快，以便频繁对齐磁盘内容时不长时间等待。
2. As a 用户，我希望支持 rar/cbr、7z/cb7、pdf 漫画 Resource，以便无需转换格式即可入库阅读。
3. As a 用户，我希望升级应用后原有 Comic、Tag、Series、阅读历史仍在，以便无缝继续阅读。
4. As a 用户，我希望二次 Library sync 在文件未变更时很快完成，以便只改了几本时不必重扫全库。
5. As a 用户，我希望阅读压缩包时翻页流畅，以便连续阅读体验接近本地看图。
6. As a 用户，我希望 Library sync 可取消且取消后库不被写乱，以便误触扫描时可安全停止。
7. As a 用户，我希望列表缩略图在 sync 后自动生成，以便浏览库时看到封面。
8. As a 用户，我希望按 Series inference 批量编入系列，以便整理同名多卷 Comic。
9. As a 用户，我希望 Standalone read 与 Series read 进度仍被记录，以便下次继续阅读。
10. As a 用户，我希望 Healthy mode 开启时列表隐藏 R18 Comic，以便浏览时过滤成人内容。
11. As a 用户，我希望按 Tag、Author、关键词筛选 Comic，以便快速找到作品。
12. As a 用户，我希望首页显示库统计（Comic 数、Series 数等），以便了解库规模。
13. As a 开发者，我希望 comicId 跨版本稳定，以便 DB 原地接管不丢关联数据。
14. As a 开发者，我希望 Rust 与 Flutter 通过结构化错误码通信，以便 UI 可区分取消、未找到与同步失败。
15. As a 用户，我希望 Windows / macOS / Linux / Android / iOS 均可运行同一套核心逻辑，以便跨平台一致。
16. As a 用户，我希望 EPUB 漫画仍可阅读，以便现有库不受影响。
17. As a 用户，我希望图片目录 Resource 仍可阅读，以便文件夹漫画源继续可用。
18. As a 用户，我希望 zip/cbz 漫画仍可阅读，以便最常见格式不受影响。
19. As a 用户，我希望手动设置 Comic 的 contentRating 与 Tag，以便元数据自控。
20. As a 用户，我希望 Saved path 增删后 Library sync 正确镜像磁盘，以便删除根路径时库被清空或更新。
21. As a 开发者，我希望 Monorepo 下 `cd app && flutter test` 与 `cd core && cargo test` 独立可跑，以便分层 CI。
22. As a 用户，我不需要「按路径关键词自动标 R18」功能，以便产品面更简洁（该功能移除）。

## Implementation Decisions

### Monorepo 与边界

- `app/`：Flutter UI、Riverpod、`LibraryComicProjection`（构筛选 DTO）、Repository → FRB、`settings.json`。
- `core/crates/core`：SeaORM、scan、sync、reader、thumbnail、series_infer、comic_id、media。
- `core/crates/flutter`：FRB 暴露 API；cdylib。
- 删除 Dart UseCase、Drift、DAO、`data/services/comic/**`；不做 Drift/Rust 双轨。

### 数据库

- SeaORM 打开 `getApplicationSupportDirectory` 下 `my_database.sqlite`（路径由 Dart 传入 `init_db`）。
- 首次接管：若表已存在且 `seaql_migrations` 空，种子 version 2；执行 migration v3（`Comics.source_modified_ms`、`source_size`）。
- `PRAGMA foreign_keys = ON`；清理遗留 `archive_cover_cache`。

### comicId

- 复刻路径规范化（trim、normalize、`\`→`/`、去尾斜杠、默认不 lowerCase）+ UTF-8 SHA1 小写 hex。
- Golden：`core/tests/fixtures/comic_id_vectors.json`（Dart/Rust 共用）。

### Library sync

- 原子 API：`create_sync_handle`、`sync_library` → `Stream<SyncProgress>`、`cancel_sync`。
- 增量：`stat` 未变则跳过 parse；zip 仅读 central directory。
- 并行：`jwalk` + `rayon` 有界 channel。
- 取消：扫描完成前取消 → 零 DB 写入；写库后取消 → DB 已提交，缩略图可部分完成。
- 缩略图：长边 512、JPEG 85、透明铺白；格式含 dir/zip/cbz/epub 及新格式。

### 阅读

- `open_reader` / `load_page_bytes` / `close_reader`；Rust 内 archive 句柄 LRU。
- 统一 `PageSource` trait；格式库：zip、unrar、sevenz-rust、epub、pdfium（vendor）。

### 查询与筛选

- `fetch_comics_page(filter, sort, page)` 等在 Rust；Dart `LibraryComicProjection` 只构 `ComicFilterDto`。
- `watch_comic_changes` 写库后广播。

### 系列与历史

- `infer_series()` 原子 API；黄金 fixture 自 `test/data.json` 迁至 `core/tests/fixtures/series_inference.json`。
- 阅读历史、Series reading history、首页统计 API 在 Rust。

### 错误模型（E1）

```text
HentaiError { code: HentaiErrorCode, message, context? }
```

Cancelled 不抛异常；DbInitFailed 阻塞启动。

### 启动

- `main()`：`RustLib.init()` → `init_db(appDataDir, dbFileName)` → `runApp`；失败显示 ErrorApp。

### 原生依赖

- `core/vendor/` + build.rs + Flutter 构建复制 pdfium/unrar 至各平台输出目录。

### 外围留 Dart

- `AppUpdateService`、打开文件夹、`settings.json`。

## Testing Decisions

- 测外部行为，不测 Rust 内部模块私有细节。
- **comicId**：共享 JSON golden；CI 双端跑。
- **series inference**：共享 `series_inference.json` golden。
- **DB 接管**：Drift v2 fixture SQLite 集成测试，断言行数与 comicId 不变。
- **缩略图**：封面选取规则 golden；不做 JPEG 字节级跨语言比对。
- **筛选**：可选 SQL/结果集 golden 对齐原 `ComicPageSqlBuilder` 语义。
- 模块优先测：`comic_id`、`series_infer`、`sync`（含取消）、`PageSource`（按格式）、SeaORM repository。

## Out of Scope

- R18 路径关键词自动检测（移除，不迁移）。
- `settings.json` 迁入 Rust。
- 应用更新检查迁入 Rust。
- 云同步、账户、在线爬取。
- Web 平台。
- 内容哈希 comicId / 移动文件后自动保留身份（仍遵 ADR-0001）。

## Further Notes

- 子任务见本 issue 评论中链接的 vertical slice issues。
- 协作文档：`docs/agents/rust-migration.md`、ADR-0002。
- 实现顺序参考子 issue 的 Blocked by 链；大爆炸发版前须完成「退役 Drift」切片。
