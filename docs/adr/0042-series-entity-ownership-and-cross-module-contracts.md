# ADR-0042: Series 实体迁入系列模块与跨模块契约（ACL / Slot / data 映射）

## Status

Accepted（2026-11-11）。局部取代 ADR-0035 的 Series 结论，并收紧 ADR-0036 的 `series` owner 面与模块边。

## Context

[#490](https://github.com/Zoti321/hentail_library/issues/490)：`Series` / `SeriesItem` / 系列元数据锁、表单与 `SeriesMetaLocks` / `SeriesComicsMetadata` 一直住在 Catalog Shared Kernel（`shared/domain/`），导致：

- `comic` 为了显示「系列上一卷/下一卷」与 smart facet 邻居直接引用 `Series` 实体与 `seriesRepoProvider`，形成隐式 `comic → series` 依赖，而 `comic ↛ series` 是模块门禁的显式禁止边。
- `series` 详情/元数据 UI 直接 import `comic` 的封面 widget、卡片右键菜单与批量编辑动作，UI 组合边与 provider 依赖穿透模块边界。
- `reader` 在「设为系列封面」后直接 `invalidate(seriesCoverSourceProvider(...))`，把 `reader → series` 变成手工失效耦合。
- `shared/ui` 收留了系列专属布局 token、连载状态枚举与下拉框，`shared` 反向承载 Series 细节。
- `seriesRepoProvider` token 在 `shared/di`，被 `comic` / `library_browse` / `library_admin` / `series` 各自 DI 引用，归属含混。

ADR-0035 §4 的「消费者收缩 / shared UI 解耦 / Dart 域行为」触发条件已满足；ADR-0041 已为 Comic 建立了同形的迁移范式。

## Decision

### 1. 真源与迁移范围

- **真源**：`features/series/domain/`
  - `series.dart`、`series_item.dart`（实体与成员）
  - `value_objects/series_meta_locks.dart`、`series_comics_metadata.dart`、`series_metadata_form.dart`
  - `series_repository.dart`、`series_comic_page_item.dart` 及 Series Tab 规则
- **FRB 映射**：`features/series/data/series_frb_mapper.dart`（仓储契约签名不变）。
- **token 归属**：`seriesRepoProvider` 迁 `features/series/public/di/series_repository_providers.dart`；`shared/di` 不再声明该 token。
- **删除死代码**：`seriesByIdStateProvider`（`shared/di`）、`library_admin` 的 Series 列表 VM、`library_browse` 的死系列仓储转接、`shared/ui` 系列专属上下文菜单。
- **Series 偏好键迁移**：`library_prefer_library_root_series` 的存储键常量归 `app_settings/domain/legacy_browse_preferences.dart`，Series 只消费已解析布尔。

### 2. 跨模块数据形状：ACL / 只读投影

`features/series/public` **不**暴露 `Series` 实体（不同于 Comic 的 thin re-export）。跨模块读取 Series 事实只经下列通道：

| 通道 | 类型 / 位置 |
|------|-------------|
| 读上下文 Port | `shared/domain/ports/series_reading_context_port.dart` → `SeriesReadingContext` record |
| 成员归属 Port | `shared/domain/ports/series_item_membership_port.dart` → `SeriesItemMembership` record |
| 排序命令 Port | `shared/domain/ports/series_item_sort_port.dart` |
| 封面解析 | `shared/domain/thumbnail/series_cover_source.dart` |
| 库 Series 行 | 匿名 record `({String id, String name, int volumeCount})`（ADR-0040） |

`comic` 不再 import `Series` / `SeriesItem`：系列导航、smart facet 邻居判定改走 `SeriesReadingContextPort` 与自身 `resourcePath`；元数据保存改走 `SeriesItemMembershipPort` / `SeriesItemSortPort`。

### 3. UI 组合：Riverpod + Slot

UI 组合边不直接跨 feature import，改为 **Slot 契约**（`shared/ui/slots/`，仅 Flutter + 原始值，禁止 `features/**`）+ `shared/di` token + bootstrap 注入：

| Slot | 归属实现 | 用途 |
|------|----------|------|
| `SeriesCoverSlot` | `comic` | 系列封面回退到成员漫画封面 |
| `SeriesMemberCoverSlot` | `comic` | 系列成员网格封面 |
| `SeriesMemberCardSlot` | `comic` | 成员卡右键菜单/阅读/删除入口 |
| `SeriesMemberSelectionActionsSlot` | `comic` | 选择模式批量编辑元数据 |
| `SeriesCoverInvalidationSlot` | `series` | reader 设系列封面后失效封面状态 |

`series` 页面因此零 `comic/public/ui` 依赖；`reader` 不再 import `features/series/**`。

### 4. 返回系列栈

`ComicDetailReturnSeriesPort`（`shared/domain/library/`，实现 @ comic）扩展 `remember(seriesId)`；`series` 详情页经 `shared/di` 的 `comicDetailReturnSeriesPortProvider` 写入，不 import comic presentation notifier。

### 5. `shared/ui` 收割

- `series_detail_page_metrics` → `features/series/presentation/patterns/series_detail/`。
- `series_serialization_dropdown` → `features/series/presentation/patterns/metadata_edit/`。
- 删除 `shared/ui/models/series_serialization_status.dart`；全面使用 `shared/domain/models/enums.dart` 的 `SerializationStatus`（表单、徽标、映射、Lab 预览数据一对一 switch）。
- 通用布局件 `comic_detail_primary_row_layout`、`comic_detail_title` 下沉 `shared/ui/layout/`；删除 `comic/public/ui/comic_detail_layout.dart` 及其 R12 白名单条目。

### 6. data 映射契约

仓储契约签名不变；FRB DTO → 领域对象由 owner `data/*_frb_mapper.dart` 纯函数承担；错误仍经 `guardFrb` / `AppException` / `DomainException` 单出口，**不引入**全局 `Result` 类型。

### 7. 门禁

新增：

- `test/architecture/series_entity_ownership_test.dart`：`shared/domain` 不含 Series 实体/VO/表单文件；`shared/**` 不出现 `Series` 类型引用（注释与生成文件除外）。
- `test/architecture/series_slot_contract_test.dart`：`shared/ui/slots/**` 不得 import `features/**`。

同步重生成 `import_boundary_baseline.json`、`shared_domain_feature_import_baseline.json`、`architecture/baseline.json`（只减不增）；`public_presentation_export_allowlist.txt` 与代码一致；`strangler_shims.txt` 保持为空。

### 8. 明确不做

- 让 `features/series/public` 暴露 `Series` 实体或第二套 Series DTO。
- 新增全局 `Result` / Either 抽象。
- 把封面生成能力（`resolveSeriesCover` / `setSeriesCoverFromPage`）从 comic 缩略图仓储迁出。
- Rust 侧改动。

## Consequences

### Positive

- `comic ↛ series` 与 `reader ↛ series` 由真实代码结构保证，而不再靠 shared 类型绕行。
- Series 规则与表单可被 `features/series` 纯 Dart 单测覆盖；shared 只保留跨模块契约。
- UI 组合边可替换（Lab/测试可注入轻量 slot 实现），模块图可读性提升。

### Negative

- 跨模块读取 Series 需经 Port / record，调用点略增。
- 依赖 bootstrap 注入 slot；遗漏 override 时 `shared/di` 的注入门禁与运行时都会明确报错。
- `shared/ui` 中历史 Series 资产迁移属一次性改路径，旧引用会编译失败而非静默沿用。

## References

- ADR-0002、ADR-0033、ADR-0034、ADR-0035、ADR-0036、ADR-0039、ADR-0040、ADR-0041
- GitHub [#490](https://github.com/Zoti321/hentail_library/issues/490)（S1 #491 / S2 #492 / S3 #493 / S4 #494）
- `docs/engineering/shared-domain-ownership.md`、`docs/engineering/library-browse-zones.md`、`docs/engineering/gate.md`
