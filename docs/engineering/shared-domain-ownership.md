# `shared/domain` 归属表（Epic #436 收尾）

**决策索引**：ADR-0033（Application 层）、ADR-0034（public only）、**ADR-0035**（Catalog Shared Kernel）。  
**门禁**：L3b `shared_domain_feature_import_baseline.json`（当前应为 `[]`）；**2026-11-02** 起 owner 域 strangler re-export 已全部移除（`strangler_shims.txt` 为空），请直接 import **`features/<owner>/domain/...`**。

## 真源在 owner feature（已从 shared 移除 strangler）

下列类型 **仅** 存在于各 feature `domain/`；`shared/domain/repositories/`、`shared/domain/reading/`、多数 `shared/domain/library/` shim 文件已删除：

| 语义 | Owner 真源 |
| --- | --- |
| `comic_trash/*`、`TrashedComic` read model | `features/comic_trash/domain/` |
| `reading/*` | `features/read_session/domain/` |
| 库 browse 壳（跨 Tab 偏好、作者、catalog 壳） | `features/library_browse/domain/browse/`（**不含** comic/series Tab 规则） |
| Comic 仓储、Comics Tab 规则、展示标题、smart facet | `features/comic/domain/` |
| Series 仓储、Series Tab 规则 | `features/series/domain/` |
| 库 admin（扫描、revision、current library 等） | `features/library_admin/domain/` |
| `comic_display_title` 等 | `features/comic/domain/` |
| read_session / app_settings 端口实现类型 | 各 owner `domain/` |
| `repositories/*` 契约 | 各 owner `features/*/domain/` |
| **reading_history** | `features/reading_history/domain/` |
| `app_setting*` | `features/app_settings/domain/` |
| home read models | `features/home/domain/` |
| named metadata 表单/字典 | `features/named_metadata/domain/`；跨 feature **`features/named_metadata/public.dart`**（仓储契约 re-export、字典 Riverpod、`listNamedFacetForMetadataForm`、MD3E 路由/Lab export） |

Feature 内代码应 **import owner `domain/`**（`library_browse` 内按 [`library-browse-zones.md`](library-browse-zones.md) 分子目录）；跨 feature 经 **`features/<owner>/public/**`**（ADR-0034）。**勿**再新增对已删除 shared shim 路径的依赖。

`models/models.dart` 仍 re-export `reading_history` 与 `app_setting` 的 **feature URI**（便捷 barrel，非 strangler 文件）。

## Catalog Shared Kernel（真源 @ shared，ADR-0035）

不在 #436 批量迁出；consumer 继续 `import shared/domain/...`：

- `models/entity/comic/**`、`models/enums.dart`
- `models/value_objects/page_request.dart`、`paged_result.dart`、`page_jump.dart`
- 与 catalog 强绑定的 form / pick / meta VO（见 `models/models.dart` barrel）
- `reading/series_reading_context.dart`（类型；读口 `SeriesReadingContextPort` @ shared/di，实现 @ series）
- `library/scan_interval.dart`、`library/metadata_refresh_types.dart`、`library/comic_metadata_bulk_patch_result.dart`（库扫描/批量结果；shared UI toast 与 `LocalLibrary` 共用）
- `models/managed_named_facet_kind.dart`（metadata 管理 Tab 枚举）
- `thumbnail/**`

## 契约仍定义在 `shared/domain`（未 owner 化）

UI / 编排命令类型；发现面经 owner `public/` re-export（ADR-0034）：

- `ports/author_detail_port.dart`
- `ports/comic_trash_command_port.dart`
- `ports/library_management_port.dart`
- `ports/library_revision_port.dart`、`ports/library_revision_signal_port.dart`
- `ports/series_reading_context_port.dart`
- `ports/read_session_launch_port.dart`
- `library/comic_detail_return_series_port.dart`（实现 @ `comic`）

`shared/di` 声明跨 feature 协作用的 Riverpod token（#426）；实现与 `createXxx()` 在 owner `di/` / `public/di/`，由 `features/bootstrap/di/overrides/` 注入。跨 feature UI 封面等用 **`comic/public.dart`**、**`series/public.dart`** 或 browse 壳 public。

## 测试目录约定

- Owner 域行为单测：`app/test/features/<owner>/domain/**`
- Shared Kernel / 跨库契约：`app/test/shared/domain/**`（entity、VO、repository 契约等）
