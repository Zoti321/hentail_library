# `shared/domain` 归属表（Epic #436 收尾）

**决策索引**：ADR-0033（Application 层）、ADR-0034（public only）、**ADR-0035**（Catalog Shared Kernel）、**ADR-0039**（领域事件）、**ADR-0041**（Comic 实体归属）、**ADR-0042**（Series 实体归属 + 跨模块契约）、**ADR-0048**（Comic metadata 模块与 Author / Tag 归属）、**ADR-0049**（剩余 models / ports 内聚）。
**门禁**：L3b `shared_domain_feature_import_baseline.json`（当前应为 `[]`）；**2026-11-02** 起 owner 域 strangler re-export 已全部移除（`strangler_shims.txt` 为空），请直接 import **`features/<owner>/domain/...`**。

## 真源在 owner feature（已从 shared 移除 strangler）

下列类型 **仅** 存在于各 feature `domain/`；`shared/domain/repositories/`、`shared/domain/reading/`、多数 `shared/domain/library/` shim 文件已删除：

| 语义 | Owner 真源 |
| --- | --- |
| `comic_trash/*`、`TrashedComic` read model | `features/comic_trash/domain/` |
| `reading/*`（Read session 域类型） | `features/reader/domain/`（ADR-0038；旧 `read_session`） |
| 库 browse 壳（跨 Tab 偏好、作者、catalog 壳） | `features/library_browse/domain/browse/`（**不含** comic/series Tab 规则） |
| Comic 仓储、Comics Tab 规则、展示标题、smart facet | `features/comic/domain/`（见下方分层） |
| **`Comic` 实体、`ComicMetaLocks`、`ComicMetadataForm`、`Comic` FRB 映射** | `features/comic/domain/`、`features/comic/infrastructure/comic_entity_mapper.dart`（ADR-0041；跨模块经 `features/comic/public/**`） |
| **Series 跨模块契约** | `shared/domain/`：`SeriesReadingContext`、`SeriesItemMembership`、`SeriesItemSortPort`、`SeriesCoverSource`（ADR-0042） |
| Series 仓储、Series Tab 规则、Series 成员读模型 | `features/series/domain/` |
| **`Series` / `SeriesItem` 实体、`SeriesMetaLocks`、`SeriesComicsMetadata`、`SeriesMetadataForm`、FRB 映射** | `features/series/domain/`、`features/series/infrastructure/series_frb_mapper.dart`（ADR-0042；public 不暴露实体） |
| 库 admin（扫描、revision、current library 等） | `features/library_admin/domain/` |
| `comic_display_title` 等 | `features/comic/domain/` |
| reader / app_settings 端口实现类型 | 各 owner `domain/` |
| `repositories/*` 契约 | 各 owner `features/*/domain/` |
| **reading_history** | `features/reading_history/domain/` |
| `app_setting*` | `features/app_settings/domain/`（阅读偏好**只**存 `String` id / `int` schema，枚举语义归 `features/reader/domain/`，两侧经 ACL 通信——ADR-0046） |
| home read models | `features/home/domain/` |
| Content rating、Comic Language、作者/标签筛选 pick | `features/comic/domain/value_objects/`；跨模块经 `comic/public/comic_metadata_types.dart`（ADR-0049） |
| Serialization status | `features/series/domain/value_objects/serialization_status.dart`（ADR-0049） |
| Resource format category、远程凭据同步 Port 与 token | `features/library_admin/domain/`、`public/providers/remote_library_credentials_providers.dart`；app_settings 仅传递旧设置载荷，bootstrap 注入凭据实现（ADR-0049） |
| named metadata 表单/字典 | `features/comic_metadata/domain/`；跨 feature **`features/comic_metadata/public.dart`**（仓储契约、字典 Riverpod、生产页）；Comic 表单窄面 **`public/comic_metadata_form.dart`**；Lab patterns **`public/ui/metadata_lab_patterns.dart`** |

Feature 内代码应 **import owner `domain/`**（`library_browse` 内按 [`library-browse-zones.md`](library-browse-zones.md) 分子目录）；跨 feature 经 **`features/<owner>/public/**`**（ADR-0034）。**勿**再新增对已删除 shared shim 路径的依赖。

### `features/comic/domain/` 分层（2026-11-11）

| 路径 | 内容 |
| --- | --- |
| `comic.dart` | `Comic` 投影型实体（构造不变式、草稿应用、元数据 diff；ADR-0041） |
| `comic_display_title.dart`、`comic_metadata_normalization.dart` | 展示标题投影、元数据规范化内部辅助 |
| `smart_facet_match.dart`、`smart_facet_match_preference.dart` | Smart facet match 规约与偏好键 |
| `value_objects/` | `ComicMetaLocks`、`ComicMetadataForm`、`LibraryComicFilter` / `Grouping` / `SortOption` |
| `repositories/` | `ComicCatalogRepository`、`ComicLookupRepository`、`ComicThumbnailRepository`、`ComicUserMetadataRepository` |

新域文件按上述职责入对应子目录；实体本身留在 `domain/` 根（DDD 命名：`{aggregate}.dart`）。

### `features/series/domain/` 分层（2026-11-11）

| 路径 | 内容 |
| --- | --- |
| `series.dart`、`series_item.dart` | `Series` 实体与成员（ADR-0042） |
| `series_repository.dart`、`series_comic_page_item.dart` | 仓储契约与成员分页读模型 |
| `value_objects/` | `SeriesMetaLocks`、`SeriesComicsMetadata`、`SeriesMetadataForm` |
| `library_series_*.dart` | 库 Series Tab 筛选/排序/分组/连载状态规则 |

`features/series/public/` **不**暴露 `Series` 实体；跨模块只经 Query / 只读 record（ADR-0042 §2）。

`shared/domain/models/models.dart` barrel 已于 #489 删除（零消费者）；需要 `reading_history` / `app_settings` 类型请直接 import 对应 feature 的 `public/**`（ADR-0034）。

## Comic 聚合 vs feature 边界（ADR-0002 / 0026 / 0036）

- **聚合写集在 Rust**：以 `comicId` 为根，同事务提交 `comics` + `comic_meta` + facet junction + Metadata field lock。单本用户写不持库级写锁；跨本 bulk / sync / trash 等走库级写接缝。
- **`features/comic` 是 feature，不是 Dart Aggregate Root**：契约与 Comics Tab 规则、展示标题、smart facet、单本元数据 application 在此；Dart `Comic` 是**投影型实体**（构造不变式 + 草稿迁移 + 元数据 diff），事务**写集**仍在 Rust（ADR-0041）。**勿**在 Dart 侧再建 `ComicAggregate` 或把 Rust 事务边界搬进 Dart。
- **对照归属**：Series 成员/排序 → `features/series`；trash 生命周期 → `features/comic_trash`；库级 bulk patch 编排 → `features/library_admin`（与 comic 单本 form 草稿路径不同，无需合并）；浏览壳 → `features/library_browse`。分区协作与 public 收窄见 [`library-browse-zones.md`](library-browse-zones.md)。

## Catalog Shared Kernel（真源 @ shared，ADR-0035）

不在 #436 批量迁出；consumer 继续 `import shared/domain/...`：

- `models/enums.dart` 仅保留 `ResourceType`、`LibraryDisplayTarget`、`ThumbnailPriority`（ADR-0049）；实体目录已清空：Comic 归 comic、Series 归 series、Author / AuthorDetail / Tag 归 comic_metadata
- `models/value_objects/page_request.dart`、`paged_result.dart`、`page_jump.dart`
- `models/value_objects/author_ref.dart`：shared metadata chip 与 comic / series 共享引用投影；`series_item_membership.dart`：comic ↛ series 的只读成员协议。语言与 pick 已归 comic（ADR-0049），`library_form.dart` 归 library_admin（#504）
- `reading/series_reading_context.dart`（类型；读口 `FindSeriesReadingContextQuery` @ shared/presentation/providers，实现 @ series）
- `library/library_age_restriction_filter.dart`（跨 Tab 年龄限制词汇：comic / series 禁止边 + home 消费，无可达 owner——ADR-0045 可达性否决，**不是遗留**；2026-11-12 起只承载语义与 `fromStorage`，存储键已下放 browse 持久化）；批量补丁类型已归 `features/library_admin/domain/`（#513）；`library/metadata_refresh_types.dart` 与 `library/library_revision_state.dart` 已于 2026-11-12 归 `library_admin`；`LocalLibrary` / `ScanInterval` / `ScanMode` 已于 2026-11-12 归 `library_admin/domain/`（#531）
- `thumbnail/**`

## 共享协作契约（ADR-0050）

纯 Dart 契约在 `shared/application/contracts/`：AppNavigator、ComicReadQuery、Series 查询/排序、TrashComicsCommand、退出重排和详情返回记忆命令。含 BuildContext 的作者详情与默认返回签名在 `shared/ui/contracts/`。读取进度直接订阅 `shared/presentation/providers/reading_history_providers.dart` 的 StreamProvider；原 ReaderLaunch 纯转发链已合并至 AppNavigator。owner 与 shared 的落点仍按禁止边、public 环、shared/core 消费者决定，具体调用示例见 [跨模块协作](cross-feature-collaboration.md)。

## 领域事件（ADR-0039）

`shared/domain/events/**` 是跨 feature 事件的**唯一**词汇表与发布/订阅接口（sealed `DomainEvent`、`DomainEventPublisher`、`DomainEventBus`）；实现 `StreamDomainEventBus`（`StreamController.broadcast(sync: true)`，无第三方依赖）在 `infrastructure/events/`。它不属于 Catalog Kernel，也不经 owner `public/` 暴露——所有 feature 直接 `import shared/domain/events/events.dart`。

`shared/presentation/providers/` 是共享 UI、禁止边或 public 环所需的 Riverpod 协作适配层，包含必需 token 与领域事件状态投影，不放外部实现。owner 的 token 实现在 `features/<owner>/presentation/providers/`，公开面只经 `public/providers.dart` 或窄 provider facade 导出。外部工厂、跨模块桥接及 override 组装在 `composition/`，不再有 feature `di/` 层。共享 UI 槽位的契约仍在 `shared/ui/slots/`；实现归 owner presentation，由组合根注入。

共享协作契约保留的理由仍按 ADR-0045 的实际消费者和模块可达性判定。新增业务默认进入 owner，不能用 shared 绕过禁止边。纯签名放 shared/application，领域词汇与事实放 shared/domain，平台/FRB 实现放 infrastructure，框架状态与视图分别放 presentation/providers 与 ui。

## 测试目录约定

- Owner 域行为单测：`app/test/features/<owner>/domain/**`
- 共享 Provider 与基础设施测试：`app/test/shared/presentation/providers/`、`app/test/infrastructure/`。旧 `test/shared/domain/` 已迁空移除。
- Comic / Series / Comic metadata 实体归属门禁：`app/test/features/{comic,series,comic_metadata}/**`、`app/test/architecture/{comic,series,comic_metadata}_entity_ownership_test.dart`
- 槽位契约门禁：`app/test/architecture/series_slot_contract_test.dart`（`shared/ui/slots/**` 不得 import `features/**`）
