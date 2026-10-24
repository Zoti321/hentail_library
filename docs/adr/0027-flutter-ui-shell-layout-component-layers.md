# ADR-0027: Flutter UI Shell / Layout / Component 四层与 shared 依赖边界

## Status

Accepted

## Context

Flutter 侧已有单响应式 App shell、Fluent 风格设计系统（`shared/ui/widgets`）与 MVVM（ADR-0017）。实践中 Shell 编排、Layout 辅助与 feature 侧栏逻辑分散在 bootstrap、shared navigation 与 library_admin；部分 shared 组件反向 import feature（导航表、库排序控件、卡片删除流等），导致设计系统无法独立门禁测试，且 Agent 难以判断新 UI 应落在哪一层。

产品术语在 `GLOSSARY.md` 中区分 **App sidebar**（含 Libraries 分区）与 **Settings list–detail**（非应用侧栏）。ADR-0020 将 Library sync 与库健康收敛到侧栏 Libraries 分区与 **shell 级**调度。

## Decision

### 1. 四层 UI 模型（与 MVVM 并存）

| 层 | 职责 | Riverpod / feature |
|----|------|-------------------|
| **Shell** | 应用外框：标题栏、App sidebar 槽、drawer、路由 body、shell 级全局反馈挂载 | 仅消费 App preference 等经 bootstrap 注入的参数；不 import feature |
| **Layout** | 断点、度量、sliver 数学、**页面模板**（Catalog/Detail 等 slot 组合） | 无业务 ViewModel |
| **Component** | 按钮、表单壳、卡片壳、对话框壳 | 无 feature import；命令经 callback 注入 |
| **Feature composition** | 页面、Libraries 分区、元数据编辑器等 | ViewModel + Repository 编排（ADR-0017） |

MVVM 规则不变：View 不直接调 Repository。Shell/Layout/纯 Component **不应** `ref.watch` feature ViewModel；feature 专用表面留在 feature 或经 Facade/callback 注入。

### 2. 物理目录约定

- **Shell**：`app/lib/shared/ui/shell/`（含 App sidebar 导航展示模型，如 `ShellNavItem`）
- **Layout**（含原 responsive 页面模板）：`app/lib/shared/ui/layout/`；多 feature 共用模板以 `page_`、`catalog_`、`detail_` 等为文件名前缀；仅单页使用的组合块留在对应 feature，避免 `library_` 等领域前缀挂在 shared
- **UI models**：`app/lib/shared/ui/models/` — 组件入参/展示用纯值（封面图源、封面 UI 状态等），**不是** FRB 或 domain 的 DTO
- **Motion（实现）**：`app/lib/shared/ui/motion/` — 路由过渡、reduced-motion 运行时辅助；**时长/曲线 token** 仍在 `shared/ui/theme/tokens`（`AppMotionTokens`、`context.motion`，ADR-0028）
- **Foundation pointer**：`app/lib/shared/ui/widgets/foundation/` — 最小点击区域、tooltip 等待、指针激活后 unfocus 等，**不属于** motion
- **Application UI ports**：`app/lib/shared/application/ports/` — 跨 feature 的 UI 编排契约（可含 `BuildContext`、路由与对话框）；与 `shared/domain/ports`（无 Flutter、对接能力/FRB）区分
- **Component**：`app/lib/shared/ui/widgets/`（按类目）
- **bootstrap**：应用入口、路由表、将 feature 实现注入 Shell 插槽的**组合根**（composition root）
- **Libraries 分区 UI** 留在 **library_admin**（`LibrariesAppSidebar`）；经 `AppShellSidebarSlot` + `AppShellSidebarBuilder` 注入 `ResponsiveAppShell`，不迁入 shared Shell 实现。
- **组合根** 为 bootstrap 的 `ApplicationShell`（非 shared 层类型）。

### 3. 依赖门禁

`shared/ui/widgets`、`shared/ui/layout`、`shared/ui/shell`、`shared/ui/motion` 禁止 import `package:.../features/`。已知违规以 gate allowlist 记录，每张收敛票必须缩小 allowlist（expand-contract）。测试缝与 ADR-0018 gate tier 对齐。

### 4. Settings 与 Reader

Settings list–detail 与 Reader 路由仍隐藏 App sidebar/drawer（现有行为）；不在本 ADR 变更信息架构。

## Consequences

### Positive

- Shell/Layout/Component 边界可文档化、可门禁，利于 Agent 与人类维护。
- Libraries 域 UI 与 `GLOSSARY.md` / ADR-0009、ADR-0020 一致。

### Negative

- bootstrap 组合根略增（`ApplicationShell` + `AppShellSidebarSlot` 显式契约）。
- 卡片、对话框等需逐步改为 callback 或 feature 包装，短期 allowlist 维护成本。

## References

- ADR-0017 — MVVM 与 View/Repository 边界
- ADR-0018 — Gate 测试缝
- ADR-0020 — shell 级调度与侧栏 Libraries
- `design-system/hentai-library/MASTER.md`
