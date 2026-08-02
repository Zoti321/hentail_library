# ADR-0007: Comic / Series metadata field locks（Komga 式）

## Status

Accepted

## Context

Library sync 原先对已存在 Comic 采用「库内元数据优先」：`title` / `content_rating` / `authors` / `tags` 始终保留，`description` / `published_at` 仅在空值时回填。这无法区分「用户刻意保留」与「首次扫描写入」，也无法在解锁后接受 ComicInfo / EPUB 等解析修正。

Series 成员排序已有 ADR-0006 的 `sort_order_locked`；Series 名称等用户字段在 rebuild 时从不覆盖文件夹推导名，同样缺少显式锁。

Komga 的模型是：字段级锁；编辑自动上锁；未锁定且刷新源有值时可覆盖；可手动切换锁。

## Decision

### 范围

- **Comic**：`title`、`description`、`published_at`、`content_rating`、`authors`、`tags`（整字段一把锁）。
- **Series**：`name`、`serialization_status`、`total_count`。
- **SeriesItem**：补齐 `sort_order_locked` 的解锁 API（与 ADR-0006 配套）。

物理字段（`path` / `page_count` / `resource_*`）不参与锁。

### Sync / rebuild 语义

- **未锁定 + 扫描有值** → 用扫描结果覆盖。
- **已锁定** → 保留库内值。
- **未锁定 + 扫描空/缺** → 不清除（对齐 Komga 对「源侧缺失」的保守处理）。
- `content_rating`：扫描侧当前固定为 `unknown` 时**不覆盖**；`authors` / `tags` 仅在扫描列表非空时替换。
- Series：仅 `name` 在未锁时由文件夹名覆盖；`serialization_status` / `total_count` 无扫描源，sync 永不改写。
- 解锁只改标志，不自动触发 Library sync；下次用户发起的 sync / rebuild 再生效。

### 写入与 API

- `update_comic_user_meta` / `update_series_user_meta`：本次写入的字段（`Some` / 显式 clear）自动 `*_locked = true`。
- Comic / Series metadata form 保存时只提交相对打开时**值变化**的字段；未改不写、不加锁；全部未改则不调用 update。
- `set_comic_meta_locks` / `set_series_meta_locks`：按字段 Optional 补丁只改锁。
- `set_series_item_sort_order_locked`：设置排序锁（含解锁）。
- 读路径 DTO 带回各锁标志；UI 在编辑表单旁提供锁开关。

### 持久化与默认值

- `comic_meta` / `series` 表布尔列，默认 `false`（未锁）。
- 存量与新建均默认未锁（升级后首次 sync 可能覆盖未锁字段）。

## Consequences

### Positive

- 用户编辑与扫描刷新可共存，语义与 Komga 及 ADR-0006 一致。
- 空扫描结果不会误清空标签/作者/分级。

### Negative

- 默认未锁会使升级后第一次 sync 可能改写既有标题等；用户需主动上锁或接受扫描结果。
- `content_rating` / `tags` 在缺少可靠扫描源时，解锁几乎不产生覆盖效果。
- 锁列与 UI/DTO 面扩大，测试需覆盖 merge、自动锁、补丁锁与排序解锁。

## References

- `CONTEXT.md` — Comic metadata form / Series metadata form / Library sync
- ADR-0006 — Series item sort order lock
- Komga Edit Metadata — field locks
