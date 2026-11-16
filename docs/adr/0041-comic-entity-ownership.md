# ADR-0041: Comic 实体迁入漫画模块（Dart 投影型实体）

## Status

Accepted

## Context

[#489](https://github.com/Zoti321/hentail_library/issues/489)：`Comic` 一直住在 Catalog Shared Kernel（`shared/domain/models/entity/comic/`），但 Dart 侧唯一直接构造它的地方是 FRB 映射，其余全是读字段。结果是：

- 围绕 Comic 的规则被拆散：标题非空校验、草稿与原值的差异计算住在元数据草稿里，实体本身没有任何不变式。
- 任何 Comic 相关能力（元数据编辑、批量编辑、封面、阅读进度展示）都要动 `shared/`，而 `shared/**` 不能引用 owner 模块（R11 / R13）。
- 文档同时存在「不要在 Dart 建 ComicAggregate」与「Comic 聚合写集在 Rust」两条断言，新贡献者无法判断 Dart 侧该给 Comic 什么地位。

ADR-0035 §4 规定的「内核迁出 shared」触发条件已满足：

1. **Dart 侧 Comic 行为膨胀**：`ComicMetadataForm` 的校验收敛、`diffAgainst` 语义与「把草稿应用到实体」都已具备实体内涵，却挂在共享草稿类型上。
2. **消费者可收缩**：除 `series` / `comic_trash` / `library_browse` / `bootstrap` 的少量读取面外，Comic 的消费者集中在 `comic` 模块；`reader` 只需 5 个字段，可自持窄读模型而不新增模块边。

## Decision

### 1. 真源与迁移范围

- **真源**：`features/comic/domain/`：
  - `comic.dart`（实体 + 构造不变式 + 草稿应用/差异）
  - `comic_meta_locks.dart`（字段锁值对象，只读投影）
  - `comic_metadata_form.dart`（UI 编辑态草稿、校验结果、差异类型）
  - `comic_metadata_normalization.dart`（facet 名称规范化与顺序比较，模块内部）
- **FRB 映射**：`features/comic/data/comic_entity_mapper.dart`；跨模块经 `features/comic/public/data/comic_entity_mapper.dart` thin re-export。
- **系列成员分页读模型**：`SeriesComicPageItem` 迁 `features/series/domain/`，经 series public thin re-export。
- **留 Shared Kernel**：`AuthorRef`、`Author`、`AuthorDetail`、`Tag`、`Series`、`SeriesItem`、分页值对象、`enums.dart`。本次只覆盖 Comic。
- **清理**：删除 `Series.hasR18Comic`（零调用）与零消费者的 `shared/domain/models/models.dart`。

### 2. Dart 侧身份：投影型实体，不是聚合根

`Comic` 是**投影型实体**（entity）。权威划分：

| 关注点 | 权威 |
|--------|------|
| 事务边界、Comic 聚合写集（`comics` + `comic_meta` + 4 个 facet junction） | Rust（ADR-0002 / ADR-0026） |
| 元数据字段锁合并（locks 与 sync/user 值的选择） | Rust（`core/crates/core/src/comic/write.rs`） |
| 构造不变式（标题非空、facet 名称规范化） | Dart 实体 |
| 草稿应用与差异计算（三态、清空发布日语义） | Dart 实体 |
| 字段锁的只读渲染投影 | Dart 实体（`locks` 原样投影） |

**禁止**：在 Dart 复刻提交前锁掩码、锁合并或写集校验。字段锁只有一份合并真源（Rust）。

不引入 `ComicAggregate` 类，不重命名文件/类（DDD 命名约定：聚合/实体 → 领域名词）。

### 3. 构造入口

- `Comic.restore({...})`：恢复入口，供 FRB 映射与测试夹具使用，**不做业务校验**（还原 Rust 已持久化事实）。
- `Comic.createMetadata({...})`：真实用户写的创建入口，执行标题非空与 facet 名称规范化。
- freezed 的无名构造器保留为生成/`copyWith` 路径；业务代码应使用上述两个入口。

### 4. 跨模块消费

- 跨模块只经 `features/comic/public/**` 的 **thin re-export**（真源仍在 `domain/` / `data/`）：`public/comic.dart`、`public/data/comic_entity_mapper.dart`。
- `series`、`library_browse`、`comic_trash`、`bootstrap` 改走 comic public。
- **不引入**「shared 反向 export feature」的 shim；`test/gate/strangler_shims.txt` 保持为空。
- 重生成 `import_boundary_baseline.json` 与 `shared_domain_feature_import_baseline.json`（只减不增）。

### 5. Reader 隔离

`reader` 被显式禁止依赖 `comic`（`test/architecture/module_boundary_test.dart`）。因此 reader 自持窄读模型：

- `features/reader/domain/reader_comic_ref.dart`：`comicId` / `path` / `resourceType` / `pageCount` / `title`。
- `OpenedReadSession.comic`、`ReadSession.comic`、`ComicPageSourcePort.loadPages`、`NativeReaderPort.openComic` 等改用该类型。
- `open_read_session_service.dart` 仍经既有 baselined public 面取 Comic，随后在 reader 侧映射为 `ReaderComicRef`；**不新增**任何 reader → comic 基线条目。

### 6. 门禁

新增 `app/test/architecture/comic_entity_ownership_test.dart`：

1. `lib/shared/domain/models/entity/comic/comic.dart` 不存在。
2. `shared/**` 不出现 `Comic` 实体类型引用（注释除外，生成文件跳过）。

### 7. 明确不做

- 把 Comic 做成 Dart 事务聚合根，或在 Dart 复刻字段锁合并 / 写集校验。
- `ComicAggregate` 包装类或类名重命名。
- 把跨模块暴露的完整 Comic 收窄为只读投影 record（后续议题，见 ADR-0040）。
- 批量元数据编辑、删除流程、封面编辑的领域化重构。
- Series / Author / AuthorDetail / Tag / 分页值对象 / 枚举的归属调整。
- Rust 侧任何改动。

## Consequences

- `shared/domain` 不再含 Comic 类型；`shared` 的 Comic 相关行为依赖归零。
- Comic 规则（构造、差异、应用）落在 `features/comic/domain/`，可被纯 Dart 单测覆盖。
- `reader` 域类型不再随 Comic 演进被牵连，模块边界只减不增。
- 字段锁渲染仍只读；Rust 保持唯一锁合并真源。
- 旧的 `shared/domain/models/entity/comic/comic.dart` 路径消失；外部引用会编译失败，而不是静默沿用共享 DTO。

## References

- ADR-0002（业务真值在 Rust）、ADR-0026（Library 写接缝）
- ADR-0034（cross-feature 只走 public）、ADR-0035（Catalog Shared Kernel；本 ADR 局部取代其 Comic 结论）
- ADR-0036（Comic / Series 模块切分）、ADR-0040（跨模块只读投影 record）
- [#489](https://github.com/Zoti321/hentail_library/issues/489)
