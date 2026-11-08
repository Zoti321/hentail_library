# Cross-feature 协作（Riverpod + ADR-0034）

**决策**：ADR-0034（#426/#435）、[`gate.md`](gate.md) import 门禁。

## 心智模型（四段）

| 段 | 位置 | 谁 import |
| --- | --- | --- |
| **契约** | `shared/domain/ports/`、owner `public/` | 跨 feature 读类型 / UI 命令 |
| **Token** | `shared/di/*_providers.dart` | 任意 feature / shared 需要 `ref.read` 时 |
| **实现** | owner `features/<id>/di/`（含 codegen 封面图） | 仅同 feature 或 **bootstrap** overrides |
| **接线** | `features/bootstrap/di/overrides/` | 仅 bootstrap |

Consumer **不要** deep import 邻居的 `features/<other>/di/`，除非 baseline 已记录的遗留 M1（应逐步删掉）。

## 典型用法

- 打开作者详情：`import shared/di/author_detail_providers.dart` → `ref.read(authorDetailPortProvider)`.
- 库管理 / 删进回收站 / 元数据刷新：`shared/di/library_management_providers.dart`、`library_command_providers.dart`；回收站列表与 purge 持久化经 `shared/di/data_providers.dart` → `comicTrashRepositoryProvider`（bootstrap `createComicTrashRepository()`，FRB `src/rust/api/comic_trash.dart`，仅 owner `features/comic_trash/data/` import）。
- 应用设置态：`shared/di/app_settings_providers.dart`.
- 阅读进度写入/恢复（read_session）：`shared/di/reading_history_providers.dart` → `readingHistoryCommandPortProvider`；库浏览封面进度 → `readingHistoryProgressPortProvider`；历史页分页/删除仍 `readingHistoryRepoProvider`。
- 元数据备份槽（设置板块 / 库页导出 / 最近备份时间）：`shared/di/settings_slot_providers.dart`、`library_state_providers.dart` → owner `features/metadata_backup/public.dart` + `metadata_backup/di/metadata_backup_shared_state_overrides.dart`（bootstrap）。
- **MD3E App shell 槽**（ADR-0027）：`shared/di/app_shell_providers.dart` → `appShellFeedbackBelowTitleBarFactoryProvider`、`md3eAppShellNavigationSlotAssemblyProvider`；bootstrap `di/overrides/app_shell_slot_overrides.dart` 注入 owner `library_admin/public.dart`（`app_shell_slot`）与 `app_settings` 诊断横幅。
- 标签/作者字典投影：`shared/di/library_dictionary_providers.dart` → bootstrap 经 `named_metadata/public.dart` 的 `allTagsProvider` / `allAuthorsProvider`（`metadata_dictionary_shared_state_overrides.dart`）。
- **Named metadata 仓储 / 表单候选**：`shared/di/data_providers.dart` 的 `authorRepoProvider`、`tagRepoProvider`、`namedFacetManagementRepoProvider`、`parodyRepoProvider` / `characterRepoProvider` → bootstrap `createAuthorRepository()` 等（`features/named_metadata/public.dart`）；Comic 元数据编辑器 / Smart facet 的 facet 候选经窄面 **`features/named_metadata/public/named_metadata_form.dart`**（`NamedFacetFormListing` @ domain + `listNamedFacetForMetadataForm` 便捷函数；实现 `NamedFacetFormListingImpl`）。FRB：`src/rust/api/named_facet/{types,management,form}.dart`、`named_facet_dictionary.dart`（Rust `api/named_facet/` + `named_facet_dictionary.rs`）。
- 漫画页数（bootstrap 注入）：`shared/di/comic_detail_providers.dart`.
- 封面 **Widget**：`import features/library_browse/public.dart` → `ComicCoverContent` / `seriesCoverSourceProvider`（public export owner `di/` 中的 codegen）.
- 无 `WidgetRef` 回库浏览：`import features/library_admin/public.dart` → `goCurrentLibraryBrowseFromContext`.

## Port 是什么

`shared/domain/ports/*_port.dart` 里的 **几个方法**；对应 `shared/di` 里的 `xxxPortProvider`。实现由 owner `createXxx(Ref)` + bootstrap `overrideWith` 注入，业务代码只读 token。

## 封面 codegen

`comicCoverProvider` 等 **只在** `library_browse/di/` 生成；跨 feature 优先 **public UI** 或 **public.dart export**；admin 清缓存等少数场景见 `import_boundary_baseline.json` 中的 M1。
