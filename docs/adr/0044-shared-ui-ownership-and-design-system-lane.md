# ADR-0044: shared/ui 所有权判据与 Design System 层

## Status

Accepted

## Context

`app/lib/shared/ui/` 曾同时承担四种互不相同的职责：设计基础（主题、token、动效、布局常量）、通用控件、**单一模块**的业务组件、以及已在 `lib/` / `test/` / `widgetbook/` 无任何符号引用的死代码。

后果具体而稳定：

- 新增「外观通用」控件没有正确落点，只能继续塞进 `shared/ui/widgets/`，shared 持续膨胀。
- 单模块组件在 shared 里无法随 owner 模块演进（改 DTO、改文案 key、改布局常量都要跨目录提交）。
- 死代码让 importer 审计与依赖图阅读失真（例：`ContentBreadcrumbLabels` 已无引用，ADR-0043 仍把它写成路由文案来源）。
- 缺少一层 Design System，使「提升为通用」与「下沉为私有」的讨论没有基准判据。

## Decision

### 1. 三层判据（模块所有权）

| 情形 | 落点 |
| --- | --- |
| 业务无关 + 可复用外观 | `lib/design-system/**` |
| 只被**一个**产品模块消费的业务组件 | `features/<owner>/presentation/**` |
| 被 **≥2** 个产品模块消费的复合组件 / 壳层 / 页面级模式 / 跨模块契约 | `lib/shared/ui/**` |

判据是「**是否 import 了领域类型，或 owner 专属文案 / 布局 token**」：有 → owner feature；无 → design-system。

跨模块需求出现时，从 owner 的 `public/ui/**` 提升，而不是把文件预置在 shared 备用。

### 2. Design System 层定位

- 路径：`app/lib/design-system/`，**单一 barrel** `design_system.dart` 是唯一对外入口。
- 结构：`theme/`、`motion/`、`l10n/`、`layout/`、`components/{inputs,calendar,chips,actions,lists,surfaces}/`、`util/`。按用途分类，不镜像 `shared/ui` 的 `widgets|layout|patterns` 三分法。
- 依赖方向（单向、无环）：

  ```
  features/**  ──▶  shared/ui/**  ──▶  design-system/**  ──▶  core/**  +  shared/util/**
       └──────────────────────────────▶  design-system/**
  ```

- 自洽：`design-system` **不依赖** `shared/ui/**`（拒绝「把 theme 留在 shared/ui 让新层依赖它」的方案——那会让通用控件在依赖图上仍挂在 shared 之下，判据失效）。

### 3. 门禁

- `design-system/**` 在 `classifyLibPath` 中归类为 `shared`，从而**自动继承** R13（不得 import `features/**`）与既有 shared 语义；不新增 product module id。
- `test/design-system/design_system_boundary_test.dart`：本层出边白名单只有 `core/**`、`shared/util/**`、层内路径与第三方包；**零 baseline、零 allowlist**；层内不得出现 export-only shim。
- `project_layout_test.dart`：`design-system/` 进入 Phase A/B 顶层白名单，并受「不得触碰 `*RepoProvider`」约束。

### 4. 与既有 ADR 的关系

- **ADR-0027**（Flutter UI 壳层/组件分层）：`shared/ui` 保留壳层与页面级模式；本 ADR 为其职责再切一刀，新增 Design System 层。
- **ADR-0028 / ADR-0032**（主题单源 + theme extensions）：主题仍是单源、仍由 `buildAppTheme` 装配，仅物理位置从 `shared/ui/theme` 迁到 `design-system/theme`。
- **ADR-0035**（Catalog Shared Kernel）：`shared/domain` 仍留跨模块领域类型；本 ADR 不动领域层（见「后续」P3/P4）。
- **ADR-0043**（导航与路由解耦）：面包屑文案直接取 `AppRoutes.*DetailName`；`ContentBreadcrumbLabels` 被删除。

### 5. 已知缺口

- `core/l10n/app_localizations_x.dart` 自身 import 了 `features/*` 的领域枚举（R13 baseline 既有条目）。`design-system` 依赖 `core/l10n` 因此**间接**触达 features；由后续 P3 拆 `core/l10n` 时消除。

### 6. 后续（本 Epic 明确不做）

- **P3**：`shared/domain` 单归属类型与 Port 迁入 owner（`home_page_counts`、`reading_activity_stats`、`library_scan_mode`、`comic_metadata_bulk_patch*` 等）与随之的 `core/l10n` 解耦。
- **P4**：`shared/di` token 归位（`data_providers.dart`、`library_state_providers.dart` 拆分；`series_*_providers` 按 ADR-0036 禁止边保留 shared）。
- **命名债**（本次保留原名，不重命名）：`named_facet_*` / `FacetMultiSelectField`、`CatalogViewMode`、`LabMotion` / `LabText` / `lab_text`、`list_detail_adaptive_layout`。

## Consequences

- 控件落点从「读全仓依赖」变成「一眼判据」，且新层从第一天起由零例外门禁保护。
- 主题/动效/布局整体搬迁，短期 import 改写量大（theme 34、motion 29、breakpoints 73、l10n 8），但方向单向、可逐票验收。
- `shared/ui` 只剩下真正跨 ≥2 模块的壳层与复合组件，文件数显著下降。
- 迁移票只做「搬 + 改 import + 移测试」，不做重命名与行为变更，因此成功判据是 `flutter analyze` 与既有测试全绿。

## References

- Epic #495（P1 归位 + P2 死代码清理；子票 S0–S6）
- ADR-0027（Flutter UI 分层）、ADR-0028 / ADR-0032（主题单源）、ADR-0033 / ADR-0034 / ADR-0035（feature 层与跨模块契约）、ADR-0036、ADR-0043
- `app/test/design-system/design_system_boundary_test.dart`、`app/test/project_layout_test.dart`、`app/test/gate/`
