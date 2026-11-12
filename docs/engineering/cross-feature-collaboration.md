# Cross-feature 协作（Riverpod + ADR-0034 / ADR-0039）

**决策**：ADR-0034（#426/#435）public only、ADR-0039（命令走 Port，事实走领域事件）、[`gate.md`](gate.md) import 门禁。

## 心智模型（六段）

| 段 | 位置 | 谁 import |
| --- | --- | --- |
| **契约** | `shared/domain/ports/`、owner `public/` | 跨 feature 读类型 / UI 命令 |
| **事件** | `shared/domain/events/`（sealed `DomainEvent` + 子类） | 任意 feature 发布 / 消费 |
| **Token** | 能力所有者 `features/<owner>/public/di/**`；`shared/di` 仅跨模块命令 / 全局状态 | 消费方直接 watch owner public token（ADR-0034 §3，#488） |
| **实现** | owner `features/<id>/di/`（含 codegen 封面图）、`shared/data/events/` | 仅同 feature 或 **bootstrap** overrides |
| **接线** | `features/bootstrap/di/overrides/` | 仅 bootstrap |
| **Port 归属判定** | 先判可达性（ADR-0045）：命中禁止边 / public 环 / `shared`·`core` 消费方 → 契约留 `shared/domain/ports/**`、token 留 `shared/di/**`；否则归 owner `domain/` + owner `public/di/**` | 判定顺序先于「谁消费得多」 |
| **Design System** | `lib/design-system/**`（ADR-0044） | `shared/ui`、任意 feature、`widgetbook` |

新增通用控件先问一句：**是否被 ≥2 个产品模块消费**？否 → 放消费方 `presentation/`；是且业务无关 → `design-system/components/`；是但含业务语义 → 留 `shared/ui/`。`design-system` 只允许依赖 `core/**` 与 `shared/util/**`（门禁 `test/design-system/design_system_boundary_test.dart`，零 allowlist）。

Consumer **不要** deep import 邻居的 `features/<other>/di/`；模块私有 token 也不再抄到 `shared/di` 转发（ADR-0034 §3）。

## 命令 vs 事件

| 需求 | 用什么 |
| --- | --- |
| 要它做事，要结果 / 可能失败 | Port（`shared/domain/ports/**`）+ `shared/di` token |
| 发生了某事，订阅方未知 | `DomainEvent`；发布在 application / data，投影在 `DomainEventRevisions` |
| UI 按当前值重建 | `domainEventRevisionsProvider.select(...)` |
| 需要 `BuildContext` | owner `public/ui/**` 命令 |

新增事件：在 `shared/domain/events/` 加子类（part of `domain_event.dart`）→ 在 `DomainEventRevisions._reduce` 归类（sealed switch 会强制）→ application 层构造注入 `DomainEventPublisher` 发布。门禁见 `domain_event_rules_test.dart`（E1/E2/E4/E5）。presentation 不得 `publish`（E2）、不得读 `domainEventBusProvider`（E5）；需要发布者时在 owner `di/` 装配用例（范例 `comic/di/comic_metadata_service.dart` → `comicMetadataApplyCommandProvider`），ViewModel 只拿命令。

当前事件：`ComicMetadataPersisted`、`LibraryCatalogChanged`、`ComicsTrashed`、`ComicsRestored`。

## 典型用法

- 打开作者详情：`import shared/di/author_detail_providers.dart` → `ref.read(authorDetailPortProvider)`.
- 库管理 / 元数据刷新：`shared/di/library_management_providers.dart` → `libraryManagementPortProvider`；元数据刷新命令 token 见 `features/library_admin/public/di/library_admin_state_providers.dart`。删进回收站经 `shared/di/data_providers.dart` → `comicTrashCommandPortProvider`（按 public 环豁免留 shared）；回收站列表与 purge 持久化 token 见 `features/comic_trash/public/di/comic_trash_providers.dart`（FRB `src/rust/api/comic_trash.dart`，仅 owner `features/comic_trash/data/` import）。
- 应用设置态：`features/app_settings/public/di/app_settings_providers.dart`（ADR-0046）→ `appSettingsProvider`、`appSettingRepositoryProvider`、`readingPreferencesRecordProvider`、`readingPreferencesControllerProvider`。**禁止** import `features/app_settings/domain/**` 或 `presentation/**`。
- 阅读偏好（reader）：`features/reader/public/reading_preferences_providers.dart` → `readingPreferencesProvider`（L2 领域值对象）；跨边界只走 `ReadingPreferencesRecord` + `features/reader/public/reading_preferences_acl.dart`（`decode` 全函数 / `encode` 穷尽 switch）。**不得**新增只为打破 import 环的 Port（ADR-0046）。
- 阅读进度写入/恢复（reader）：`features/reading_history/public.dart` → `readingHistoryCommandPortProvider`；库浏览封面进度 → `shared/di/reading_history_providers.dart` 的 `readingHistoryProgressPortProvider`（禁止边豁免）；历史页分页/删除仍 `readingHistoryRepoProvider`（`features/reading_history/public/di/reading_history_repository_providers.dart`）。
- 元数据备份槽（设置板块 / 库页导出 / 最近备份时间）：`library_state_providers.dart` → owner `features/metadata_backup/public.dart` + `metadata_backup/di/metadata_backup_shared_state_overrides.dart`（bootstrap）。设置页分区不再经 DI 槽位：组合根 `bootstrap/.../app_router.dart` 把 `MetadataBackupSettingsSections` 与 `readerSettingsSections(context)` 传给 `SettingsPage(sectionsBuilder:)`（ADR-0046）。
- **MD3E App shell 槽**（ADR-0027）：`shared/di/app_shell_providers.dart` → `appShellFeedbackBelowTitleBarFactoryProvider`、`md3eAppShellNavigationSlotAssemblyProvider`；bootstrap `di/overrides/app_shell_slot_overrides.dart` 注入 owner `library_admin/public.dart`（`app_shell_slot`）与 `app_settings` 诊断横幅。
- 标签/作者字典投影：`shared/di/library_dictionary_providers.dart` → bootstrap 经 `named_metadata/public.dart` 的 `allTagsProvider` / `allAuthorsProvider`（`metadata_dictionary_shared_state_overrides.dart`）。
- **Named metadata 仓储 / 表单候选**：`features/named_metadata/public/di/named_metadata_repository_providers.dart` 的 `authorRepoProvider`、`tagRepoProvider`、`namedFacetManagementRepoProvider`、`parodyRepoProvider` / `characterRepoProvider` → bootstrap `createAuthorRepository()` 等（`features/named_metadata/public.dart`）；Comic 元数据编辑器 / Smart facet 的 facet 候选经窄面 **`features/named_metadata/public/named_metadata_form.dart`**（`NamedFacetFormListing` @ domain + `listNamedFacetForMetadataForm` 便捷函数；实现 `NamedFacetFormListingImpl`）。FRB：`src/rust/api/named_facet/{types,management,form}.dart`、`named_facet_dictionary.dart`（Rust `api/named_facet/` + `named_facet_dictionary.rs`）。
- 漫画页数（bootstrap 注入）：`shared/di/comic_detail_providers.dart`；漫画 Repository token 见 `features/comic/public/di/comic_repository_providers.dart`；阅读器只经 `shared/di/data_providers.dart` 的 `comicReadLookupPortProvider`（`ComicReadLookupPort`，reader ↛ comic 禁止边豁免）。
- 封面 **Widget**：`import features/library_browse/public.dart` → `ComicCoverContent` / `seriesCoverSourceProvider`（public export owner `di/` 中的 codegen）.
- 无 `WidgetRef` 回库浏览：`import features/library_admin/public.dart` → `goCurrentLibraryBrowseFromContext`.

## Port 是什么

`shared/domain/ports/*_port.dart` 里的 **几个方法**；对应 `shared/di` 里的 `xxxPortProvider`。实现由 owner `createXxx(Ref)` + bootstrap `overrideWith` 注入，业务代码只读 token。

## 封面 codegen

`comicCoverProvider` 等 **只在** `library_browse/di/` 生成；跨 feature 优先 **public UI** 或 **public.dart export**；admin 清缓存等少数场景见 `import_boundary_baseline.json` 中的 M1。
