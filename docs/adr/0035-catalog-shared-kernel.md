# ADR-0035: Catalog Shared Kernel（`shared/domain` 保留）

## Status

Accepted

## Context

Epic [#436](https://github.com/Zoti321/hentail_library/issues/436) 将各限界上下文的**规则、端口与 Repository 契约**迁入 owner feature（#437–#444 已落地），但下列 **Catalog 相关类型**仍集中在 `shared/domain`，且在多 feature 与 `shared/ui` 中广泛引用：

| 区域 | 典型路径 | 主要消费者 |
|------|----------|------------|
| 实体 DTO | `models/entity/comic/**`（Comic、Series、Author、Tag 等） | library_browse、reader、home、named_metadata、comic_trash、shared/data FRB mapper、`shared/ui` |
| 枚举与展示辅助 | `models/enums.dart` | 库筛选、阅读、UI 组件 |
| 分页值对象 | `models/value_objects/page_request.dart`、`paged_result.dart`、`page_jump.dart` | 各 Repository 契约、FRB 分页 |
| 缩略图 seam | `thumbnail/**` | 封面/缩略图组件、Series cover、FRB 事件 |

Rust `core/` 仍为扫描、sync 与 catalog 谓词真值（ADR-0002）；Dart 侧上述类型主要是 **FRB 映射与 UI 编排用的共享 DTO**，不是单一 feature 私有的富领域模型。

备选方案曾认真权衡：

1. **保留 Shared Kernel @ `shared/domain`**（本 ADR）。
2. **`library_browse` single-owner**：实体迁入 `features/library_browse/domain/`，经 `library_browse/public` 对外；`shared/ui` 与其余 feature 改 import public。  
   - 优点：目录归属与「库页/catalog UX」叙事一致。  
   - 缺点：reader、home、comic_trash、named_metadata、bootstrap、`shared/data` 适配器与 **`shared/ui` 大面积改边**；易触发 ADR-0034「public 第二套 DTO」反模式；与 FRB 映射层分散在 multi-feature data 的现状冲突。

在 #437–#444 已完成的迁移中，**catalog 行为**（筛选 intent、投影、展示标题等）已 owner 化；**内核 DTO 仍留在 shared** 与现行 Gate（R11、L3b、strangler）一致。

## Decision

### 1. 保留 Catalog Shared Kernel 于 `shared/domain`

以下路径 **继续作为 Shared Kernel**，**不**在 Epic #436 后续批次中整体迁入单一 product feature：

- `shared/domain/models/entity/comic/**`
- `shared/domain/models/enums.dart`（及与 catalog 强绑定的 enum 导出面，见 `models/models.dart`）
- `shared/domain/models/value_objects/page_request.dart`、`paged_result.dart`、`page_jump.dart`
- `shared/domain/thumbnail/**`

**Owner 关系（语义，非物理目录）**

| 语义 owner | 已 / 将 位于 feature `domain/` 的内容 | 仍 @ Shared Kernel 的内容 |
|------------|----------------------------------------|---------------------------|
| library_browse | 筛选/排序/投影、`comic_display_title` 等 | Comic/Series 等 **实体 DTO**、分页 VO |
| reader | 阅读域类型、会话端口（ADR-0038；旧 read_session） | 打开阅读时使用的 **Comic** 等映射类型 |
| 其他 feature | 各自 Repository 契约、read model（#443–#444） | 通过 import **`shared/domain`** 引用内核类型 |

### 2. 与 ADR-0034 的关系

- **Cross-feature 协作**仍仅 `features/*/public/**`（M1）；**Shared Kernel 类型不通过 public export**（避免第二套 DTO）。
- Consumer feature **允许** `import package:hentai_library/shared/domain/...` 引用内核实体与 VO。
- **`shared/**` 仍不得** import `features/*/public/**`（R11）；内核定义留在 `shared/domain`，不由 shared re-export 依赖 feature public 真源（与 #437–#444 strangler 方向相反：feature 真源 → shared thin export，**不适用于内核**）。

### 3. 明确拒绝的方案

- 将 Comic/Series 等 **整体**迁入 `library_browse/domain` 并强制其余模块只读 browse public——**本阶段不采用**（成本与 ADR-0034 宪章风险高于收益）。

### 4. 后续迁移触发条件（再开 ADR 或修订本 ADR）

仅当 **至少一条**成立时，才启动「内核迁出 shared」专项（新 Epic / ADR 修订），并单独评估 Gate：

1. **消费者收缩**：除 `library_browse` 外，不再有 product feature 或 `shared/data` 直接依赖 Comic/Series 实体（含 FRB mapper 上移为 browse-owned data）。
2. **`shared/ui` 解耦**：封面/列表/详情组件不再直接依赖 `shared/domain/models/entity/comic`（改由 browse public 或中性 read model）。
3. **Dart 域行为膨胀**：Comic/Series 上需长期维护的 **Dart-only 不变式**明显多于 FRB 映射，且 owner 可单一化为 browse（或独立 `catalog` 包）。
4. **包边界**：Catalog 内核拆为独立 Dart package（非 Wayfinder feature id），由 app 与 features 共同依赖。

未满足上述条件时，**禁止**仅为目录整齐而批量移动内核文件（Epic #446 收尾时亦不得默认迁移内核）。

### 5. Gate 与工程影响

| 机制 | 内核保留 shared 时的预期 |
|------|-------------------------|
| **M1 / public 图** | 内核 import 不计入 product→product 边；cross-feature 仍只走 public |
| **R11** | shared 不 import feature public；内核文件不得 `export` feature domain 真源 |
| **L3b** | `shared/domain` → `features/` import 仍 ratchet；内核迁移前 **不得**新增 shared→feature 耦合（baseline：`shared_domain_feature_import_baseline.json`） |
| **Strangler shims** | 仅适用于 **feature 真源 → shared thin export**（#437–#444）；内核 **不**建立反向 shim |
| **`shared/ui` → features** | 仍遵守 `shared_ui_no_feature_import` allowlist；内核保留 shared 可避免 UI 为 Comic 类型改 import browse public |
| **codegen-drift** | FRB 与 freezed 生成仍针对现有路径；迁内核时需同步 `build_runner` / FRB 与 CI |

### 6. Epic #436 收尾（#446）含义

- #446 的 baseline 更新与 `shared/domain` 体积 ratchet **针对已迁出的 feature 域**，**不包含**本 ADR 列出的内核路径。
- 索引与文档：本 ADR 取代 #436 子票 #445 的开放决策；#446 可在 PR 中引用 ADR-0035 说明内核范围 excluded。

## Consequences

### Positive

- 与 ADR-0002、现 FRB 布局一致；避免 #436 后期对 `shared/ui` 与多 feature data 的爆炸式改 import。
- catalog **行为**已在 feature domain，**数据形状**在 Shared Kernel，职责清晰。
- Gate 规则可预测：内核不动，strangler 列表不无限增长。

### Negative

- `shared/domain` 仍保留较大体积；新贡献者需读 ADR-0035 区分 kernel vs 已迁出的 owner 域。
- 若未来确需 browse-only 富实体，须单独立项并满足 §4 触发条件。

## References

- ADR-0002、ADR-0017、ADR-0027、ADR-0033、ADR-0034
- Epic [#436](https://github.com/Zoti321/hentail_library/issues/436) 及子票 #437–#446
- `docs/engineering/gate.md`（L3b、strangler shims）
- `app/test/gate/import_boundary_rules.dart`、`strangler_shims.txt`
