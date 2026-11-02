# ADR-0034: Cross-feature 协作 — public API only

## Status

Accepted

## Context

Wayfinder 落地后，产品 feature 之间仍采用「零 cross-feature import + `shared/application/ports` + bootstrap override」协作（ADR-0027、import boundary M1）。该模式可行但编排面分散，与 NestJS 式「模块只 export public」心智不一致。

Epic [#425](https://github.com/Zoti321/hentail_library/issues/425) 已闭合 export 边界（#426）、Gate 语义（#427）、Port 迁移波次（#428）。本 ADR 将 **import 规则** 与 **物理 `public/` 目录** 写死，作为后续迁移 spec 的共同前提。

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
- **`shared/**` 不得** import 任意 `features/*/public/**`（R11）；跨模块契约仍经 `shared/domain` / `shared/application/ports` 等，consumer 为 **其他 product feature** 或 **bootstrap**。

### 2. 与 ADR-0033 Application 层

- Application 层 **L1 规则不变**（R6–R10）：`application` 不触 data/presentation/Flutter/FRB；`domain` 不触 `application`。
- ADR-0033 中「产品 feature 间 import 仍禁止」由本 ADR **取代**：改为 **仅 public 路径允许**；Application 层目录仍 **不是** cross-feature 合法目标（除非经 owner 的 `public/` re-export，由后续 spec 定义 barrel）。

### 3. Riverpod 与 DI

- Consumer 仍可 `ref.read` **`shared/di`** 声明的 Provider token（#426）。
- 实现与工厂逐步迁入 owner **`public/di`**；bootstrap override **逐步收缩**（Spec 7 / #435）。

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

**L1（R12）**：`public/` 内 **不得** import 本 feature `presentation/`（含 `view_models/`、`views/`）。

**Anti-patterns（review 拒收）**

- 在 `public/` export presentation 类型或 re-export `presentation/` barrel。
- 在 `public/` 复制 `shared/domain` 实体为第二套 DTO。
- 让 `shared/**` import `features/*/public/`（R11）。
- Consumer deep import `features/<other>/data|application|di/`（M1）。

## Consequences

### Positive

- Cross-feature 边界可扫描、可文档化；与模块 export 心智一致。
- Spec 3–7 可在不 reopen Wayfinder 决策票的前提下迁移 Port。

### Negative

- 每个对外能力需显式 public 面；短期与 shared Port 并存。

## References

- ADR-0017、ADR-0027、ADR-0033
- #425–#428、#429（Gate + ADR 落地）
- `app/test/gate/import_boundary_rules.dart`、`docs/engineering/gate.md`
