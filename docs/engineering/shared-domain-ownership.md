# `shared/domain` 归属表（Epic #436 收尾）

**决策索引**：ADR-0033（Application 层）、ADR-0034（public only）、**ADR-0035**（Catalog Shared Kernel）、**ADR-0039**（领域事件）。  
**门禁**：L3b `shared_domain_feature_import_baseline.json`（当前应为 `[]`）；**2026-11-02** 起 owner 域 strangler re-export 已全部移除（`strangler_shims.txt` 为空），请直接 import **`features/<owner>/domain/...`**。

## 真源在 owner feature（已从 shared 移除 strangler）

下列类型 **仅** 存在于各 feature `domain/`；`shared/domain/repositories/`、`shared/domain/reading/`、多数 `shared/domain/library/` shim 文件已删除：

| 语义 | Owner 真源 |
| --- | --- |
| `comic_trash/*`、`TrashedComic` read model | `features/comic_trash/domain/` |
| `reading/*`（Read session 域类型） | `features/reader/domain/`（ADR-0038；旧 `read_session`） |
| 库 browse 壳（跨 Tab 偏好、作者、catalog 壳） | `features/library_browse/domain/browse/`（**不含** comic/series Tab 规则） |
| Comic 仓储、Comics Tab 规则、展示标题、smart facet | `features/comic/domain/` |
| Series 仓储、Series Tab 规则 | `features/series/domain/` |
| 库 admin（扫描、revision、current library 等） | `features/library_admin/domain/` |
| `comic_display_title` 等 | `features/comic/domain/` |
| reader / app_settings 端口实现类型 | 各 owner `domain/` |
| `repositories/*` 契约 | 各 owner `features/*/domain/` |
| **reading_history** | `features/reading_history/domain/` |
| `app_setting*` | `features/app_settings/domain/` |
| home read models | `features/home/domain/` |
| named metadata 表单/字典 | `features/named_metadata/domain/`；跨 feature **`features/named_metadata/public.dart`**（仓储契约、字典 Riverpod、生产页）；Comic 表单窄面 **`public/named_metadata_form.dart`**；Lab patterns **`public/ui/metadata_lab_patterns.dart`** |

Feature 内代码应 **import owner `domain/`**（`library_browse` 内按 [`library-browse-zones.md`](library-browse-zones.md) 分子目录）；跨 feature 经 **`features/<owner>/public/**`**（ADR-0034）。**勿**再新增对已删除 shared shim 路径的依赖。

`models/models.dart` 仍 re-export `reading_history` 与 `app_setting` 的 **feature URI**（便捷 barrel，非 strangler 文件）。

## Comic 聚合 vs feature 边界（ADR-0002 / 0026 / 0036）

- **聚合写集在 Rust**：以 `comicId` 为根，同事务提交 `comics` + `comic_meta` + facet junction + Metadata field lock。单本用户写不持库级写锁；跨本 bulk / sync / trash 等走库级写接缝。
- **`features/comic` 是 feature，不是 Dart Aggregate Root**：契约与 Comics Tab 规则、展示标题、smart facet、单本元数据 application 在此；**勿**在 Dart 侧再建 `ComicAggregate` 或把 Kernel DTO 迁入本 feature（ADR-0035）。
- **对照归属**：Series 成员/排序 → `features/series`；trash 生命周期 → `features/comic_trash`；库级 bulk patch 编排 → `features/library_admin`（与 comic 单本 form 草稿路径不同，无需合并）；浏览壳 → `features/library_browse`。分区协作与 public 收窄见 [`library-browse-zones.md`](library-browse-zones.md)。

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
- `ports/series_reading_context_port.dart`
- `ports/reader_launch_port.dart`（旧名 `read_session_launch_port`；ADR-0038）
- `library/comic_detail_return_series_port.dart`（实现 @ `comic`）

## 领域事件（ADR-0039）

`shared/domain/events/**` 是跨 feature 事件的**唯一**词汇表与发布/订阅接口（sealed `DomainEvent`、`DomainEventPublisher`、`DomainEventBus`）；实现 `StreamDomainEventBus`（`StreamController.broadcast(sync: true)`，无第三方依赖）在 `shared/data/events/`。它不属于 Catalog Kernel，也不经 owner `public/` 暴露——所有 feature 直接 `import shared/domain/events/events.dart`。

`shared/di` 只声明跨 feature **命令 Port** 与全局状态 token（#426 / ADR-0034 §3）；模块私有 token 归 owner `public/di/**`，由消费方直接 watch。实现与 `createXxx()` 在 owner `di/` / `public/di/`，由 `features/bootstrap/di/overrides/` 注入。跨 feature UI 封面等用 **`comic/public.dart`**、**`series/public.dart`** 或 browse 壳 public。

## 测试目录约定

- Owner 域行为单测：`app/test/features/<owner>/domain/**`
- Shared Kernel / 跨库契约：`app/test/shared/domain/**`（entity、VO、repository 契约等）
