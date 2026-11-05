# `library_browse` 与 Comic / Series 模块（ADR-0036）

**2026-11-05**：Comic 与 Series 已拆为独立 Wayfinder module **`comic`**、**`series`**（[#457](https://github.com/Zoti321/hentail_library/issues/457)）。本文件描述 **browse 壳** 与两 module 的协作；完整决策见 **ADR-0036**。

**Catalog 实体 DTO**（`Comic`、`Series` 等）仍 @ `shared/domain`（**ADR-0035**）。

## 模块一览

| Module id | 语义 | 代码落点 |
| --- | --- | --- |
| **`comic`** | 单本漫画、Comics Tab 规则、详情/metadata/bulk | `features/comic/{domain,data,application,presentation,public}/` |
| **`series`** | 系列、Series Tab 规则、详情/metadata | `features/series/...` |
| **`library_browse`** | 当前库双 Tab 壳、搜索、作者详情、`presentation/catalog` | `features/library_browse/...` |

## `library_browse` 壳内保留

| 路径 | 内容 |
| --- | --- |
| `domain/browse/` | 库页 request 编排、年龄限制投影偏好、跨 Tab facet selection（**不含** `library_comic_*` / `library_series_*` 规则类型） |
| `presentation/browse/` | `library_md3e_*`、搜索、browse VM |
| `presentation/catalog/` | 双 Tab 共用分页/选择、metadata 编辑导航/锁 UI |
| `presentation/author/` | 作者详情 |

Comics/Series Tab **筛选/排序/投影规则类型** 分别 @ `comic/domain`、`series/domain`；壳 VM 经 **`comic/public`**、**`series/public`** 引用（ADR-0034）。

## Cross-feature

- 允许：`library_browse` → `comic` / `series` public；`series` → `comic` public（封面）。
- 禁止：`comic` → `series` public（连读上下文经 `SeriesReadingContextPort` @ shared/di）。

## 参考

- ADR-0036、ADR-0035、ADR-0034
- [`shared-domain-ownership.md`](shared-domain-ownership.md)
