# Wayfinder 源码 ownership 矩阵（现状 → 目标）

**版本**：2026-10-16  
**依据**：#218 模块清单、#219 拓扑、#221 shared/domain 切分、#222 DI/`shared/ui`、#223 import 盘点  
**用途**：各 migration slice 搬迁清单；**非**单 PR 范围。目标 URI 前缀均为 `package:hentai_library/` 下 `app/lib/` 相对路径。

## 图例

| 列 | 含义 |
|----|------|
| **现状路径** | 今日 `app/lib/` 下路径 |
| **目标模块** | `shared` 或 `features/<id>/` |
| **目标层** | `presentation` / `domain` / `data` / `di` / （`shared` 子目录 `core`/`ui`） |
| **Slice** | 建议随 #218 迁移顺序执行的 slice（`bootstrap` = 收尾） |
| **备注** | 含 ⚠️ 为 ambiguous / 需 #223 收敛 |

**目标路径公式**（默认）：

- `features/<id>/presentation/<legacy-subpath>` ← `ui/features/...` 下 `views/`、`view_models/`、`widgets/` 等
- `shared/domain/...` ← 今日 `domain/models`、`domain/repositories`、`domain/ports` 等
- `shared/data/...` ← 今日 `data/**` 整树
- `shared/core/...` ← 今日 `core/**` 整树
- `shared/ui/...` ← 今日 `ui/core/**` 整树

生成代码（`*.g.dart`、`*.freezed.dart`）与源文件同批移动；`src/rust/**` 不动。

---

## 1. `shared` 内核（整树搬迁）

### 1.1 `data/` → `shared/data/`

| 现状路径 | 目标路径 | Slice | 备注 |
|----------|----------|-------|------|
| `data/adapters/**` | `shared/data/adapters/**` | 随首个触及 FRB 的 slice；建议 `library_admin` 前完成骨架 | 与 #221 端口化同期 |
| `data/repositories/**` | `shared/data/repositories/**` | 同上 | |
| `data/services/app_update/**` | `features/app_settings/data/services/app_update/**` | `app_settings` | #221：单 feature 服务 |
| `data/services/tag_dictionary/**` | `features/named_metadata/data/services/tag_dictionary/**` | `named_metadata` | |

### 1.2 `core/` → `shared/core/`

| 现状路径 | 目标路径 | Slice | 备注 |
|----------|----------|-------|------|
| `core/app_data/app_data_wipe_flow.dart` | `features/app_settings/presentation/app_data_wipe_flow.dart` | `app_settings` | UI 编排（#220 R1：避免 feature `domain`→`data`）；矩阵原写 `domain/` |
| `core/constants/**` | `shared/core/constants/**` | `app_settings` 或 `bootstrap` | |
| `core/errors/**` | `shared/core/errors/**` | `bootstrap` | |
| `core/image/**` | `shared/core/image/**` | `bootstrap` | `main` 引用 |
| `core/io/**` | `shared/core/io/**` | `library_admin` | Local root 访问 |
| `core/l10n/**` | `shared/core/l10n/**` | `bootstrap` | |
| `core/logging/**` | `shared/core/logging/**` | `bootstrap` | §2.2 FRB：`diagnostic_logging` 需 adapter 化 |
| `core/metadata/**` | `features/metadata_backup/domain/**` + `features/metadata_backup/data/**` | `metadata_backup` | flow/service 入 feature；paths/bytes 可拆 data |
| `core/util/**` | `shared/core/util/**` | `bootstrap` | |
| `core/utils/**` | `shared/core/utils/**` | `library_browse` | 拼音筛选 |

### 1.3 `domain/` → 主要为 `shared/domain/`

#### 仓储接口（全部 `shared/domain/repositories/`）

| 现状文件 | Slice |
|----------|-------|
| `app_setting_repository.dart` | `app_settings` |
| `author_repository.dart` | `named_metadata` |
| `comic_repository.dart` | `library_browse` |
| `comic_thumbnail_repository.dart` | `shared/di` 消费者；文件随 `shared` |
| `home_page_repository.dart` | `home` |
| `library_repository.dart` | `library_admin` |
| `named_facet_dictionary_repository.dart` | `named_metadata` |
| `named_facet_management_repository.dart` | `named_metadata` |
| `reading_history_repository.dart` | `home` / `read_session` |
| `remote_library_credential_store.dart` | `library_admin` |
| `series_repository.dart` | `library_browse` |
| `tag_repository.dart` | `named_metadata` |

#### 模型 / 端口 / 缩略图（`shared/domain/`）

| 现状路径 | 目标 | 备注 |
|----------|------|------|
| `domain/models/**` | `shared/domain/models/**` | 含 freezed 源文件 |
| `domain/ports/**` | `shared/domain/ports/**` | + #221 新建 library write ports |
| `domain/thumbnail/**` | `shared/domain/thumbnail/**` | |

#### `domain/library/` 拆分（#221）

| 现状文件 | 目标模块 | 目标层 |
|----------|----------|--------|
| `library_sync_coordinator.dart` | `library_admin` | `domain` |
| `metadata_refresh_coordinator.dart` | `library_admin` | `domain` |
| `comic_metadata_bulk_patch_coordinator.dart` | `library_admin` | `domain` |
| `comic_metadata_bulk_patch_types.dart` | `shared/domain/library/` | 端口签名共用 |
| `metadata_refresh_types.dart` | `shared/domain/library/` | |
| `sync_library_types.dart` | `shared/domain/library/` | |
| `library_scan_scheduler.dart` | `library_admin` | `domain` |
| `comic_trash_service.dart` | `comic_trash` | `domain` |
| `comic_purge_policy.dart` | `comic_trash` | `domain` |
| `library_comic_filter.dart` | `library_browse` | `domain` |
| `library_comic_projection.dart` | `library_browse` | `domain` |
| `library_series_projection.dart` | `library_browse` | `domain` |
| `library_expand_by_series.dart` | `library_browse` | `domain` |
| `library_prefer_library_root_series.dart` | `library_browse` | `domain` |
| `library_needs_metadata_only.dart` | `library_browse` | `domain` |
| `comic_list_query.dart` | `library_browse` | `domain` |
| `smart_facet_match.dart` | `library_browse` | `domain` |
| `smart_facet_match_preference.dart` | `library_browse` | `domain` |
| `author_filter_preference_migration.dart` | `library_browse` | `domain` |
| `library_sidebar_layout.dart` | `library_admin` | `domain` |
| `format_group.dart` | `shared/domain/library/` | l10n 依赖 |
| `scan_interval.dart` | `shared/domain/library/` | |
| `library_*_filter.dart` / `library_comic_sort_option.dart` 等枚举筛选 | `shared/domain/library/` | 多 feature + l10n |
| `library_tri_state_pick.dart` | `library_browse` | `domain` |

#### `domain/reading/` 拆分

| 现状文件 | 目标模块 | 目标层 |
|----------|----------|--------|
| `read_session.dart` | `read_session` | `domain` |
| `read_session_coordinator.dart` | `read_session` | `domain` |
| `read_session_page.dart` | `read_session` | `domain` |
| `read_session_exceptions.dart` | `read_session` | `domain` |
| `reader_session_service.dart` | `read_session` | `domain` |
| `reader_session_snapshot.dart` | `read_session` | `domain` |
| `reader_page_payload.dart` | `read_session` | `domain` |
| `page_image_copy.dart` | `read_session` | `domain` |
| `auto_play_*.dart` | `read_session` | `domain` |
| `spread_index.dart` | `read_session` | `domain` |
| `reading_mode.dart` | `shared/domain/reading/` | 设置/阅读共用 |
| `series_reading_context.dart` | `shared/domain/reading/` | #223：消除 browse→reading |

### 1.4 `ui/core/` → `shared/ui/`

| 现状路径 | 目标路径 | Slice |
|----------|----------|-------|
| `ui/core/dto/**` | `shared/ui/dto/**` | 随首个引用方 slice |
| `ui/core/interaction/**` | `shared/ui/interaction/**` | `read_session` |
| `ui/core/layout/**` | `shared/ui/layout/**` | `bootstrap` |
| `ui/core/theme/**` | `shared/ui/theme/**` | `bootstrap` |
| `ui/core/widgets/**` | `shared/ui/widgets/**` | 分批随 feature |

⚠️ **Ambiguous**：`ui/core/widgets/overlays/dialog/confirm/comic_confirm_trash_dialog.dart`、`comic_confirm_purge_dialog.dart` — 语义属 `comic_trash`，物理位置建议在 **`shared/ui`**（dumb 对话框 + callback）或 **`comic_trash/presentation/widgets`**；推荐 **shared/ui**（ADR-0017 dumb overlay）。

### 1.5 `ui/providers/` → `shared/di/`（#222）

| 现状文件 | 目标 |
|----------|------|
| `ui/providers/comic_cover_providers.dart` | `shared/di/comic_cover_providers.dart` |
| `ui/providers/series_cover_providers.dart` | `shared/di/series_cover_providers.dart` |
| `ui/providers/comic_cover_load_gate.dart` | `shared/di/comic_cover_load_gate.dart` |
| `ui/providers.dart` | 删除；`features/bootstrap/di/deps.dart` + strangler |

### 1.6 `main.dart`

| 现状 | 目标 | 备注 |
|------|------|------|
| `main.dart` | 保留 `app/lib/main.dart` | 逻辑归属 `bootstrap`；#220 R2 白名单 |

---

## 2. `features/bootstrap`

| 现状路径 | 目标路径 | 备注 |
|----------|----------|------|
| `ui/features/shell/views/app.dart` | `features/bootstrap/presentation/views/app.dart` | |
| `ui/features/shell/views/routing/**` | `features/bootstrap/presentation/views/routing/**` | 含 `app_router` |
| `ui/features/shell/views/responsive_app_shell.dart` | `features/bootstrap/presentation/views/responsive_app_shell.dart` | |
| `ui/features/shell/views/all_libraries_browse_page.dart` | `features/bootstrap/presentation/views/all_libraries_browse_page.dart` | 占位 |
| `ui/features/shell/view_models/app_startup_coordinator_notifier.dart` | `features/bootstrap/presentation/view_models/app_startup_coordinator_notifier.dart` | |
| `ui/features/shell/view_models/aggregates.dart` | `features/bootstrap/presentation/view_models/aggregates.dart` | ⚠️ 若仅 re-export 其他 feature，改为 bootstrap 薄 barrel |
| `ui/features/shell/view_models/debouncer.dart` | `shared/core/util/debouncer.dart` 或 `bootstrap/...` | ⚠️ 通用工具 → **shared/core** |
| `ui/features/shell/view_models/stream_throttle.dart` | `shared/core/util/stream_throttle.dart` | 同上 |
| `ui/features/shell/di/deps.dart` | `features/bootstrap/di/deps.dart` | 组合根 |
| `ui/features/shell/shell.dart` | 删除或 bootstrap barrel | |
| `ui/features/shell/di/repos.dart` 等 | 见 §3 各 feature + `shared/di` | #222 |

---

## 3. `features/home`

| 现状路径 | 目标路径 |
|----------|----------|
| `ui/features/shell/views/home_page/**` | `features/home/presentation/views/home_page/**` |
| `ui/features/shell/view_models/home_alert_dismiss_notifier.dart` | `features/home/presentation/view_models/home_alert_dismiss_notifier.dart` |
| `ui/features/shell/view_models/home_page_dashboard_notifier.dart` | `features/home/presentation/view_models/home_page_dashboard_notifier.dart` |
| `ui/features/shell/view_models/home_probe_coordinator_notifier.dart` | `features/home/presentation/view_models/home_probe_coordinator_notifier.dart` |
| `ui/features/shell/views/history_page.dart` | `features/home/presentation/views/history_page.dart` |
| `ui/features/shell/views/history_page/**` | `features/home/presentation/views/history_page/**` |
| `ui/features/shell/view_models/history_*.dart` | `features/home/presentation/view_models/history_*.dart` |
| `domain/models/read_models/home_page_read_models.dart` | `shared/domain/models/read_models/home_page_read_models.dart` |

---

## 4. `features/library_admin`

| 现状路径 | 目标路径 |
|----------|----------|
| `ui/features/shell/views/navigation/**` | `features/library_admin/presentation/views/navigation/**` |
| `ui/features/shell/view_models/current_library_notifier.dart` | `features/library_admin/presentation/view_models/current_library_notifier.dart` |
| `ui/features/shell/view_models/scan_library_controller.dart` | `features/library_admin/presentation/view_models/scan_library_controller.dart` |
| `ui/features/shell/view_models/library_revision_notifier.dart` | `features/library_admin/presentation/view_models/library_revision_notifier.dart` |
| `ui/features/shell/view_models/library_revision_throttle_busy.dart` | `features/library_admin/presentation/view_models/library_revision_throttle_busy.dart` |
| `ui/features/shell/view_models/library_reorder_mode_notifier.dart` | `features/library_admin/presentation/view_models/library_reorder_mode_notifier.dart` |
| `ui/features/shell/view_models/library_series_providers.dart` | `features/library_admin/presentation/view_models/library_series_providers.dart` |
| `ui/features/shell/view_models/metadata_refresh_controller.dart` | `features/library_admin/presentation/view_models/metadata_refresh_controller.dart` |
| `ui/features/shell/view_models/metadata_refresh_toasts.dart` | `features/library_admin/presentation/view_models/metadata_refresh_toasts.dart` |
| `ui/features/shell/view_models/library_scan_toasts.dart` | `features/library_admin/presentation/view_models/library_scan_toasts.dart` |
| `ui/features/shell/view_models/comic_metadata_bulk_patch_controller.dart` | `features/library_admin/presentation/view_models/comic_metadata_bulk_patch_controller.dart` |
| `ui/features/shell/view_models/comic_metadata_bulk_patch_toasts.dart` | `features/library_admin/presentation/view_models/comic_metadata_bulk_patch_toasts.dart` |
| `ui/features/shell/views/library_scan_shell_feedback.dart` | `features/library_admin/presentation/views/library_scan_shell_feedback.dart` |
| `ui/features/shell/views/comic_metadata_bulk_patch_shell_feedback.dart` | `features/library_admin/presentation/views/comic_metadata_bulk_patch_shell_feedback.dart` |
| `ui/features/shell/di/library_sync.dart` | `features/library_admin/di/library_sync.dart` |
| `ui/features/shell/di/metadata_refresh.dart` | `features/library_admin/di/metadata_refresh.dart` |
| `ui/features/shell/di/comic_metadata_bulk_patch.dart` | `features/library_admin/di/comic_metadata_bulk_patch.dart` |
| `domain/library/*` coordinator 等 | 见 §1.3 | |

---

## 5. `features/library_browse`

**整树**：`ui/features/library/**` → `features/library_browse/presentation/**` | **已迁**（2026-10-17）

| 现状路径 | 目标 | 备注 |
|----------|------|------|
| `ui/features/library/**` | `features/library_browse/presentation/**` | **已迁** |
| Author 三件套 | `shared/ui/widgets/author/` | **已迁** |
| `library_scroll_to_top_button` | `shared/ui/widgets/navigation/` | **已迁** |
| §1.3 browse 专属 `domain/library/*` | `features/library_browse/domain/` | **已迁**（`library_comic_sort_option` 等待 `shared/domain/library`） |
| `comic_delete_flow.dart` | 同路径 under presentation | 仍调 `comic_trash` di（#223） |

---

## 6. `features/read_session`

| 现状路径 | 目标路径 |
|----------|----------|
| `ui/features/reader/**` | `features/read_session/presentation/**` | **已迁**（2026-10-17）；`module/controller` 阶段二另票 |
| `read_session_launcher.dart` | `ui/features/shell/views/routing/read_session_launcher.dart` | **已迁**（#220 R5：library 经 shell 路由打开阅读，不进 read_session presentation） |
| `domain/reading/*`（read_session 专属） | `features/read_session/domain/**` | **已迁** |
| `reading_mode.dart` / `series_reading_context.dart` | `shared/domain/reading/` | **已迁** |

---

## 7. `features/comic_trash`

| 现状路径 | 目标路径 |
|----------|----------|
| `ui/features/shell/views/trash_page/**` | `features/comic_trash/presentation/views/trash_page/**` |
| `ui/features/shell/view_models/trash_page_controller.dart` | `features/comic_trash/presentation/view_models/trash_page_controller.dart` |
| `ui/features/shell/view_models/trash_page_state.dart` | `features/comic_trash/presentation/view_models/trash_page_state.dart` |
| `ui/features/shell/view_models/comic_trash_actions.dart` | `features/comic_trash/presentation/view_models/comic_trash_actions.dart` |
| `ui/features/shell/di/comic_trash.dart` | `features/comic_trash/di/comic_trash.dart` |
| `domain/library/comic_trash_service.dart` 等 | `features/comic_trash/domain/**` | §1.3 |
| `domain/models/read_models/trashed_comic.dart` | `shared/domain/models/read_models/trashed_comic.dart` | |

⚠️ `trash_page` 复用 `history_page` header → 抽 **`shared/ui`** 或 `home` 暴露 dumb header（#223）。

---

## 8. `features/named_metadata`

| 现状路径 | 目标路径 |
|----------|----------|
| `ui/features/metadata/**` | `features/named_metadata/presentation/**` | **已迁**（2026-10-17） |
| `data/services/tag_dictionary/**` | `features/named_metadata/data/services/tag_dictionary/**` | **已迁** |
| `domain/models/named_facet_form_candidate.dart` | `shared/domain/models/named_facet_form_candidate.dart` | **已迁** |
| `domain/models/tag_dictionary_import_result.dart` | `features/named_metadata/domain/` 或 `shared/domain` | ⚠️ 暂留 `domain/models/`（`tag_repository` 在 shared domain） |

---

## 9. `features/app_settings`

| 现状路径 | 目标路径 |
|----------|----------|
| `ui/features/settings/**` | `features/app_settings/presentation/**` | **已迁**（2026-10-16） |
| `core/app_data/app_data_wipe_flow.dart` | `features/app_settings/presentation/app_data_wipe_flow.dart` | **已迁**；§1.2 |
| `data/services/app_update/**` | `features/app_settings/data/services/app_update/**` | **已迁** |

⚠️ **Ambiguous**：`settings/view_models/metadata_auto_backup_*.dart` — UI 在设置页，领域属 **metadata_backup**：

| 文件 | 目标 |
|------|------|
| `metadata_auto_backup_coordinator_notifier.dart` | `features/metadata_backup/presentation/view_models/` | **已迁**（2026-10-17）；设置页 `ref.watch` canonical provider |

---

## 10. `features/metadata_backup`

| 现状路径 | 目标 |
|----------|------|
| `core/metadata/metadata_import_flow.dart` | `features/metadata_backup/presentation/` | **已迁**（含 FRB adapter 依赖） |
| `core/metadata/metadata_export_flow.dart` | `features/metadata_backup/presentation/` | **已迁** |
| `core/metadata/metadata_auto_backup_service.dart` | `features/metadata_backup/data/` | **已迁** |
| `core/metadata/metadata_auto_backup_logic.dart` | `features/metadata_backup/domain/` | **已迁** |
| `core/metadata/metadata_backup_paths.dart` | `features/metadata_backup/data/` | **已迁** |
| `core/metadata/metadata_backup_bytes.dart` | `features/metadata_backup/domain/` | **已迁** |
| `core/metadata/metadata_export_options.dart` | `features/metadata_backup/domain/` | **已迁** |
| `app_settings/.../metadata_auto_backup_*.dart` | `features/metadata_backup/presentation/view_models/` | **已迁** |
| `data/adapters/metadata_backup_frb_adapter.dart` | `shared/data/adapters/` | 待 `shared/data` slice |

---

## 11. `shared/di`（自 shell/di）

| 现状 | 目标 |
|------|------|
| `ui/features/shell/di/repos.dart` | `shared/di/repos.dart` |
| `ui/features/shell/di/ports.dart` | `shared/di/ports.dart` |
| `ui/features/shell/di/services.dart` | 拆分 §1.1 / §7–9 feature `di` | #222 |

---

## 12. 已删除 / 不重迁

| 路径 | 说明 |
|------|------|
| `ui/features/*/state/` | 已移除（ADR-0017） |
| 根级 `presentation/`、`model/` 等 | 禁止（coding-style） |

---

## 13. 维护

- 路径级全量枚举：`find app/lib -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart'`
- 模块边对照：`python scripts/research/cross_feature_import_audit.py`
- 矩阵变更：PR 须更新本文件版本表与 #225 slice checklist

| 版本 | 说明 |
|------|------|
| 2026-10-16 | 初版（#224） |
| 2026-10-16 | `app_settings` slice：presentation + `app_data_wipe_flow` + `app_update` 已落目标路径 |
| 2026-10-17 | `named_metadata` slice：presentation + `tag_dictionary` + `named_facet_form_candidate` → `shared/domain` |
| 2026-10-17 | `metadata_backup` slice：`core/metadata` + 自动备份 ViewModel 归位 |
| 2026-10-17 | `read_session` slice：reader presentation + domain/reading 拆分 + launcher 归 shell 路由 |
| 2026-10-17 | `library_browse` slice：library presentation + browse domain + 共用 author/scroll UI |
