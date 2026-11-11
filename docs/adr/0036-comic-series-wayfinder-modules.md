# ADR-0036: Comic / Series Wayfinder 模块切分

## Status

Accepted

## Context

`library_browse` 同时承担单本 Comic、Series、库页双 Tab 壳与作者详情，虽已有内部分区文档（`library-browse-zones.md`），但 **Wayfinder module id** 仍为单一 feature，cross-feature public 图、Application 编排与 Gate 模块图可读性不足。Epic [#436](https://github.com/Zoti321/hentail_library/issues/436) 已将多数 Dart 域真源 owner 化；[#457](https://github.com/Zoti321/hentail_library/issues/457) 将 Comic 与 Series **物理模块**从 browse 壳拆出，并与 ADR-0033（Application）、ADR-0034（public only）、ADR-0035（Catalog Shared Kernel 留 shared）对齐。

## Decision

### 1. 三个 product module

| Module id | Owner 语义 |
|-----------|------------|
| **`comic`** | 单本 Comic 仓储、库 Comics Tab 规则类型、用户元数据/缩略图、展示标题、smart facet、详情/bulk/删除 UI、`ComicDetailReturnSeriesPort` 实现、Comic metadata application |
| **`series`** | Series 仓储、库 Series Tab 规则类型、详情与 metadata UI、Series metadata application、`SeriesReadingContextPort` 实现 |
| **`library_browse`** | 当前库双 Tab 壳、搜索、作者详情、`presentation/catalog` 共用基础设施；跨 Tab 年龄限制等壳层偏好 public |

**Catalog 实体 DTO**（`Comic`/`Series` 等）、分页 VO、`thumbnail/**`、`SeriesReadingContext` **类型** 仍 @ `shared/domain`（**ADR-0035 不变**）。

### 2. Cross-feature public 依赖（无环）

- 允许：`library_browse` → `comic` / `series` public；`series` → `comic` public（封面/展示）；`reader` / `home` / `reading_history` / `comic_trash` → `comic` public；`bootstrap` → 各 module public。
- **禁止**：`comic` → `library_browse` / `series` / `reader`；`series` → `library_browse`；`reader` → `comic`（存量三条 public 读取边 shrink-only，见 `test/architecture/module_boundary_test.dart`）。reading context 经 **`shared/di` + `SeriesReadingContextPort`**（series 实现）。
- Gate：`kImportBoundaryModules` 含 `comic`、`series`；**R5** 扩展至 `comic` / `series`（禁止 import `reader`）。2026-11-11 起由 `test/architecture` 执行**显式禁止边表**（`import` + `export`）。

### 2.1 跨模块只读投影（2026-11-11，#488）

- 壳（`library_browse`）持查询态，模块持查询规则与能力；跨模块只走三条通道：**Port（命令）**、**领域事件（事实）**、**只读投影 record**。
- 库页列表行使用**匿名 record**（comic：`({String comicId, String title, int pageCount, String path})`；series：`({String id, String name, int volumeCount})`），由 owner 仓储直接返回，不再定义 `ComicBrowseListItem` / `SeriesBrowseListItem` 具名类。
- 组装器（`ComicCatalogQueryAssembly` / `SeriesCatalogQueryAssembly`）属壳：`library_browse/presentation/browse/models/`，组合查询意图与 owner `public/library_age_restriction_*` 扩展方法。
- 具名化后再跨模块导出 record 等价 DTO **禁止**；理由与边界见 **ADR-0040**。

### 3. Application 层（ADR-0033）

- `comic/application/`：Comic 用户元数据保存（原 presentation apply）。
- `series/application/`：Series 元数据落库编排（自 `series_metadata_form` 迁出）；Series 成员排序持久化。

### 4. 文档取代关系

- **`library-browse-zones.md`** 中「不新增 Wayfinder module」表述由本 ADR **supersede**；分区表修订为三 module + browse 壳保留路径。
- **`shared-domain-ownership.md`** owner 表同步：`comic` / `series` / `library_browse` 分列。

## Consequences

### Positive

- Module 图与 Issue 边界一致；L3b 可删除 `series_metadata_form` → feature domain 边。
- `reader` 与详情页经窄 Port 协作，避免 public 环。

### Negative

- 一次性大量路径与 import 变更；shell VM 仍须经 `comic`/`series` public 引用 Tab 规则类型。

## References

- ADR-0033、ADR-0034、ADR-0035
- GitHub #457
