# ADR-0032: MD3E Cutover 后 `shared/ui/theme` 只保留一套主题

## Status

Accepted

> **实现修订（2026-11-11，#495 / ADR-0044）**：主题仍单源，仍由 `buildAppTheme` 装配；物理位置从 `shared/ui/theme` 迁到 `design-system/theme`（`lib/design-system/`）。下文 `shared/ui/theme/` 路径按此阅读。

## Context

ADR-0028 将生产主题装配收敛到 `shared/ui/theme/` 的 `buildAppTheme`。MD3E Lab 另有一套 `md3e/theme/`（`M3EThemeData`、`buildMd3eMaterialTheme` 等），目前仅服务 Lab 与 Widgetbook。

按 ADR-0031，各 feature 将逐个切换到 MD3E。若在迁移期间长期保留两套主题（Baseline 与 MD3E），会出现：

- 同一应用内两种颜色与间距体系并存；
- `context.hentai`、`context.tokens` 与 `M3ETheme` 的读取路径混用；
- 收缩双轨时难以判断哪一套为准。

备选方案：

- 保留两套主题，由各 feature 自行选择；
- 以 MD3E 主题为唯一来源，替换 Baseline 主题装配。

前者会使双轨无法收缩；后者是有代价的替换（需要一并迁移 `ColorScheme`、语义色扩展与 token），因此需要单独记录。

## Decision

1. **Cutover 完成后，`shared/ui/theme/` 只保留一套主题**，即由 MD3E 语义映射而来的 `buildAppTheme` 装配。Baseline 主题的 token 与扩展在对应 feature 的 Cutover 完成时一并移除，不长期并存。
2. **迁移期间的过渡方式**：首个需要 MD3E 主题的 feature（即 `app_settings`，见 ADR-0031）可通过 `Md3eThemeScope` 包裹页面局部使用 MD3E 主题，不改变全局 `buildAppTheme`。全局替换在所有 feature 迁完后、shell 迁移时统一完成。
3. **语义色、间距、圆角与动效 token** 的映射关系以代码为准，并在全局替换前补充契约测试，覆盖 `buildAppTheme` 的 extensions 与关键 token。
4. 本 ADR 不规定具体色值；色值与品牌色仍遵循 ADR-0028 的 `ColorScheme` 与 `HentaiColorScheme` 结构。

## Consequences

### Positive

- 迁移完成后，主题只有一个真源，读取路径统一为 `context.tokens` / `context.hentai` 等既有入口。
- 与 ADR-0031 的双轨收缩目标一致。

### Negative

- 全局替换会影响所有页面的视觉基线，需要在 shell 迁移时进行一次集中回归。
- 迁移期间的局部 `Md3eThemeScope` 会暂时形成两套主题同时存在的状态，需要在 Cutover 完成判定中检查清除。

## References

- ADR-0027：Shell / Layout / Component 四层
- ADR-0028：设计系统主骨架（ThemeExtension + theme_tailor）
- ADR-0030：MD3E Lab 冻结 design-system 文档
- ADR-0031：MD3E 生产迁移按 feature Cutover
