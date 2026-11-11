# `library_browse` 与 Comic / Series 模块（ADR-0036）

**2026-11-05**：Comic 与 Series 已拆为独立 feature **`comic`**、**`series`**（[#457](https://github.com/Zoti321/hentail_library/issues/457)）。本文件描述 **browse 壳** 与两 feature 的协作；完整决策见 **ADR-0036**。

**Catalog 实体 DTO**（`Comic`、`Series` 等）仍 @ `shared/domain`（**ADR-0035**）。

## 模块一览

| Feature id | 语义 | 代码落点 |
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

## Comic 聚合 vs Dart feature（一致性边界）

- **Comic 聚合写集**（Rust 真源，ADR-0002 / 0026）：同事务内 `comics` + `comic_meta`（含 Metadata field lock）+ authors/tags/parodies/characters junction。单本用户元数据写**不持**库级写锁。
- **Dart `features/comic`** 是 feature / 限界上下文：仓储契约、Comics Tab 规则、详情与元数据 UX、窄 public。**不是** Aggregate Root 类，也不在 Dart application 复刻 lock / sync merge。
- **外置**：Series 成员与排序（`series`）、Comic trash 生命周期（`comic_trash`）、阅读历史、跨本 bulk / sync（`library_admin` + 库级写锁）。
- Catalog 实体 DTO 仍 @ Shared Kernel（ADR-0035）；勿为目录整齐迁入 `comic/domain`。

## browse ↔ comic/series 壳接缝（2026-11-11 终态，#488）

- **已删除** `presentation/integrations/{comic,series}_presentation_bridge.dart` 与 `public/catalog/for_comic_and_series.dart`。bridge 用 `export` 转发跨模块 presentation，旧门禁只扫 `import` 因此隐形；现由 `app/test/architecture/module_boundary_test.dart` 同时扫 `import` + `export`。
- **壳持查询态**：搜索/筛选/排序/分组状态与分页组装留在 `library_browse`；`ComicCatalogQueryAssembly` / `SeriesCatalogQueryAssembly` 在 `presentation/browse/models/`。
- **模块持规则与能力**：`comic` / `series` 的筛选/排序/分组/年龄限制规则通过 owner `public/library_*_browse_rules.dart` 与 `public/library_age_restriction_*.dart` 暴露；列表行是匿名 record（见 ADR-0040）。
- **browse 单向 watch**：`ref.watch` owner `public/di` 的 token（`comicDetailProvider`、`comicReadPageIndexByIdProvider` 等）；模块不反向读壳。
- **R12**：`public/` 对自身 `presentation/` 的 `import`/`export` 见 `app/test/gate/public_presentation_export_allowlist.txt`（条目数棘轮只减不增）。

## Cross-feature

- 允许：`library_browse` → `comic` / `series` public；`series` → `comic` public（封面）。
- 禁止：`comic` → `library_browse` / `series` / `reader`；`series` → `library_browse`（连读上下文经 `SeriesReadingContextPort` @ shared/di）。
- 门禁：`module_boundary_test.dart` 的显式禁止边表；`reader → comic` 存量 public 边 shrink-only。

## 参考

- ADR-0036、ADR-0035、ADR-0034、ADR-0002、ADR-0026
- [`shared-domain-ownership.md`](shared-domain-ownership.md)
