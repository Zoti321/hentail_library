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

## `comic/public/shell` 消费者基线（阶段 1 清单）

`features/comic/public/shell/library_browse_shell_exports.dart` 是 #457 壳接缝（re-export presentation），**非领域 API**；阶段 2 可收窄。观测（`integrate/md3e`）：

| 符号（经 shell / 等价 bridge） | 实际消费方 |
| --- | --- |
| `ComicCardHost`、return-series / series-nav VM、`comic_read_progress`、bulk presenter、metadata draft/present/page | **`library_browse`** 经 `presentation/integrations/comic_presentation_bridge.dart`（browse 内同符号 deep export；壳文件大量 `import` 该 bridge） |
| 其它 feature（`series` / `read_session` / `comic_trash` / `reading_history` / `app_settings` / bootstrap） | 多用 `comic/public` 窄路径（cover、lookup、display_title、DI），**不**依赖 shell 桶 |

结论：browse 主路径已走本地 bridge；`public/shell` 仍经 `comic/public.dart` 对外暴露，收窄前勿假定「无外部消费者」。

## Cross-feature

- 允许：`library_browse` → `comic` / `series` public；`series` → `comic` public（封面）。
- 禁止：`comic` → `series` public（连读上下文经 `SeriesReadingContextPort` @ shared/di）。

## 参考

- ADR-0036、ADR-0035、ADR-0034、ADR-0002、ADR-0026
- [`shared-domain-ownership.md`](shared-domain-ownership.md)
