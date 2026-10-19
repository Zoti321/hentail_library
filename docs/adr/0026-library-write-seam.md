# ADR-0026: Library-level write seam（库级写接缝）

## Status

Accepted

## Context

库级写（Library sync、Metadata refresh、Metadata bulk patch、Comic trash / restore / purge、Local Library root 变更）需要全局单飞，否则会互相覆盖。ADR-0013 / ADR-0022 / ADR-0023 各自写了一遍「获取 `library_write_lock`，占用则立即失败、不排队」。

原实现把这两件事分散在两处：

- 互斥：`sync/library_lock.rs` 里一个 `AtomicBool` 单飞。
- 事务：每个操作各自 `db.begin()` / `commit()`，读接口看不出并发与原子性保证。

代价已经显现：`import_comic_metadata` 是跨 Comic 的批量写，却既不取锁、又逐本开了两次事务，形参连接还完全没用上；新增库级写时也容易忘记取锁。同时全仓约 109 处 `connection()?` 自取全局连接，说明「接缝拥有锁」比「接缝拥有连接」现实。

约束：

- 单 Comic 用户写（元数据、阅读进度、缩略图、系列字段）**不能**持锁，否则 Library sync 期间用户无法编辑。
- fail-fast、不排队是产品语义，被集成测试钉住（`tests/comic_trash.rs`、`tests/metadata_refresh.rs`、`tests/comic_metadata_bulk_patch.rs`、`tests/update_local_library_root.rs`）。
- 事务粒度是产品语义：sync 每库一事务；Metadata bulk patch、Comic purge 与 Metadata refresh 逐本（逐 Comic）一事务（被取消或部分失败时，已提交的成员保留，未处理的成员不写入）；Comic trash / restore、Local Library root 变更单事务。

## Decision

### 接缝

新增 `core/crates/core/src/library_write.rs`，拥有库级写的互斥与事务边界：

- `with_library_write(f)`：只取锁，运行 `f`。
- `begin_library_write_txn()` → `LibraryWriteTxn`：取锁 + 单一事务。`txn()` 借用事务，`commit()` 提交，`rollback()` 显式回滚；未提交就 drop 时结构体字段顺序保证先触发事务回滚、随后才释放库级写锁（未提交改动对其它连接不可见）。
- `try_acquire_library_write_lock()` / `LibraryWriteGuard` 由 `sync/library_lock.rs` 迁入（旧文件删除；`crate::sync` 仍 re-export，FRB 导出面不变）。

事务不用闭包承载：`FnOnce(&DatabaseTransaction) -> Fut` 缺少「返回值不借用参数」的生命周期上界，sea-orm 自身也用 `Box::pin` 绕开，因此采用会话语义。

### 规则

- **跨 Comic 的批量库级写必须持锁**；**单 Comic 用户写不持锁**。
- 锁 fail-fast、不排队、不可重入：公开入口取锁一次，内部 `*_locked` 体不再走接缝（否则二次取锁会误报「库写入操作进行中」）。`*_locked` 后缀在本接缝内表示「已持库级写锁」，与 Metadata field lock 的同名后缀（如 `set_series_item_sort_order_locked`）无关。
- 事务粒度显式：单事务操作走 `begin_library_write_txn()`；需要先读、先校验或先触碰文件系统（`update_local_library_root` 的 root probe、Metadata refresh 的 stat + parse）的操作走 `with_library_write` + 体内自开事务，避免事务跨越文件系统 I/O；逐本事务操作（Metadata bulk patch、Comic purge、Metadata refresh）在 `*_locked` 体内自开事务。
- 一本 Comic 的完整写入集（`comics` + `comic_meta` + 四个 junction facet）必须在同一事务内提交，无论调用方是 Library sync 还是 Metadata refresh：`upsert_comics` 的调用方负责用连接开事务，`comic_meta` 与 junction 不会在 `comics` 已提交之后单独暴露。
- 事务不跨越文件系统 I/O：`update_local_library_root` 只用 `with_library_write` 持锁，根目录 probe 在事务打开之前完成。

### 覆盖

持锁入口：`sync_library`、`refresh_comic_metadata`、`refresh_series_metadata`、`refresh_library_metadata`、`apply_comic_metadata_bulk_patch`、`trash_comics`、`restore_comics`、`purge_comics`、`update_local_library_root`，以及本次新纳入的跨 Comic 批量写：`import_comic_metadata`、`rename_tag`、`delete_tags_by_names`、`rename_author`、`delete_authors_by_names`、`rename_named_facet_name`、`delete_named_facet_by_names`、`merge_named_facet_name`、`clear_all_reading`。

不纳入：只写字典且幂等的 `add_tag` / `add_named_facet_name` / `import_tag_dictionary`；单 Comic 的 `replace_comic_named_facet` 与全部单 Comic 用户写；Series 成员排序（ADR-0006 用字段锁解决）。

`import_comic_metadata` 在解析 payload 之前取锁（plan 阶段读匹配索引也在锁内），每本记录一个事务写入全部字段；不再单独调用 `set_comic_meta_locks`（九个字段全部写入时 auto-lock 已等价置满）。

顺带修正两处同族缺陷：`delete_authors_by_names` 的三条 DELETE（`author_links` / `comic_authors` / `authors`）现在同一事务，避免中途失败留下悬挂作者；`LibraryWriteTxn` 增加 `rollback()`，让「放弃这次写」有确定性表达（drop 的回滚由 sea-orm 在连接回收时完成）。

## Consequences

### Positive

- 并发与原子性保证变成可读的接口契约：新库级写只需选 `with_library_write` 或 `begin_library_write_txn`。
- 补上 `import_comic_metadata` 的漏锁与双重事务；`delete_authors_by_names` 的三条 DELETE 现在同一事务。
- Metadata refresh 的写入集边界与 Library sync 对齐：`upsert_comics` 虽然已经拥有 16 列 `comic_meta` 写入集与四个 junction 替换，但刷新路径此前把同一份写入集拆成逐条自动提交，失败会在库里留下「`comics` 已更新、`comic_meta` 未更新」的撕裂行；现在逐 Comic 单事务。
- `upsert_comics` 返回未写入的 Comic（`page_count <= 0`），调用方不再把「什么都没写」当作成功。
- fail-fast 由集成测试覆盖到全部持锁入口：`tests/library_write_lock.rs`（Library sync、元数据备份导入、Tag / Author / Named facet 的批量改名与删除、清空阅读历史）、`tests/comic_trash.rs`（trash / restore / purge）、`tests/comic_metadata_bulk_patch.rs`、`tests/metadata_refresh.rs`（三个 refresh）、`tests/update_local_library_root.rs`。

### Negative

- 未覆盖全部写入口（其余多为单 Comic 用户写）；「批量写必须持锁」仍由 ADR 与评审约束，而非类型强制。
- 命名双轨（公开入口 + `*_locked` 体）要求实现者记住「内部不得再走接缝」，误用会表现为运行时 busy 错误。这里刻意不做运行时重入检测：锁本身不记录属主，检测无法区分「合法持有者再次申请」和「另一个写者」，只由文档、命名与测试约束。
- Library sync / Metadata refresh 进行中，标签与作者重命名、清空阅读历史、导入元数据备份会直接失败（不排队）。

## References

- `GLOSSARY.md` — Library、Comic、Library sync、Metadata field lock
- ADR-0007 — Metadata field locks
- ADR-0013 — Path migration
- ADR-0018 — 测试三层缝
- ADR-0022 — Comic metadata bulk patch（逐本事务 + 单飞先例）
- ADR-0023 — Comic trash → Comic purge（逐本 purge 事务）
