# ADR-0045: Port 与读模型按可达性归属（生产者拥有）

## Status

Accepted（2026-11-11，#503）

## Context

`app/lib/shared/domain/` 与 `app/lib/shared/di/` 曾同时装着三种互不相同的东西，路径无法表达归属：

1. **真正的 Catalog Shared Kernel**（`Author` / `Tag` / 分页 VO / `SeriesCoverSource` 等）：被 ≥2 个产品模块消费，无单一 owner。
2. **只服务一个 owner 的领域类型 / 读模型**：例如 `HomeLibraryStat`、`ReadingActivityStats`、阅读历史 Command / Progress Port。它们留在 shared，导致 owner 改自己的读模型必须动 shared。
3. **只服务一个 owner 的 DI token**：`reading_stats_providers.dart` 声明的是 reading_stats 的三个 Port token，reading_stats 却是唯一实现方。

由此产生的具体问题：

- `shared/di/data_providers.dart`（36 个消费方）与 `library_state_providers.dart`（28 个消费方 / 10 个模块）把互不相关的 token 塞进同一文件，任何归属讨论都退化为「改一个大文件」。
- 反向依赖（`shared/**` → `features/**`、`core/**` → `features/**`）靠 baseline 容忍，且旧 baseline 只校验「新增」，删文件忘删行会永久掩盖。
- R13（shared 内核不得 import feature）有两套实现（只扫 `import` / 扫 `import + export`），写代码的人不知道要满足哪一套。
- `shared/di/home_library_stats_providers.dart` 是 canonical 路径下的 export-only 转发，指向 `features/home/di/**`，同一 import 面有两条路径。

## Decision

### 1. 生产者拥有（producer ownership）

**类型的定义与实现所在模块即 owner。** 不采用「消费最多的模块拥有」——后者会让读模型随消费方漂移，并在 `home ↔ reading_stats` 这类互消费模块之间造出 public 环。

### 2. 可达性否决条件（优先级高于「单一 owner」判据）

| 情形 | 落点 |
|------|------|
| 定义与实现都在同一个 owner，且没有 `shared/**` / `core/**` 消费方 | owner `domain/`，跨模块经 owner `public/**` |
| 任一消费者 import owner 会命中 ADR-0036 禁止边 | Port 真源留 `shared/domain/ports/**`，token 留 `shared/di/**`，实现留 owner |
| 任一消费者 import owner 会造成 public 跨模块环 | 同上（环检测零 baseline，比违规更不可容忍） |
| 任一消费方是 `shared/**` 或 `core/**` | 真源留 shared（否则立刻制造 R13） |
| 被 ≥2 个产品模块消费且无单一 owner | 保留 Catalog Shared Kernel |

这三条是**否决条件**，先于「单一 owner」判据生效。

### 3. `shared/di` 拆分轴：按可达性，不按 owner

对 `data_providers.dart` 与 `library_state_providers.dart` 逐 token 判定：

- 全部消费方同属一个 owner，且无 `shared/**` / `core/**` 消费方 → 迁该 owner `public/di`；
- 消费方跨 ≥2 个 owner、都是产品模块且不构成禁止边 / 环 → 迁**生产者** owner `public/di`；
- 任一消费方是 `shared/**` / `core/**`，或迁走会构成禁止边 / public 环 → **留 shared**，并在本文档登记原因。

`data_providers.dart` 与 `library_state_providers.dart` 迁移后若仍非空则保留，**不得**为了「删掉文件名」把 shared 语义的 token 硬塞给某个 owner。

### 4. 显式留在 shared 的 Port 与 token（结论，非遗留）

| 契约 / token | 消费方 | 豁免理由 |
|------|--------|----------|
| `LibraryBrowseFallbackPort` + token（窄口，仅 `goDefaultLibraryBrowse(BuildContext)`） | `shared/ui/navigation/library_browse_navigation.dart` | shared 消费方。全量 `LibraryManagementPort` 已归 `library_admin`（2026-11-12 修订） |
| `LibraryReorderModePort` + token（真源 `shared/domain/ports/`） | `shared/domain/catalog/selection/catalog_selection_notifier.dart` | shared 消费方 |
| `ReaderLaunchPort` + token | `shared/**`、comic / library_browse | 禁止边 + shared 消费方 |
| `SeriesReadingContextPort` / `SeriesItemMembershipPort` / `SeriesItemSortPort` + token | comic / series 之外多方；ADR-0035 §4 判定 | 禁止边 |
| `AuthorDetailPort` + token | comic、series（两者都禁止 import library_browse） | 禁止边 |
| `ReadingHistoryProgressPort` + token | library_browse、reader | 禁止边 |
| `ComicTrashCommandPort` + token | comic 消费 / comic_trash 实现（互引成环） | public 环 |
| `RemoteLibraryCredentialsPort` + token | library_admin / comic / reader 三方，无单一生产者 | 无单一 owner |
| `ComicReadLookupPort` + token | reader 消费 / comic 实现（reader ↛ comic 为禁止边） | 禁止边 |
| `metadata_refresh_types.dart` | ~~`shared/ui` 元数据刷新 toast（series 与 library_admin 双消费）~~ | **2026-11-12 已消除**：真源迁 `library_admin/domain/`，toast 迁 `library_admin/public/ui/metadata_refresh_toasts.dart`，`shared` 不再消费 |
| `library/library_age_restriction_filter.dart` | comic / series / home / library_browse 四方 | 禁止边（`comic ↛ library_browse`、`series ↛ library_browse`）+ `library_admin → home` 已存在（迁 admin 会成环）；跨 Tab 壳词汇，无单一可达 owner |
| `library/library_revision_state.dart` + token | —（原 admin 生产者 + 6 模块只读） | **2026-11-12 已归位** `library_admin/domain/` 与 `library_admin/public/di/` |
| `library/library_media_type_filter.dart` | —（仅 library_browse） | **2026-11-12 已归位** `library_browse/domain/browse/`（筛选态，与同目录其它 browse filter 同址） |
| `appNavigatorProvider`、`domainEventBusProvider` / `domainEventRevisions` | 全局 | 基础设施 |

> **实现修订（2026-11-12，`shared/domain/library/` 收敛 P0–P2）**：`library_media_type_filter.dart` → `library_browse/domain/browse/`（筛选态，零新边）；`library_revision_state.dart` + `libraryRevisionStateProvider` → `library_admin/domain/` 与 `library_admin/public/di/`（token 与类型同址）；`metadata_refresh_types.dart` 真源 → `library_admin/domain/`，`metadata_refresh_toasts.dart` → `library_admin/public/ui/`（消除 `shared/ui → admin` 唯一 R13 边）。`shared/domain/library/` 由 7 文件降为 4 文件（`library_age_restriction_filter` / `library_scan_mode` / `scan_interval` / `comic_detail_return_series_port`：前两者为已登记豁免，后两者待 P4 与本模块 Port / `LocalLibrary` 联动迁移）。

> **实现修订（2026-11-12，P3 / #530）**：全量 `LibraryManagementPort` 真源迁 `library_admin` 的 public UI 契约面，token 归 `library_admin/public/di/`；`shared/domain/ports/` 只保留仅含 `BuildContext` 的 `LibraryBrowseFallbackPort`（token `libraryBrowseFallbackPortProvider` @ `shared/di`），由同一适配器在两个 token 上注入。删除 `library_admin/di/library_management_navigation.dart` 与 `shared/ui` 的同名重复实现（保留 `shared/ui` 一份），`route_not_found_page` 改读窄口。`shared/domain/ports/library_management_port.dart` 删除，`shared/` 不再认识 `LocalLibrary` / `ScanMode`。

### 5. 实现修订（2026-11-11，P3m 收口；2026-11-12 由 ADR-0046 收口）

> **实现修订（2026-11-12，#517）**：本节的 5 条 `R13|shared|app_settings` 豁免**已全部消除**。ADR-0046 用「持久化 schema / 领域值对象 + ACL」替换了 `app_settings ↛ reader` 的 import 与三个只为打破环而存在的 Port，`app_settings` 不再认识阅读枚举，`baseline.json` 归零。以下内容保留为当时的决策语境。

当时 `app_settings` 的 5 个 token **无法**按「生产者拥有」归位，原因是双向依赖而非惰性：

- `app_settings` 的 settings page 渲染 reader 偏好控件（`settings_sections.dart` → `features/reader/public/reading_preference_l10n.dart`，`app_settings/domain/reader_session_preference_types.dart` → `features/reader/public/reading_preference_types.dart`），即 **`app_settings → reader` 已存在**；
- 因此 reader 反向 import `features/app_settings/public/**`（拿 `appSettingsStateProvider` 等）会立刻构成 public 环；
- 把这些类型搬进 `shared/domain` 只能把 R13 换个方向（`shared → features/reader`、`shared → features/app_settings`），因为 `AppSetting` 实体同时引用 reader 的阅读偏好枚举与 app_settings 的外观枚举。

当时的结论是：这 5 条 `R13|shared|app_settings|...` 按「shared 消费方 / public 环」豁免**显式登记**在 `app/test/architecture/baseline.json`，并在文件头注释说明；`#515` 的「分类存疑留 shared 并登记，不要猜」原则优先于「baseline 归零」的字面目标。真正需要归零的是 `shared_domain_feature_import_baseline.json`（已 `[]`）与 `core/**` → features（已归零）。

同一轮里已按本文档完成归位的（R13 从 11 条降到 5 条）：

| 提交 | 内容 |
|------|------|
| #506 | `HomeLibraryStat` → `features/home/domain/` |
| #507 | `ReadingActivityStats` / `HomePageCounts` + 三 Port / token → `features/reading_stats/` |
| #508 / #509 | 阅读历史 / 回收站 Command、ReaderSession Port 与 token 归位（Progress / Command 各有一条按环豁免留 shared） |
| #510 | `ThumbnailEvent` 归位 comic；返回系列 Port 留 shared |
| #511 / #512 / #513 / #514 | `library_browse` 筛选态、library_admin 库状态 / 批量补丁、`ManagedNamedFacetKind` 归位 |
| #505 | 领域枚举文案下放到 owner，`core/l10n` 不再 import feature |
| #515 | `shared/di` 巨型文件拆分 + 转发 shim 删除；comic 两个 Repository token 归 comic，`LibraryReorderModePort` 真源进 shared；reader 改经 `ComicReadLookupPort`，`core/logging` 的 FRB 调用移到 `shared/data/frb/` |

### 6. 与既有 ADR 的关系

- **ADR-0035**：Catalog Shared Kernel 范围不变；§4「内核整体迁出」的四条触发条件只有第 1 条（消费者收缩）成立，**不启动**迁移。
- **ADR-0036**：禁止边表是本文档「可达性否决」的第一输入；禁止边存量的 shrink-only baseline 不变。
- **ADR-0039**：命令仍走 Port、事实仍走领域事件。本文档只改 **Port 的物理位置判定**：不再「一律放 `shared/domain/ports`」，而是按可达性判定。
- **ADR-0040**：跨模块只读投影仍用匿名 record；`ComicReadLookupPort` 的返回类型是 shared 内的窄快照类，因为它需要跨文件复用且字段多于 2 个。
- **ADR-0041 / ADR-0042**：`shared/**` 不得出现 Comic / Series 实体类型这一条不变，因此 comic 的 Repository 接口（返回 `Comic`）不能迁 shared，只能以窄 Port 形式暴露给 reader。

## Consequences

### Positive

- 归属判据可预测：从「谁定义、谁实现」判断，而不是「谁 import 得多」。
- `shared/domain` 只剩内核类型与按豁免保留的 Port；owner 改自己的读模型不再产生 shared diff。
- `shared/di` 巨型文件按可达性拆散，转发 shim 删除，同一能力只有一条 import 路径。
- `core/**` → `features/**` 归零；`shared_domain_feature_import_baseline.json` 归零。

### Negative

- ~~5 条 `R13|shared|app_settings` 边保留并登记~~（已由 ADR-0046 消除，`baseline.json` 为 `[]`）。
- 为绕开禁止边新增了两个窄 Port（`ComicReadLookupPort`、缩略图活动读模型），跨模块协作路径比「直接 import Repository」多一跳。
- `shared/domain/ports/` 现在同时承载「真正的跨模块契约」与「按可达性豁免的单归属契约」，需要靠本文档表格区分。

### Neutral

- 本 Epic 不改变任何运行时行为；结构正确性由既有 `test/gate` + `test/architecture` 承担，未新增测试。

## References

- Epic #503；子票 #504–#516
- ADR-0034（feature public API only）、ADR-0035（Catalog Shared Kernel）、ADR-0036（comic / series / library_browse）、ADR-0039（Port + DomainEvent）、ADR-0040（record 投影）、ADR-0041（Comic 实体归属）
- `app/test/architecture/baseline.json`、`app/test/gate/shared_domain_feature_import_baseline.json`
- `docs/engineering/cross-feature-collaboration.md`、`docs/engineering/gate.md`
