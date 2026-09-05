# ADR-0006: Series item sort order lock（Komga 式手动排序）

## Status

Accepted

## Context

Series 成员默认按 sync 时文件名自然排序写入 `SeriesItem.order`。用户有时需要手动调整系列内单本漫画的相对位置（例如在中间插入一卷、把番外放到末尾），且希望该调整在后续 Library sync 中不被文件名排序覆盖。

Komga 等同类产品的常见做法是：用户编辑排序值后，将该条目标记为「已锁定」，sync/rebuild 时跳过对锁定项 order 的自动重写，仅对未锁定项重新按文件名排序。

此前 `order` 为整数，无法表达「插入到两卷之间」的细粒度位置；Flutter 侧系列详情也未提供编辑入口。

## Decision

### 数据模型

- `SeriesItem.sort_order` 迁移为 **REAL（Dart `double`）**。
- 新增 **`sort_order_locked`**（bool，默认 false）。
- 领域层 `SeriesItem.order` 同步为 `double`；新增 `sortOrderLocked`。

### 写入语义

- 新 API **`updateSeriesItemSortOrder(seriesId, comicId, sortOrder)`**：
  - 设置 `sort_order = sortOrder`；
  - 设置 **`sort_order_locked = true`**。
- **`setSeriesItemsOrder`**（按 comicId 列表批量重排）保留，供后续拖拽排序等场景；本 ADR 不扩展其锁定语义。
- Library sync / folder series rebuild：
  - **已锁定**成员：保留现有 `sort_order` 与 `sort_order_locked`；
  - **未锁定**成员：仍按文件名自然排序写入 `sort_order`。
- **`set_series_item_sort_order_locked(seriesId, comicId, locked)`**：可单独解锁；解锁后下次 rebuild 按文件名重编号（见 ADR-0007）。

### 读取与 UI

- **`fetchSeriesComicsPage`** 返回 **`PagedSeriesComicsResult`**，每项含 `(comic, sortOrder)`，供系列详情分页网格使用。
- 成员排序编辑并入 **Comic 元数据对话框**（常规页分区；无 Series 归属时隐藏）；一次保存编排元数据写入与 `updateSeriesItemSortOrder` / 锁。
- 系列详情（desktop / 非 compact）：封面 hover 铅笔与右键 / 长按菜单打开同一元数据对话框（带排序种子）；卡片 **不展示** 排序数字。
- 校验：必填、有限数字；允许负数与重复值（由用户自行承担语义）。
- 排序有变更时保存后 bump library revision（系列漫画 catalog 随之刷新）。

## Consequences

### Positive

- 手动排序与 sync 自动排序可共存，行为与 Komga 等预期一致。
- 浮点 order 支持在两卷之间插入。
- 锁定粒度为单本，不影响同系列其他成员。

### Negative

- 重复或任意浮点 order 可能导致阅读器卷序与用户直觉不一致（有意不强制唯一）。
- sync rebuild 逻辑需维护锁定集合，测试面扩大。
- 旧整数 order 经迁移转为 REAL；极端大整数无精度问题（漫画系列规模下可忽略）。

## References

- `CONTEXT.md` — Series / Folder series
- ADR-0005 — Series reading context（卷序仍按 order 排序后的 comicId 列表派生）
