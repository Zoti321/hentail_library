# ADR-0048: `comic_metadata` 模块与 Author / Tag 归属

## Status

Accepted（2026-11-12，#533）

**局部取代**：[ADR-0035](0035-catalog-shared-kernel.md) 把 `Author` / `AuthorDetail` / `Tag` 列为「Catalog Shared Kernel 仍留 shared」的结论。分页 VO、`enums.dart`、`thumbnail/**` 与其余 Port 结论不变。

## Context

`named_metadata` 这个 product module 同时拥有 Author 稳定身份仓储、Tag / Parody / Character 字典、标签字典导入、元数据管理页与 Widgetbook Lab 面；但真正属于该限界上下文的三个实体（`Author`、`AuthorDetail`、`Tag`）仍在 `shared/domain` 的 Catalog Shared Kernel 里。由此产生三个具体问题：

1. **路径表达不了归属**：改一个 Author 字段要动 `shared/`，而 `shared/` 的 diff 天然按「影响全仓」评审（ADR-0045）。
2. **模块名与领域词汇错位**：模块 id 说的是「命名元数据」，实际拥有的是「Comic 元数据字典 + 管理面」。AFK agent 拿到元数据任务无法靠目录定位，只能全仓 grep。
3. **一个只服务三方的字典 token 挤在 shared**：`shared/di/library_dictionary_providers.dart` 的两个 token 只有 `bootstrap` / `library_browse` / `comic_metadata` 消费，但因为放在 shared 而无法随 owner 演进。

ADR-0035 §4 曾给出「内核迁出」的触发条件，其中第 1 条是 **消费者收缩**。本次判定：`Author` / `AuthorDetail` / `Tag` 的直接消费者只剩 `comic_metadata`（owner）、`comic`（Comic 实体与表单）与 `library_browse`（作者详情 / 筛选），且 `shared/di` 里唯一的 shared 消费方是一个待迁走的 token 文件——条件成立。

## Decision

### 1. 模块 id 更名为 `comic_metadata`

`features/named_metadata/` → `features/comic_metadata/`。文件名含旧模块名的 9 个文件改为 `comic_metadata_*`（含 `di/` 与 `public/di/`）。

**不跟随改名的**：

- 领域术语 **Named metadata facet**（GLOSSARY 词条，尚未变化）；
- 类型名 `NamedFacetFormCandidate` / `NamedFacetFormListing` / `NamedFacetDictionaryRepository` / `NamedFacetManagementRepository` / `ManagedNamedFacetKind` 与 `named_facet_*` 文件名；
- 路由 `/metadata`、Tab 段、界面文案、ARB 键；
- Rust `core/` 的 `named_facet` 模块、FRB 生成物与 wire 名。

理由：改名的因果只到「目录与模块 id」。把类型名一起改会把一次结构迁移膨胀为全域重命名，并抹掉 `named_facet` 这一仍在使用的领域词汇；Rust 侧改名只增加 FFI 面风险，与内聚目标无关。

### 2. 三个实体迁入 owner

`Author`、`AuthorDetail`（含 `AuthorLinkPlatform` 与主机名推断函数）、`Tag` 真源迁入 `features/comic_metadata/domain/`，跨模块经 `features/comic_metadata/public/comic_metadata_entities.dart` thin re-export（不复制 DTO）。

`shared/domain/models/entity/comic/` 目录随之清空删除。

### 3. 字典 token 归 owner

`shared/di/library_dictionary_providers.dart` 的两个异步字典 token 迁入 `features/comic_metadata/public/di/comic_metadata_dictionary_state_providers.dart`，文件在 shared 侧删除；`bootstrap` 的 override 改读 owner public token。

### 4. 明确留在原处（非遗留，按 ADR-0044 / ADR-0045 判据）

| 资产 | 判据 |
| --- | --- |
| `AuthorRef` | comic 与 series 双方消费的跨模块引用投影 |
| `AuthorDetailPort` + token | `comic ↛ library_browse` 为禁止边，实现方在 `library_browse`（ADR-0045 可达性豁免） |
| `library_author_pick` / `library_tag_pick` | 库筛选值对象，comic + library_browse 双消费 |
| 拼音辅助名称过滤 | `design-system` 亦消费；迁入 feature 会立刻制造 `design-system → features` 违规 |
| detail metadata chip 行 / chip band 布局 | comic + series 双消费（ADR-0044 ≥2 模块判据） |
| `metadata_edit` 通用 UI（surface / actions / 锁列表 / 锁按钮） | comic + series + library_admin 三家消费 |
| `metadata_backup` 模块 | 导出/恢复 + 自动调度是独立能力，不并入字典管理 |

### 5. 模块边界

新增零容忍显式禁止边（`import` 与 `export` 均算违规，不看是否 public）：

```
comic_metadata ↛ {comic, library_browse, series, reader}
```

允许方向不变：`comic → comic_metadata`、`library_browse → comic_metadata`、`bootstrap → comic_metadata`；既有 `comic_metadata → metadata_backup` 保留（`metadata_backup` 无跨模块 import，不构成 public 环）。

### 6. 门禁

- `test/architecture/module_boundary_test.dart`：禁止边表新增上述四条。
- 新增 `test/architecture/comic_metadata_entity_ownership_test.dart`：三个实体不得回到 shared Kernel 路径；`shared/**`（剔除注释与生成文件）不得出现 `Author` / `AuthorDetail` / `Tag` 全词；旧模块目录与旧 import 前缀不得复活。

## Consequences

### Positive

- 三个实体的定义与实现同址，owner 改自己的模型不再产生 shared diff。
- `shared/domain/models/entity/` 消失，`shared/domain` 只剩分页 VO、`enums.dart`、`thumbnail/**` 与豁免 Port。
- 模块 id 与领域词汇一致，issue 标题可直接映射目录。
- 反向依赖由禁止边与实体归属测试执行，不靠文档约定。

### Negative

- 一次性路径改写量大（约 97 个文件），但全部是 import / 文案与清单同步，无运行时变更。
- `comic_metadata` 的 public 面新增一个实体 barrel；消费方多一跳 re-export。

### Neutral

- 纯结构迁移：不改 DTO 形状、事务边界、字段锁语义、备份文件格式与 Rust wire。
- 成功判据是 `flutter analyze` 零告警 + 既有测试全绿 + 新增架构测试通过，`R13` 与 L3b baseline 仍为空。

## References

- Epic / spec [#533](https://github.com/Zoti321/hentail_library/issues/533)；子票 [#534](https://github.com/Zoti321/hentail_library/issues/534)、[#535](https://github.com/Zoti321/hentail_library/issues/535)、[#536](https://github.com/Zoti321/hentail_library/issues/536)
- ADR-0034（feature public API only）、ADR-0035（Catalog Shared Kernel）、ADR-0036（三模块切分）、ADR-0044（shared/ui 所有权）、ADR-0045（Port 与读模型归属）
- `app/test/architecture/module_boundary_test.dart`、`app/test/architecture/comic_metadata_entity_ownership_test.dart`
