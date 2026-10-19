# 跨 feature import 现状盘点（#223）

> **已归档**（2026-10-16 快照）。现行边界以 `app/test/gate/import_boundary_test.dart` 与 `docs/agents/testing.md` 为准。

**日期**：2026-10-16  
**依据**：Wayfinder [#218](https://github.com/Zoti321/hentail_library/issues/218) 已对齐的目标模块与依赖规则；源码 Primary source 为 `app/lib/**/*.dart`（排除 `*.g.dart` / `*.freezed.dart`）。  
**复现**：`python scripts/research/cross_feature_import_audit.py`（路径→目标模块的启发式分类，见脚本内 `classify()`）。

## 1. 目标规则（盘点对照）

| 规则 | 来源 |
|------|------|
| 禁止 product feature 的 presentation 互引（跨 feature 仅 `bootstrap` 路由/launcher + `shared` 类型） | [#218 resolution](https://github.com/Zoti321/hentail_library/issues/218#issuecomment) |
| `library_browse` 不 import `read_session` 的 domain | 同上 |
| `domain` 不 import `data` | 同上；ADR-0002 薄边在 `data/` |
| FRB（`src/rust`）仅 `shared/data`（+ 启动 `main` 等极少数例外） | [#218](https://github.com/Zoti321/hentail_library/issues/218) + `docs/agents/rust-core.md` |
| `views/` 与 `ui/core/widgets/` 不引用 `*RepoProvider` | `app/test/project_layout_test.dart` |

**模块分类说明**：今日目录仍是 `ui/features/{shell,library,reader,settings,metadata}` + 全局 `domain/data/core`。脚本将 **shell 子路径** 按 [#218](https://github.com/Zoti321/hentail_library/issues/218) 拆到 `home` / `library_admin` / `comic_trash` / `bootstrap`，用于模拟迁移后的边界。

## 2. 硬性违规（应对齐后消除）

### 2.1 `domain` → `data`（3 处）

| 文件 | import |
|------|--------|
| `domain/library/library_sync_coordinator.dart` | `data/adapters/sync_library_frb_adapter.dart` |
| `domain/library/metadata_refresh_coordinator.dart` | `data/adapters/metadata_refresh_frb_adapter.dart` |
| `domain/library/comic_metadata_bulk_patch_coordinator.dart` | `data/adapters/comic_metadata_bulk_patch_frb_adapter.dart` |

**迁移含义**：coordinator 迁至 `library_admin` 的 feature `domain` 或 `data` 编排层，或经 `shared/domain` port + `shared/data` 实现倒置。

### 2.2 非 `data/` → `src/rust`（8 个源文件）

| 文件 | 目标模块（脚本） | 说明 |
|------|------------------|------|
| `main.dart` | bootstrap | 启动初始化，可保留白名单 |
| `core/logging/diagnostic_logging.dart` | shared | 应经 adapter 或下沉到 `shared/data` |
| `core/metadata/metadata_import_flow.dart` | metadata_backup | |
| `core/metadata/metadata_export_flow.dart` | metadata_backup | |
| `core/metadata/metadata_auto_backup_service.dart` | metadata_backup | |
| `core/app_data/app_data_wipe_flow.dart` | app_settings | |
| `ui/features/shell/view_models/scan_library_controller.dart` | library_admin | 应经 sync adapter |
| `ui/features/metadata/view_models/tag_dictionary_import_controller.dart` | named_metadata | 应经 data 层 |

`data/**` 内 27 个文件引用 `src/rust` — **符合** 目标态。

### 2.3 `library_browse` → `domain/reading`（1 处）

| 文件 | import |
|------|--------|
| `ui/features/library/view_models/comic_detail_series_nav_provider.dart` | `domain/reading/series_reading_context.dart` |

**迁移含义**：将 `series_reading_context` 抽到 `shared/domain` 或改为 `bootstrap`/`read_session` 暴露的导航 DTO，browse 不依赖 reading 子域。

### 2.4 `*RepoProvider` in views / core widgets

`project_layout_test.dart` 当前 **0 offenders** — 与 ADR-0017 一致。

## 3. 模块间 import 边（聚合）

脚本统计 **37 条有向模块边**（同一文件多条 import 计多次）。`bootstrap` 作为组装层 **允许** 指向各 product feature；下表列出 **需在迁移后收敛** 的边（排除 `bootstrap` 作为源或汇总的「合法组装」场景时，关注 product↔product）。

### 3.1 Product feature 之间（不含 bootstrap 中转）

| 源 → 目标 | import 次数（约） | 典型原因 |
|-----------|-------------------|----------|
| `library_browse` → `library_admin` | 26 | ViewModel 依赖 `current_library`、catalog revision、`shell/di/repos` |
| `library_browse` → `named_metadata` | 4 | 库页筛选引用 `author_management_notifier` / `tag_management_notifier` |
| `library_browse` → `comic_trash` | 1 | `comic_delete_flow` → `comic_trash_actions` |
| `library_browse` → `read_session` | 1 | `comic_detail_primary_actions` → `read_session_launcher` |
| `library_browse` → `app_settings` | 1 | 元数据编辑后触发自动备份 coordinator |
| `home` → `library_admin` | 7 | Home 仪表盘 / probe / continue reading 与库管理、扫描 |
| `home` → `library_browse` | 2 | 仪表盘过滤器、history 页封面 viewport |
| `comic_trash` → `library_admin` | 5 | trash 动作与 revision / sync / bulk patch 互斥 |
| `comic_trash` → `home` | 2 | 复用 history 页 layout/header 组件 |
| `library_admin` → `library_browse` | 3 | bulk patch DI、侧栏导航、catalog selection |
| `library_admin` → `named_metadata` | 3 | bulk patch 依赖 facet 字典 providers |
| `library_admin` → `app_settings` | 1 | bulk patch 后自动备份 |
| `named_metadata` → `library_browse` | 2 | Author 详情 UI、`library_scroll_to_top_button` |
| `read_session` → `library_browse` | 1 | （见脚本 `read_session->library_browse` 示例，需 ownership 矩阵确认） |
| `read_session` → `app_settings` | 3 | 阅读器设置与 App preference |
| `app_settings` → `library_admin` | 2 | 诊断/备份行引用 `scan_library_controller`、`current_library_notifier` |

### 3.2 UI 层跨 `ui/features/*`（17 组边，节选）

| 源 feature 目录 → 目标 | 文件示例 |
|------------------------|----------|
| `library` → `shell` | `library_page_widgets.dart` → `app_router` / `library_management_actions`（约 29 个 library 文件引用 shell 路径，见 §4） |
| `library` → `metadata` | `library_metadata_filter_section.dart` → `author_management_notifier` |
| `library` → `reader` | `comic_detail_primary_actions.dart` → `read_session_launcher.dart` |
| `library` → `shell`（trash） | `comic_delete_flow.dart` → `comic_trash_actions.dart` |
| `metadata` → `library` | `named_facet_management_panel.dart` → `show_author_detail.dart` |
| `settings` → `shell` | `settings_notifier.dart` → `shell/di/repos.dart` |

完整 JSON 示例边见脚本 stdout 的 `module_edge_examples` / `ui_feature_cross_examples`。

## 4. 横切枢纽（迁移风险点）

### 4.1 `ui/features/shell/di/*`

至少 **47** 个 `app/lib` 文件直接 import `ui/features/shell/di/`（含 `repos.dart`、`deps.dart`、`library_sync.dart` 等）。  
消费方分布：`library_browse`、`read_session`、`named_metadata`、`app_settings`、`library_admin`、`comic_trash` 均有。

**结论**：`shell/di` 是今日事实上的 **全局 DI 根**；迁移时应整体落入 `bootstrap/di` 或 `shared/di`，各 feature 仅保留 feature-scoped providers。

### 4.2 `ui/providers`（封面等）

约 **34** 个文件 import `ui/providers` 或 `ui/providers/*`。  
与 `shell/di/repos` 一起构成 **presentation 对基础设施的直接依赖**。

### 4.3 `shared` 层（`domain` / `data` / `ui/core`）

- 全部 `domain/**`、`data/**` 在目标模型中属 **`shared`**（feature 专属 domain 尚未从全局树拆出）。
- `ui/core/**` 被各 feature 广泛引用 — 目标 **`shared/ui`**；不构成 feature 互引违规，但会抬高 **shared 变更面**。

## 5. 与「禁止 presentation 互引」的差距（摘要）

| 类别 | 现状 |
|------|------|
| 经 `bootstrap`（路由/DI）合法组装 | `app_router`、`shared_content_routes` 已集中注册各 feature 页面 — **保留并强化** |
| 违规/待收敛的 product↔product UI | `library`↔`metadata` 双向、`library`→`reader` launcher、`comic_trash` 复用 `home` 组件、`library`→`shell` trash actions |
| 违规 domain 依赖 | §2.1、§2.3 |
| FRB 泄漏 | §2.2 |

## 6. 建议供 #224 ownership 矩阵优先处理

1. **DI 归位**：`shell/di` + `ui/providers` → `bootstrap`/`shared` 清单（§4）。  
2. **高耦合簇**：`comic_metadata_bulk_patch`（`library_admin` + `library_browse` + `named_metadata` + `app_settings`）。  
3. **Author 详情 UI**：`show_author_detail` / `author_detail_surface` 被 `library_browse` 与 `named_metadata` 共用 → 候选 **`shared/ui`** 或 `shared/domain` + 单一 presentation 组件。  
4. **阅读入口**：`read_session_launcher` → 保留在 `read_session`，`library_browse` 仅通过 `bootstrap` 回调或路由 API 调用。  
5. **Trash 与 History 共享 chrome**：`trash_page` 对 `history_page` widget 的依赖 → 抽到 `shared/ui` 或 `home` 暴露的 dumb header。

## 7. 变更记录

| 版本 | 说明 |
|------|------|
| 2026-10-16 | 初版盘点（#223） |
