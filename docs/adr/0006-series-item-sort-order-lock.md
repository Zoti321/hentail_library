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
- **`setSeriesItemsOrder`**（按 comicId 列表批量重排）为核心批量写序 API（无系列详情拖拽 UI；元数据对话框走单条 `updateSeriesItemSortOrder`）：
  - 入参为该 Series 的**完整新序** comicId 列表；仅对现存成员生效，重复/非成员忽略。
  - **锚点 + 夹缝插值**分配 `sort_order`：从左到右贪心保留「已锁且其原值严格大于上一保留锚点」的成员原 `sort_order` 作为锚点；未锁成员、以及会破坏严格递增的已锁成员，改由相邻锚点间线性夹缝插值重算；首锚点前 / 末锚点后按 1.0 步长外推；若无任何锚点，退化为 `1..n` 顺序编号。
  - 本次提交的**所有成员一律** `sort_order_locked = true`，使后续 Library sync 不再按文件名覆盖该顺序。
  - 整批在**单事务**内提交，失败回滚保持 DB 一致。
  - 结果 `sort_order` 序列严格递增；已锁成员在相对顺序未变且与已保留锚点相容时保留原数值。
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

> **实现修订（2026-09-16）**：`setSeriesItemsOrder` 的语义（完整新序入参、锚点 + 夹缝插值、全员加锁、单事务）不变，但它**降级为 core-only**：#121 的系列详情拖拽 UI 被回退后该 API 无任何消费方，故删除 Dart `SeriesRepository` 声明 / `SeriesRepositoryImpl` 实现与 `set_series_items_order_frb`（顺带少一个 sync FRB 写入口，见 #129），仅保留 `core` 实现与 `core/crates/core/tests/series_item_sort_order.rs` 的测试守护。重排 UI 阻塞于缺少满足要求的网格拖拽方案（见 #121），解除阻塞时经 FRB codegen 重新上桥即可。

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
