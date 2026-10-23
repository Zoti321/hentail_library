# 08 · 桌面端 tone-based surface：按区域取角色是默认做法，单条梯级不合格

> **状态**：调研 + 已定稿的桌面口径。本轮**不改** Flutter 代码、**不改**任何 hex 值（`MASTER.md §2.2` 的 46 个值原样保留）；Figma 侧按本文口径已改造 `41:2384` 并补 large/expanded 详情模板（见 `09` §7）。
> **决策前提**：不推翻 `MASTER.md §1` 的 D3「A · 柔和玫瑰」（seed `#E91E63` / tonalSpot / primary chroma 36 / neutral chroma 6）。本文所有方案都保留主色与整体粉调。
> **证据分级**（沿用本目录 `README.md` 规则）：**A** = 官方规范/官方博文原文；**B** = 官方实现源码（Flutter SDK / Compose `*Tokens.kt` / material-color-utilities）或按本仓库既有一手材料实测反推；**C** = 工程推断（含视觉感知结论，未做被试实验）。
> **抓取说明**：`https://m3.material.io/styles/color/system/overview` **抓取失败（返回空正文，JS 渲染）**，本条降级；替代主源为官方博文 `https://m3.material.io/blog/tone-based-surface-color-m3`（本次抓取成功，6067 字符）与 `https://m3.material.io/styles/elevation/{overview,applying-elevation}`、`https://m3.material.io/styles/color/roles`（均抓取成功）。逐条降级声明见「附录 B」。
> **数值来源**：全部 tone 由 `MASTER.md §2.2` 的 hex 逐色计算（tone ≡ CIELAB L∗，方法见 §2.0，含校验），**没有编造任何数值**。
> **索引状态**：已登记 `README.md` 索引（行数与 URL 数同步）。`design-system/example.png` 只读未改，由用户自行提交入库（`854dc1d3`）。

---

## 0. TL;DR

- **先说结论，避免误读：tone-based surface 本来就是为大屏设计的**（A：官方博文副标题 `New surface color roles offer more flexibility for large screens and rich color features`）。本文**不是**说它「只适合移动端」——恰恰相反，桌面端该做的是**把它的能力用满**（区域级 add-on surface colors，官方专门为大窗口类开的），而不是退回被弃用的 elevation 叠色。三个命题的区别见 **§0.5**。
- **模型本身没坏**：tone-based surface 把「层级」编码成 `surface → surfaceContainer*` 的**明度差**，官方明确说这套角色「不再与 elevation 绑定」，且**本来就是为更大的屏**准备的（A，官方博文副标题 + roles 页原文）。
- **根因是「只有一个编码通道，而且通道太窄」**：A · 柔和玫瑰的亮色阶梯每级只有 **ΔL∗ 1.93–2.11**（对 surface 的 WCAG 对比度仅 **1.05–1.23**，ΔE76 2.07–2.11），整条 `surfaceBright → surfaceContainerHighest` 只有 **8.15** 个 L∗。这个级差放在 48dp 卡片上够看，铺在 1440×900 的**并列大分区**上就消失：桌面没有移动端那套「小视口 + 挤在一起共边比较 + splash/按压反馈 + 圆角」的辅助线索，层级只剩一条 2 个 L∗ 的通道。
- **官方配套手段是有的，但我们的规范里全关掉了**：`MASTER §2.3` 写了「不要再拿 elevation 阴影表达层级」、`§4.2` 把阴影当「可选」、stroke 宽度连 token 都没有。官方原文给的是「tone 为默认 + 需要时用 hairline / 阴影 / scrim 补」（A）。
- **推荐（本文最终合并口径）**：**主通道 = 区域级 add-on surface 映射**——桌面档 rail 用 `surfaceDim`、导航列表与 supporting pane 用 `surfaceContainer`、主内容用 `surface`，亮色级差 **7.0 / 4.0**、暗色 **10.0 / 6.0**，**46 个 hex 一个不改**（官方明文允许「在大窗口类增加 add-on surface colors」，A，§1.6）；**第二通道 = 1dp `outlineVariant` hairline**（级差不足、高环境光、低端屏时按需叠加；可交互边界换 `outline`）；**浮层 = level2–5 真阴影 + tint 全关**（§3.3 限域版）。**不采纳 b2「把整条梯级压暗」**（会动移动端观感 + 需要第二个 mode）。
- **对 46 角色的增量**：**颜色值 0 变更、角色 0 新增**；新增 **2 个数值 token**（`stroke/hairline` 1dp、`stroke/focus` 2dp），**扩用 2 个既有颜色角色**（`outlineVariant` / `outline`），**1 条规则变更**（阴影使用范围）。

### 0.0 硬口径（桌面端决策口径，2026-10-23 定稿）

> **桌面端按区域取 surface 角色，是默认做法，不是可选项；只用一条 surface 梯级去铺并列大区，在本项目视为不合格设计。**

三条可执行判定，评审时逐条对照：

| 编号 | 口径 | 判定方式 |
|---|---|---|
| **T1 结构** | 任何 **≥1200dp** 的并列 pane，必须显式声明各自的区域角色：**rail → `surfaceDim`**、**导航列表 / supporting pane → `surfaceContainer`**、**主内容 → `surface`**；面板内卡片再降一档（`surfaceContainerLow`），浮起卡片用 `surfaceContainerLowest`。代码以「区域」为参数，不以组件为参数（同一个 `Card` 在内容区与面板内取不同角色）。 | 看实现里取色是否由「区域上下文」决定，是否有区域→角色的单一映射表 |
| **T2 阈值** | 相邻两个并列区域若 tone 级差 **< 4（亮色）/ < 6（暗色）**，必须叠加 1dp `outlineVariant` hairline 或提升一档角色；单靠 2 个 L\* 的档差**不算分隔**。 | 逐对 pane 算 ΔL\*，对照 §4.1 的实取值 |
| **T3 边界** | 46 个 hex **不改**；新增 `stroke/hairline` 1dp、`stroke/focus` 2dp；阴影**只**给浮层（level 2–5）且 tint 全关；任何情况下不回退到被弃用的 elevation-tint 叠色。 | 看 token 清单与组件样式 |

这三条就是「用满官方为大窗口开的 add-on surface colors」（A，§1.6）与「默认梯级密度不够」（B，§2）的合成结论；后文的方案 1/2/3 只是它们的实现细节。

### 0.5 先消歧义：「为大屏设计」与「默认梯级在大屏上不够用」是两件事

这三个命题经常被混成一个，混了就会得出错误结论（「tone-based 不适合桌面」或「那就回去加阴影」）：

| # | 命题 | 依据 | 判定 |
|---|---|---|---|
| **P1** | tone-based surface 是**专为大屏新增**的模型 | **A**：官方博文副标题 `New surface color roles offer more flexibility for large screens and rich color features`；正文 `now have more layout flexibility for larger screens`；roles 页 `especially helpful for creating hierarchy and nested containers in layouts for expanded screens` | **成立**。它就是为了让大屏**不必再靠 elevation 叠色**去分区 |
| **P2** | baseline M3 的**相邻档差**（亮色约 2 个 L∗、对比度 1.05–1.23）不足以单独承担「同屏并列、无边界、大尺度」分区的分隔 | **B**：本仓库 46 个 hex 实测（§2.1 / §2.2）+ 真实桌面产品反证（§2.5） | **成立**，但对象是「**单一梯级 + 关掉第二通道**」这种用法，**不是 tone-based 整体** |
| **P3** | 桌面端对 tone-based 该做的是「**用满**它」，不是退回阴影 | **A**：roles 页 `you can use add-on surface colors in larger window class sizes as long as colors are consistently applied` | **成立**；这正是 §4.1 区域级映射的官方依据 |

**这三条不冲突**，关系是：

- P1 说的是**模型定位**：用 tone 取代 elevation 表达层级，大屏收益最大。
- P2 说的是**默认取值的密度**：`surface` 98 / `container*` 96·94·92·90 这套数字是为「小面积 + 卡片 containment + splash + 可选阴影」调的；把它**同一个梯级**去铺 3–4 个并列大区，等于**面积放大了、密度没换**。
- P3 给出正解：**按区域换角色**（rail → `surfaceDim`、面板 → `surfaceContainer`、内容 → `surface`），把桌面需要的级差从 2 拉到 **7.0 / 4.0**（亮）与 **10.0 / 6.0**（暗）——**用的仍是 tone-based，只是从「一条梯级」变成「一张区域映射表」**；官方允许的 **hairline** 作为第二通道按需叠加。**没有任何一步回到被弃用的 elevation-tint 模型**（§1.6 原文：tone 是默认，阴影 / scrim / hairline 是补充手段）。

> 换句话说：**「桌面端需要比移动端更大的级差」与「tone-based 更适合桌面端」是同一件事的两面**——正因为桌面要靠 tone（而不是靠阴影）表达层级，才需要动用官方为大屏开的区域级 add-on 能力把级差拉开。

---

## 1. Tone-based surface 体系到底是什么

### 1.1 surface 序列（五容器 + bright/dim）

官方原文（A，https://m3.material.io/blog/tone-based-surface-color-m3 ）：

> The previous way makers could achieve tinted surfaces … was to assign the color role "surface" to a component, and increase its elevation to achieve the desired tinting which was applied via an opacity layer.
>
> The update introduces dedicated surface color roles that are **no longer tied to elevation**. Makers will be able to choose the right surface roles based on the **containment needs** of their products, and now have **more layout flexibility for larger screens**.
>
> "Surface container" is the **recommended default** color role for a **contained area** against the "surface" color role.

官方角色定义（A，https://m3.material.io/styles/color/roles ）：

> There are also five surface container roles named based on their level of emphasis: **Surface container lowest: Lowest-emphasis container color** … **Surface container highest: Highest-emphasis container color**
>
> **Surface container** is the default role, but the others are especially helpful for creating hierarchy and nested containers in **layouts for expanded screens**.
>
> The most common combination of surface roles uses **surface** for a background area and **surface container** for a navigation area.
>
> All color mappings – but especially surface colors – should **remain the same for layout regions across breakpoints**. For example, the body area will use the **surface** color and the navigation area will use the **surface container** color on both mobile and tablet.
>
> Depending on necessary hierarchy, feature area, and design logic, you can use **add-on surface colors in larger window class sizes** as long as colors are consistently applied.

两条 add-on 角色（A，同页）：

> **Surface dim:** Dimmest surface color in light and dark themes
> **Surface bright:** Brightest surface color in light and dark themes

对应实现（B，Flutter SDK `packages/flutter/lib/src/material/color_scheme.dart:101-102` 与 `:1260-1262`）：

> Material 3 also introduces tone-based surfaces and surface containers. They replace the old opacity-based model which applied a tinted overlay on top of surfaces based on their elevation.
>
> Surface container color roles are independent of elevation.

> **这句话的分量**：官方把「surface container」定位为**为 expanded 布局提供层级与嵌套容器**，并明确「在大窗口类可以使用 add-on surface colors」。也就是说：**桌面端读不清层级不是「官方没想到大屏」，而是「我们只用了 tone 这一个通道、没用官方配套的第二通道」**。这条是 §2.4-H4 的判定依据。

### 1.2 `surfaceTint` 恒等于 `primary`

| 断言 | 来源 | 等级 |
|---|---|---|
| `ColorScheme.surfaceTint` 的实现是 `get surfaceTint => _surfaceTint ?? primary` | Flutter `color_scheme.dart` | **B** |
| Compose `SurfaceTint = Primary`（`inline get() = Primary`） | `compose/material3/.../tokens/ColorLightTokens.kt`（`// VERSION: v0_210`） | **B** |
| mcu `MaterialDynamicColors.surfaceTint` = `isDark ? tone 80 : tone 40`，等于 primary 的 tone | `material_color_utilities-0.11.1/lib/dynamiccolor/material_dynamic_colors.dart` | **B** |
| 本仓库实测 `surfaceTint` = `#8E4957`(Light) / `#FFB2BE`(Dark) = `primary` | `MASTER.md §2.2`、`.scratch/palette.json` | **B** |

### 1.3 tonal elevation（tint 叠加）以及它的现状

官方对「elevation 到底怎么表达」的立场（A，https://m3.material.io/styles/elevation/overview ）：

> **Tokens have no shadows or color**; each platform determines the specific shadows and values to use at each elevation level
> Elevation can be shown as **tonal surface colors or shadows**

实现层（B，Flutter `packages/flutter/lib/src/material/elevation_overlay.dart`，表体带 `BEGIN GENERATED TOKEN PROPERTIES - SurfaceTint` 注释，注明 generated from **the Material Design token database**）：

| elevation | 0 | 1 | 3 | 6 | 8 | 12 |
|---|---:|---:|---:|---:|---:|---:|
| tint 透明度 | 0.00 | 0.05 | 0.08 | 0.11 | 0.12 | 0.14 |

叠加方式（B，同文件）：`Color.alphaBlend(surfaceTint.withOpacity(opacity), color)`；`Material` 的开关是 `surfaceTintColor`（B，`material.dart`）：useMaterial3 且不为 null/透明时才叠，否则完全不叠。

**两个当前实况（B，Flutter 源码）**，对根因很关键：

1. `card.dart` 里 M3 的 `CardDefaults.surfaceTintColor` **全部是 `Colors.transparent`** → Flutter M3 的 Card **默认不叠 tint**，层级靠 `surfaceContainerLow` 这样的**裸色**表达。
2. `app_bar.dart:1233-1240` 仍然传 `theme.colorScheme.surfaceTint`，注释原文：「// M3 defaults.surfaceTint is Colors.transparent now. It is not used here because otherwise, it will cause breaking change for scrolledUnderElevation.」→ **AppBar 在滚动抬升时仍会叠 tint**，这是本项目当前唯一「色 + tint 双轨」的显性叠加点。

### 1.4 角色 → tone 的权威对照（B，Compose v0_210 + mcu 0.11.1，与本仓库实测一致）

| 角色 | Light tone | Dark tone | 本仓库 Light | 本仓库 Dark |
|---|---:|---:|---|---|
| surface | 98 | 6 | `#FFF8F7` | `#191112` |
| surfaceDim | 87 | 6 | `#E7D6D7` | `#191112` |
| surfaceBright | 98 | 24 | `#FFF8F7` | `#413738` |
| surfaceContainerLowest | 100 | 4 | `#FFFFFF` | `#140C0D` |
| surfaceContainerLow | 96 | 10 | `#FFF0F1` | `#22191A` |
| surfaceContainer | 94 | 12 | `#FBEAEB` | `#261D1E` |
| surfaceContainerHigh | 92 | 17 | `#F5E4E5` | `#312829` |
| surfaceContainerHighest | 90 | 22 | `#F0DEE0` | `#3C3233` |
| onSurface | 10 | 90 | `#22191A` | `#F0DEE0` |
| onSurfaceVariant | 30 | 80 | `#524345` | `#D6C2C3` |
| outline | 50 | 60 | `#847375` | `#9F8C8E` |
| outlineVariant | 80 | 30 | `#D6C2C3` | `#524345` |

→ **本仓库没有取错值**：46 角色就是标准 tone 分配（`surfaceDim` 的 Dark 侧等于 `surface` 也是 baseline 行为：两者都是 tone 6）。

### 1.5 版本演进（两处「纠错」撤回）

| 事实 | 来源 | 等级 |
|---|---|---|
| `background` / `onBackground` / `surfaceVariant` 弃用，分别指向 `surface` / `onSurface` / `surfaceContainerHighest` | docs.flutter.dev「new-color-scheme-roles」迁移页原文 + 「In stable release: **3.22.0**」 | **A** |
| tokens v6.1 应用到 Flutter Material：`onPrimaryContainer/onSecondaryContainer/onTertiaryContainer/onErrorContainer` 由 **Tone10 → Tone30**；chip 边框由 `outline` → `outlineVariant` | docs.flutter.dev「material-design-3-token-update」迁移页原文 + 「In stable release: **3.27**」 | **A** |
| 旧 opacity 模型与新角色「两套并存一段较长过渡期」 | 官方博文原文：「Both methods will co-exist for an extended transition period」 | **A** |
| 浅色 surface 由 tone 99 → 98、neutral chroma 4 → 6、暗色 surface 略变暗 | 官方博文原文 | **A** |

> **两处「纠错」撤回（本稿第二版由主会话复核后修正）**：
> 1. **「3.22 弃用」成立**——一手来源是 docs.flutter.dev 的 `release/breaking-changes/new-color-scheme-roles`（页面写明 In stable release: **3.22.0**）。容易混淆的是 Flutter `color_scheme.dart` 里的 `@Deprecated` 注解文案写「deprecated after **v3.18.0-0.1.pre**」——那是**该 API 在 pre 版本落地的时间**，与「stable 发布版本 3.22」是两种口径，不矛盾。
> 2. **「3.27 把 4 个 `on*Container` 由 Tone10 改 Tone30」成立**——一手来源是 docs.flutter.dev 的 `release/breaking-changes/material-design-3-token-update`（In stable release: **3.27**，tokens v6.1）。用 Compose `ColorLightTokens.kt`（`// VERSION: v0_210`，仍是 `OnPrimaryContainer = Primary10`）或 mcu 0.11.1 的 `isDark ? 90 : 10` 来反证**不成立**：那是 **Compose 库的版本滞后**，不能用来否定 Flutter 侧已落地的 token 更新。
> → 因此本仓库 `MASTER §2.2` 的 `onPrimaryContainer #3B0716`（Light，L∗ ≈ 12.6，Tone10）不是错误，而是**保有 Flutter 3.22 口径**；若将来升到 3.27 口径，这 4 个角色需要重生成。这是**版本选择问题，不是取值错误**。

### 1.6 官方给的「边界手段」清单（这才是桌面端该用的东西）

官方从不认为 tone 是唯一手段（A，https://m3.material.io/styles/elevation/applying-elevation ）：

> By default, Material 3's surfaces use tonal difference to indicate separation. **Other methods can be used to indicate edges, such as: Giving surfaces a drop shadow / Placing a scrim behind a surface**
>
> For interactive components, **edges must create sufficient contrast between surfaces (by meeting or exceeding accessible contrast ratios)** for them to be seen as separate from one another.
>
> Any overlapping containment areas or components **should have different color roles** in order to visually communicate separation.
>
> When it comes to applying shadows, **less is more**.
>
> Protect elements: When a background is patterned or visually busy, **the hairline style** might not provide sufficient protection. In these cases, use elevation to separate and emphasize elements such as cards, chips, or buttons.
>
> Scrims use the scrim color role at an opacity of **32%**.

> 读法：官方点名了 **the hairline style**（细描边）这一档表达；它没在正文里给出 1dp 这个数值（→ 1dp 具体值与 1px/1dp 表述见 §3.1，等级降为 B）。而「hairline 不够用时用 elevation」这句话反过来也成立：**elevation 不够用时 hairline 就是官方给的备选**。

---

## 2. 根因分析（含可复算的数字）

### 2.0 度量方法与校验（必须可复现）

- sRGB → 线性：`c ≤ 0.04045 ? c/12.92 : ((c+0.055)/1.055)^2.4`
- 相对亮度：`Y = 0.2126R + 0.7152G + 0.0722B`；对比度：`(Yhi+0.05)/(Ylo+0.05)`
- CIELAB（D65，Xn=0.95047 / Yn=1 / Zn=1.08883）：`f(t)= t>0.008856 ? t^(1/3) : 7.787t + 16/116`，`L∗ = 116f(Y) − 16`，`a∗ = 500(f(X/Xn) − f(Y))`，`b∗ = 200(f(Y) − f(Z/Zn))`
- `C∗ = √(a∗²+b∗²)`；`ΔE76 = √(ΔL∗²+Δa∗²+Δb∗²)`
- tint 合成：`alphaBlend(fg, bg, a) = fg·a + bg·(1−a)`（与 Flutter `Color.alphaBlend` 同式）

**校验（这一步决定了后面所有 ΔL∗ 是不是可信）**：把 `MASTER.md §2.2` 的 hex 算成 L∗，与官方 tone 值逐一比对，误差全部 **≤ 0.15**：surface 98→**98.08**、containerLow 96→**95.97**、container 94→**94.04**、containerHigh 92→**91.93**、containerHighest 90→**89.93**、dim 87→**86.99**、lowest 100→**100.00**、outlineVariant 80→**80.08**、outline 50→**50.04**、onSurfaceVariant 30→**30.01**。→ **tone 就是 CIELAB L∗**，「tone 差」与「ΔL∗」在本文可以互相代入（B，计算自证）。

### 2.1 亮色阶梯实测（A · 柔和玫瑰 · Light）

| 角色 | tone | hex | L∗ | C∗ | 相邻 ΔL∗ | 相邻 ΔE76 | 对 surface 对比度 |
|---|---:|---|---:|---:|---:|---:|---:|
| surfaceContainerLowest | 100 | `#FFFFFF` | 100.00 | 0.00 | — | — | 1.05 |
| **surfaceBright = surface** | 98 | `#FFF8F7` | **98.08** | 2.52 | — | — | 1.00 |
| surfaceContainerLow | 96 | `#FFF0F1` | 95.97 | 5.38 | **−2.11** | 3.71 | **1.05** |
| surfaceContainer | 94 | `#FBEAEB` | 94.04 | 6.13 | **−1.93** | 2.07 | **1.11** |
| surfaceContainerHigh | 92 | `#F5E4E5` | 91.93 | 6.16 | **−2.10** | 2.10 | **1.17** |
| surfaceContainerHighest | 90 | `#F0DEE0` | 89.93 | 6.61 | **−2.01** | 2.11 | **1.23** |
| surfaceDim | 87 | `#E7D6D7` | 86.99 | 6.24 | −2.94 | 3.00 | 1.34 |
| outlineVariant | 80 | `#D6C2C3` | 80.08 | 7.49 | −6.91 | 7.03 | 1.62 |
| outline | 50 | `#847375` | 50.04 | 7.09 | −30.04 | 30.05 | 4.27 |
| onSurface | 10 | `#22191A` | 9.88 | — | — | — | 16.38 |
| onSurfaceVariant | 30 | `#524345` | 30.01 | — | — | — | 8.91 |

三个可直接引用的数：

1. **主用级差（页面 → 卡片）= ΔL∗ 2.11、对比度 1.05**；容器之间 **1.93–2.10、1.11–1.23**。官方对边界的要求是「meet or exceeding **accessible contrast ratios**」（3:1），而**同色相的明度差 2 个 L∗ 在数学上就到不了 3:1**（要 3:1 需要 tone ≈ 60，见 §3.1 计算）。
2. **整条容器阶梯总跨度只有 8.15 ΔL∗**（98.08 → 89.93）；5 档分完，每档 2 个 L∗。
3. **ΔE76 几乎等于 ΔL∗**（2.07–2.11），因为 chroma 只有 2.52–6.61 → **明度是唯一线索，没有第二个通道**（色相都在 10–15° 附近，见下）。

补充一个易被忽略的事实（B，计算）：容器越深，**chroma 越大**（C∗ 2.52 → 5.38 → 6.13 → 6.16 → 6.61），色相从 surface 的 **31°** 漂到容器区的 **14.9° / 10.8°**。也就是说「往下压一级」在 A 板里同时意味着「**更粉、更灰**」——这正是用户说「脏」的物理来源之一，而不是错觉。

### 2.2 暗色阶梯实测（A · 柔和玫瑰 · Dark）

| 角色 | tone | hex | L∗ | C∗ | 相邻 ΔL∗ | 相邻 ΔE76 | 对 surface 对比度 |
|---|---:|---|---:|---:|---:|---:|---:|
| surfaceContainerLowest | 4 | `#140C0D` | 3.98 | 3.07 | — | — | 1.04 |
| **surface = surfaceDim** | 6 | `#191112` | **5.88** | 3.81 | — | — | 1.00 |
| surfaceContainerLow | 10 | `#22191A` | 9.88 | 4.80 | **+3.99** | 4.11 | 1.08 |
| surfaceContainer | 12 | `#261D1E` | 11.85 | 4.70 | **+1.98** | 1.98 | 1.13 |
| surfaceContainerHigh | 17 | `#312829` | 17.13 | 4.48 | **+5.28** | 5.29 | 1.30 |
| surfaceContainerHighest | 22 | `#3C3233` | 21.88 | 4.80 | **+4.74** | 4.75 | 1.50 |
| surfaceBright | 24 | `#413738` | 24.13 | 4.72 | +2.26 | 2.26 | 1.62 |
| outlineVariant | 30 | `#524345` | 30.00 | 6.92 | +5.87 | 6.27 | 1.99 |
| outline | 60 | `#9F8C8E` | 59.96 | 7.63 | +29.96 | 29.97 | 5.85 |
| onSurface | 90 | `#F0DEE0` | 89.93 | — | — | — | 14.36 |

**关键读法**：暗色级差 **2.0–5.3**（跨度 16.0），**是亮色的 2 倍以上**；而且暗色阶梯是「越往上越亮」，与「越往下越深」的亮色方向相反。→ 用户的抱怨**大概率只出现在亮色主题**（`MASTER §9` 未分主题记录，建议主会话按主题复查），暗色侧即便是 baseline 值也基本能用。

### 2.3 tonal elevation 叠加实测（这是「偏粉/糊」的定量证据）

Light，`alphaBlend(primary #8E4957, surface #FFF8F7, a)`：

| 等级 / a | 结果 | ΔL∗ | C∗ | 色相 h | 正文对比度（onSurface） |
|---|---|---:|---:|---:|---:|
| level0 / 0.00 | `#FFF8F7` | 0 | 2.52 | 31.0° | 16.38 |
| level1 / 0.05 | `#F9EFEF` | **−2.87** | 3.56 | 19.5° | 15.24 |
| level2 / 0.08 | `#F6EAEA` | **−4.46** | 4.30 | 19.6° | 14.63 |
| level3 / 0.11 | `#F3E5E5` | **−6.06** | 5.04 | 19.6° | 14.03 |
| level4 / 0.12 | `#F1E3E4` | **−6.73** | 5.08 | 13.8° | 13.79 |
| level5 / 0.14 | `#EFE0E1` | **−7.71** | 5.45 | 14.2° | 13.44 |

Dark，`alphaBlend(primary #FFB2BE, surface #191112, a)`：

| 等级 / a | 结果 | L∗ | ΔL∗ | C∗ | 正文对比度 |
|---|---|---:|---:|---:|---:|
| level1 / 0.05 | `#25191B` | 10.32 | +4.43 | 6.47 | 13.16 |
| level2 / 0.08 | `#2B1E20` | 12.90 | +7.02 | 6.82 | 12.40 |
| level3 / 0.11 | `#322325` | 15.56 | +9.68 | 7.68 | 11.57 |
| level4 / 0.12 | `#352427` | 16.33 | +10.45 | 8.73 | 11.33 |
| level5 / 0.14 | `#39282A` | 18.16 | +12.28 | 8.53 | 10.74 |

三条硬结论：

1. **亮色下单一级 tint 就把 surface 拉走 2.9–7.7 个 L∗**，同时 **C∗ 从 2.52 涨到 3.56–5.45（翻倍以上）**，色相从 31° 拽到 **13.8–19.6°**（更红/更玫）→ 大面积浅色上就是「一层很薄的粉膜」，这就是「偏粉、显脏、发糊」的机制。
2. **tint 与容器阶梯是同一个维度上的替代品**：level3（0.11）把 surface 压到 L∗ 91.5，几乎**等于 surfaceContainerHigh 的 91.93**；暗色 level1 就 +4.43，等于跨过 2–4 个容器级差。**两个一起用 = 同一层级编码两次**，且 tint 会把刚拉开的档差再焊回去。
3. **tint 只压明度、不加边界**：它把整块面变暗变粉，但没有任何「边缘」（ΔL∗ 在块内是均匀的）。所以**没有真阴影时，tint 不产生空间层次，只产生脏**——这一条正好对上任务书里「和真阴影不叠加时没有空间层次」的假设。

### 2.4 假设逐条判定

| # | 假设 | 判定 | 依据（数字 / 来源） |
|---|---|---|---|
| **H1** | 桌面浅色大屏上 `surface` 与 `surfaceContainer*` 的 ΔL∗ 太小 | **成立** | ΔL∗ 1.93–2.11、ΔE76 2.07–2.11、对比度 1.05–1.23；总跨度 8.15。官方对边界的要求是「meet or exceeding accessible contrast ratios」（A，applying-elevation），而 3:1 需要 tone ≈ 60（§3.1 计算）→ **1.05–1.23 差了一个数量级**。 |
| **H2** | tonal elevation 的 tint（叠 5–14% primary）在大面积浅色上整体偏粉、显脏，且与真阴影不叠加时没有空间层次 | **部分成立** | 机制可量化：C∗ 2.52→3.56/4.30/5.04/5.45，h 31°→13.8–19.6°，ΔL∗ −2.87…−7.71（§2.3）。**但**本仓库 `MASTER §2.3` 写的是「tonal elevation 只在需要时叠加，默认不叠」，且 Flutter M3 `CardDefaults.surfaceTintColor = Colors.transparent`（B）→ 日常根本没叠 tint。所以用户看到的「粉/脏」主要来自：(a) 容器本身 C∗ 5.4–6.61 且色相已偏玫；(b) **桌面 hover 的 8% primary state layer**（下面 H6 有数字）；(c) **AppBar `scrolledUnderElevation` 仍然叠 tint**（B，`app_bar.dart:1233-1240`）。→ 「tint 是机制」成立，「tint 是当前主因」不成立。 |
| **H3** | 桌面端没有移动端的大圆角 / 小视口 / 环境光假设，边界主要靠 real elevation 与分隔线表达 | **部分成立（C）** | 「没有大圆角」**不成立**：Flutter 的圆角是常量（`Card` 12dp，B），全平台一致，桌面并不缺圆角。「小视口」**成立**（这是视口定义本身）。「环境光」属 **C 级推断**（明亮办公室/远距/Gamma）。真正成立的是：**桌面同时失去了 splash（`MASTER §4.4` 桌面 NoSplash，B）与阴影（§2.3 明文禁止用阴影表层级），并且面积放大** → 三条几何/动效线索一起没，只剩 2 个 L∗。 |
| **H4** | 官方是否承认这个局限；Web/桌面怎么补 | **部分成立，且方向相反** | 官方**不承认**「tone-based 不适合桌面」，它说的恰恰是「新角色让**大屏**有更多布局弹性」「容器角色对 **expanded 布局**尤其有用」（A，blog + roles）。官方给的桌面补法是：**hairline 描边 / 阴影 / scrim 32% / 边界必须满足可访问对比度**（A，applying-elevation）。→ 结论应改写为：**桌面端失效是「只上 tone、没上官方配套第二通道」，不是模型失效**。 |
| **H5** | 暗色档不受影响 | **成立** | 暗色级差 1.98–5.28（跨度 16.0），是亮色（1.93–2.11）的 2 倍以上；对比度 1.08–1.72。抱怨应主要集中在亮色主题。 |
| **H6** | 桌面 hover 的 8% primary state layer 会在大面积上放大粉感 | **成立（计算）** | `alphaBlend(primary, surfaceContainer #FBEAEB, 0.08)` = **`#F2DDDF`**，L∗ 94.04→**89.82（−4.22）**、C∗ 6.13→**7.71（+1.58）**，色相 14.9°→12.2°。**hover 一次就等于「整块降一级 + 更粉」**，而桌面没有 splash，唯一能表达 hover 的正是它（`MASTER §4.4`）。 |

> **关于「官方是否承认局限」的准确表述**（避免误引）：官方最接近的表达是博文副标题与 roles 页的「为大屏提供弹性/对 expanded 布局尤其有用」；**没有任何官方文字说 tonal 模型在桌面失效**。本文把「桌面读不清」定性为**本项目条件下的工程判断（C）**，其可测部分（级差、对比度、C∗、叠加效果）是 B。

### 2.5 旁证：真实桌面产品的分区级差（B，本仓库 `design-system/example.png` 复核）

对仓库内 `design-system/example.png`（2048×1440，Google Chat 改版对照图，**只读、未修改**）做逐像素统计，本次复核确认下列填色确实大面积存在（像素计数）：`#F8FAF0` 321,754 ／ `#EDEFE5` 259,630 ／ `#F3F5EB` 146,075 ／ `#D9DBD1` 49,679（另有 1,205,953 像素为插图底色 `#D9E7CB`，非 UI 分区）。

| 区域 | 采样色 | L∗ |
|---|---|---:|
| 应用栏 / icon rail | `#D9DBD1` | 87.01 |
| 导航列表 / 顶部 app bar / 辅助面板 | `#EDEFE5` | 94.05 |
| 主内容 | `#F8FAF0` | 97.88 |
| 辅助面板内卡片 | `#F3F5EB` | 96.14 |

| 相邻关系 | ΔL∗ | 对比度 |
|---|---:|---:|
| rail → 列表 | **7.05** | 1.205 |
| 列表 → 主内容 | **3.83** | 1.102 |
| 主内容 → 卡片 | 1.74 | 1.045 |
| 列表 → 面板内卡片 | 2.09 | 1.055 |

**读法（这是全文最有实践价值的一条）**：真实产品并没有把 5 档当梯级顺序用，而是「**87 / 94 / 98 三个 zone，配大级差 7 和 4**」，zone 内部（卡片）才用「1.7–2.1 + 圆角 + 阴影」。也就是说：**小级差可以用，但只能用在有几何线索（圆角/内距/阴影）的容器上；无边界的大面积并列分区必须 ≥4 ΔL∗（最好 ≥7）或另加一条可见边界。**（B：本仓库实测；本文未写入任何位图工件。）

### 2.6 机理合并：为什么同一个梯级在移动端够、搬到桌面并列大区就不够

1. **编码通道只有一个，且通道宽度只有 2 个 L∗**（§2.1）。移动端靠「小视口 + 容器小（48–88dp）+ 两块几乎总是共边/同屏 + 圆角 + splash/按压 + 有时还有系统阴影」这一堆**几何与动效线索**把这个 2 补上；桌面把面积放大一个数量级、把 splash 关掉（`MASTER §4.4`）、把阴影禁用（`MASTER §2.3`），**只剩那 2 个 L∗**。
2. **对比度的物理下限**：2 个 L∗ 在 sRGB 上对应对比度 1.05，而官方对边界的要求是可访问级（3:1）。**明度差到不了 3:1，意味着「靠色差当边界」在这套色板里本质上不可能达标**——必须引入第二种编码（描边/阴影/间距），这是几何问题不是调色问题。
3. **tint 会吃掉刚拉开的差距**（§2.3）：tint 是「压明度 + 抬 chroma + 移色相」，与容器阶梯同轴；两者叠加 = 重复编码，还会让大面积浅色变粉。
4. **「脏」是 chroma 的后果，不是错觉**：容器区 C∗ 5.4–6.6、色相 10–15°（玫偏红），大面积平涂时低 chroma 的偏色最容易被读成「脏」（C 级视觉判断，数字是 B）。
5. **桌面真正的层级载体是 chrome 分区**，而我们的组件映射把它们压在同一档：`§4.2` 里 level1–2 用 containerLow/container，物理上就是相邻 2 个 L∗ 的两块（B，`MASTER §4.2`）。

一句话根因（注意措辞，别读成「tone 不适合桌面」）：**tone-based surface 用「2 个 L∗ 的明度差」编码层级；小面积、两块总是共边、还有 splash/圆角兜底时够用；桌面把这些兜底全去掉、又把**同一个梯级**铺到 3–4 个大面积并列分区上，编码宽度不足就暴露了——问题不在「用 tone」，而在「只用一条梯级、只开一个通道」。官方为大屏准备的正解正是 §4.1 的区域级 add-on 映射（把级差从 2 拉到 7/4），仍属 tone-based。**

---

## 3. 三个可落地修正方案

**共同约束**：不推翻 D3（seed `#E91E63`、primary `#8E4957`、粉调保留）、不改 46 个 hex（方案 B 例外）、Figma Starter 仍是 1 collection = 1 mode（`05-color-directions.md`）、遵守官方「跨断点保持区域颜色映射一致」的建议。

### 3.1 方案 A（推荐骨架）· 桌面 +1 级 hairline 描边

**机制**：不去改色差，而是给每个 pane/容器**加一条局部高频边界**，把「2 个 L∗ 的面差」升级成「面差 + 18 个 L∗ 的边差」。

计算依据（B，本文计算）：`outlineVariant` 与 `surface` 的差是 **ΔL∗ 18.00（Light：98.08→80.08，对比度 1.62）**、**24.12（Dark：5.88→30.00，对比度 1.99）**——**是容器阶梯级差（2）的约 9–12 倍**，但只占 1dp 宽，视觉上读作「边」而不是「块」。这正是官方说的 hairline style。

1dp 这个数值的来源（B，Flutter SDK `packages/flutter/lib/src/material/divider.dart:359-370`，表体带 `BEGIN GENERATED TOKEN PROPERTIES - Divider`，注明 generated from **the Material Design token database**）：

```dart
class _DividerDefaultsM3 extends DividerThemeData {
  const _DividerDefaultsM3(this.context)
      : super(space: 16, thickness: 1.0, indent: 0, endIndent: 0);
  @override Color? get color => Theme.of(context).colorScheme.outlineVariant;
}
```

→ **官方 token 数据库里「分割线 = 1.0dp + outlineVariant」**，所以「1dp + outlineVariant」是 B 级有据，不是拍脑袋。（`MASTER §7` 组件表里 Divider 已经写「与内容相邻一侧 1px outlineVariant」，但**§4.1 的 Number token 里没有 stroke 宽度这一档**，所以本文把它补成 token，见 §5。）

**规则草案**（桌面档 = expanded/large/XL，即 ≥840dp；可选下移到 600）：

| 边界类型 | 处置 | 颜色 | 依据 |
|---|---|---|---|
| 并列 pane 之间（rail ｜ 列表 ｜ 详情 ｜ 辅助面板） | **1dp 描边** | `outlineVariant` | 本文 H1/H4、example.png 的 7.05/3.83 |
| 容器与同级容器之间（卡片列表、分区块） | 1dp 描边（或仅相邻一侧） | `outlineVariant` | 同上 |
| 可点击/可聚焦目标的边界（Chip、输入框、可选卡片） | 1dp 描边（桌面档建议用 `outline` 而非 `outlineVariant`） | `outline` | 官方要求「interactive 边界满足可访问对比度」；`outline` 实测 **4.27 / 5.85 ≥ 3:1**；`outlineVariant` **1.62 / 1.99 < 3:1**（B，计算） |
| 移动端（compact） | **不加**（保持现状） | — | 移动端有小视口/共边/圆角兜底，加线会让列表密度上升 |
| 同 tone 相邻（例如两块都用 surface） | **必须加线** | `outlineVariant` | 否则零边界 |

**对 §2.2 四十六角色表的增量**：**颜色 0 变更、角色 0 新增**；新增 2 个**数值 token**（`stroke/hairline` = 1dp、`stroke/focus` = 2dp，后者 `§7.1` 已有 2px 焦点层，只是没 token 化），并把 `outlineVariant` / `outline` 的**使用范围**从「Divider/Outlined 卡片」扩到「桌面 pane 与容器边界」。

**代价与风险**：
- 线密度上升会「显硬件化」——需要硬规则：**每条边界最多 1 条线，且描边宽度只有 1dp/2dp 两个值**。
- `outlineVariant` 对比度只有 1.62/1.99，在强环境光/低端面板/远程投屏下可能看不见（C）→ 若有此风险，改用 `outline`（4.27/5.85）或用 §3.2 的 b2 加深容器。
- **1px 与 1dp 的表述冲突**：`MASTER §7` 写 1px，Flutter 是 1.0 逻辑像素；在 125%/150% DPI 下「1 物理像素」会消失或变虚。规范里应统一写 **1dp（= 1 逻辑像素）**。
- 描边是**静态**线索，不表达 z 序（浮层仍需方案 C 的阴影），所以 A 必须和 C 一起用。

**证据等级**：机制 **A/B**（官方 hairline 提法 + Flutter token 值），「ΔL∗ 18 是阶梯的 9 倍因而可读」是 **B（计算）+ C（视觉）**。

### 3.2 方案 B（后备）· 拉大 tone 跨度

两种形态，都只针对**亮色**（暗色级差已够，§2.2）。

**b1 · 用官方对比档（B，mcu `ContrastCurve`）**：material-color-utilities 的 `surfaceContainer*` 不是常量，而是 `ContrastCurve(low, normal, medium, high)`（`contrast_curve.dart` 原文：「[low] Value for contrast level -1.0 … [medium] 0.5 … [high] 1.0」），`ColorScheme.fromSeed(contrastLevel:)` 文档也写「medium and high contrast correspond to 0.5 and 1.0」（B，Flutter `color_scheme.dart`）。取出的 tone：

| 档 | lowest | low | container | high | highest | dim | bright |
|---|---:|---:|---:|---:|---:|---:|---:|
| 现状（0.0） | 100 | 96 | 94 | 92 | 90 | 87 | 98 |
| 0.5 | 100 | 96 | **92** | **88** | **84** | **80** | 98 |
| 1.0 | 100 | 95 | **90** | **85** | **80** | **75** | 98 |

**致命缺陷（必须说清）**：`surface` 被钉死在 98、`low` 在 96/95 → **最常用的那一步（页面 → 卡片）永远是 ΔL∗ 2**，无论对比档多高。所以 b1 **不解决主问题**，只加深嵌套深处。

**b2 · 阶梯整体下移一级（C，取现有 tone 为主）**：

| 角色 | 现状 Light | b2 Light | 现状 Dark | b2 Dark |
|---|---|---|---|---|
| surfaceContainerLow | 96 `#FFF0F1` | **94 `#FBEAEB`** | 10 `#22191A` | **12 `#261D1E`** |
| surfaceContainer | 94 `#FBEAEB` | **90 `#F0DEE0`** | 12 `#261D1E` | **17 `#312829`** |
| surfaceContainerHigh | 92 `#F5E4E5` | **87 `#E7D6D7`** | 17 `#312829` | **22 `#3C3233`** |
| surfaceContainerHighest | 90 `#F0DEE0` | **84 ≈ `#E0CDCE`**（需重生成） | 22 `#3C3233` | **26 `#453B3C`** |

- **主用级差从 2.11 变成 4.04**（98.08→94.04），对 surface 对比度 1.05→1.11；其余级差 4/3/3。暗色全部用**既有 tone**（12/17/22/26），零新值。
- **唯一新值**是 Light tone 84：本机按 neutral 调色板在 CIELAB 空间线性插值（11 个已知 tone 为支点，逆变换回 sRGB），得 **≈`#E0CDCE`**，留一交叉验证误差 **≤3/255（Light）**；**最终值必须以 `.scratch/generate_palette.dart` 重新生成为准**（这是计算近似，不是一手值）。
- **踩线警告（B，计算）**：highest 落到 tone 84 后，`outline`（`#847375`）对它的对比度降到 **2.94 < 3:1**，`onSurfaceVariant` 降到 6.14（正文仍安全）。→ b2 若采纳，**可交互边界必须改回 `outlineVariant`+真阴影**，或把 highest 停在 87。
- **官方冲突**：roles 页明确「All color mappings … should remain the same for layout regions across breakpoints」；b2 等于给桌面一套不同的 surface 映射，属于打擦边球（官方允许的是「在大窗口类**增加** add-on surface colors」，不是「换掉主映射」）。
- **成本**：Figma Starter 1 collection = 1 mode → 桌面档只能新建一整套 collection（现有 6 → 12，46 变量 → 92），且 Flutter 侧要两套 `ColorScheme` 按断点切换。
- **感性风险**：tone 越深 chroma 越大（87 档 C∗ 6.24，dark 更低档也在 4.5–4.8），大面积下玫瑰倾向加重，与 D3「surface 保持近中性」的意图拉扯。

**对 §2.2 的增量**：Light 改 5 个 tone（low/container/high/highest/dim，可选）、Dark 改 4 个；**新增的不是 token，而是「桌面档 mode」这套基础设施**。
**证据等级**：机制 **B**（mcu ContrastCurve 原文）、取值 **B/C**、代价与官方冲突 **A（原文）+ C（判断）**。

### 3.3 方案 C（推荐限域使用）· tonal tint + real shadow 双轨

**机制**：承认「层级需要两个通道」，但把两个通道**分工**而不是叠加：**面 = tone（静态层级）**，**边/影 = 真阴影（浮动层级）**；同一块面**永不同时**用 tint 与 container 表达层级。

阴影的量化能力（B，Flutter `packages/flutter/lib/src/material/shadows.dart:43-45`，三个常量正是 `MASTER §4.2` 抄的来源）：

```dart
_kKeyUmbraOpacity     = 0x33000000  // alpha 0.20
_kKeyPenumbraOpacity  = 0x24000000  // alpha 0.14
_kAmbientShadowOpacity= 0x1F000000  // alpha 0.12
```

把黑叠在 `#FFF8F7` 上算（B，计算）：单层 0.20 → L∗ **80.4（−17.7）**；0.14 → 85.8（−12.3）；0.12 → 87.6（−10.5）；三层在**完全重叠点**等效 alpha = 1−(1−0.20)(1−0.14)(1−0.12) = **0.395** → L∗ **62.5（−35.6）**。⚠️ 这是**上界**：三层偏移不同（如 level3 是 (0,3)+blur3 / (0,3)+blur4 / (0,1)+blur8），实际最暗像素达不到 −35.6，但**边缘 1–3dp 范围内的局部压暗仍远大于容器级差 2**——这就是「阴影能表达容器阶梯表达不了的 z 序」的数学原因（也解释了官方那句「Shadows can express the degree of elevation between surfaces in ways that other techniques can't」）。

**规则草案（与 `MASTER §4.2` 的 `elevation/level0–5` Effect Style 一一对齐）**：

| 层级 | dp | Effect Style | 桌面档用途 | tint |
|---|---:|---|---|---|
| level0 | 0 | `elevation/level0` | 页面底、pane 底（静止） | 不叠 |
| level1 | 1 | `elevation/level1` | 卡片静止（可选用 1dp 阴影替代描边） | 不叠 |
| level2 | 3 | `elevation/level2` | Menu / Popover / Dropdown / 拖拽中 | 不叠 |
| level3 | 6 | `elevation/level3` | Dialog / FAB / 悬浮工具条 | 不叠 |
| level4 | 8 | `elevation/level4` | hover 抬升（FAB hover、可拖起卡片） | 不叠 |
| level5 | 12 | `elevation/level5` | Modal / 拖拽峰值 | 不叠（scrim 32% 代替） |

即：**静止容器（pane/card/list）用 level0–1，且靠「tone + hairline」；真浮层用 level2–5，且靠「阴影 + containerHigh」**；**tint 全面关闭**（`applySurfaceTint = false`，含 AppBar 的 `scrolledUnderElevation` —— 需要显式传 `surfaceTintColor: Colors.transparent`，因为 Flutter 默认仍会叠）。

**对 §2.2 的增量**：**颜色 0 变更、角色 0 新增、数值 token 0 新增**；变更的是 `MASTER §2.3` 的规则句（「不要再拿 elevation 阴影表达层级」→「静止容器不用阴影；真浮层用阴影，且不与 tint 叠加」）与 `§4.2` 的定位（1:1 映射只对浮层成立）。
**代价与风险**：① 与 `MASTER §2.3` 现有明文冲突，需要主会话确认改口（决策级改动）；② Windows/macOS 桌面阴影观感偏「Web 卡片」，大面积使用时比移动端更显廉价（C）；③ 滚动/动画重绘成本高于纯色（B/C，Flutter 侧是 `BoxShadow` 列表，静态无成本、动画时有）。
**证据等级**：官方阴影用途 **A**、阴影数值 **B**、桌面适用性 **C**。

### 3.4 优劣矩阵

| 维度 | A · hairline 描边 | B · 拉大 tone | C · 限域阴影 |
|---|---|---|---|
| 解决「并列分区读不出」 | **强**（边差 18 L∗） | 中（面差 4 L∗） | 弱（阴影不适合 pane 边界） |
| 解决「浮层没有 z 序」 | 弱 | 无 | **强**（−10…−35 L∗） |
| 改 46 个 hex | **0** | **Light 5 个 / Dark 4 个** | **0** |
| 新增 token | 2 个数值 | 0（但要一整套 mode） | 0（规则变更） |
| 移动端副作用 | 无（断点 gating） | **有**（若全局生效移动端也变深） | 无（浮层本就两侧都要） |
| 官方依据 | A（hairline）+ B（1dp token） | B（对比档）/ C（手工下移） | A（阴影用途）+ B（数值） |
| 与官方「跨断点映射一致」冲突 | 无 | **有（b2）** | 无 |
| Figma 成本 | 极低（Stroke/Effect 样式） | **高（collection 翻倍）** | 低（已有 level0–5） |
| 风险 | 线密度、1.62 对比度可能偏弱 | 粉感加重、官方冲突、双份维护 | 与 §2.3 明文冲突、观感 |

---

## 4. 推荐方案与理由

**推荐：A（hairline 描边）作为层级骨架 ＋ C 的限域版（只有真浮层上 level2–5 真阴影）＋ tint 彻底关闭；B 只作为「实机验证后仍读不出」的后备升级（且只上 b2 的前 3 档：low 94 / container 90 / high 87，不动 highest，避免踩 2.94 那条线）。**

六条理由：

1. **它修的是「通道不足」这个真因**：A 给 18 个 L∗ 的边差，把「1.05：1 的看不见」变成「1.62：1 + 一条 1dp 硬边」。B 只把面差从 2 提到 4，**仍然到不了 3:1**（4 个 L∗ 约 1.11）。
2. **零改色、零新增角色**：完全不碰 D3 与 46 个 hex，Figma 侧只加 Stroke 样式与 Effect 使用规则，Starter 的 mode 限制不咬人。
3. **符合官方口径**：官方自己点名 hairline style、要求「interactive 边界满足可访问对比度」、建议「跨断点保持区域颜色映射一致」。A 只改**装饰**不改**映射**，三条全过；b2 恰好在第三条上打擦边球。
4. **能同时表达两种层级**：A 管「并列分区」，C 管「浮层层级（z）」，分工不重叠——这正是 `example.png` 里真实产品的用法（zone 用大面差/边界，卡片用圆角+阴影）。
5. **可回退、可增量**：线密度是「加一条/减一条」的开关；B 一旦上了桌面 mode 就退回不了（要维护两套 collection）。
6. **风险可测**：A 的唯一未知是 `outlineVariant` 1.62 在实机上够不够（见 §6），这是「看一眼就知道」的问题，不需要行为实验。

> **上述六条理由的定位已调整**：它们原本用来论证 A 是「骨架」。第 7 条证据（下文 §4.1 与 `09-desktop-layout-reference.md` §3.4）显示，官方自己的桌面产品（Google Chat 改版）在 1440 宽下就是 **纯 tone、零 hairline**，靠的正是 **7.05 / 3.83** 的面差；也就是说「面差从 2 提到 7」之后，1.62:1 的 hairline 不再是必需品。因此 A 从「骨架」降为「**第二通道/保险丝**」：默认不加线，只在下列三种情况叠加——① 两个面板必须同 tone（无法靠映射拉开）；② 高环境光 / 低端面板 / 远程投屏；③ 需要一条「可交互边界」（此时用 `outline` 4.27/5.85，而不是 `outlineVariant` 1.62/1.99）。
>
> 这条调整**不削弱** A 的论证价值：B 的 b2 仍被否决，A 的 token 增量（`stroke/hairline` 1dp）仍建议建，只是**默认关闭**。

**对移动端有没有副作用**：
- **A**：规则按断点 gating（≥840 生效），**移动端零变化**。若不做 gating 而全平台加线，移动端列表会变密、卡片会显得「硬」，观感退步（低风险但需看图）。
- **C**：移动端本来就该有浮层阴影（Reader 的浮动面板已如此，`MASTER §7⟧），规范里写成「浮层 = 阴影」不改变移动端现状；**唯一行为变化是显式关掉 AppBar 的 tint**（当前滚动时有 5–11% 的粉层），这在移动端也是**改善**。
- **B**：若做成「全局换色」会直接改移动端观感（容器更深、更粉）；做成「桌面档 mode」则移动端不变，但工程与 Figma 双份维护成本翻倍。

### 4.1 主通道具体取值：区域级 add-on surface 映射

**亮色（chrome 往暗走）**

| 区域 | 角色 | hex | L\* | 与相邻区级差 |
|---|---|---|---:|---:|
| 导航 rail | `surfaceDim` | `#E7D6D7` | 87.0 | rail→面板 **7.0** |
| 导航列表 · supporting pane | `surfaceContainer` | `#FBEAEB` | 94.0 | 面板→内容 **4.0** |
| 主内容 | `surface` | `#FFF8F7` | 98.1 | — |
| 面板内卡片 | `surfaceContainerLow` | `#FFF0F1` | 96.0 | 对所属面板 2.0 |
| 主内容浮起卡片 | `surfaceContainerLowest` | `#FFFFFF` | 100.0 | 对主内容 1.9 |

**暗色（chrome 往亮走——暗色没有更暗的 chrome，`surfaceDim` 在暗色等于 `surface`）**

| 区域 | 角色 | hex | L\* | 与相邻区级差 |
|---|---|---|---:|---:|
| 导航 rail | `surfaceContainerHighest` | `#3C3233` | 21.9 | 面板 **10.0** |
| 导航列表 · supporting pane | `surfaceContainer` | `#261D1E` | 11.9 | 内容 **6.0** |
| 主内容 | `surface` | `#191112` | 5.9 | — |
| 面板内卡片 | `surfaceContainerHigh` | `#312829` | 17.1 | 对所属面板 5.3 |

- **官方口径合规**：roles 页原文「`All color mappings (i.e. surface container, primary, secondary) should remain the same for layout regions across breakpoints`」+「you can use add-on surface colors in larger window class sizes」⇒ 这是「**大窗口追加区域角色**」，不是「换掉主映射」；但必须补一条**跨断点一致性**：同一个 region 只要存在，就始终用它同一个角色（例如 rail 在 medium 80 与 large 80 都是 `surfaceDim`），不能在 1199/1200 处换色。
- **与参考位对齐**：`design-system/example.png` 实测并列面板级差 **7.05 / 3.83**、**无任何 hairline**（B）——与上表 7.0 / 4.0 同量级。这是「纯 tone 够用」的唯一实证。
- **与 `MASTER §2.6` 一致**：该表已按此映射写入；Figma 侧下一轮把 `41:2384`（XL）与 `41:1578`（Large）的 pane 填充按此重绑变量，组件库卡片角色不变。

---

## 5. 需要改的 token 清单

「现状」列取自 `MASTER.md §2.2/§4.1/§4.2` 与 `.scratch/palette.json`（一致）。**推荐方案（A + C 限域）只动前 6 行；后 3 行是方案 B 的可选增量，未采纳前不落地。**

| # | token 名 | 现状 Light | 现状 Dark | 建议 Light | 建议 Dark | 是否新增 | 影响哪些组件 |
|---|---|---|---|---|---|---|---|
| 1 | `stroke/hairline` | 无（只有 `§7` 里「1px」的散落写法） | 同 | **1dp** | **1dp** | **是（数值 token）** | Divider、Card(outlined/elevated 边)、AppBar 底边、pane 边界、Menu/Popover 边框、List 分隔 |
| 2 | `stroke/focus` | 2px（`§7.1` 已用，未 token 化） | 同 | **2dp**（固化） | **2dp** | **是（数值 token）** | 所有可聚焦控件：Button/Chip/TextField/ListTile/卡片选中态 |
| 3 | `color/outlineVariant` | `#D6C2C3`（L∗ 80.08，1.62） | `#524345`（L∗ 30.00，1.99） | **值不变，扩用**：桌面 pane/容器 hairline 主色 | 同 | 否 | Divider、Card outlined、桌面 pane 边界、List 分隔 |
| 4 | `color/outline` | `#847375`（4.27） | `#9F8C8E`（5.85） | **值不变，扩用**：桌面「可交互边界」用色（≥3:1） | 同 | 否 | Chip、TextField、可点击卡片/容器边界、聚焦环 |
| 5 | `elevation/level0–5`（Effect Style 引用） | 仅 Figma 有 3 层阴影（0.20/0.14/0.12） | 同 | **规则变更**：level0–1 只给静止容器（pane/card/list），level2–5 只给真浮层 | 同 | 否（Effect Style 已存在） | Dialog、Menu、Popover、Dropdown、Tooltip、FAB、拖拽、Modal |
| 6 | `color/surface` / `surfaceContainerLow/Lowest/Container/High/Highest` / `surfaceDim` / `surfaceBright` | 现值（§2.2） | 现值 | **不变** | **不变** | 否 | 全部（「不变」的意思是：本轮不靠改它们解决问题） |
| 7 | （方案 B 可选）`surfaceContainerLow/Container/High` | 96 / 94 / 92 | 10 / 12 / 17 | **94 / 90 / 87**（桌面档 b2，需重生成 hex） | **12 / 17 / 22** | 否（值变更 + 需「桌面档」mode） | 全部 pane 与容器 |
| 8 | （方案 B 可选）`surfaceContainerHighest` / `surfaceDim` | 90 / 87 | 22 / 6 | **84（≈`#E0CDCE`，计算近似）/ 80** | 26 / **不变** | 否（同上） | 高强调容器；`surfaceDim` 桌面底 |
| 9 | （可选新色）`color/borderStrong` | 无 | 无 | tone ≈ **60**（3:1 所需，hex 待生成） | tone ≈ **41**（3:1，待生成） | **是（新色角色）** | 仅当 `outlineVariant` 1.62 实机不够时，替代 hairline 主色 |

**统计（推荐方案）**：**新增 2 个 token（均为数值，其中 `stroke/hairline` 默认关闭）＋ 扩用 2 个既有颜色角色（值不变）＋ 2 条规则变更（阴影使用范围；§4.1 区域级映射）；颜色角色新增 0、颜色值变更 0。**

**已落地（2026-10-23，B）：桌面区域别名层。** §4.1 的区域映射没有写进任何 hex，而是在 `Theme/A · Light` / `Theme/A · Dark` 各加 5 个**别名变量** `color/desktop/{window,pane,paneHeader,card,field}`（Light `71:884`–`71:888` / Dark `71:889`–`71:893`），另加数值 `radius/pane` = 20（`71:894`）。Light：window→`surfaceContainerHigh`、pane→`surface`、paneHeader/card→`surfaceContainerLow`、field→`surfaceContainerLowest`；Dark：window→`surfaceContainerLowest`、pane→`surfaceContainer`、paneHeader/card→`surfaceContainerHigh`、field→`surfaceContainerHighest`。这样做的依据是官方那条「同一 region 跨断点必须同角色」（A，见 §1.6 引文），别名层保证换主题时整体跟随，46 角色一个不动。 若实机验证后仍偏平，再启用第 7/8 行（Light 改 5 个 tone、Dark 改 4 个）+ 可能第 9 行。

**为什么 `borderStrong` 的 tone 是 60/41**（B，计算，写出来以便复核）：要让某个边界色对 `surface` 达到 3:1，解 `(Ysurf+0.05)/(Yb+0.05)=3`：
- Light：`Y(#FFF8F7)=0.95110` → `Yb=(0.95110+0.05)/3−0.05=0.28370` → `L∗=60.22`；
- Dark：`Y(#191112)=0.00651` → `Yb=3×(0.00651+0.05)−0.05=0.11953` → `L∗=41.14`（暗色方向取更亮者）。
即：**亮色要一条「能当边界的线」至少要 tone 60，而现有 `outlineVariant`(80) 与 `outline`(50) 之间是空的**——这就是 A 方案在极端环境下可能偏弱的根源，也是预留第 9 行的原因。

---

## 6. 剩余未决项（需要 Flutter 实机看效果才能定）

| # | 未决项 | 怎么验证 | 如果不对怎么办 |
|---|---|---|---|
| 1 | `outlineVariant`（1.62 / 1.99）在真实办公环境光与低端屏上够不够读作「边界」 | 桌面实机（≥1440）、亮/暗两主题、正午窗边光与夜间各看一次，同时开 100%/125%/150% 缩放 | 改 `outline`（4.27/5.85，但偏重）；或按第 9 行新增 `borderStrong`（tone 60/41） |
| 2 | 1dp 在 DPR 1.25/1.5 下的实际观感（会不会虚成 2px 灰边） | Windows 125%/150% 缩放下截图对比（**只看不入库**） | 规范改「1dp 逻辑像素，禁止写成 1 物理像素」；必要时允许局部例外 |
| 3 | 是否要给移动端也上 hairline | 手机上看加线/不加线的列表密度 | 保持断点 gating（默认建议不加） |
| 4 | 阴影上到 level2–5 后是否与 Windows 11 系统窗口层次打架 | 桌面实机开 Dialog/Menu/FAB，与系统对话框并排看 | 降一档（level2 用 2dp）或只给 Modal/Menu |
| 5 | `AppBar.scrolledUnderElevation` 的 tint 是否必须显式关闭 | 滚动到 tint 生效后看 AppBar 是否发粉（当前会） | 显式 `surfaceTintColor: Colors.transparent`（与 `MASTER §4.4` 的 NoSplash 同思路） |
| 6 | 桌面 hover 的 8% primary state layer 是否要降到 5%（H6） | 大卡片/整行 hover 时看是否「整块降一级 + 变粉」 | 桌面档 hover 降为 5%，保持移动端 8% |
| 7 | rail / 列表 / 详情三区到底谁用哪一档（现状 `§4.2` 的 1:1 映射在桌面上会撞车） | 按 `07-supporting-pane.md⟧ 的三栏稿在实机比对 | 若采用「三区重映射」思路（rail=`surfaceDim`，ΔL∗ 7.0），需先解决 rail 变粉；宁可 A 方案先上 |
| 8 | 方案 B 是否真的需要（还是 A+C 已够） | A+C 落地后重看「三栏是否还平」 | 只上 b2 前三档（94/90/87），绝不动 `surfaceContainerHighest`（否则 `outline` 掉到 2.94） |
| 9 | `background/onBackground/surfaceVariant` 是否从 `.scratch/generate_palette.dart` 的生成范围里移除 | 读脚本与 `palette.json` 的 46 key | 移除并记入 `05-color-directions.md` 备注 |
| 10 | 感知阈值本身没有一手标准 | 需要 5–8 人快速辨色测试（ΔL∗ 2 / 4 / 7 三档） | 测试前所有「够不够看」的结论一律标 C |

---

## 附录 A · 复现方法

**重新生成 46 角色（一手，B 级）**：

```
E:\flutter sdk\flutter\bin\cache\dart-sdk\bin\dart.exe --packages='E:\projects\hentai_library\app\.dart_tool\package_config.json' 'E:\projects\hentai_library\.scratch\generate_palette.dart'
```

（读 `.scratch/palette.json` 注意编码：UTF-16LE，BOM `FF FE`，需 `buf.slice(2).toString("utf16le")`。）

**本文数值的计算流程（可逐条复核）**：
1. 取 `MASTER.md §2.2` 的 hex → sRGB → 线性化 → `Y`；
2. `L∗/a∗/b∗`（D65）→ 与官方 tone 校验（误差 ≤0.15，见 §2.0）；
3. 相邻档 `ΔL∗`、`ΔE76`、对比度 `(Yhi+0.05)/(Ylo+0.05)`（§2.1/§2.2）；
4. tint 用 `alphaBlend(primary, surface, a)` 复算六个等级（§2.3）；
5. 阴影上界用 `1−Π(1−α)` 与「黑色按 α 叠加到 `#FFF8F7`」估算（§3.3，明确标注为上界）；
6. 新 tone 值（如 84）用 neutral 调色板 11 个已知 tone 在 CIELAB 空间按 L∗ 分段线性插值 a∗/b∗ 再逆变换，留一验证误差 ≤3/255 —— **属计算近似，最终以脚本重生成值为准**。

---

## 附录 B · 来源清单与降级声明

**A 级（官方原文，本次抓取成功）**

| 内容 | URL |
|---|---|
| tone-based surface 的引入、五容器、与 elevation 解绑、迁移映射、「为大屏更多弹性」、tone 99→98 / chroma 4→6 / 暗色变暗、两套模型共存 | https://m3.material.io/blog/tone-based-surface-color-m3 |
| elevation 六档、resting 0–3 / hover-dragged +4+5、tonal vs 阴影、hairline style、边界须满足可访问对比度、containers 与 elevation 解绑、scrim 32%、less is more | https://m3.material.io/styles/elevation/applying-elevation |
| 「Tokens have no shadows or color」、elevation 可用 tonal 或 shadow、不改变组件默认 elevation、FAB/按钮 hover +1 级 | https://m3.material.io/styles/elevation/overview |
| 26 个标准角色 / 六组、3:1 配对、Surface/Container/On/Variant 术语、五容器与 expanded 布局、surface dim/bright 定义、跨断点映射一致、大窗口类可用 add-on | https://m3.material.io/styles/color/roles |

**B 级（官方实现源码 / 本仓库一手材料）**

| 内容 | 位置 |
|---|---|
| tone-based 取代 opacity 模型、五容器注释、`surfaceTint ?? primary`、`background` 弃用 v3.18、`fromSeed(contrastLevel)` 语义、tonalSpot 默认 | Flutter SDK `packages/flutter/lib/src/material/color_scheme.dart`（约 101-102 / 1260-1262 行及各 getter 注释） |
| tint 表 0/0.05/0.08/0.11/0.12/0.14 与 `alphaBlend` 实现 | Flutter SDK `packages/flutter/lib/src/material/elevation_overlay.dart` |
| `surfaceTintColor` 语义、useMaterial3 分支 | Flutter SDK `packages/flutter/lib/src/material/material.dart`（约 511-518 行） |
| M3 `CardDefaults.surfaceTintColor = Colors.transparent`（默认不叠 tint） | Flutter SDK `packages/flutter/lib/src/material/card.dart` |
| AppBar 仍传 `colorScheme.surfaceTint`（scrolledUnderElevation 例外） | Flutter SDK `packages/flutter/lib/src/material/app_bar.dart:1233-1240` |
| **Divider = 1.0dp + `outlineVariant`（generated from the Material Design token database）** | Flutter SDK `packages/flutter/lib/src/material/divider.dart:359-370` |
| 阴影三层常量 0.20 / 0.14 / 0.12 与 level1/2/3/4/6/8 的 offset/blur | Flutter SDK `packages/flutter/lib/src/material/shadows.dart:43-45` 起 |
| `surfaceContainer*` / `SurfaceTint = Primary` / `On*Container = Primary10` 等 tone 分配（`// VERSION: v0_210`） | `androidx/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ColorLightTokens.kt`、`ColorDarkTokens.kt` |
| `ContrastCurve(low, normal, medium, high)` 与 -1/0/0.5/1 的对应；tonalSpot chroma（primary 36 / neutral 6 / neutralVariant 8）；surface 固定 98/6 | `material_color_utilities-0.11.1/lib/dynamiccolor/{contrast_curve.dart,material_dynamic_colors.dart}`、`scheme/scheme_tonal_spot.dart` |
| 46 角色 hex、§2.3 用法规则、§4.1/§4.2 elevation 与阴影、§7 组件映射、§7.1 焦点层 | `design-system/hentai-library/MASTER.md` |
| 真实产品分区级差（本次复核：`#F8FAF0`/`#EDEFE5`/`#F3F5EB`/`#D9DBD1` 像素计数与 L∗） | `design-system/example.png`（**只读**，2048×1440；本文未写入任何位图） |

**降级声明（必须显式）**

1. **`/styles/color/system/overview` 抓取失败**（返回空正文，JS 渲染）。该页本应提供「颜色系统总览 + surface 与 elevation 关系」的规范原文 → 本条**降级为 A 级替代源**（官方博文 + roles 页）与 **B 级实现源码**（Compose/Flutter token 表）。本文**没有**从该页引用任何数值。
2. **桌面/大屏专属的颜色指引页抓取失败**：`/foundations/layout/applying-layout/window-size-classes`、`/foundations/large-screen-apps/overview`、`/m3/pages/breakpoints/expanded` 均返回空正文；`/foundations/layout/breakpoints/overview` 可读但**不含颜色内容**。→ 「桌面该怎么用 surface」的结论**降级为 A（roles 页的 expanded 段落）+ B（实现）+ C（工程判断）**。
3. **「1dp」这个宽度没有官方条文**：`applying-elevation` 只提到「the hairline style」，未给宽度/token。→ **1dp 降级为 B 级**（Flutter `_DividerDefaultsM3.thickness = 1.0`，generated from the Material Design token database）+ C（与 Figma 1px 表述的对齐）。
4. **「tone 99 → 98」「chroma 4 → 6」有 A 级原文**（官方博文），故 `surface = Neutral98/6` 属 **A**；**「3.22 起三角色弃用」与「3.27 起 4 个 `on*Container` Tone10→Tone30」同样有 A 级原文**（docs.flutter.dev 的 `new-color-scheme-roles` / `material-design-3-token-update` 两页，见 §1.5）。Compose / mcu 的 Tone10 属实现滞后，不构成反证。
5. **「桌面读不清」这个因果判断是 C**：级差/对比度/C∗/叠加效果都是 B（可复算），但「多大级差才算看得清」没有任何一手标准（官方只给可访问对比度，不给分区级差）→ 需要 5–8 人辨色测试才能升到规范级（见 §6-10）。
6. **`raw.githubusercontent.com` 直连不可用**（`web_fetch` 报 non-public IP），Compose/mcu 源码经 `read_page` 桥取回；`material-web` 的 `tokens/versions/v0_192` 路径本次未能取到，故 **surface-tint 在 material-web 的保留情况沿用 `01-foundations.md⟧ 的既有记录（B）**，本文未独立复核。
7. **`design-system/example.png` 的采样是 B 级旁证**，不是规范依据；本轮只读，未产生任何位图/截图工件。
