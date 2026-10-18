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
- `core/...` ← 应用横切内核（l10n、logging、util 等；2026-10-18 自 `shared/core` 回迁 `lib/core`）
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

### 1.2 应用 `core/`（`lib/core`，非 Rust `core/`）

| 现状路径 | 目标路径 | Slice | 备注 |
|----------|----------|-------|------|
| `core/app_data/app_data_wipe_flow.dart` | `features/app_settings/presentation/app_data_wipe_flow.dart` | `app_settings` | UI 编排（#220 R1：避免 feature `domain`→`data`）；矩阵原写 `domain/` |
| `core/constants/**` | `core/constants/**` | `app_settings` 或 `bootstrap` | |
| `core/errors/**` | `core/errors/**` | `bootstrap` | |
| `core/image/**` | `core/image/**` | `bootstrap` | `main` 引用 |
| `core/io/**` | `features/library_admin/data/local_library_root_access.dart` | `library_admin` | Local root 访问（2026-10-18 迁出 `lib/core`） |
| `core/l10n/**` | `core/l10n/**` | `bootstrap` | |
| `core/logging/**` | `core/logging/**` | `bootstrap` | §2.2 FRB：`diagnostic_logging` 需 adapter 化 |
| `core/metadata/**` | `features/metadata_backup/domain/**` + `features/metadata_backup/data/**` | `metadata_backup` | flow/service 入 feature；paths/bytes 可拆 data |
| `core/util/**` | `core/util/**` | `bootstrap` | |
| `core/utils/**` | `shared/util/name_pinyin_assisted_filter.dart` | `library_browse` / `named_metadata` | 拼音筛选（2026-10-18 迁出 `lib/core`） |

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
| `library_comic_filter.dart` | `shared/domain/library/` | **已迁**（#297，仓储契约共用） |
| `library_comic_projection.dart` | `library_browse` | `domain` |
| `library_series_projection.dart` | `shared/domain/library/` | **已迁**（#298，仓储契约共用） |
| `library_expand_by_series.dart` | `library_browse` | `domain` |
| `library_prefer_library_root_series.dart` | `library_browse` | `domain` |
| `library_needs_metadata_only.dart` | `library_browse` | `domain` |
| `comic_list_query.dart` | `library_browse` | `domain` |
| `smart_facet_match.dart` | `library_browse` | `domain` |
| `smart_facet_match_preference.dart` | `library_browse` | `domain` |
| `author_filter_preference_migration.dart` | `library_browse` | `domain` |
| `library_sidebar_layout.dart` | `shared/domain/library/` | **已迁**（#299，仓储契约共用） |
| `format_group.dart` | `shared/domain/library/` | l10n 依赖 |
| `scan_interval.dart` | `shared/domain/library/` | |
| `library_*_filter.dart` / `library_comic_sort_option.dart` 等枚举筛选 | `shared/domain/library/` | 多 feature + l10n |
| `library_tri_state_pick.dart` | `shared/domain/library/` | **已迁**（#296，metadata 筛选共用） |

#### `domain/reading/` 拆分

| 现状文件 | 目标模块 | 目标层 |
|----------|----------|--------|
| `read_session.dart` | `read_session` | `domain` |
| `read_session_coordinator.dart` | `read_session` | `domain` |
| `read_session_page.dart` | `shared/domain/reading/` | **已迁**（#300，端口载荷共用） |
| `read_session_exceptions.dart` | `read_session` | `domain` |
| `reader_session_service.dart` | `read_session` | `domain` |
| `reader_session_snapshot.dart` | `read_session` | `domain` |
| `reader_page_payload.dart` | `shared/domain/reading/` | **已迁**（#300，端口载荷共用） |
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
| shell `app` / `routing` / `responsive_app_shell` / startup VM | `features/bootstrap/presentation/**` | **已迁**（2026-10-17） |
| `debouncer` / `stream_throttle` | `core/util/` | **已迁** |
| `deps` + `repos` / `ports` / `services` | `features/bootstrap/di/` | **已迁**；`shared/di` 见 #258 bootstrap-final |
| `shell.dart` | 删除 | **已删** |

**已完成（#258 bootstrap-final，2026-10-17）**：legacy `ui/`/`core/`/`data/`/`domain/` 整树 → `shared/`、Phase B 启用、`ui/providers.dart` 删除。

---

## 3. `features/home`

| 现状路径 | 目标路径 |
|----------|----------|
| shell `home_page` / `history_page` + home/history view_models | `features/home/presentation/**` | **已迁**（2026-10-17） |
| `home_page_read_models` | `shared/domain/models/read_models/` | **已迁** |

`home_page_repository` 等仍见 §1.3（`shared/domain/repositories` 待 bootstrap 或后续票）。

---

## 4. `features/library_admin`

| 现状路径 | 目标路径 |
|----------|----------|
| shell navigation + library 管理 VM + shell feedback + `di/*_sync` 等 | `features/library_admin/{presentation,di}/**` | **已迁**（2026-10-17） |
| §1.3 coordinators / `library_scan_scheduler` | `features/library_admin/domain/` | **已迁** |
| `library_sidebar_layout` | `shared/domain/library/` | **已迁**（#299） |

端口与共用 types（`sync_library_types` 等）仍见 `domain/library/` → 后续 `shared/domain/library`。

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
| `read_session_launcher.dart` | `features/bootstrap/presentation/views/routing/read_session_launcher.dart` | **已迁**（#220 R5） |
| `domain/reading/*`（read_session 专属） | `features/read_session/domain/**` | **已迁** |
| `reading_mode.dart` / `series_reading_context.dart` | `shared/domain/reading/` | **已迁** |

---

## 7. `features/comic_trash`

| 现状路径 | 目标路径 |
|----------|----------|
| shell `trash_page` + trash view_models + `di/comic_trash` | `features/comic_trash/{presentation,di}/**` | **已迁**（2026-10-17） |
| `comic_trash_service` / `comic_purge_policy` | `features/comic_trash/domain/` | **已迁** |
| `trashed_comic` | `shared/domain/models/read_models/` | **已迁** |

⚠️ `trash_page` 仍引用 `features/home` 的 `history_page` header（M1 baseline）；抽 shared/ui 另票（#223）。

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

### Gate 保护（与代码同步）

| 矩阵目标 | Gate / 文档 |
|----------|-------------|
| `shared/ui/**`（含 `theme/`）不得依赖 `features/` | L3a：`shared_ui_no_feature_import_test.dart`（ADR-0027） |
| `shared/domain/**` 不得新增对 `features/` 的 import 边 | L3b：`shared_domain_no_feature_import_test.dart` + baseline ratchet（#295） |
| `shared/data/adapters/**` 允许故意 import feature（FRB 薄边） | `shared_feature_import_rules.dart` 白名单；**不**对整棵 `shared/data` ratchet |
| product feature↔feature 图 | L2：`import_boundary_baseline.json`（#220） |
| `shared/domain` / feature `domain/` 不得 import `shared/data` | L1 R1：`import_boundary_test.dart` |

| 版本 | 说明 |
|------|------|
| 2026-10-16 | 初版（#224） |
| 2026-10-16 | `app_settings` slice：presentation + `app_data_wipe_flow` + `app_update` 已落目标路径 |
| 2026-10-17 | `named_metadata` slice：presentation + `tag_dictionary` + `named_facet_form_candidate` → `shared/domain` |
| 2026-10-17 | `metadata_backup` slice：`core/metadata` + 自动备份 ViewModel 归位 |
| 2026-10-17 | `read_session` slice：reader presentation + domain/reading 拆分 + launcher 归 shell 路由 |
| 2026-10-17 | `library_browse` slice：library presentation + browse domain + 共用 author/scroll UI |
| 2026-10-17 | `comic_trash` slice：trash UI/VM/di + domain + `trashed_comic` → shared |
| 2026-10-17 | `home` slice：home/history presentation + `home_page_read_models` → shared |
| 2026-10-17 | `library_admin` slice：navigation/VM/di + domain coordinators |
| 2026-10-17 | `bootstrap` slice（presentation）：shell 残余 → `features/bootstrap` + util → `shared/core`（后于 2026-10-18 回迁 `lib/core`） |
| 2026-10-17 | `bootstrap-final`（#258）：`core/data/domain/ui` 整树 → `shared/*`；`ui/providers` → `shared/di`；删除 `ui/providers.dart`；Phase B 启用；Gate 基线 135 条 feature↔feature 边保留（follow-up 解耦） |
| 2026-10-18 | #295 P3：`shared/ui/theme` 纳入 L3a；`shared/domain`→`features` L3b ratchet；`shared/data` adapter 白名单文档化（见 §13 Gate 保护） |
