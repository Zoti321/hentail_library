# ADR-0037: Tone-based color system 与 M3E roles 为主

## Status

Accepted

## Context

ADR-0028 将颜色定为两层：`ColorScheme` + 大表语义扩展 `HentaiColorScheme`。ADR-0032 要求 Cutover 后 `buildAppTheme` 单源，色值结构仍跟 0028。

生产已切 MD3E design system，但装配默认走 `M3EColorScheme.fromSeed`（底层 tonalSpot），且 `HentaiColorScheme` 为与 seed 无关的固定明暗常量。用户切换固定配色方案时，主色变了，大量壳层表面仍像旧 Baseline 灰蓝。系统动态配色字段存在但未实现。

产品选择 Tone-based color system（HCT tone / tone 差骨架），工程上复用 Material Color Utilities，不自研第二套公式；扩展白名单仅 Reader color extension。

## Decision

1. **色真源**：seed → `ColorScheme.fromSeed(dynamicSchemeVariant: fidelity)`（material_ui）→ `M3EColorScheme.fromColorScheme` → `buildAppTheme` / `M3ETheme`。因 `M3EColorScheme.fromSeed` 不透传 variant，应用侧薄封装是刻意决策。
2. **Variant**：生产固定 **fidelity**（contrast 默认 0），保证九档固定配色「所选即所得」。不在本决策启用 `expressive`（会故意扭开 primary 色相）。
3. **消费**：壳层与共享组件以 M3E / Flutter color roles 为主。禁止新代码依赖大表壳层语义色。
4. **扩展**：仅 **Reader color extension**（恒暗沉浸底，不跟壳层 seed / 应用浅色主题把阅读页变浅）。
5. **动态配色**：`useDynamicColor` 开启时，经 `DynamicColorBuilder` 取系统 `ColorScheme.primary` 作为 seed，再走同一 fidelity 装配；平台无动态色时回退固定配色方案。开启期间设置页禁用「配色方案」项，但保留已选 preference。
6. **品牌 seed**：定稿为配色方案「紫罗兰色」（Kazumi / `0xFF6750A4`，常量 `kBrandSeedColor`）。偏好 id `brand` 与 `violet` 同色、JSON id 仍正交。
7. **相对 ADR-0028**：废弃「大表 `HentaiColorScheme` 作为通用第二层」；保留 ThemeExtension 机制仅用于阅读器等白名单场景。ADR-0032 的单源装配入口不变。

## Consequences

### Positive

- 换配色后壳层表面与 seed 同源，减少双轨色。
- 与 MD3E design system / GLOSSARY（Tone-based color system、Reader color extension）对齐。
- 动态配色与固定配色共用同一 Tone-based 装配路径，仅替换 seed 来源。

### Negative

- 需迁移历史 `context.hentai` 调用并收缩扩展，有一波视觉回归面。
- fidelity 与旧 tonalSpot / 手写语义表观感不同，需按预设 × 明暗目视。
- 薄封装依赖 material_ui API；若上游 `fromSeed` 透传 variant，可再简化但不必阻塞。
- 桌面等无系统动态色的平台开启开关后外观仍跟固定方案，需靠文案说明。

## References

- GitHub #470（及子票 #471–#474）
- ADR-0028、ADR-0032
- GLOSSARY：Tone-based color system、Reader color extension、MD3E design system
