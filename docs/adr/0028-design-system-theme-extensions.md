# ADR-0028: 设计系统主骨架（ThemeExtension + theme_tailor + Widgetbook）

## Status

Accepted

## Context

应用需要可演进的桌面风格定制 UI，但间距、语义色、阴影与动效 token 分散在主题与组件中；手写 `ThemeExtension` 的 `copyWith` / `lerp` 随字段增多易漏改。产品仍以单壳响应式 shell 为主（见 `design-system/hentai-library/MASTER.md`），不引入整包 M3 UI Kit，也不在阶段一抽取独立 `packages/design_system`（与 #227 一致）。

## Decision

1. **模块边界**（`app/lib/shared/ui/theme/`）：`color/`（M3 `ColorScheme` + `HentaiColorScheme`）、`tokens/`（spacing/radius/typography/layout、shadow、motion）、`extensions/`（`context.tokens` / `shadows` / `motion` / `hentai`）、`theme.dart` 内 `buildAppTheme` 为唯一装配入口。
2. **theme_tailor**：多个 `ThemeExtension`（`AppThemeTokens`、`HentaiColorScheme`、`AppShadowTokens`、`AppMotionTokens`）；生成物 `*.tailor.dart` 提交仓库，由现有 `gate-codegen-drift` / `build_runner` 门禁。
3. **颜色两层**：底层 `ColorScheme`（`app_color_scheme.dart`）+ 语义色 `HentaiColorScheme` 实例挂入 `ThemeData.extensions`；`ColorScheme.hentai` 保留为 `@Deprecated`，新代码用 `context.hentai`。
4. **阴影**：命名预设集中在 `AppShadowTokens`（颜色仍可与语义色同步）；组件逐步改用 `context.shadows`，不要求单次 PR 改完全部 call site。
5. **Widgetbook**：`app/widgetbook/main.dart` 为 dev-only 入口（不在 `lib/` 内，避免生产包依赖 widgetbook），不进 `app/test/gate/manifest.txt`；手动维护目录树（不依赖 Widgetbook 黄金图 CI）。
6. **测试缝**：扩展 `buildAppTheme` 契约测试（extensions 非空、spacing/radius 抽样、语义色关系、shadow/motion 存在）；可选 `lerp` 抽样；不测生成代码行级细节（ADR-0018 快轨）。

## Consequences

### Positive

- Token 与预览基础设施可演进，Agent 与人类共享同一 `buildAppTheme` 缝。
- 与 ADR-0027 shared UI 边界一致，无需独立 design_system 包即可落地。

### Negative

- `build_runner` 全量扫描仍包含 widgetbook_generator（dev）；若构建变慢可后续用 `build.yaml` 收窄。
- 大量历史 `colorScheme.hentai` call site 需分批迁移。

## References

- GitHub #227
- `design-system/hentai-library/MASTER.md`
