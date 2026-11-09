# ADR-0034: Cross-feature 协作 — public API only

## Status

Accepted

## Context

Wayfinder 落地后，产品 feature 之间仍采用「零 cross-feature import + `shared/application/ports` + bootstrap override」协作（ADR-0027、import boundary M1）。该模式可行但编排面分散，与 NestJS 式「模块只 export public」心智不一致。

Epic [#425](https://github.com/Zoti321/hentail_library/issues/425) 与 implementation spec **#429–#435 已关闭**（决策 #426–#428）。本 ADR 记录现行 import 规则与 `public/` 物理布局。

### 术语（勿混）

| 术语 | 含义 |
|------|------|
| **Application data** | glossary / ADR-0019：磁盘上的应用数据目录 |
| **Application 层** | ADR-0033：`features/*/application/` 用例编排（无 Flutter） |
| **public API** | 本 ADR：`features/<owner>/public/**` 对外 export 面 |

## Decision

### 1. 唯一合法的 cross-feature import 路径

- 产品 feature A 仅允许 `import` 产品 feature B 的 **`features/<b>/public/**`**（含 `public/ui/`）。
- import **`presentation/`、`data/`、`domain/`、`application/`（非 public）、`di/`（非 public）** 等 deep 路径：仍违规（M1）。
- **bootstrap** 作为组合根，不受 M1 约束（与现 M3 ratchet 并存）。
- **`shared/**` 不得** import 任意 `features/*/public/**`（R11）。契约类型定义在 **`shared/domain`**；`shared/di` 只声明 Provider token。产品 feature 与 bootstrap **消费** owner `public.dart`；实现与 `createXxx()` 工厂在 owner `public/di` 或 `di/`，由 `features/bootstrap/di/overrides/` 注入。

### 2. 与 ADR-0033 Application 层

- Application 层 **L1 规则不变**（R6–R10）：`application` 不触 data/presentation/Flutter/FRB；`domain` 不触 `application`。
- ADR-0033 中「产品 feature 间 import 仍禁止」由本 ADR **取代**：改为 **仅 public 路径允许**；Application 层目录仍 **不是** cross-feature 合法目标（除非经 owner 的 `public/` re-export，由后续 spec 定义 barrel）。

### 3. Riverpod 与 DI

- Consumer 仍 `ref.read` **`shared/di`** 声明的 Provider token（#426）。
- 工厂经 owner **`public/di`** 暴露；bootstrap 在 `features/bootstrap/di/overrides/` 按 owner 拆分 override（#435）。

> **实现修订（2026-11-09）**：`shared/di` 的占位 token 统一用 `app/lib/shared/di/injected_di.dart` 的 `injectedDi` / `injectedFutureDi` / `injectedFutureDiFamily` 声明，保留显式类型标注；不再手写 `throw UnimplementedError`。组合根收敛为 `features/bootstrap/di/bootstrap_overrides.dart` 的 `bootstrapDiOverrides()`（data → shared state → composition），`main.dart` 只调用它。**新增 token 必须补齐 override**，由 `app/test/gate/shared_di_override_coverage_test.dart` 静态校验「`shared/di` 声明 ⊆ 应用内 override」。

### 4. Wayfinder 布局

- `features/<id>/public/` 为 **可选** 顶层 layer，与 `application`、`data` 等并列（`kWayfinderFeatureLayerDirs` 含 `public`）。

### 5. Gate

- **M1**：由「任意 product→product 边均 ratchet」改为「非 public 路径仍记 M1；public 路径不记 M1」。
- **M2**：presentation cross-feature 规则 **不变**。
- **M3**：product→bootstrap **不变**。
- **R11**：`shared` → `features/*/public/**`，L1 零 tolerance。
- **public 依赖环**：仅 public 边构成有向图；**禁止环**（零 tolerance，见 `import_boundary_test`）。

### 6. `public/` 宪章（Spec 2 / #430）

| 路径 | 用途 |
|------|------|
| `features/<id>/public.dart` | **单一 barrel**（推荐）：只 `export` 本 feature `public/` 下符号 |
| `features/<id>/public/*.dart` | Facade、command 接口、无 Flutter 的跨模块契约 |
| `features/<id>/public/ui/` | 含 `BuildContext` 的 UI 命令（不 export View / Notifier） |
| owner `di/` 或 `public/di/` | Provider 工厂；consumer 仍 read **`shared/di` token** |

**L1（R12）**：`public/` 内 **不得** `import` **或** `export` 本 feature `presentation/`（含 `view_models/`、`views/`），除非该源文件列入 Gate allowlist `app/test/gate/public_presentation_export_allowlist.txt`（仅收缩、不扩张；用于既有 `public/ui` 路由页与经评审的 catalog 壳 barrel）。

**Anti-patterns（review 拒收）**

- 在 allowlist 之外于 `public/` `import`/`export` presentation，或新增壳桶 re-export 半棵 presentation 树。
- 在 `public/` 复制 `shared/domain` 实体为第二套 DTO。
- 让 `shared/**` import `features/*/public/`（R11）。
- Consumer deep import `features/<other>/data|application|di/`（M1）。

## Consequences

### Positive

- Cross-feature 边界可扫描、可文档化；与模块 export 心智一致。
- #429–#435 已落地：admin / browse / reader / comic_trash 等 owner `public/` 与 Gate 同步。

> **实现修订（2026-11-02）**：移除 `shared/application/ports/`；UI 命令契约在 `shared/domain/ports/`（如 `AuthorDetailPort`、`LibraryManagementPort`）。跨 feature **import 类型**请用 owner `public.dart`；`shared/di` 仍自 shared 层 import 契约（R11 禁止 shared→feature public）。

> **实现修订（2026-11-02，#436 收尾）**：Repository 与多数 port/库规则类型真源在 owner **`features/<id>/domain/`**；shared 同名路径为 strangler re-export，**禁止**在 `public/` 复制第二套 DTO。仍 @ shared 的 UI 命令与 **Catalog Shared Kernel** 见 **ADR-0035** 与 [`docs/engineering/shared-domain-ownership.md`](../engineering/shared-domain-ownership.md)。L3b baseline 维持零条 `shared/domain`→`features/` 边。

### Negative

- 每个对外能力需维护 public barrel；部分契约真值仍在 shared/domain（UI 命令 + kernel），与 public re-export 需同步 review。

## References

- ADR-0017、ADR-0027、ADR-0033
- #425–#435（epic + implementation spec，已关闭）
- `app/test/gate/import_boundary_rules.dart`、`docs/engineering/gate.md`
- Owner public 示例：`features/library_admin/public.dart`、`library_browse/public.dart`、`reader/public.dart`、`comic_trash/public.dart`
