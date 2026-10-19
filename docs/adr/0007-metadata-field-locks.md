# ADR-0007: Comic / Series metadata field locks（Komga 式）

## Status

Accepted

## Context

Library sync 原先对已存在 Comic 采用「库内元数据优先」：`title` / `content_rating` / `authors` / `tags` 始终保留，`description` / `published_at` 仅在空值时回填。这无法区分「用户刻意保留」与「首次扫描写入」，也无法在解锁后接受 ComicInfo / EPUB 等解析修正。

Series 成员排序已有 ADR-0006 的 `sort_order_locked`；Series 名称等用户字段在 rebuild 时从不覆盖文件夹推导名，同样缺少显式锁。

Komga 的模型是：字段级锁；编辑自动上锁；未锁定且刷新源有值时可覆盖；可手动切换锁。

## Decision

### 范围

- **Comic**：`title`、`description`、`published_at`、`content_rating`、`authors`、`tags`、`languages`、`parodies`、`characters`（整字段一把锁）。
- **Series**：`name`、`serialization_status`、`total_count`。
- **SeriesItem**：补齐 `sort_order_locked` 的解锁 API（与 ADR-0006 配套）。

物理字段（`path` / `page_count` / `resource_*`）不参与锁。

### Sync / rebuild 语义

- **未锁定 + 扫描有值** → 用扫描结果覆盖。
- **已锁定** → 保留库内值。
- **未锁定 + 扫描空/缺** → 不清除（对齐 Komga 对「源侧缺失」的保守处理）。
- `content_rating`：扫描侧当前固定为 `unknown` 时**不覆盖**；`authors` / `tags` / `languages` / `parodies` / `characters` 仅在扫描列表非空时替换。
- Series：仅 `name` 在未锁时由文件夹名覆盖；`serialization_status` / `total_count` 无扫描源，sync 永不改写。
- 解锁只改标志，不自动触发 Library sync 或 Metadata refresh；下次用户发起的 sync / rebuild / Metadata refresh 再生效。
- 用户主动的 Metadata refresh（单本 Comic 或 Series 成员批量）与 Library sync 使用同一套 merge / 字段锁规则；refresh 不删除 orphan、不重建成员排序、不重生成缩略图。

### 写入与 API

- `update_comic_user_meta` / `update_series_user_meta`：本次写入的字段（`Some` / 显式 clear）自动 `*_locked = true`。
- Comic / Series metadata form 保存时只提交相对打开时**值变化**的字段；未改不写、不加锁；全部未改则不调用 update。
- `set_comic_meta_locks` / `set_series_meta_locks`：按字段 Optional 补丁只改锁。
- `set_series_item_sort_order_locked`：设置排序锁（含解锁）。
- 读路径 DTO 带回各锁标志；UI 在编辑表单旁提供锁开关。

### 持久化与默认值

- `comic_meta` / `series` 表布尔列，默认 `false`（未锁）。
- 存量与新建均默认未锁（升级后首次 sync 可能覆盖未锁字段）。

### 字段表与归一化（实现约定）

- 字段清单只有一处：`core/crates/core/src/metadata_lock/field.rs` 的 `ComicMetaField` / `SeriesMetaField`。每个变体给出 `as_str()`（锁标志键，也是列式字段的 `comic_meta` 值列、`ComicMetaLocks` 的 serde 键）、`lock_column()`（`{as_str}_locked`）、`has_scan_source()`，以及 `storage()`：值在 `comic_meta` 列上（`ComicMetaStorage::Column`）还是挂在附着表（`ComicMetaStorage::Junction { table, key_column }`）。附着式字段为 `authors`（`comic_authors.author_id`，作者稳定身份见 ADR-0024）、`tags`（`comic_tags.tag_name`）、`parodies`、`characters`；`languages` 是列式字段。
- auto-lock（`ComicAutoLocks` / `SeriesAutoLocks`）与 `set_comic_meta_locks` / `set_series_meta_locks` 的补丁都遍历该字段表；写锁列的 `apply_comic_lock` / `apply_series_lock` 是穷尽 `match`，新增字段未接线时无法编译。
- `has_scan_source()` 是「该字段是否有扫描源」的**声明性契约**（Series 仅 `name`），由守卫测试 `scan_sources_match_adr_0007` 固定；它不参与运行时分支——各字段的 merge 路径签名不同，合并规则在 `metadata_lock::comic` / `metadata_lock::series`。Comic 的 `ComicMetaLocks` 由 `comic_meta_locks_serde_keys_match_field_table` 钉住 serde 键，Series 的 `SeriesMetaLocks` 无 serde 键，由 `series_locks_mirror_the_field_table` 钉住字段名。
- 归一化口径集中在 `core/crates/core/src/metadata_lock/normalize.rs`：
  - `normalize_names`：trim、丢空、保序去重、**保大小写**，用于落库值（`languages` 列与各附着表的名字序列，保证字典行与附着行按同一顺序写入）。
  - `normalize_match_tokens`：trim、小写、丢空、保序保重，用于 filter / 查询串（`ComicFilterDto::normalized`）。
  - `normalize_tag_expression_tokens`：trim、小写、丢空、排序去重，用于 tag 表达式搜索的候选集合。
  - 匹配侧的大小写由 SQL `lower(...)` 兜住（`core/crates/core/src/comic/filter_predicate.rs`），所以落库保留原样、不强制小写。
- 多值补丁代数（`MultiValueOp` / `MultiValuePatch` / `merge_multi_value`）在 `metadata_lock/multi_value.rs`；`comic::bulk_patch` 复用它并 re-export，single-comic 写入与批量补丁共享同一份 add / remove / replace 语义。
- 落库名序列统一走 `normalize_names`，因此**空名不再落库**：`""` 与纯空白名被 trim 后丢弃（此前 `comic_tags` / `comic_parodies` / `comic_characters` 的写入可能插入 `""` 字典/附着行，author 路径可能保留纯空白名）。既有库中的历史空名行不迁移；Metadata backup 的孤儿计数（`count_new_orphan_names`）复用同一规则。

### 新增一个 Metadata 字段的清单

1. 在 `ComicMetaField`（或 `SeriesMetaField`）加变体，并补齐 `ALL`、`as_str`、`lock_column`、`storage`、`has_scan_source`：四个方法的 `match` 臂是穷尽的，漏接线会**编译失败**；`ALL` 由 `field_tables_list_every_variant`（字段表枚举）与各守卫测试固定，漏进 `ALL` 时 `index()` 一旦被调用即 panic。
2. 加迁移：列式字段补值列 + `*_locked` 布尔列；附着式字段建附着表并补齐 key 列。
3. 在 `update_*_user_meta` 的写入分支、读路径 DTO 与表单中接线（DTO 的 `is_written` / `patch` 是穷尽 `match`，漏接线会编译失败）。
4. 跑 `metadata_lock::field` 的守卫测试：它在内存库跑全部迁移并比对 `PRAGMA table_info`——缺锁列、缺值列 / key 列、或出现未登记的锁列都会失败。

## Consequences

### Positive

- 用户编辑与扫描刷新可共存，语义与 Komga 及 ADR-0006 一致。
- 空扫描结果不会误清空标签/作者/分级。

### Negative

- 默认未锁会使升级后第一次 sync 可能改写既有标题等；用户需主动上锁或接受扫描结果。
- `content_rating` / `tags` 在缺少可靠扫描源时，解锁几乎不产生覆盖效果。
- 锁列与 UI/DTO 面扩大，测试需覆盖 merge、自动锁、补丁锁与排序解锁。
- 归一化只对**新写入**生效：库里既有的未 trim 名字（`" Action "` 与 `"Action"`）不会被迁移合并，需要时另行清洗。

## References

- `GLOSSARY.md` — Comic metadata form / Series metadata form / Library sync
- ADR-0006 — Series item sort order lock
- ADR-0022 — Comic metadata bulk patch（多值 add / remove / replace 语义现由 `metadata_lock::multi_value` 提供）
- Komga Edit Metadata — field locks
- Implementation locality: `core/crates/core/src/metadata_lock/`（字段表 `field.rs` + 守卫测试、Comic merge、Series name / sort resolve、user-meta auto-lock、归一化 `normalize.rs`、多值补丁代数 `multi_value.rs`）；Library sync / Metadata refresh / comic·series write 共用该 interface
