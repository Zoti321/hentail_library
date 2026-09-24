# ADR-0017: Flutter UI 层采用 MVVM（Riverpod）及命名与边界约定

## Status

Accepted

## Context

Flutter UI 已以 Riverpod Notifier/Provider 为主干，但存在以下漂移：

- `view_models/` 与 `state/` 目录并存，职责相同却命名分裂。
- 类名混用 `Notifier`、`Controller`、`ViewModel`（含函数型 provider），阅读器子模块另用 `module/controller/`。
- 部分 `views/` 与 `ui/core/widgets/` 直接 `ref.read(*RepoProvider)`，绕过 ViewModel。
- 库页等复杂屏订阅十余 Provider，View 无统一命令入口；局部采用 Intent→派生列表（类 MVI），与整体 MVVM 表述不一致。

业务逻辑已在 Rust（ADR-0002）；Dart UI 层应聚焦展示、UI 状态与用户命令编排，边界需写清以便 Agent 与人类维护者一致执行。

## Decision

### 1. 主架构：MVVM + Riverpod

- **View**：`ui/features/**/views/`、`ui/core/widgets/` — 渲染与用户手势；通过 `ref.watch` 订阅 ViewModel/Facade；通过 Notifier 方法或 callback 发出命令。
- **ViewModel**：Riverpod `@Riverpod` 类（及聚合型 provider）— 持有 UI 状态、编排 Repository/Service、暴露命令 API。
- **Model**：`domain/models/` + `domain/repositories/` 接口；**Repository 实现**在 `data/repositories/`（FRB 薄层）。

不引入 `package:provider`；状态管理统一 **Riverpod 3**（`flutter_riverpod` / `hooks_riverpod` / `riverpod_annotation`）。代码中的 `Provider` 指 Riverpod 的 provider 类型，不是 legacy Provider 包。

### 2. 复杂屏：内部可保留 Intent→派生，对外必须是 MVVM 门面

库浏览等场景可在 ViewModel 层 **内部** 保留「用户意图状态 + Catalog 派生」链（原 `LibraryQueryIntent` 思路），但 **View 不得** 直接订阅 Intent/Filter/Catalog 全套 Provider 作为常规模式。

- 页面根 Widget 应订阅 **Facade Provider**（如 `libraryPageFacadeProvider`），命令经 Facade Notifier 转发。
- 叶子 Widget 仍可对 Facade 或经 Facade 暴露的 selector 做细粒度 `select`，避免 rebuild 退化。
- 不为了「纯 MVVM」拆除已验证的派生链；MVI 式命名可逐步改为 ViewModel 子状态，非必须一次性删除。

### 3. 命名与目录（分阶段）

**阶段一（优先）**

- 各 feature 下 **`state/` 迁入 `view_models/`**，删除空 `state/` 目录。
- **可变 UI 状态**：类名 `{Noun}Notifier`（如 `SettingsNotifier`），状态类型 `{Noun}State`。
- **只读聚合 / 组合输出**：函数或类 provider，命名 `{noun}ViewModel` → `{noun}ViewModelProvider`（如现有 `readerPageViewModel`）。
- **分页目录与长任务编排**（Library catalog 分页、Library sync、Metadata refresh）：可保留 `{Noun}Controller` 后缀，表示 orchestration/pagination engine，但须位于 `view_models/`。

**阶段二**

- `reader/module/controller/` 迁入 `reader/view_models/`（或保留 `module/` 物理分包但目录名改为 `view_models`），统一 import 路径。

**禁止** 新增 `state/` 目录或 `@ProviderFor` 以外的第二套 presentation 根。

### 4. 硬规则：View 不直连 Repository

- **`views/` 下任何文件** 禁止 import 并调用 `*RepoProvider`（含 `ref.read` / `ref.watch`）。
- **`ui/core/widgets/`** 共享组件禁止持有 Repository；持久化/删除等通过 **构造参数 callback** 或 **由 feature 注入的 Notifier 命令** 完成（与 `comic_delete_flow` 经 Service 的模式一致）。
- Dialog 在 feature 内时可调用 **ViewModel**；在 `ui/core` 时必须 dumb，只触发 `onSave` / `onDelete` 等回调。
- Repository 调用只出现在：`view_models/`、`data/`、`domain/`（接口）、`ui/features/**/di/`（provider 定义）、以及 **非 View 的编排 helper**（如 `*_flow.dart`，且 helper 应优先委托 ViewModel/Service）。

### 5. 交付切片

实现拆为多个 GitHub issue（见父 PRD），按 feature 渐进迁移；每切片保持 CI 绿，避免一次性全库 rename。

## Consequences

### Positive

- UI 边界清晰，View 变薄，测试接缝稳定在 ViewModel（mock Repo override）。
- 与 ADR-0002 分层一致：Rust 业务 + Dart 展示，Repository 仅在 ViewModel 侧出现。
- 库页等复杂屏保留派生性能，同时有 Facade 降低认知负担。

### Negative

- 阶段一 rename/move 产生大量机械 diff，需严格分 PR。
- Facade 过厚时可能成为 God Notifier；须约定 Facade 只做命令转发与聚合 watch，派生逻辑留子 Notifier。
- `ui/core` Dialog 改为 callback 后，call site 略增样板。

## References

- `docs/agents/coding-style.md` — Widget 与 Riverpod 命名（随 ADR 同步补充 ViewModel 规则）
- `docs/agents/testing.md` — ViewModel 层 mock Repo 测试为首选接缝
