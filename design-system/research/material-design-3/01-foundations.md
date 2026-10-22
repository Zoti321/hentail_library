# Material 3 Foundations 与 Token 体系（官方文档调研）

> 用途：为 `design-system/` 以 Material 3 为基准重写 MASTER.md、foundations/*、pages/* 与 Flutter 主题（`app/lib/shared/ui/theme/`）提供可长期引用的一手依据。
> 三类信息在正文中以标记区分：**[规范]** = m3.material.io 设计文档/规格；**[实现]** = Compose Material3 / Flutter Material / material-web 的实际 API、默认值与源码；**[Expressive]** = M3 Expressive（2025-05 起陆续发布，适用范围见各节）。
> 三者冲突时不强行统一，逐条并列记录。

---

## 0 检索说明

### 0.1 抓取通道与失效情况

| 项目 | 情况 |
| --- | --- |
| 可用通道 | 经 modsearch 桥（Firecrawl 渲染抓取）读取 m3.material.io / developer.android.com / api.flutter.dev / raw.githubusercontent.com 的原始文件 |
| m3.material.io 失效页 | 大量页面为 JS 交互式 token module，抓取返回空正文（长度 0 或仅剩标签文字）。已确认失效：`/foundations/interaction/states/state-layers`、`/foundations/interaction/states/applying-states`、`/styles/shape/corner-radius-scale`、`/styles/spacing/tokens`、`/styles/elevation/tokens`、`/styles/motion/easing-and-duration/tokens-specs`、`/styles/motion/overview/specs`、`/styles/color/system/how-the-system-works`、`/styles/color/dynamic/user-generated-source`、`/styles/color/advanced/adjust-existing-colors`、`/styles/color/static`、`/styles/typography/type-scale`、`/foundations/layout/grids-spacing/grids`、`/foundations/layout/grids-spacing/density`、`/foundations/accessibility/designing`、`/styles/icons` |
| 后半段限流 | Firecrawl 返回 429（`retry_after_seconds: 3893`），此后 docs.flutter.dev 全站与 api.flutter.dev 新页面均不可再抓；仅 raw.githubusercontent.com 等静态源可用 |
| 结果 | 凡 JS token module 页给出的数值，改用官方 **实现源码/token 文件**取证（Compose 的 `*Tokens.kt`、material-web 的 `tokens/versions/v0_192/*.scss`、Flutter `lib/src/**`），并在表内注明是规范值还是实现值 |

### 0.2 页面自身显示的版本/更新线索（照抄，未据此推断"当前日期"）

| 来源 | 页面/文件自述 |
| --- | --- |
| material-web token 文件 | 文件头：`Design system display name: Google Material 3`、`Design system version: v0.192`、`Platform: Web`、`Scheme: Dynamic`、`Audience: 3P`（自动生成，禁止手改） |
| material-web 文档 | `docs/theming/{color,typography,shape}.md` 头部带 freshness 元数据：`reviewed: '2026-07-31'` |
| m3 Typography | Updates 区块含 **Aug 2026**（language script height support）、**May 2025**（M3 Expressive emphasized 样式） |
| m3 Shape | What's new 含 **May 2025**（M3 Expressive：35 个新形状 + shape morphing + 新增圆角 token） |
| m3 Color system | What's new 含 **May 2025**（三级对比度）、**Aug 2024**（on-*-container 在 light theme 更彩色）、**Oct 2023**（重组文档） |
| m3 Motion | Overview 标注 **May 2025** 引入 motion physics system，替代 easing/duration 体系 |
| m3 Layout grids & spacing | What's new 含 **May 2026**（grids 与 rulers 指南、Expressive spacing guidelines） |
| developer.android.com | 页脚 `Last updated`：无障碍页 **2026-10-16 UTC**、dynamic colors 页 **2026-10-16 UTC**、window size classes 页 **2026-10-22 UTC**（该页返回的是本地化版本，页脚为葡萄牙语 `Última atualização`，内容与英文页同构） |
| Compose tokens | 每个 token 文件带 `const val VERSION`：PaletteTokens/ColorLightTokens/ColorDarkTokens = `v0_210`；TypeScaleTokens/ElevationTokens/MotionTokens = `v0_103`；ShapeTokens/ShapeKeyTokens = `14_1_0`；ExpressiveMotionTokens/StandardMotionTokens = `v0_14_0` |

### 0.3 本文覆盖与未覆盖面

覆盖：design tokens、color、state layers、typography、shape、elevation、motion、layout & spacing、iconography、accessibility、官方工具。
未覆盖（留给 components / pages 文档）：单组件规格、导航模式细节、Material A-Z 条目、Web/桌面专用组件行为。

---

## 1 Design tokens 架构

### 1.1 三层 token 与命名 **[规范]**

来源：https://m3.material.io/foundations/design-tokens/overview

- token = **名字 + 值**两件套，例：`md.ref.palette.secondary90` = `#E8DEF8`；值可以是颜色、字体、度量，**也可以是另一个 token**。
- 命名按"如何使用/在何处使用"，而非按外观：`md.<class>.<...>`；示例 `md.comp.fab.primary.container.color`（FAB 容器色）。**值变、名称与用途不变**。
- 三类 token：**reference（ref.）** / **system（sys.）** / **component（comp.）**；component 类在该页被标注 **"Component tokens (in development)"**。
- 设计原则：system token 在可能时应**指向 reference token**（而非硬编码值），从而让"高对比色板""TV 专用字号"这类系统性替换一次生效。
- **Contexts**：同一 token 在不同 context 下有不同值，页面列举 light/dark、density、RTL、device 等标签；组件 spec 中的 token 分组顺序是"先 state、再 element"。
- 何时不该用 token（官方原话要点）：既有产品全是硬编码且一两年内不改；产品没有设计系统。

### 1.2 官方 token 资产 **[规范]**

| 资产 | 链接 | 页面标注状态 |
| --- | --- | --- |
| Material baseline theme and tokens（DSP 格式） | https://github.com/material-foundation/material-tokens （别名 goo.gle/material-tokens） | Available |
| M3 Design Kit（Figma） | https://goo.gle/m3-design-kit / https://www.figma.com/community/file/1035203688168086460 | Available |
| Material Theme Builder（Figma plugin） | https://goo.gle/material-theme-builder-figma / https://www.figma.com/community/plugin/1034969338659738588/material-theme-builder | Available |

material-tokens 仓库自述：Material 支持 **DSP（Design System Package）**，用于与 Material Theme Builder 互导 token（README：https://raw.githubusercontent.com/material-foundation/material-tokens/main/README.md）。**未能从官方文档确认**：该仓库当前目录清单与 `md.ref.*`/`md.sys.*` JSON 的实际文件名（GitHub 页面与 API 均抓取失败，见 §13）。

### 1.3 与 Compose / Flutter / material-web 的对应 **[实现]**

| 层 | Compose Material3 | Flutter Material | material-web |
| --- | --- | --- | --- |
| reference | `androidx.compose.material3.tokens.PaletteTokens`（每种 key color 的 tone 常量，如 `Primary40`） | 无公开 ref 层；由 `ColorScheme.fromSeed` 内部的 material_color_utilities 生成 | `--md-ref-palette-*`（`tokens/versions/v0_192/_md-ref-palette.scss`） |
| system | `androidx.compose.material3.ColorScheme`（字段名 = 角色名）+ `*Tokens.kt` 内部常量 | `ColorScheme` 字段（`primary`、`onPrimary`、`surfaceContainerHighest`…）、`TextTheme`、`Shapes` | `--md-sys-color-*`、`--md-sys-typescale-*`、`--md-sys-shape-*`、`--md-sys-elevation-*`、`--md-sys-motion-*`、`--md-sys-state-*` |
| component | `*Defaults` 对象（如 `ButtonDefaults`）+ `tokens/Button*Tokens.kt` | `ButtonTheme`/`*Theme` 与 `*Defaults` | `--md-comp-*-*`（`_md-comp-*.scss`） |
| 命名映射 | `md.sys.color.primary` → `ColorScheme.primary`；`md.sys.shape.corner.medium` → `Shapes.medium`；`md.sys.typescale.body-medium` → `TextTheme.bodyMedium` | 同左（首字母小写驼峰） | `--md-sys-color-primary` 等直接复用 `md.sys.*` 命名 |

实现文档里的 token 用法（material-web `docs/theming/color.md`、`typography.md`、`shape.md`，见 §0.2 的 reviewed 时间）：
- color：`--md-sys-color-<token>`；每个颜色角色都有配对的 `--md-sys-color-on-<token>`；所有 surface 系列 token 的内容色统一用 `on-surface` / `on-surface-variant`。
- typography：`--md-sys-typescale-<scale>-<size>-<property>`，property ∈ {font, size, line-height, weight}；改全站字体优先改 `--md-ref-typeface-brand` / `--md-ref-typeface-plain`。
- shape：`--md-sys-shape-corner-<token>`；文档明确 **"cut" corners are not supported**。

---

## 2 Color

### 2.1 角色清单与 light/dark 映射 **[规范 + 实现]**

m3 角色页：https://m3.material.io/styles/color/roles 。页面首句称 **"26 standard color roles organized into six groups"**（primary / secondary / tertiary / error / surface / outline），但同页图注又称 **"all 45 color roles"**（含 add-on roles）——**官方页面自身口径不一致**，本文按 token 实际条目为准。

下表左侧为角色（`md.sys.color.*`），右侧为 baseline scheme 中指向的 reference tone。实现取证：Compose `tokens/ColorLightTokens.kt` / `ColorDarkTokens.kt`（`androidx-main`，VERSION `v0_210`）与 material-web `tokens/versions/v0_192/_md-sys-color.scss`，两者**完全一致**。

| 角色 | light = ref | dark = ref |
| --- | --- | --- |
| primary | Primary40 | Primary80 |
| on-primary | Primary100 | Primary20 |
| primary-container | Primary90 | Primary30 |
| on-primary-container | Primary10 | Primary90 |
| primary-fixed | Primary90 | Primary90 |
| primary-fixed-dim | Primary80 | Primary80 |
| on-primary-fixed | Primary10 | Primary10 |
| on-primary-fixed-variant | Primary30 | Primary30 |
| inverse-primary | Primary80 | Primary40 |
| secondary | Secondary40 | Secondary80 |
| on-secondary | Secondary100 | Secondary20 |
| secondary-container | Secondary90 | Secondary30 |
| on-secondary-container | Secondary10 | Secondary90 |
| secondary-fixed | Secondary90 | Secondary90 |
| secondary-fixed-dim | Secondary80 | Secondary80 |
| on-secondary-fixed | Secondary10 | Secondary10 |
| on-secondary-fixed-variant | Secondary30 | Secondary30 |
| tertiary | Tertiary40 | Tertiary80 |
| on-tertiary | Tertiary100 | Tertiary20 |
| tertiary-container | Tertiary90 | Tertiary30 |
| on-tertiary-container | Tertiary10 | Tertiary90 |
| tertiary-fixed | Tertiary90 | Tertiary90 |
| tertiary-fixed-dim | Tertiary80 | Tertiary80 |
| on-tertiary-fixed | Tertiary10 | Tertiary10 |
| on-tertiary-fixed-variant | Tertiary30 | Tertiary30 |
| error | Error40 | Error80 |
| on-error | Error100 | Error20 |
| error-container | Error90 | Error30 |
| on-error-container | Error10 | Error90 |
| surface | Neutral98 | Neutral6 |
| surface-dim | Neutral87 | Neutral6 |
| surface-bright | Neutral98 | Neutral24 |
| surface-container-lowest | Neutral100 | Neutral4 |
| surface-container-low | Neutral96 | Neutral10 |
| surface-container | Neutral94 | Neutral12 |
| surface-container-high | Neutral92 | Neutral17 |
| surface-container-highest | Neutral90 | Neutral22 |
| surface-variant | NeutralVariant90 | NeutralVariant30 |
| on-surface | Neutral10 | Neutral90 |
| on-surface-variant | NeutralVariant30 | NeutralVariant80 |
| surface-tint | Primary40 | Primary80 |
| inverse-surface | Neutral20 | Neutral90 |
| inverse-on-surface | Neutral95 | Neutral20 |
| outline | NeutralVariant50 | NeutralVariant60 |
| outline-variant | NeutralVariant80 | NeutralVariant30 |
| scrim | Neutral0 | Neutral0 |
| shadow | Neutral0 | Neutral0 |
| background（旧） | Neutral98 | Neutral6 |
| on-background（旧） | Neutral10 | Neutral90 |

要点（均可在上表与下方来源核对）：
- baseline 的 `surface` 是 **Neutral98 / Neutral6**，不是早期 M3 常见的 Neutral99/Neutral10；dark `surface` 与 `surface-dim` 同值。
- `surface-tint` 恒等于 **Primary 角色**（light=Primary40，dark=Primary80）。
- **fixed 系列的语义**：light/dark 取同一 tone，因此明暗主题下颜色不变；`primary-fixed-dim` 是 fixed 的"暗一档"（tone 80）；配套 `on-*-fixed`（tone 10）与 `on-*-fixed-variant`（tone 30）。
- m3 角色页术语（**[规范]**）：**Container** 角色用于前景填充，**不得承载文字/图标**；**On** 前缀 = 叠在该色之上的文字/图标；**Variant** = 低强调替代。surface 作背景 + surface-container 作导航区是官方推荐的常见组合；组件默认映射例：elevated button/card = surface-container-low，top/bottom bar = surface-container，FAB/basic dialog = surface-container-high，input label/off switch = surface-container-highest。
- outline 用于边界（如 text field outline）；outline-variant 用于 dividers/装饰，**不得单独定义可点击目标的边界**（交互目标边界需 3:1）。官方 Do/Don't 明确：不要用 outline 当 divider/card 边框；不要用 outline-variant 定义可点击目标。
- error 角色默认 **static**：dynamic color 下不随壁纸偏移，仅随明暗主题适配（角色页）。
- light theme 下四个 `on-*-container` 在 **Aug 2024** 被调成更彩色（影响 badge/button/FAB/chip/list/menu/navigation/switch/toolbar）：https://m3.material.io/styles/color/system

### 2.2 Tonal palette（tone 0–100）**[实现]**

baseline 参考值取自 Compose `tokens/PaletteTokens.kt`（VERSION `v0_210`）；键色各取 13 档 tone（0/10/20/30/40/50/60/70/80/90/95/99/100），其中 Primary 的描述性档位如下：

| tone | Primary | Secondary | Tertiary | Error | NeutralVariant |
| --- | --- | --- | --- | --- | --- |
| 10 | #21005D | — | — | — | — |
| 20 | #381E72 | — | — | — | — |
| 30 | #4F378B | — | — | — | #49454F |
| 40 | #6750A4 | #625B71 | #7D5260 | #B3261E | — |
| 50 | #7F67BE | — | — | — | #79747E |
| 60 | #9A82DB | — | — | — | #938F99 |
| 70 | #B69DF8 | — | — | — | — |
| 80 | #D0BCFF | #CCC2DC | #EFB8C8 | #F2B8B5 | #CAC4D0 |
| 90 | #EADDFF | #E8DEF8 | #FFD8E4 | #F9DEDC | #E7E0EC |
| 95 | #F6EDFF | — | — | — | — |
| 99 | #FFFBFE | — | — | — | — |

Neutral 系列（surface 系角色实际取用的档位，8bit RGB）：
| tone | RGB | ≈hex |
| --- | --- | --- |
| 4 | (15,13,19) | #0F0D13 |
| 6 | (20,18,24) | #141218 |
| 12 | (33,31,38) | #211F26 |
| 17 | (43,41,48) | #2B2930 |
| 22 | (54,52,59) | #36343B |
| 24 | (59,56,62) | #3B383E |
| 87 | (222,216,225) | #DED8E1 |
| 92 | (236,230,240) | #ECE6F0 |
| 94 | (243,237,247) | #F3EDF7 |
| 96 | (247,242,250) | #F7F2FA |
| 98 | (254,247,255) | #FEF7FF |
| 100 | 纯白 | #FFFFFF |

**固定映射规则（可直接写成代码生成规则）**：light 主题下 accent 用 tone **40**、container 用 **90**、on-accent 用 **100**、on-container 用 **10**；dark 主题整体倒置（accent **80**、container **30**、on-accent **20**、on-container **90**）。对应表见 §2.1，来源为上述 ColorLight/ColorDarkTokens。

### 2.3 Dynamic color **[规范 + 实现]**

- **[规范]** 官方叙述：dynamic color 属 color system 组成部分（user-generated 壁纸 / content-based 内容），并带 user-controlled contrast；Flutter 的官方实现入口在该页 Resources 表中被列为 **pub.dev/packages/dynamic_color**：https://m3.material.io/styles/color/system
- **[实现]** Android 侧机制（https://developer.android.com/develop/ui/views/theming/dynamic-colors）：Android **12** 起可用；流程 = 从壁纸取 source color → 外推 **5 个 key colors**（primary/secondary/tertiary/neutral/neutral variant）→ 每个 key color 展开为 **13 档 tones** 的 tonal palette → 派生 **5 套 color scheme**。scheme variants：Android 12 仅 Tonal Spot；Android 13 增加 Neutral、Vibrant Tonal、Expressive。widgets 自 Android 12、adaptive icons 自 Android 13 支持；`HarmonizedColors` 用于把自定义色与用户色协调。
- **[实现]** Dart/Flutter 对应：`ColorScheme.fromSeed({required seedColor, Brightness brightness = light, DynamicSchemeVariant dynamicSchemeVariant = tonalSpot, double contrastLevel = 0.0, ...})`（https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html）；`DynamicSchemeVariant` 枚举含 tonalSpot/fidelity/monochrome/neutral/vibrant/expressive/content/rainbow/fruitSalad（https://api.flutter.dev/flutter/material/DynamicSchemeVariant.html）。
- 算法实现：material-color-utilities（C++/Dart/Java/Kotlin/Swift/TypeScript 多语言官方库，https://raw.githubusercontent.com/material-foundation/material-color-utilities/main/README.md ；Dart 包名 `material_color_utilities`）。
- **未能从官方文档确认**：dynamic color 在各平台（尤其 Windows/macOS/Linux 桌面）的可用性矩阵。m3 与 developer.android.com 均以 Android 为叙述主体，未给出逐平台清单；"桌面/Windows 不可用"属工程推断（桌面端无系统级壁纸取色 API，Flutter 侧需 `dynamic_color` 插件提供平台实现），**不应写成规范结论**。

### 2.4 Contrast levels **[规范 + 实现]**

- **[规范]** https://m3.material.io/styles/color/system 的 May 2025 条目："Color roles support three levels of contrast so people can select the one that best suits their vision needs. Contrasts also are tokenized."（standard / medium / high）。
- **[规范]** 角色页明确其归属：**"User-controlled contrast is a dynamic color feature"**——即三级对比度是 dynamic color 能力的一部分，static baseline scheme 不提供 UI 级切换。
- **[实现]** Flutter 用单一数值参数表达：`contrastLevel`：`0.0` 为默认（normal），`-1.0` 最低，`1.0` 最高；文档原文给出 "the medium and high contrast correspond to 0.5 and 1.0 respectively"（同 fromSeed 页）。
- **[实现]** Compose 侧存在 `ContrastLevel` 相关 API（该结论来自实现侧导航，本次抓取未取到 reference 页面原文，见 §13）。

### 2.5 Surface tint 与 tonal elevation：现行规则与三方冲突

| 来源 | 表述 |
| --- | --- |
| **[规范]** m3 Elevation https://m3.material.io/styles/elevation/overview | "Tokens have no shadows or color; each platform determines the specific shadows and values."；默认用 tonal difference 表达层级，而非阴影；surface / surface-container 颜色角色 **"are not tied to elevation"** |
| **[实现]** material-web v0.192 | 保留 `surface-tint` token（= Primary 角色：light Primary40 / dark Primary80），作为可取用的颜色角色存在 |
| **[实现]** Flutter `ElevationOverlay.applySurfaceTint` | 文档原文："With Material Design 3, some components will use a 'surface tint' color overlay with an opacity applied to their base color to indicate they are elevated. The amount of opacity will vary with the elevation as described in: https://m3.material.io/styles/color/the-color-system/color-roles."（https://api.flutter.dev/flutter/material/ElevationOverlay/applySurfaceTint.html） |
| **[实现]** Flutter `packages/flutter/lib/src/material/elevation_overlay.dart` | `_surfaceTintElevationOpacities`：elevation 0→0.0、1→0.05、3→0.08、6→0.11、8→0.12、12→0.14；越界 clamp、中间线性插值；实现为 `Color.alphaBlend(surfaceTint.withOpacity(opacity), color)` |

结论（供本项目采用）：**规范层已放弃"elevation 绑定 surface tint"的强制关系**（surface 角色与 elevation 解耦），但 Flutter 与 material-web 仍保留 surface tint 机制作为可选实现。写文档时应表述为"可选实现路径"，而不是"elevation 必有 tint"。

### 2.6 Light / dark 语义差异

- 不是简单反色：dark 下 accent tone 上移（40→80）、container 下移（90→30），因暗底需要更高亮度才达对比度（§2.1 表）。
- `surface-dim` / `surface-bright` 保持**相对亮度**而不随主题反转：dark 下 `surface-dim` = Neutral6（与 surface 同）、`surface-bright` = Neutral24（更亮）；light 下 `surface-dim` = Neutral87、`surface-bright` = Neutral98（角色页 add-on roles 段）。
- `inverse-surface` / `inverse-on-surface` / `inverse-primary` 用于 snackbar 等"反色层"，两主题均指向对侧的 tone。

---

## 3 State layers

规范页（`/foundations/interaction/states`）给出**六态**：enabled、disabled、hover、focused、pressed、dragged；要点是"States have two visual indicators to ensure accessibility"、状态可组合（如 selected+hover）、跨组件一致。**但具体 opacity 只存在于实现 token 中**（state-layers / applying-states 子页为 JS module，抓取为空，见 §0.1）。

| 状态 | material-web v0.192（`tokens/versions/v0_192/_md-sys-state.scss`） | 备注 |
| --- | --- | --- |
| hover | 0.08 | `hover-state-layer-opacity` |
| focus | 0.12 | `focus-state-layer-opacity` |
| pressed | 0.12 | `pressed-state-layer-opacity` |
| dragged | 0.16 | `dragged-state-layer-opacity` |
| disabled | **token 文件中不存在** | 官方 state token 集未给 disabled opacity；disabled 的视觉处理在组件层实现 |
| disabled content | **未能从官方文档确认** | 常见 0.38 说法未能在本次抓取到的官方源码/文档中核实 |

冲突与缺口（必须记录）：
- Compose 侧常量未能取证：`compose/material3/.../{StateLayer.kt, internal/StateLayer.kt, internal/InteractiveComponentSize.kt}` 三次尝试均 404（文件路径或已重构），因此**无法给出 Compose 的 state layer 数值**。
- 因此 §3 的数值只能标为 **[实现] material-web**，不能标为 **[规范]**。

---

## 4 Typography

### 4.1 体系 **[规范]**

https://m3.material.io/styles/typography ：
- **30 个 type style**：15 baseline + 15 emphasized（May 2025 起）；五类角色 Display / Headline / Title / Body / Label × small/medium/large。
- "Use variable fonts for more control over expression in editorial treatments"；"Use Material tokens to easily define font, line height, size, tracking, weight"。
- **Roboto Flex**：可用于表达情绪区间，但官方明确 **"is not yet part of the M3 typescale"**。Google Sans Flex 有六条可变轴（Google Design 文章）。
- **Aug 2026**：type scale 按语言 script height 类别（small / medium / large / extra large）自动调整 line height，组件据此调整尺寸。
- Availability 表：Design Kit / Google Fonts Available；Flutter Available（链接指 `Typography.material2021`）、Jetpack Compose Available、Compose Expressive Available、MDC-Android Available、MDC-Android Expressive Available、Web Available、**Web Expressive Unavailable**。

### 4.2 15 个 baseline 样式：两套官方数值并列

| 样式 | size | line-height | tracking（Compose） | tracking（web v0.192） | weight |
| --- | --- | --- | --- | --- | --- |
| display-large | 57 | 64 | -0.2 | **-0.25** | Regular |
| display-medium | 45 | 52 | 0 | 0 | Regular |
| display-small | 36 | 44 | 0 | 0 | Regular |
| headline-large | 32 | 40 | 0 | 0 | Regular |
| headline-medium | 28 | 36 | 0 | 0 | （web 文件未解析出，Compose 为 Regular） |
| headline-small | 24 | 32 | 0 | 0 | Regular |
| title-large | 22 | 28 | 0 | 0 | Regular |
| title-medium | 16 | 24 | 0.2 | **0.15** | Medium |
| title-small | 14 | 20 | 0.1 | 0.1 | Medium |
| body-large | 16 | 24 | 0.5 | 0.5 | Regular |
| body-medium | 14 | 20 | 0.2 | **0.25** | Regular |
| body-small | 12 | 16 | 0.4 | 0.4 | Regular |
| label-large | 14 | 20 | 0.1 | 0.1 | Medium |
| label-medium | 12 | 16 | 0.5 | 0.5 | Medium |
| label-small | 11 | 16 | 0.5 | 0.5 | Medium |

- Compose 来源：`compose/material3/.../tokens/TypeScaleTokens.kt`（VERSION `v0_103`），单位 sp。
- Web 来源：`tokens/versions/v0_192/_md-sys-typescale.scss`（rem→px 按 16px/rem 换算）。
- **三方冲突点：三处 tracking**（display-large −0.2 vs −0.25；title-medium 0.2 vs 0.15；body-medium 0.2 vs 0.25）。规范页的数值表（`/styles/typography/type-scale`）为 JS module，抓取为空，**无法判定谁与规范一致**。
- 字族分工：Compose `TypefaceTokens` 中 `Brand` 用于 Display*/Headline*/TitleLarge，`Plain` 用于其余；两者在 Compose 里都映射 `FontFamily.SansSerif`（即不绑定字体文件，交给系统）。material-web 文档则要求"若不改字族，必须自行加载默认 **Roboto**"，并明确每套字体需 normal/medium/bold 三档（400/500/700）。

### 4.3 Emphasized 15 样式 **[Expressive / 实现先行]**

Compose `TypeScaleTokens.kt` 已含 15 个 `*Emphasized` 样式，文件内注释写 **"TODO update with the generated tokens once available"** → 可实现但规范未定稿。特点：字号/行高/字距基本等同 baseline，**weight 提升**（Title/Body/Label 多为 Medium~Bold，label 系列为 Bold），tracking 普遍收窄：

| 样式 | size/line-height | tracking | weight |
| --- | --- | --- | --- |
| display-large-emphasized / display-medium / display-small | 同 baseline | 0 | Medium |
| headline-large/medium/small-emphasized | 同 baseline | 0 | Medium |
| title-large-emphasized | 22/28 | 0 | Medium |
| title-medium-emphasized | 16/24 | 0.15 | Bold |
| title-small-emphasized | 14/20 | 0.1 | Bold |
| body-large-emphasized | 16/24 | 0.15 | Medium |
| body-medium-emphasized | 14/20 | 0.25 | Medium |
| body-small-emphasized | 12/16 | 0.4 | Medium |
| label-large-emphasized | 14/20 | 0.1 | Bold |
| label-medium-emphasized | 12/16 | 0.5 | Bold |
| label-small-emphasized | 11/16 | 0.5 | Bold |

token 命名（规范页）：`display-large-emphasized` 形式，即在 baseline token 名后加 `-emphasized`。

### 4.4 Flutter 实现 **[实现]**

- `Typography.material2021` 是 M3 类型系统入口；`englishLike2021` 常量文档原文："The font sizes, weights, and letter spacings in this version match the 2021 Material Design 3 specification."（https://api.flutter.dev/flutter/material/Typography/englishLike2021-constant.html）
- `Typography.material2021` 工厂按平台选择 `black`/`white` 文本主题（iOS/macOS=Cupertino，android/fuchsia=MountainView，windows=Redmond，macOS=RedwoodCity，linux=Helsinki），并内置 `englishLike`/`dense`/`tall` 三套脚本变体（dense/tall 对应不同语言的字形高度）。
- **未能取得 Flutter 逐样式的具体数值**：`packages/flutter/lib/src/material/typography.dart` 中 `_M3Typography` 的数值位于文件尾部，抓取在 50000 字符被截断（见 §13）。

---

## 5 Shape

### 5.1 圆角 scale：两套官方数值 **[规范 + 实现]**

| 名称 | Compose `ShapeTokens.kt`（VERSION `14_1_0`） | material-web v0.192 `_md-sys-shape.scss` | m3 Expressive 新增 **[Expressive]** |
| --- | --- | --- | --- |
| none | 0dp（RectangleShape） | 0px | — |
| extra-small | 4dp | 4px | — |
| small | 8dp | 8px | — |
| medium | 12dp | 12px | — |
| large | 16dp | 16px | — |
| large increased | **20dp** | 无（v0.192 未含） | 新增 |
| extra-large | 28dp | 28px | — |
| extra large increased | **32dp** | 无 | 新增 |
| extra extra large | **48dp** | 无 | 新增 |
| full | `CircleShape` | `9999px` | 定义改为 **full**（不再用"组件尺寸的 50%"） |

方向性变体（Compose `ShapeKeyTokens`）：`corner-extra-small-top` 4/4/0/0、`corner-large-top` 16/16/0/0、`corner-large-start` 16/0/0/16、`corner-large-end` 0/16/16/0、`corner-extra-large-top` 28/28/0/0；web 侧对应 `corner-*-top/start/end` 元组值。

m3 Shape 页 **May 2025** 更新要点（https://m3.material.io/styles/shape）：
- 新增 **35 个形状** 与 **shape morphing** 到 Material Shape Library（Figma Design Kit）与 Jetpack Compose `MaterialShapes`；
- 新增圆角 token：**Large increased 20dp、Extra large increased 32dp、Extra extra large 48dp**；
- **"Updated fully rounded corners to use `full`. Previously, this was defined using 50% of the component size."**
- 设计原则：shape is versatile not semantic（不按语义指定形状）；abstract shapes 少用；shape can be 2.5D；用 tension（方圆对比）建立层级。

对照 m2 到 m3 的直接差异：web 文档明确 **"cut" corners are not supported**（不支持切角，只有圆角）。

### 5.2 Shape morph **[Expressive]**

https://m3.material.io/styles/shape/shape-morph ：
- morph 目前只落在 **标准 button group** 与 **loading indicator** 等组件；
- 默认使用 **expressive motion scheme**（可切换到 standard）；
- 平台支持：Android = Compose `MaterialShapes`；**"Web is not currently available"**；Flutter 未被该页列出（→ 本项目在 Flutter 上做 morph 无官方依据，只能自行实现路径插值）。

---

## 6 Elevation

### 6.1 六个 level 与数值

| Level | material-web v0.192 `_md-sys-elevation.scss` | Compose `ElevationTokens.kt`（`v0_103`） |
| --- | --- | --- |
| level0 | 0 | 0dp |
| level1 | 1 | 1dp |
| level2 | 3 | 3dp |
| level3 | 6 | 6dp |
| level4 | 8 | 8dp |
| level5 | 12 | 12dp |

两边完全一致（**这是少数规范值可直接当实现默认值的项**）。

### 6.2 使用规则 **[规范]**

https://m3.material.io/styles/elevation/overview 与 `/styles/elevation/applying-elevation`：
- 层级写作 level0 / +1 … +5；**resting elevation 只允许 0 ~ +3**，**+4 / +5 保留给 hover、dragged 等交互态**。
- 默认**不用阴影**表达层级，而用 tonal difference（surface / surface-container 角色差）；"Tokens have no shadows or color; each platform determines the specific shadows and values."
- **M2 → M3 差异**：不再给所有层级默认加阴影；引入新颜色映射与 dynamic color；用 level 语言替代 dp 阴影表。
- surface / surface-container 角色 **"are not tied to elevation"**；但重叠区域应取**不同的** surface 角色。
- scrim 使用 `scrim` 角色，**opacity 32%**。
- 交互态规则：FAB hover 时 level 3 → 4；所有 Material button hover 升 1 级；**不要改组件默认 elevation**。

---

## 7 Motion

### 7.1 体系切换（2025-05 起）**[Expressive]**

https://m3.material.io/styles/motion/overview ：
- May 2025 引入 **motion physics system**（弹簧），并明确 **"is replacing the previous system based on easing and duration"**。
- 两套 preset scheme：**expressive**（有 overshoot/bounce，用于多数场景与关键交互）与 **standard**（几乎不回弹，用于功利型场景）。
- spring 三属性：**stiffness**（越高收敛越快）、**damping**（越高越快消抖；**damping = 1 完全消除回弹**）、initial velocity。
- spring token 分两组：**spatial**（位移/旋转/尺寸/圆角，会 overshoot）与 **effects**（color/opacity，不 overshoot）；各三速 fast / default / slow；命名例 `md.sys.motion.spring.fast.spatial`；scheme 在产品层选择，不写进 token。
- Availability：MDC-Android Available（**尚未加到组件**）、**Flutter Unavailable**、Jetpack Compose Available（`MotionScheme`）、Web "Compatible with Compose springs"；Compose 上 **21 个 Material 组件默认使用 motion physics**。
- easing/duration 页明确：Expressive 更新后该体系 **"is no longer maintained"**，但仍用于 transitions。

### 7.2 Duration tokens（两实现同值）**[实现]**

| 组 | 值（ms） |
| --- | --- |
| short1–4 | 50 / 100 / 150 / 200 |
| medium1–4 | 250 / 300 / 350 / 400 |
| long1–4 | 450 / 500 / 550 / 600 |
| extra-long1–4 | 700 / 800 / 900 / 1000 |

来源：material-web `_md-sys-motion.scss`（`duration-short1` 等）与 Compose `MotionTokens.kt`（`Short1`…`ExtraLong4`），数值完全相同。

### 7.3 Easing tokens（两实现同值）**[实现]**

| token | cubic-bezier |
| --- | --- |
| standard | 0.2, 0, 0, 1 |
| standard-accelerate | 0.3, 0, 1, 1 |
| standard-decelerate | 0, 0, 0, 1 |
| emphasized | 0.2, 0, 0, 1 |
| emphasized-accelerate | 0.3, 0, 0.8, 0.15 |
| emphasized-decelerate | 0.05, 0.7, 0.1, 1 |
| legacy | 0.4, 0, 0.2, 1 |
| legacy-accelerate | 0.4, 0, 1, 1 |
| legacy-decelerate | 0, 0, 0.2, 1 |
| linear | 0, 0, 1, 1 |

注意：**standard 与 emphasized 的主曲线在这两套官方实现中同值**（0.2, 0, 0, 1）；差异只体现在 accelerate/decelerate 分支。material-web 的 motion token 文件里还有一条 `'path': null`（motion_path 类型未支持）。

### 7.4 推荐 duration/easing 配对 **[规范]**

https://m3.material.io/styles/motion/easing-and-duration ：

| 场景 | 推荐 |
| --- | --- |
| 起止都在屏内 | Emphasized 500ms |
| 进入（enter） | Emphasized decelerate 400ms |
| 退出（exit） | Emphasized accelerate 200ms |
| 通用 | Standard 300ms（iOS/Web 等不支持 Emphasized 的平台用 Standard 兜底） |
| 进入（Standard） | Standard decelerate 250ms |
| 退出（Standard） | Standard accelerate 200ms |

其他要点：exit 短于 enter；M3 相比 M2 easing 更 expressive、duration 略长；Emphasized 为默认推荐。

### 7.5 Spring tokens：数值 **[实现]**

Compose：`tokens/ExpressiveMotionTokens.kt` 与 `tokens/StandardMotionTokens.kt`（各 VERSION `v0_14_0`），全量 `spring(dampingRatio, stiffness)`：

| token | Expressive damping / stiffness | Standard damping / stiffness |
| --- | --- | --- |
| default spatial | 0.8 / 380 | 0.9 / 700 |
| fast spatial | 0.6 / 800 | 0.9 / 1400 |
| slow spatial | 0.8 / 200 | 0.9 / 300 |
| default effects | 1.0 / 1600 | 1.0 / 1600 |
| fast effects | 1.0 / 3800 | 1.0 / 3800 |
| slow effects | 1.0 / 800 | 1.0 / 800 |

规律（可直接用于文档表述）：**effects 组两个 scheme 完全相同且 damping 恒 1.0**（不允许 overshoot）；**expressive 的 spatial 用 0.6/0.8 制造回弹，standard 的 spatial 恒 0.9**（几乎不回弹）。`MotionScheme.kt` 暴露 `standard()`/`expressive()` 两个 `MotionScheme`，各含上述六个 spec，并提供 `MotionScheme.fromToken(MotionSchemeToken)`。

- material-web v0.192 **没有 spring token**（只有 duration + easing）→ 印证 §7.1 的 "Flutter/Web 侧 spring 尚未落地"。

### 7.6 Reduce motion **[实现]**

Flutter：`MediaQueryData.disableAnimations`（https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html）原文要点：
- "Whether the platform is requesting that animations be disabled or reduced as much as possible."
- 对应 **Android 的 "Remove animations" 无障碍设置**；**iOS 的 reduced motion 通过 `dart:ui.AccessibilityFeatures.reduceMotion` 暴露，不设置该 flag**。
- 值直接来自引擎 `SemanticsBinding.disableAnimations`，被 `AnimationController` 等框架级 API 使用，**且不能通过 MediaQuery 覆盖**。

**[规范]** m3 侧 reduce motion 的正式要求页（`/foundations/accessibility/*`、motion 的 accessibility 段）本次抓取均为空，**未能从官方文档确认** M3 对 reduced motion 的具体规定。

---

## 8 Layout & spacing

### 8.1 8dp 基线与 spacing 体系 **[规范]**

https://m3.material.io/styles/spacing ：
- 原话："The spacing system is measured on an **8dp scale**, where **space100 = 8dp**"。系统只定义推荐档位，scale 可扩展。
- 页面示例档位（按 space 命名）：2 / 4 / 6 / 8 / … / 48 / 56 / 64 / 72。
- 三类 spacing：**padding**（内边距）、**gap**（元素之间）、**margins**（外边距）；方位分 vertical / top / bottom / horizontal / leading / trailing（**RTL 时 leading/trailing 互换**）。
- 布局级用 **panes + spacers（含 drag handle）+ margins** 组织。
- 示例数值：search 容器 **8dp 垂直 padding、8dp 水平 gap、24dp 水平 margin（focused 时 12dp）**。
- Availability 表：MDC-Android **Unavailable**、Jetpack Compose **Available**、Web **Unavailable**（spacing 尚无跨平台官方实现）。
- `/styles/spacing/tokens` 页为 JS module，只能取到枚举名（Space0/25/50/…/900），**dp 值未能从官方文档确认**。

https://m3.material.io/foundations/layout/grids-spacing ：grid 提供一致基础并随 breakpoint 适配；spacing 分组信息并引导注意力；density 让数据密集视图显示更多信息。Resources 表列 Jetpack Compose **Rulers**（https://developer.android.com/reference/kotlin/androidx/compose/ui/layout/Ruler）为 Available。页面 What's new 含 **May 2026** 条目（grids/rulers 指南、Expressive spacing guidelines）。

### 8.2 Breakpoints / window size classes

| 来源 | 断点定义 |
| --- | --- |
| **[规范]** m3 Breakpoints（https://m3.material.io/foundations/layout/breakpoints） | Compact <600dp；Medium 600–839dp；Expanded 840–1199dp；Large 1200–1599dp；Extra-large 1600dp+ |
| **[实现]** developer.android.com window size classes（https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes） | 宽度：Compact <600dp；Medium 600≤w<840；Expanded 840≤w<1200；Large 1200≤w<1600；Extra-large ≥1600。高度（仅 Android）：Compact h<480dp；Medium 480≤h<900；Expanded h≥900 |
| 旧 material.io 断点 | 600 / 905 / 1240 / 1440（**与现行不同**） |

差异与要点：
- m3 已把 "window size class" 改称 **breakpoint**，定义原文："Breakpoints are opinionated window sizes where a layout changes"；明确 **"These apply to Android and web."**
- 高度断点**只在 Android 文档**给出，m3 解释是多数布局纵向滚动，很少需要按高度调整。
- 官方强调 window size class **由应用可用窗口决定，不是设备屏幕尺寸**；原文 "explicitly not determined by the size of the device screen … not intended for isTablet-type logic"。窗口可因分屏/多窗口任意变小，因此不能写 `isTablet` 式逻辑。
- 布局随窗口增长的路径：单 pane → 双 pane → 三 pane；跨断点决策四式：reveal / divide / resize / reposition / swap。

### 8.3 Canonical layouts 与 density

- m3 导航中确有 `Layout → Canonical examples`（list-detail、supporting pane、feed 等），但**该页与 `/foundations/layout/grids-spacing/{grids,density}` 本次抓取为空**，因此 canonical layouts 的具体 pane 宽度/边距数值、density 的档位定义 **未能从官方文档确认**（见 §13）。
- Flutter 侧的对应实现是 `VisualDensity`（本仓库 `buildAppTheme` 已使用 `VisualDensity.adaptivePlatformDensity`，见 §12），但**Flutter 的 VisualDensity 与 M3 density 指南不是同一体系**，不可互相当作规范。

---

## 9 Iconography

### 9.1 Material Symbols **[规范/官方资源]**

https://developers.google.com/fonts/docs/material_symbols ：
- "over 2,500 glyphs in a single font file"；**three styles** 与 **four adjustable variable font axes**：**fill、weight、grade、optical size**。
- 轴取值：**FILL** 0/1；**wght** 100（thin）–700（bold）；**GRAD** 可正可负（官方示例 low emphasis −25、high emphasis 200），比 weight 更细粒度且对尺寸影响小；**opsz** 范围 **20dp–48dp**，随字号自动调整 stroke weight。
- 许可 **Apache License 2.0**；git 仓库 **github.com/google/material-design-icons**。

### 9.2 推荐尺寸与旧 Material Icons 差异

- **推荐尺寸 20dp / 24dp 未能从官方文档确认**：m3 `/styles/icons`（含 overview 变体）本次抓取返回空正文，无法取得"recommended 20dp/24dp"的原文。
- **[实现]** Flutter 的图标默认尺寸为 **24**：`packages/flutter/lib/src/widgets/icon.dart` 中 `final double tentativeIconSize = size ?? iconTheme.size ?? kDefaultFontSize;`，其类文档示例写 `size: 24.0`；图标尺寸还会在 `applyTextScaling` 为真时经 `MediaQuery.textScalerOf(context).scale(...)` 缩放（见 §10）。
- 与旧 Material Icons 的差异（可变字体轴、单一字体文件承载多风格）以 §9.1 为准；**"旧 Icons 为 5 个静态字族/two-tone 等"的说法本次未取得官方页面佐证**，不写入结论。

---

## 10 Accessibility

### 10.1 触控目标与对比度 **[规范/官方]**

https://developer.android.com/guide/topics/ui/accessibility/apps （页脚 Last updated 2026-10-16 UTC）：
- 触控目标：**48dp × 48dp**，原文 "48dpx48dp. Larger is even better."；并注明**精确输入（鼠标、触控板）可小于 48dp**。
- 对比度原文："If the text is smaller than 18sp, or if the text is bold and smaller than 14sp, use … at least **4.5:1**. For all other text, … at least **3:1**."（即正文 4.5:1；≥18sp 或 bold ≥14sp 可 3:1）
- 组件级：Compose 的 Button/IconButton/ListItem 已内置最小尺寸；自定义交互元素需自行约束到 48dp。

### 10.2 字体缩放、focus、semantics

- **[实现]** 字体缩放：Flutter 通过 `MediaQuery.textScalerOf` 提供缩放；图标在 `applyTextScaling` 开启时随文字缩放（`icon.dart` 第 271 行）。
- **[实现]** reduce motion：见 §7.6（`MediaQueryData.disableAnimations`，Android "Remove animations"；iOS 走 `AccessibilityFeatures.reduceMotion`）。
- **[规范]** m3 的 `Accessibility → Designing / Building for all` 等页面这次全部抓取为空，**focus 可见性、semantics 的具体官方条款未能从官方文档确认**；可确认的间接约束是 m3 States 页的 "two visual indicators"（颜色 + 形状/其他非颜色手段）与角色页的对比度配对规则。

---

## 11 官方可用资源与工具（含"官方状态"证据）

| 资源 | 链接 | 官方状态证据 |
| --- | --- | --- |
| M3 Design Kit（Figma） | https://goo.gle/m3-design-kit ；https://www.figma.com/community/file/1035203688168086460 | m3 design tokens / typography / shape / grids 多页 Resources 表均标 Available |
| Material Theme Builder（Figma plugin） | https://goo.gle/material-theme-builder-figma ；https://www.figma.com/community/plugin/1034969338659738588/material-theme-builder | m3 design tokens 页与 color system 页 Tools 行标 Available |
| Material baseline theme and tokens（DSP） | https://github.com/material-foundation/material-tokens （goo.gle/material-tokens） | m3 design tokens 页 Implementation 行标 Available |
| Material Symbols（字体） | https://developers.google.com/fonts/docs/material_symbols ；代码库 https://github.com/google/material-design-icons | Google Fonts 官方文档页 + Apache-2.0 仓库 |
| material-color-utilities | https://raw.githubusercontent.com/material-foundation/material-color-utilities/main/README.md | Google 官方 repo，README 列出 7 种语言实现 |
| material-web | https://github.com/material-components/material-web （token：`tokens/versions/v0_192/`） | 官方组件库；token 文件头部自述 "Design system version v0.192" |
| Compose Material3 | https://github.com/androidx/androidx （`compose/material3/.../tokens/`） | 官方 AndroidX 源码；token 文件带 VERSION 常量 |
| Flutter Material（M3） | https://api.flutter.dev/flutter/material/Typography/Typography.material2021.html ；源码 `packages/flutter/lib/src/material/` | m3 typography 页把该 API 列为 Flutter 实现 |
| Flutter dynamic color | https://pub.dev/packages/dynamic_color | m3 color system 页 Resources 表把该 pub 包列为 Flutter dynamic color 实现 |

---

## 12 对本项目的含义（引用现有真实路径与符号）

现有落地位置：`app/lib/shared/ui/theme/`（`theme.dart`、`color/app_color_scheme.dart`、`color/hentai_color_scheme.dart`、`extensions/theme_context_extensions.dart`、`tokens/app_{layout,motion,radius,shadow,spacing,text,theme}_tokens.dart`），以及 `docs/adr/0027`、`0028`、`0029`。

1. **`buildAppTheme(Brightness)` 的 M3 开关已打开，但有四处反向设置需要重审**
   `theme.dart` 设 `useMaterial3: true`，同时 `splashFactory: NoSplash.splashFactory`、`highlightColor: Colors.transparent`、`AppBarTheme(surfaceTintColor: Colors.transparent, scrolledUnderElevation: 0.0)`。按本文 §3 与 §2.5/§6，这等于**把 M3 的状态层表达与 scrolled-under 的 tonal 反馈全部关掉**。迁移时需二选一：要么恢复 ink/state layer 与 surface tint，要么在 `MASTER.md` 明确写"本项目自建按压反馈，M3 state layer 仅作数值参考"。

2. **`HentaiColorScheme` / `buildBaseColorScheme` 必须按 §2.1 的 49 角色表重建**
   现有 `color/hentai_color_scheme.dart` + `color/app_color_scheme.dart` 提供的是自定义 scheme。M3 迁移最小正确集：`primary/onPrimary/primaryContainer/onPrimaryContainer`、`surface/surfaceContainer{,Low,High,Highest,Lowest}/surfaceDim/surfaceBright`、`onSurface/onSurfaceVariant`、`outline/outlineVariant`、`*-fixed` 系列。注意 baseline 的 `surface` 是 **Neutral98 / Neutral6**（§2.1），与旧实现常见的 Neutral99/Neutral10 不同；`theme.dart` 里 `scaffoldBackgroundColor/canvasColor = colorScheme.surface`、`dividerColor = colorScheme.outlineVariant` 会自动跟随，不必另设。

3. **`AppRadiusTokens` 可一一对应到 §5.1 的 corner scale**
   M3 的 4/8/12/16/28（+Expressive 的 20/32/48）应成为 radius token 的唯一来源；Flutter 的 `Shapes`（`extraSmall..extraLarge`）只覆盖 5 档，Expressive 的 increased/48 档需自建 `ShapeBorder`/`BorderRadius`。

4. **`AppTextTokens` 与 `fontFamily: 'MI_Sans_Regular'` 存在硬冲突**
   `theme.dart` 全局 `fontFamily: 'MI_Sans_Regular'`，而 M3 type scale 的 Medium/Bold 与 15 个 emphasized 样式都依赖 3 档字重（400/500/700，§4.2/§4.3；material-web 文档亦要求三档齐全）。若 MI Sans 只有单一字重，emphasized 样式只能靠合成加粗，需要在文档里显式接受或替换字体。

5. **`AppMotionTokens` 需同时容纳两套体系**
   §7.3 的 easing 表与 §7.2 的 duration 表可继续用作 transitions；但 Flutter **官方不支持** motion physics（§7.1 Availability: Flutter Unavailable），本项目要做 spring 只能自带 `SpringSimulation`，且必须自行实现 §7.6 的 reduce-motion 分支（`MediaQueryData.disableAnimations`）。ADR-0028 的 `ThemeExtension`（`context.motion`）正好是承载 scheme 选择（standard/expressive）的落点。

6. **`visualDensity: VisualDensity.adaptivePlatformDensity` 与 M3 density 指南不是同一套**
   §8.3 已说明 M3 density 页不可得；不要把 Flutter 的 VisualDensity 当作 M3 density 规范引用。

7. **门禁与目录约定**
   ADR-0027 仍写着"Fluent 风格设计系统"，迁移后该句必须改；同时 `app/lib/shared/ui/theme/` 是四层（Shell/Layout/Component/Feature）之外的 token 层，M3 token 命名（`md.sys.*`）建议只出现在文档与注释里，Dart 侧继续用 `ColorScheme`/`TextTheme`/`Shapes` + `ThemeExtension`，避免引入第三套命名。

---

## 13 证据薄弱与待确认清单

| 项 | 现状 | 已尝试 |
| --- | --- | --- |
| State layer 的规范数值 | 只有 material-web v0.192（0.08/0.12/0.12/0.16，无 disabled）；Compose 常量未取到 | `/foundations/interaction/states/{state-layers,applying-states}` 空；Compose `StateLayer.kt` 三次 404 |
| Typography 规范数值 | Compose `v0_103` 与 web `v0.192` 在 3 处 tracking 冲突；规范表页空 | `/styles/typography/type-scale`、`/styles/typography/type-scale-tokens` 空 |
| Flutter 逐样式字号 | 仅知 `englishLike2021` "matches the 2021 spec"；数值未取到 | `typography.dart` 抓取 50000 字符截断（`_M3Typography` 在文件尾） |
| spacing / grids / density dp 值 | 只有 space100=8dp、示例 8/12/24dp；列宽、gutter、density 档位全缺 | `/styles/spacing/tokens`、`/foundations/layout/grids-spacing/{grids,density}` 空 |
| canonical layouts | 页面存在但正文空；list-detail / supporting pane / feed 的具体 pane 宽度、边距未取得 | `/foundations/layout/canonical-examples` 空 |
| 图标推荐尺寸（20/24dp） | 未确认；只有 Symbols 的 opsz 20–48dp 与 Flutter Icon 默认 24 | `/styles/icons`、`/styles/icons/overview` 空 |
| Material Symbols 与旧 Icons 的对比 | 仅确认 Symbols 的可变轴与合并字体文件；旧 Icons 的结构未获官方页面 | `/styles/icons` 空 |
| M3 无障碍条款（focus 可见性、semantics） | 仅确认 48dp 与 4.5:1/3:1（来自 developer.android.com） | `/foundations/accessibility`、`/foundations/accessibility/designing` 空 |
| dynamic color 平台可用性 | 仅确认 Android 12 起、Flutter 走 `dynamic_color` 包；桌面/Windows 不可用属推断 | m3 color system、dev dynamic-colors 均未给逐平台矩阵 |
| material-tokens 仓库结构 | 只有 README（DSP 流程）；`md.*` JSON 的实际文件清单未取得 | github.com 页面与 api.github.com 均被限流/失败 |
| M3 规范对 reduced motion 的要求 | 未确认（只有 Flutter 侧实现文档） | 相关 m3 页空 |

> 结论性提醒：本文所有**数值**在引用时应同时给出"来源类型"——`v0.192`(web) / `v0_210`(Compose color) / `v0_103`(Compose type/elevation/motion) / `14_1_0`(Compose shape) / 规范页——因为它们仍在演进，且规范页与实现存在已知冲突（§4.2、§2.5）。