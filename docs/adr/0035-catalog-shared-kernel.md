# ADR-0035: Catalog Shared Kernel（`shared/domain` 保留）

## Status

Accepted；**Comic 部分被 [ADR-0041](0041-comic-entity-ownership.md) 局部取代（2026-11-11）；Series 部分被 [ADR-0042](0042-series-entity-ownership-and-cross-module-contracts.md) 局部取代（2026-11-11）**。Author / AuthorDetail / Tag / 分页 VO / `enums.dart` 结论仍有效。

> **实现修订（2026-11-11，#489 / ADR-0041）**：`Comic` 实体、`ComicMetaLocks`、`ComicMetadataForm` 与 FRB 映射已迁入 `features/comic/`；`shared/domain` 不再有 Comic 类型，跨模块经 `features/comic/public/**` thin re-export。
>
> **实现修订（2026-11-11，#490 / ADR-0042）**：`Series` / `SeriesItem` / 系列锁、元数据表单与 FRB 映射已迁入 `features/series/`；`shared/domain` 不再有 Series 实体/VO，跨模块只经 Port 与只读 record。下文凡称「Series 等内核 DTO 留在 shared」的表述仅对 Author / AuthorDetail / Tag / 分页 VO / `enums.dart` 成立。
>
> **实现修订（2026-11-12，#533 / ADR-0048）**：`Author` / `AuthorDetail` / `Tag` 已迁入 `features/comic_metadata/domain/`（模块原 `named_metadata`），跨模块经 `features/comic_metadata/public/comic_metadata_entities.dart`；`shared/di` 的全局 Author / Tag 字典 token 同迁 owner `public/di`。下文凡称这三个类型「留在 shared」的表述失效；分页 VO、`enums.dart`、`thumbnail/**` 与豁免 Port 结论不变。

## Context

> **实现修订（2026-11-12，ADR-0049）**：`SerializationStatus` 归 series；`ContentRating`、Comic Language 与两个筛选 pick 归 comic；资源格式类别归 library_admin；资源类型 wire 映射归 shared/data。下文关于完整 `enums.dart` 与这些 VO 留 shared 的历史结论由 ADR-0049 局部取代。分页、资源类型、缩略图优先级、浏览目标及不可达引用协议继续共享。

Epic [#436](https://github.com/Zoti321/hentail_library/issues/436) 将各限界上下文的**规则、端口与 Repository 契约**迁入 owner feature（#437–#444 已落地），但下列 **Catalog 相关类型**仍集中在 `shared/domain`，且在多 feature 与 `shared/ui` 中广泛引用：

| 区域 | 典型路径 | 主要消费者 |
|------|----------|------------|
| 实体 DTO | `models/entity/comic/**`（Author、AuthorDetail、Tag 等；**Comic 已于 2026-11-11 迁出**，见 ADR-0041；**Series 迁出**，见 ADR-0042） | library_browse、reader、home、named_metadata、comic_trash、shared/data FRB mapper、`shared/ui` |
| 枚举与展示辅助 | `models/enums.dart` | 库筛选、阅读、UI 组件 |
| 分页值对象 | `models/value_objects/page_request.dart`、`paged_result.dart`、`page_jump.dart` | 各 Repository 契约、FRB 分页 |
| 缩略图 seam | `thumbnail/**` | 封面/缩略图组件、Series cover、FRB 事件 |

Rust `core/` 仍为扫描、sync 与 catalog 谓词真值（ADR-0002）；Dart 侧上述类型主要是 **FRB 映射与 UI 编排用的共享 DTO**，不是单一 feature 私有的富领域模型。

备选方案曾认真权衡：

1. **保留 Shared Kernel @ `shared/domain`**（本 ADR）。
2. **`library_browse` single-owner**：实体迁入 `features/library_browse/domain/`，经 `library_browse/public` 对外；`shared/ui` 与其余 feature 改 import public。  
   - 优点：目录归属与「库页/catalog UX」叙事一致。  
   - 缺点：reader、home、comic_trash、named_metadata、bootstrap、`shared/data` 适配器与 **`shared/ui` 大面积改边**；易触发 ADR-0034「public 第二套 DTO」反模式；与 FRB 映射层分散在 multi-feature data 的现状冲突。

在 #437–#444 已完成的迁移中，**catalog 行为**（筛选 intent、投影、展示标题等）已 owner 化；**内核 DTO 仍留在 shared** 与现行 Gate（R11、L3b、strangler）一致。

## Decision

### 1. 保留 Catalog Shared Kernel 于 `shared/domain`

以下路径 **继续作为 Shared Kernel**，**不**在 Epic #436 后续批次中整体迁入单一 product feature：

- `shared/domain/models/entity/comic/**`（**仅 Author / AuthorDetail / Tag / library**；`comic/comic.dart` 于 ADR-0041 迁出，Series 于 ADR-0042 迁出）
- `shared/domain/models/enums.dart`（及与 catalog 强绑定的 enum 导出面）
- `shared/domain/models/value_objects/page_request.dart`、`paged_result.dart`、`page_jump.dart`
- `shared/domain/thumbnail/**`

**Owner 关系（语义，非物理目录）**

| 语义 owner | 已 / 将 位于 feature `domain/` 的内容 | 仍 @ Shared Kernel 的内容 |
|------------|----------------------------------------|---------------------------|
| library_browse | 筛选/排序/投影、`comic_display_title` 等 | Author / Tag 等 **实体 DTO**、分页 VO（Series 已迁 series，ADR-0042） |
| reader | 阅读域类型、`ReaderComicRef` 窄读模型、会话端口（ADR-0038；旧 read_session） | —（Comic 已迁 comic，ADR-0041） |
| series | Series 实体/VO/仓储/表单（ADR-0042） | 跨模块契约：`SeriesReadingContext`、`SeriesItemMembership`、`SeriesItemSortPort`、`SeriesCoverSource` |
| 其他 feature | 各自 Repository 契约、read model（#443–#444） | 通过 import **`shared/domain`** 引用内核类型 |

### 2. 与 ADR-0034 的关系

- **Cross-feature 协作**仍仅 `features/*/public/**`（M1）；**Shared Kernel 类型不通过 public export**（避免第二套 DTO）。**例外**：`Comic` 已归 `comic` feature，跨模块经 `features/comic/public/**` **thin re-export**（ADR-0041），不产生第二套类型。
- Consumer feature **允许** `import package:hentai_library/shared/domain/...` 引用内核实体与 VO。
- **`shared/**` 仍不得** import `features/*/public/**`（R11）；内核定义留在 `shared/domain`，不由 shared re-export 依赖 feature public 真源（与 #437–#444 strangler 方向相反：feature 真源 → shared thin export，**不适用于内核**）。

### 3. 明确拒绝的方案

- 将 Comic/Series 等 **整体**迁入 `library_browse/domain` 并强制其余模块只读 browse public——**不采用**（Comic 归 `comic`、Series 归 `series`，见 ADR-0041 / ADR-0042）。

### 4. 后续迁移触发条件（再开 ADR 或修订本 ADR）

仅当 **至少一条**成立时，才启动「内核迁出 shared」专项（新 Epic / ADR 修订），并单独评估 Gate：

1. **消费者收缩**：除 `library_browse` 外，不再有 product feature 或 `shared/data` 直接依赖 Comic/Series 实体（Comic/Series 已分别迁出，ADR-0041 / ADR-0042）。
2. **`shared/ui` 解耦**：封面/列表/详情组件不再直接依赖 catalog 实体（Comic / Series 的 shared/ui 专属资产已分别由 ADR-0041 / ADR-0042 收割）。
3. **Dart 域行为膨胀**：Comic/Series 上需长期维护的 **Dart-only 不变式**明显多于 FRB 映射，且 owner 可单一化为 browse（或独立 `catalog` 包）。
4. **包边界**：Catalog 内核拆为独立 Dart package（非 Wayfinder feature id），由 app 与 features 共同依赖。

未满足上述条件时，**禁止**仅为目录整齐而批量移动内核文件（Epic #446 收尾时亦不得默认迁移内核）。

> **书面判定（2026-11-11，#503 / ADR-0045）**：四条触发条件中只有第 1 条（消费者收缩）已满足，第 2–4 条均不满足，故 **不启动**「内核整体迁出 shared」专项。`metadata_refresh_types.dart` 与 `library_management_port.dart` 保留 shared 属 ADR-0045 的「shared 消费方豁免」，**不是遗留**；series 的 Slot / Port 终态经核查只跨 comic / series、且 ADR-0036 禁止边已定案，**保持现状**，不另立票。
>
> **实现修订（2026-11-12）**：上一段的 `metadata_refresh_types.dart` 豁免**已解除**——真源迁 `library_admin/domain/`，toast 迁 `library_admin/public/ui/`，`shared` 不再消费（详见 ADR-0045 §4 与 §5 修订）。本节 `library/` 相关结论中仅 `library_age_restriction_filter.dart`（跨 Tab 词汇，禁止边 + home 消费）与 `comic_detail_return_series_port.dart`（public 环）继续留 shared。

> **实现修订（2026-11-12，P3/P4 #530 / #531）**：`library_management_port.dart` 的豁免同样**已解除**——全量 Port 真源迁 `library_admin/public/ui/`，shared 只留仅含 `BuildContext` 的 `LibraryBrowseFallbackPort`。`LocalLibrary`（含 `isRemoteLibrary` / `isLocalLibrary` / `localLibraryDisplayName`）、`ScanInterval`、`ScanMode` 迁 `library_admin/domain/`，经 `library_admin/public.dart` 跨模块可见；`shared/domain/models/entity/library/` 目录已删除。`ResourceFormatCategory` 继续留 shared（`app_settings` 消费，搬入 `library_admin` 会构成 public 环）。

### 5. Gate 与工程影响

| 机制 | 内核保留 shared 时的预期 |
|------|-------------------------|
| **M1 / public 图** | 内核 import 不计入 product→product 边；cross-feature 仍只走 public |
| **R11** | shared 不 import feature public；内核文件不得 `export` feature domain 真源 |
| **L3b** | `shared/domain` → `features/` import 仍 ratchet；内核迁移前 **不得**新增 shared→feature 耦合（baseline：`shared_domain_feature_import_baseline.json`） |
| **Strangler shims** | 仅适用于 **feature 真源 → shared thin export**（#437–#444）；内核 **不**建立反向 shim |
| **`shared/ui` → features** | 仍遵守 `shared_ui_no_feature_import` allowlist；内核保留 shared 可避免 UI 为 Comic 类型改 import browse public |
| **codegen-drift** | FRB 与 freezed 生成仍针对现有路径；迁内核时需同步 `build_runner` / FRB 与 CI |

### 6. Epic #436 收尾（#446）含义

- #446 的 baseline 更新与 `shared/domain` 体积 ratchet **针对已迁出的 feature 域**，**不包含**本 ADR 列出的内核路径。
- 索引与文档：本 ADR 取代 #436 子票 #445 的开放决策；#446 可在 PR 中引用 ADR-0035 说明内核范围 excluded。

## Consequences

### Positive

- 与 ADR-0002、现 FRB 布局一致；避免 #436 后期对 `shared/ui` 与多 feature data 的爆炸式改 import。
- catalog **行为**已在 feature domain，**数据形状**在 Shared Kernel，职责清晰。
- Gate 规则可预测：内核不动，strangler 列表不无限增长。

### Negative

- `shared/domain` 仍保留较大体积；新贡献者需读 ADR-0035 区分 kernel vs 已迁出的 owner 域。
- 若未来确需 browse-only 富实体，须单独立项并满足 §4 触发条件。

## References

- ADR-0002、ADR-0017、ADR-0027、ADR-0033、ADR-0034
- Epic [#436](https://github.com/Zoti321/hentail_library/issues/436) 及子票 #437–#446
- `docs/engineering/gate.md`（L3b、strangler shims）
- `app/test/gate/import_boundary_rules.dart`、`strangler_shims.txt`
