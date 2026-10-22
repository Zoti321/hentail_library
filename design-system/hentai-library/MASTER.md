# Hentai Library · Material 3 设计系统（MASTER）

> 状态：**Figma 建库中**。本文件是设计系统的唯一规划入口；颜色方向 A 已定（亮/暗预览均已建），30 个 Text Style 已建，组件集 / 模板尚未完成。
> 代码未迁移：`app/` 仍是旧 Fluent 取向的主题与页面。设计稿评审通过后才改代码（见 §8）。
> 证据底稿：`design-system/research/material-design-3/`（01 基础、02 组件、03 Flutter 实现、04 Figma 工作流、05 粉色方向）。规范数值若与本文件冲突，先查底稿的证据级别（A 官方规范 / B 官方实现源码 / C 推断）。

## Directory charter

`design-system/` 的职责边界（ADR-0029 修订后仍适用）：

| 路径 | 角色 | 是否规范来源 |
|---|---|---|
| `design-system/hentai-library/MASTER.md` | 设计系统总纲：决策、token、组件清单、Figma 页面图、代码映射 | **是**（语义与用法） |
| `design-system/hentai-library/pages/*.md` | 每条路由的版式与状态说明（待重建） | 是（页面级） |
| `design-system/research/material-design-3/*` | 一手来源调研、取色记录、Figma API 经验 | 否（证据底稿） |
| `app/lib/shared/ui/theme/` | 颜色的**数值真源**；`buildAppTheme` 是唯一装配入口 | 是（数值） |
| `app/lib/shared/ui/layout/` | 断点与壳层布局的代码实现 | 是（布局数值） |

规则：

1. **数值真源在代码**（`theme/`），语义与用法真源在本文件；Figma 是设计与代码之间的镜像，不反过来定义 token 名。
2. 调研目录只回答「官方怎么说」，不作为交付规范；把结论提炼进本文件时必须保留证据级别。
3. `pages/` 不进 Figma 组件库；Screens 页只放带真实内容的实例。
4. 本文件不复制 Figma 变量表之外的派生值；颜色/字阶以 §2/§3 为准。

## 1. 已锁定决策

| # | 决策 | 结论 | 说明 |
|---|---|---|---|
| D1 | 断点 | **M3 五档 600 / 840 / 1200 / 1600** | 设计稿按五档出；代码 `app_layout_breakpoints.dart` 仍是 600/1024，迁移时改 |
| D2 | 字体 | **MiSans**，Regular / Medium / Semibold / Bold | Figma 字族 `MiSans`；style `Semibold` 无空格。应用目前只打包 Regular，迁移时补资产 |
| D3 | 品牌色 | **A · 柔和玫瑰**：`#E91E63` + `tonalSpot` | 46 角色见 §2；B/C 变量与预览保留在 `01 Tokens` 作备选 |
| D4 | 状态反馈 | **恢复 M3 state layer；splash 按平台**：移动端开启，桌面端关闭 | hover 8% / focus 12% / pressed 12% / dragged 16%；桌面用 state layer 代替 splash。细节见 §4.4；代码暂不动 |
| D7 | 首批设计稿 | **主壳 + 首页 + 书库 + 阅读器** | 1440×900 主稿，1024×768 验接缝，600×800 验紧凑；按此顺序评审 |
| D8 | 图标集 | **Material Symbols** | outlined 为默认，selected/激活用 filled；`04 Icons & Assets` 按此建，代码迁移时替换 `lucide_icons_flutter` |
| D5 | Expressive | **排除**（按调研建议；用户未反对） | Flutter 无官方支持（flutter/flutter#168813 仍 Open）；官方 Figma kit 已 Expressive 化，因此自建库 |
| D6 | 建库方式 | **混合**：手工定结构 + figwright 批量写节点 | 结构、命名、页面分工手工决定；重复节点用脚本 |
| — | 交付顺序 | **先 Figma 设计稿，定稿后才改代码** | 用户明确要求；代码迁移不在本轮 |

D1–D8 已全部拍板；设计侧进入组件集与首批页面。代码仍按约定等设计稿定稿后再动。

## 2. 颜色

### 2.1 生成方式

- seed `#E91E63`，scheme variant `tonalSpot`（即 Flutter `ColorScheme.fromSeed` 默认），由 `material_color_utilities 0.11.1` 的 `MaterialDynamicColors` 生成。
- 46 个角色，命名 `color/<camelCaseRole>`；不含 3.22 起弃用的 `background` / `onBackground` / `surfaceVariant`。
- 生成脚本与原始输出：`.scratch/generate_palette.dart`、`.scratch/palette.json`（非交付物，临时文件）。
- Figma 是 Starter 套餐：每个 variable collection 只能 1 个 mode，所以按「一主题一 collection」建了 6 个集合（A/B/C × Light/Dark），每个 46 变量。

### 2.2 正式 token（A · 柔和玫瑰）

| role | Light | Dark | role | Light | Dark |
|---|---|---|---|---|---|
| primary | `#8E4957` | `#FFB2BE` | onPrimary | `#FFFFFF` | `#561D2A` |
| primaryContainer | `#FFD9DE` | `#71333F` | onPrimaryContainer | `#3B0716` | `#FFD9DE` |
| primaryFixed | `#FFD9DE` | `#FFD9DE` | primaryFixedDim | `#FFB2BE` | `#FFB2BE` |
| onPrimaryFixed | `#3B0716` | `#3B0716` | onPrimaryFixedVariant | `#71333F` | `#71333F` |
| secondary | `#75565B` | `#E5BDC2` | onSecondary | `#FFFFFF` | `#43292D` |
| secondaryContainer | `#FFD9DE` | `#5C3F43` | onSecondaryContainer | `#2C1519` | `#FFD9DE` |
| secondaryFixed | `#FFD9DE` | `#FFD9DE` | secondaryFixedDim | `#E5BDC2` | `#E5BDC2` |
| onSecondaryFixed | `#2C1519` | `#2C1519` | onSecondaryFixedVariant | `#5C3F43` | `#5C3F43` |
| tertiary | `#795831` | `#EBBF90` | onTertiary | `#FFFFFF` | `#452B08` |
| tertiaryContainer | `#FFDDBA` | `#5F411C` | onTertiaryContainer | `#2B1700` | `#FFDDBA` |
| tertiaryFixed | `#FFDDBA` | `#FFDDBA` | tertiaryFixedDim | `#EBBF90` | `#EBBF90` |
| onTertiaryFixed | `#2B1700` | `#2B1700` | onTertiaryFixedVariant | `#5F411C` | `#5F411C` |
| error | `#BA1A1A` | `#FFB4AB` | onError | `#FFFFFF` | `#690005` |
| errorContainer | `#FFDAD6` | `#93000A` | onErrorContainer | `#410002` | `#FFDAD6` |
| surface | `#FFF8F7` | `#191112` | onSurface | `#22191A` | `#F0DEE0` |
| surfaceDim | `#E7D6D7` | `#191112` | surfaceBright | `#FFF8F7` | `#413738` |
| surfaceContainerLowest | `#FFFFFF` | `#140C0D` | surfaceContainerLow | `#FFF0F1` | `#22191A` |
| surfaceContainer | `#FBEAEB` | `#261D1E` | surfaceContainerHigh | `#F5E4E5` | `#312829` |
| surfaceContainerHighest | `#F0DEE0` | `#3C3233` | onSurfaceVariant | `#524345` | `#D6C2C3` |
| outline | `#847375` | `#9F8C8E` | outlineVariant | `#D6C2C3` | `#524345` |
| inverseSurface | `#382E2F` | `#F0DEE0` | inverseOnSurface | `#FEEDEE` | `#382E2F` |
| inversePrimary | `#FFB2BE` | `#8E4957` | shadow | `#000000` | `#000000` |
| scrim | `#000000` | `#000000` | surfaceTint | `#8E4957` | `#FFB2BE` |

### 2.3 用法规则

- **primary**：主 CTA、选中态、进度、链接。A 的 primary 偏灰玫瑰，大面积铺底会显脏；大面积品牌区用 `primaryContainer`。
- **surface 家族**：页面底 `surface`；卡片/列表容器按层级用 `surfaceContainerLow` → `surfaceContainer` → `surfaceContainerHigh`；不要再拿 elevation 阴影表达层级。
- **on* 配对**：文字/图标放在同色容器上时用对应 `on*`；不要用纯黑/纯白绕过 token。
- **fixed 角色**：只用于跨主题保持不变的内容（品牌插画、固定徽标）；普通界面不用。
- **surfaceTint = primary**：tonal elevation 只在需要时叠加（0/1/3/6/8/12 → 0/0.05/0.08/0.11/0.12/0.14），默认不叠。

### 2.4 对比度（WCAG，计算值）

| 组合 | A-Light | A-Dark |
|---|---:|---:|
| primary / onPrimary | 6.48 | 7.70 |
| primaryContainer / onPrimaryContainer | 13.22 | 7.22 |
| surface / onSurface | 16.38 | 14.36 |
| surface / onSurfaceVariant | 8.91 | 10.94 |

### 2.5 Figma 落点

- 页面 `01 Tokens`（`9:9`）：6 个 collection `Theme/{A,B,C} · {Light,Dark}`（id 见 `05-color-directions.md` §2）。
- 方向预览：A `10:308`、B `10:357`、C `10:404`，390×844，靠原型 `粉色方案 A/B/C` 切换；A 为起点。
- 暗色预览：`A · 柔和玫瑰 · Dark Preview` `13:578`（y=1020），53 填充 + 2 描边绑定 `Theme/A · Dark`；切换器已隐藏、不参与原型。
- 预览只用于色彩评审，不是首页版式交付。

![A 柔和玫瑰 · 暗色预览](../research/material-design-3/assets/dark-preview.png)

## 3. 排版

### 3.1 字阶（30 个 Text Style，已建）

字重代号：R=Regular 400，M=Medium 500，B=Bold 700。emphasized 与 baseline 同字号/行高，仅字重与少量 tracking 不同。

| token | size / line-height | tracking (base / emph) | baseline | emphasized |
|---|---:|---:|---|---|
| display-large | 57 / 64 | -0.25 / 0 | R | M |
| display-medium | 45 / 52 | 0 / 0 | R | M |
| display-small | 36 / 44 | 0 / 0 | R | M |
| headline-large | 32 / 40 | 0 / 0 | R | M |
| headline-medium | 28 / 36 | 0 / 0 | R | M |
| headline-small | 24 / 32 | 0 / 0 | R | M |
| title-large | 22 / 28 | 0 / 0 | R | M |
| title-medium | 16 / 24 | 0.15 / 0.15 | M | B |
| title-small | 14 / 20 | 0.1 / 0.1 | M | B |
| body-large | 16 / 24 | 0.5 / 0.15 | R | M |
| body-medium | 14 / 20 | 0.25 / 0.25 | R | M |
| body-small | 12 / 16 | 0.4 / 0.4 | R | M |
| label-large | 14 / 20 | 0.1 / 0.1 | M | B |
| label-medium | 12 / 16 | 0.5 / 0.5 | M | B |
| label-small | 11 / 16 | 0.5 / 0.5 | M | B |

- tracking 采用 material-web v0.192 值，与 Flutter `englishLike2021` 对齐；与 Compose tokens 有 3 处冲突（display-large、title-medium、body-medium），已选 web/Flutter 一侧。
- Figma 样式名与 token 同名（`display-large`、`display-large-emphasized`），无分组前缀，便于交接时直接搜 token。
- 样张 frame `10:577`（页面 `02 Styles`）：左 baseline / 右 emphasized，30 行全量对照。

![30 个 M3 Text Style 样张](../research/material-design-3/assets/type-scale.png)

### 3.2 字体映射

| Figma style | FontWeight（Flutter） | 用途 |
|---|---|---|
| Regular | `w400` | display/headline/title-large/body 的 baseline |
| Medium | `w500` | title-medium/small、全部 label、emphasized 的 display/headline/title-large/body |
| Bold | `w700` | emphasized 的 title/label |
| Semibold | `w600` | 当前 30 样式未使用；留给自定义强调（谨慎新增） |

- 应用侧 `app/pubspec.yaml` 目前只有 `assets/fonts/MiSans-Regular.ttf`，迁移时必须补 Medium/Bold 资产并注册 `fontWeight`，否则层级会塌。
- CJK 行高：M3 2026 起会按 script 调整；本项目先按表中固定行高，等官方 Flutter 实现再对齐。

## 4. 形状 / 高度 / 动效（未完成）

| 维度 | 计划 | 状态 |
|---|---|---|
| shape | M3 scale：none 0 / xs 4 / sm 8 / md 12 / lg 16 / xl 28 / full | Figma 变量与代码 `AppRadiusTokens` 待建 |
| elevation | level 0–5，阴影 + 可选 tonal overlay；surface 不再随高度变色 | Figma Effect Styles 待建；代码 `AppShadowTokens` 待替换 |
| motion | duration short/medium/long + standard/emphasized easing；桌面保留 fade-through | Figma Motion 页待建；代码 `AppMotionTokens` 待对齐 |

> 这三项在 `01-foundations.md` 有 B 级数值；建 effect/grid style 时再逐项核实，不在本文件提前写死。

### 4.4 状态反馈与 splash（D4 已定）

| 状态 | state layer 不透明度 | 说明 |
|---|---:|---|
| hover | 8% | 桌面指针悬停；移动端无 |
| focus | 12% | 键盘/焦点环之外的第二层反馈 |
| pressed | 12% | 按下瞬间；与 splash 二选一或叠加，避免双重变暗 |
| dragged | 16% | 拖拽/长按拖动 |

- **移动端（Android / iOS）**：保留平台默认 splash（ink ripple/sparkle）作为按压反馈；state layer 主要用于 selected/focus 等非瞬时态。
- **桌面端（Windows / macOS / Linux）**：关闭 splash（`NoSplash.splashFactory`），hover/pressed 全部由 state layer 提供；否则鼠标点击会出现与桌面习惯不符的扩散动画。
- 组件实现：`ButtonStyle.overlayColor` / `InkWell.hoverColor` / `MaterialStateProperty` 按上表取值；不要在组件里写死颜色，叠 `onSurface` 的 alpha。
- 触达尺寸：视觉高度可以 40，但可点击区不得小于 48×48（桌面与移动一致）。
- 代码落点（迁移时）：`app/lib/shared/ui/theme/theme.dart:62-64` 现在是 `NoSplash` + 透明 highlight + `adaptivePlatformDensity`，要改成**按平台条件**：`splashFactory = 移动端 ? 平台默认 : NoSplash`，并恢复 overlay/hover 的 state layer。**本轮只写文档，不改代码。**

## 5. 布局与断点

| class | 宽度 (dp) | 代表 frame | 壳层 |
|---|---:|---|---|
| compact | < 600 | 390×844 | 底部导航；单列 |
| medium | 600–839 | 800×1280 | 抽屉或 rail（按页面）；两列内容 |
| expanded | 840–1199 | 1024×768 | 常驻 navigation rail；列表-详情可并排 |
| large | 1200–1599 | 1440×900 | rail + 内容最大宽；三列网格 |
| extra-large | ≥ 1600 | 1920×1080 | 同上，内容居中限宽，避免无限拉伸 |

- 接缝测试：599/600、839/840、1199/1200、1599/1600 各出一张对照。
- 断点按**应用可用窗口**判断，不用设备类型。
- 代码现状 `app/lib/shared/ui/layout/app_layout_breakpoints.dart:10,13` 是 600/1024；迁移时改五档。

## 6. Figma 库结构

文件：`Hentai Library UI  (Material Design) v2`（`UI` 与 `(` 之间两个空格）。

| 页面 | id | 内容 | 状态 |
|---|---|---|---|
| 00 Cover · Changelog · Status | `0:1` | 封面、变更记录、建库进度 | 待补 |
| 01 Tokens | `9:9` | 6 个颜色集合、A/B/C 方向预览 | 颜色完成；shape/spacing 变量待建 |
| 02 Styles | `9:10` | 30 Text Style + 样张 | 完成；effect/grid 待建 |
| 03 Foundations | `9:11` | 角色用法、字阶、层级、a11y 规范页 | 待建 |
| 04 Icons & Assets | `9:12` | 图标、插画、占位图 | 待建；D8 已定 Material Symbols（outlined 默认 / filled 选中） |
| 05 Components | `9:13` | 无业务语义的原子组件 | 待建 |
| 06 Patterns | `9:14` | 有业务语义的组合（导航、列表-详情、搜索、阅读器） | 待建 |
| 07 Templates | `9:15` | 五档壳层模板 | 待建 |
| 08 Screens | `9:16` | 带真实内容的页面实例 | 待建 |
| 09 States & Content Lab | `9:17` | loading/empty/error/offline、长文本、CJK、大图 | 待建 |
| 10 Motion | `9:18` | 转场与时长标注 | 待建 |
| 11 Handoff & A11y | `9:19` | token 映射、组件 API、do/don't、覆盖看板 | 待建 |
| 12 Archive & Scratch | `9:20` | 废弃方向、Expressive 实验 | 待建 |

建库顺序：variables → text/effect/grid styles → primitives → patterns → templates × 断点 → screens → states/content → docs。

## 7. 组件清单（规划）

P0 = 首批页面必需；P1 = 第二批。状态均为「待建」。

| 组件 | 优先级 | 关键 variant | Flutter 对照 / 风险 |
|---|---|---|---|
| Icon（Material Symbols） | P0 | outlined / filled × 20 / 24 / 40 | 自托管 SVG 或图标包；迁移时替换 `lucide_icons_flutter`；filled 只用于 selected/激活 |
| Button（filled/tonal/outlined/text/elevated） | P0 | emphasis × size × icon × state | `FilledButton` 等；需统一高度 40、圆角 full |
| Icon Button | P0 | standard/filled/tonal/outlined × toggle | 最小点击区 48 |
| FAB | P0 | size (56/80/96) × color × extended | Flutter 只有 56，80/96 需自绘 |
| Text Field / Search Bar | P0 | filled/outlined × focus/error | 桌面 hover/focus state layer |
| Navigation Bar / Rail | P0 | destinations 3–5 × selected | 大屏 rail 与 bottom bar 的切换策略 |
| List Item | P0 | 1/2/3 line × leading/trailing | 高度 56/72/88；封面图用 2:3 缩略图 |
| Card | P0 | elevated/filled/outlined | 与列表容器区分，不叠阴影 |
| Chip | P0 | assist/filter/input/suggestion | 选中态用 secondaryContainer |
| Dialog | P0 | basic/full-screen × scrollable | 桌面宽度上限 |
| Snackbar | P1 | 1/2 line × action | 桌面位置 |
| Progress / Slider | P1 | linear/circular × determinate | Flutter `year2023` 默认值不等于现行外观 |
| Tabs / Menu / Tooltip / Divider / Badge | P1 | — | Tooltip 桌面最小高 24 |
| Segmented Button | 暂缓 | — | 官方 2025-05 起不再推荐，改用 connected button group |

业务组件（Comic Card、Reader Overlay、Library Grid、History Row、Metadata Panel、Settings Section）放 `06 Patterns`，不混进 `05 Components`。

## 8. 代码映射（迁移前只读）

| 设计侧 | 代码侧（现状） | 迁移动作 |
|---|---|---|
| 颜色 46 角色 | `app/lib/shared/ui/theme/color/app_color_scheme.dart`（26 字段手工枚举，primary `#005FB8`） | 改为 `ColorScheme.fromSeed(seedColor: #E91E63, dynamicSchemeVariant: tonalSpot)` 或直接生成 46 角色；保留 `HentaiColorScheme` 扩展 |
| Text Style 30 | `tokens/app_text_tokens.dart`、`buildAppTheme` 的 `fontFamily: 'MI_Sans_Regular'` | 换 MiSans 四档资产；`TextTheme` 按 §3.1 重建 |
| 断点五档 | `layout/app_layout_breakpoints.dart`（600/1024） | 改 600/840/1200/1600；`isCompact/isMedium/isExpanded` 扩展为五档 |
| shape/elevation/motion | `tokens/app_radius_tokens.dart`、`app_shadow_tokens.dart`、`app_motion_tokens.dart` | 按 Figma 定稿值替换 |
| 组件状态 / splash | `theme.dart:62-64` 现为 NoSplash + transparent highlight + 桌面 compact density | 按 D4：**移动端保留平台 splash，桌面 `NoSplash` + state layer**；恢复 hover 8% / focus 12% / pressed 12% / dragged 16%；触达尺寸不得低于 48 |
| 图标 | `lucide_icons_flutter ^3.1.9`（全库使用） | 换 Material Symbols（outlined 默认 / filled 选中）；先替换导航、播放器、列表动作等 P0 图标 |

已知阻塞：`app/test/project_layout_test.dart:36-54` 仍断言本文件存在且含 `## Directory charter`、`pages/` 目录存在；`pages/` 尚未重建，迁移窗口内该测试会失败，按约定暂不修。

## 9. 未决事项

1. **组件状态矩阵**：每个组件的 hover/focus/pressed/disabled/selected 是否都出 variant，还是只出关键态（建议：P0 组件出默认/hover/pressed/disabled/selected 五态，其余只出默认 + selected）。
2. **effect / grid style 取值**：P0 的 3 个层级与 grid 断点尚未在 Figma 建 style，建时按 `01-foundations.md` 的 B 级数值复核。
3. **图标光学尺寸**：Material Symbols 的 20 / 24 / 40 与 weight/fill 轴需要逐处标注，`04 Icons & Assets` 建页时确定。

## 10. 变更记录

| 变更 | 内容 |
|---|---|
| 设计系统转向 | Fluent 2 → Material 3（baseline，排除 Expressive）；旧 `design-system/hentai-library/` 24 文件已删，历史在 git HEAD |
| 颜色 | A/B/C 粉色在 Figma 预览；选定 A 柔和玫瑰，46 角色写入 §2 |
| 排版 | 30 个 Text Style 建成（Figma `02 Styles`，样张 `10:577`）；MiSans 四档就绪 |
| 暗色 | A 暗色预览 `13:578` 建成，53 填充 + 2 描边重绑到 `Theme/A · Dark` |
| 断点 | 按 M3 官方五档 600/840/1200/1600 出设计稿 |
| D4 状态反馈 | 恢复 M3 state layer；splash 按平台（移动端开启 / 桌面关闭），只入文档，代码未动 |
| D7 首批稿 | 主壳 + 首页 + 书库 + 阅读器；1440×900 主稿、1024×768 接缝、600×800 紧凑 |
| D8 图标 | Material Symbols，outlined 默认 / filled 选中；代码迁移时替换 Lucide |
