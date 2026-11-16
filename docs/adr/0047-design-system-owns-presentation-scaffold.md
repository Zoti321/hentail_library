# ADR-0047: Design System 承接纯外观页级 scaffold

## Status

Accepted（2026-11-12）

## Context

ADR-0044 §1 的判据表把「被 **≥2** 个产品模块消费的复合组件 / 壳层 / **页面级模式**」一律指向 `lib/shared/ui/**`，同时把「业务无关 + 可复用外观」指向 `lib/design-system/**`。两条规则在**页头工具行、Tab 壳、确认框动作行**这类件上同时成立，实际落点靠运气。

后果是可观测的：

- 同一段「返回按钮 + 汉堡菜单 + 标题」在 `home`、`named_metadata`、`reading_history`、`comic_trash` 各手写一遍，图标间距已漂移（4 vs 8）。
- 元数据编辑 Tab 外壳在 `comic` 与 `series` 各 75 行逐字重复。
- `shared/ui` 现有 117 个手写文件中，仅 9 个 import 了 `shared/domain` / `features/` / `shared/di`；其余纯外观件滞留在 shared，ADR-0044 的「design-system」一层长期空转。
- 反向证据也在：`lib/shared/ui/widgets/overlays/dialog/confirm/**` 生产零引用，仅靠自带测试续命——因为没有任何规则要求新确认框复用共享件。

## Decision

### 1. 判据修订：按「是否承载业务」而非「被几个模块消费」

ADR-0044 §1 的第三行收紧为：**只有 import 了领域类型 / Port / owner 专属文案（l10n key 或硬编码业务词）或 owner 布局 token 的复合件，才留在 `shared/ui`。**

纯外观的**页级 scaffold**（不 import 领域层、不 import feature、不消费 feature l10n）一律归 `lib/design-system/**`，无论被 2 个还是 12 个模块消费。典型：页头工具行、Tab 外壳、对话框动作行、弹簧显隐、列表–详情导航项。

`shared/ui` 收敛后的职责只剩两件：

- **App 壳层**（`shell/**`：rail、drawer、侧栏槽）。
- **跨模块复合业务件**（例：`catalog/detail/detail_back_header.dart`，依赖 `AppNavigator` 与 location resolver）。

### 2. Design System 目录补充

沿用 ADR-0044 §2 的「按用途分类」，新增三类落点：

| 用途 | 路径 |
| --- | --- |
| 页级 scaffold（页头工具行、Tab 外壳、对话框动作行） | `lib/design-system/components/scaffold/` |
| 列表–详情导航骨架（导航项、详情切换） | `lib/design-system/components/list_detail/` |
| 锚定菜单原语（`AnchoredMenu` 及选择菜单 helper） | `lib/design-system/components/menu/` |

`design_system.dart` 仍是唯一 barrel；层内仍禁止 export-only shim（ADR-0044 §3）。

### 3. 依赖方向不变，迁移必须自上而下

`design-system` 不得依赖 `shared/ui`（ADR-0044 §2，零 allowlist 门禁）。因此任何迁入 design-system 的 scaffold，其依赖的**原件**必须先迁入：

`page_title`、`page_header_back_button`、`pinned_toolbar_chrome`、`page_header`（`PageHeaderSliver` / `PageHeaderDelegate`）、`library_page_header_metrics`、`pinned_toolbar_chrome_metrics`、`metadata_edit_form_metrics`、`metadata_edit_form_scroll`、`metadata_field_label_row`、`list_detail_nav_item`、`list_detail_detail_transition`、`segmented_capsule_bar`、`anchored_menu`。

迁移纪律沿用 ADR-0044：**只搬 + 改 import + 移测试**，不改行为、不改名（`PageHeaderSliver`、`AnchoredMenu` 等名称保留）。成功判据是 `flutter analyze` 与既有测试全绿。

### 4. 门禁

- `test/design-system/design_system_boundary_test.dart` 仍是零 allowlist；`components/scaffold|list_detail|menu` 与既有 `components/*` 同等对待。
- 新增结构约束：`design-system/components/scaffold/**` 不得出现 `Text(context.l10n.…)` 等业务文案取值——文案一律由调用方以 `String` / `Widget` 注入。该约束由同一 boundary test 内的 import 扫描 + 一条 `rg` 式源码断言覆盖。

### 5. 与既有 ADR 的关系

- **ADR-0044**：本 ADR 修订其 §1 第三行判据，并延长其 P1「归位」的范围到页级 scaffold；其余条款（单 barrel、零 allowlist、`classifyLibPath` 归类）继续有效。
- **ADR-0027**：壳层（Shell）职责不变；本 ADR 只重划 Component 层内部边界。
- **ADR-0036 / ADR-0041 / ADR-0042**：`comic` 与 `series` 的领域层隔离不变；本 ADR 只共享两者的 **presentation scaffold**，不引入泛型 `Entity` 抽象。

## Consequences

- 「新页头 / 新 Tab 壳 / 新确认框」有了唯一落点，不再各写一遍。
- `shared/ui` 从 117 个手写文件降到壳层 + 少量跨模块业务件；`design-system` 从 70 个文件增至约 100 个。
- 迁移期 import 改写量大（约 60 个 importer），但方向单向、可按子票据逐个验收。
- 代价：`design-system` 的「业务无关」纪律需要持续人工把关——一旦有人把带 l10n 取值的组件塞进 `components/scaffold/`，门禁 §4 会失败。

## References

- Epic（本 ADR 配套 spec，DRY 收敛）
- ADR-0044（shared/ui 所有权判据与 Design System 层，Epic #495）
- ADR-0027（Flutter UI 四层）、ADR-0036（comic/series 模块）、ADR-0041、ADR-0042
- `app/test/design-system/design_system_boundary_test.dart`、`app/test/gate/project_layout_test.dart`
