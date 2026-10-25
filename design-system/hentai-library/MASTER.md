# Hentai Library · Material 3 设计系统（MASTER）

> 状态：**Figma 设计稿阶段完成，待评审**。本文件是设计系统的唯一规划入口；颜色方向 A 已定（亮/暗预览）、44 个 Number token、30 个 Text Style、6 个 Effect Style、5 个 Grid Style、01–04 文档页已建；05 已建齐 P0 原子组件集（Button / IconButton / TextField / SearchBar / TopAppBar / Snackbar / NavigationBar / NavigationRail / FAB / FilterChip / ListItem / Card / Dialog），06 有 8 个业务组件，07 五档模板齐全，08 首页与阅读器四档出图、Settings 与 History 各两档，09 States & Content Lab（含文字缩放样例）、10 Motion、11 Handoff & A11y 已建成。导航组件已按 2025-05 官方 rail 规范改版（menu 切换、active indicator 贴合内容、active 图标 filled）。代码未迁移。
> 代码未迁移：`app/` 仍是旧 Fluent 取向的主题与页面。设计稿评审通过后才改代码（见 §8）。
> 证据底稿：`design-system/research/material-design-3/`（01 基础、02 组件、03 Flutter 实现、04 Figma 工作流、05 粉色方向、06 自适应布局）。规范数值若与本文件冲突，先查底稿的证据级别（A 官方规范 / B 官方实现源码 / C 推断）。

## Directory charter

`design-system/` 的职责边界（ADR-0029 修订后仍适用）：

| 路径 | 角色 | 是否规范来源 |
|---|---|---|
| `design-system/hentai-library/MASTER.md` | 设计系统总纲：决策、token、组件清单、Figma 页面图、代码映射 | **是**（语义与用法） |
| `design-system/hentai-library/pages/[page-name].md` | 每条路由的版式与状态说明（待重建） | 是（页面级） |
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
| D3 | 品牌色 | **A · 柔和玫瑰**：`#E91E63` + `tonalSpot` | 46 角色见 §2；B/C 变量与预览移至 `12 Archive & Scratch` 作备选 |
| D4 | 状态反馈 | **恢复 M3 state layer；splash 按平台**：移动端开启，桌面端关闭 | hover 8% / focus 12% / pressed 12% / dragged 16%；桌面用 state layer 代替 splash。细节见 §4.4；代码暂不动 |
| D7 | 首批设计稿 | **主壳 + 首页 + 书库 + 阅读器** | 1440×900 主稿，1024×768 验接缝，600×800 验紧凑；按此顺序评审 |
| D8 | 图标集 | **Material Symbols** | outlined 为默认，selected/激活用 filled；`04 Icons & Assets` 按此建，代码迁移时替换 `lucide_icons_flutter` |
| D5 | Expressive | **排除**（按调研建议；用户未反对） | Flutter 无官方支持（flutter/flutter#168813 仍 Open）；官方 Figma kit 已 Expressive 化，因此自建库 |
| D6 | 建库方式 | **混合**：手工定结构 + figwright 批量写节点 | 结构、命名、页面分工手工决定；重复节点用脚本 |
| — | 交付顺序 | **先 Figma 设计稿，定稿后才改代码** | 用户明确要求；代码迁移不在本轮 |

D1–D8 已全部拍板；设计侧进入组件集与首批页面。代码仍按约定等设计稿定稿后再动。

## 2. 颜色

### 2.1 生成方式

- seed `#E91E63`，scheme variant `tonalSpot`（即 Flutter `ColorScheme.fromSeed` 默认），由 **`material_color_utilities 0.13.0`**（与 `app/pubspec.lock`）的 `MaterialDynamicColors` 生成。§2.2 十六进制表仍来自 0.11 时代脚本输出；若与 0.13 生成结果不一致，用 `.scratch/generate_palette.dart` 重算并对照 `app/lib/shared/ui/theme/`（Issue #332 / 视觉回归）。
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
- **桌面区域取色（large / XL，≥1200dp；官方「大窗口 add-on surface colors」，A）**：窗口底与导航 rail **同色** `surfaceContainerLow`（96.0；暗色 `surfaceContainerLow` #22191A 9.9）；pane（列表 / 详情 / 设置内容）**`surfaceContainerLowest`（100.0，纯白）**；pane 内顶栏条 `surface`（98.1），卡片与列表行 `surfaceContainerLow`（96.0）；search bar / 输入类 `surfaceContainerHigh`（官方 search 明确 `surface container high`，A）。**46 个 hex 一个不改**，全部直接绑 `01 Tokens` 的 46 角色（不建 `color/desktop/*` 分类）。**同一个 region 在它所存在的所有断点用同一角色**（官方「跨断点保持映射一致」，A）。相邻级差：rail→pane **4.03**（T2 下限）、pane→卡片 4.03、顶栏条对 pane 1.93（嵌套条不计入 T2）。
  - **适用范围（2026-10-23 收敛，此前写宽了）**：这条只约束**区域级并列面板**之间的分隔——窗口底 / rail / 导航列表 / pane / 详情列之间靠「角色级差 + 24dp 画布缝」，不加 1dp 线、不加投影。它**不是**「所有容器一律无阴影」：组件各按自己的官方 specs——search bar 官方明写 `Lower elevation and no shadow by default`（A）；FAB / Dialog / Menu / Snackbar 一类浮层按官方 elevation token 允许阴影（A）。原先把这句写成跨全部容器的桌面硬规则是我的外推（C），用户本意也只是「pane、NavigationRail 这些**区域**用背景色区分而不是边框」。
- **tonal elevation 与 pane 互斥**：pane 级容器一律不叠 surfaceTint（`applySurfaceTint = false`）；tonal elevation 只留移动端组件级反馈与桌面浮层（menu / dialog / side sheet）。
- **桌面口径（硬，评审按此判定；完整版见 `08` §0.0）**：**T1 结构**——≥1200dp 的并列 pane 必须显式按区域取角色（窗口/rail `surfaceContainer` / pane 与内容 `surface` / 顶栏条与卡片 `surfaceContainerLow`），以「区域」为参数而非以组件为参数；**T2 阈值**——相邻并列区域 ΔL\* 亮色 **< 4**、暗色 **< 6** 时必须叠 1dp `outlineVariant` 或提一档角色，**2 个 L\* 的档差不算分隔**；**T3 边界**——46 个 hex 不改、只新增 `stroke/hairline` 1dp 与 `stroke/focus` 2dp、阴影只给浮层 level 2–5 且 tint 全关、不回退 elevation-tint。桌面底板 `#EAE8E6` 是画布层，**不在 46 角色内**。
- **桌面窗口与 pane 取色（用户偏好 B 级，2026-10-23 深夜最终）**：chrome = 窗口底 **= rail = NavigationBar = `surfaceContainerLow`**（`#FFF0F1`，L\* 96.0，暗色 `#22191A` 9.9）；pane = **`surfaceContainerLowest`**（`#FFFFFF`，100.0，纯白）；pane 顶栏条 = `surface`（`#FFF8F7`，98.1）；卡片 / 列表行 / 分组卡 = `surfaceContainerLow`（96.0）；search bar / 输入类 = `surfaceContainerHigh`（`#F5E4E5`，91.9，官方 search A）。**pane 之间与 pane 右/下缘留 24dp 窗口底色缝**（B，参考图 18px 间隙即此手法），边界由「pane 比 chrome 高 4.03 + 24dp 缝」共同给出；compact 全出血、pane 直接 `surface`。演进：`surfaceContainerHigh`(91.9) → `surfaceDim`(87.0)「太暗」→ `surfaceContainer`(94.0) → 现 `surfaceContainerLow`(96.0) + pane 纯白（用户「背景色大多偏亮」，2026-10-23 深夜）。顶栏条对 pane 只有 1.93，属嵌套条，靠 56 高与内容基线区分。

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
- 预览只用于色彩评审，不是首页版式交付。仓库不存截图，直接在 Figma 看节点 `13:578`。

- **桌面区域取色（2026-10-23 改为直接绑 46 角色，B）**：**不建 `color/desktop/*` 这类新色彩分类**，模板/页面里的区域填充直接绑定 `Theme/A · Light`（暗色绑 `Theme/A · Dark`）的角色变量。`01 Tokens` 的 6 个 collection 仍是唯一色彩来源；看变量面板就知道每个区域用了哪个角色，切主题自动跟随。唯一新增的是数值 token `radius/pane` = 20（`71:894`，§4.1）。

| 区域 | 亮色角色（变量 id，L\*） | 暗色角色（变量 id，L\*） | 说明 |
|---|---|---|---|
| 窗口底（帧底）/ pane 间隙 | **与 rail 同色**：`surfaceContainerLow` #FFF0F1 (`10:56`, 96.0) | `surfaceContainerLow` #22191A (9.9) | 2026-10-23 用户定「窗口底色就用 NavigationRail 的背景色」；当晚再按「背景色大多偏亮」提亮一级（`surfaceContainer` 94.0 → 本档 96.0） |
| 导航 rail **与 NavigationBar** | `surfaceContainerLow` #FFF0F1 (`10:56`, 96.0) | `surfaceContainerLow` #22191A (9.9) | **两者共用同一角色**（2026-10-23 定）；与 pane（100.0）差 **4.03** |
| 内容 pane（列表 / 详情 / 设置内容） | `surfaceContainerLowest` #FFFFFF (`10:55`, 100.0) | `surfaceContainerHigh` #312829 (17.1) | 最亮面（纯白），承载正文；2026-10-23 深夜由 `surface` 98.1 提亮一级 |
| pane 顶栏条 | `surface` #FFF8F7 (`10:51`, 98.1) | `surface` #191112 (5.9) | 嵌套条，与 pane 差 1.9（**嵌套不计入 T2**，靠 56 高与内容对齐区分） |
| 分组卡 / 列表行 | `surfaceContainerLow` #FFF0F1 (`10:56`, 96.0) | `surfaceContainerLow` #22191A (9.9) | 与 pane 差 **4.03**（满足 T2） |
| 搜索框 / 输入类 | **`surfaceContainerHigh`** #F5E4E5 (`10:58`, 91.9) | `surfaceContainerHigh` #312829 (17.1) | 官方 search 明确 `surface container high`（A）；与 chrome 96.0 差 4.04，与 pane 100.0 差 8.1 |
| 浮层（menu / dialog / 浮起卡） | 按各自官方 specs | 同左 | menu 用 `surfaceContainer`、dialog 用 `surfaceContainerHigh` 一类，**允许 elevation 阴影**；不套用「区域级不加阴影」 |
| 桌面标题栏 | 与窗口/rail 同色 `surfaceContainerLow` | 同左 | **64 高**（2026-10-23 两次加高后定稿：搜索 40 → y=12 上下各 12、窗控 32 居中 y=16），控件直接浮在窗口色上，不设分隔线、不设独立底色；menu 归属 NavigationRail（中心 = 标题栏中线 32） |
| 全局搜索框 | `surfaceContainerHigh` #F5E4E5 (`10:58`, 91.9) | `surfaceContainerHigh` #312829 | 720×40 / r20；左缘 = pane 左缘，不用页内搜索 |
| 窗口按钮 | 图标 `onSurfaceVariant` (`10:60`)；关闭 hover 底 `errorContainer` (`10:49`) + 图标 `onErrorContainer` (`10:50`) | 暗色对应 `10:107` / `10:96` / `10:97` | 32×32 圆形；hover `onSurface` 8%、pressed 12%；无描边无阴影 |

- **暗色模式不做 Figma 设计稿（2026-10-23 用户定）**：Figma 侧只保留 `Theme/A · Dark` 的 46 个角色值与 `01 Tokens` 的 A Dark 预览作为**色彩约定**，不再产出暗色页面 / 组件样张（已删 `SearchBar · Dark` 样张）；暗色主题在**代码层**按这套值实现（Flutter `ColorScheme.dark`）。评审只看亮色稿，暗色按 token 对照验收。
- 已清理：此前的 `color/desktop/{window,pane,paneHeader,card,field,rail}` 12 个别名变量（Light `71:884`–`71:888` + `75:1683`、Dark `71:889`–`71:893` + `75:1684`）**已全部删除**；86 处填充改为直接绑上表角色变量（07/08 共 19 帧底、25 个 pane、9 条顶栏、19 个 rail 实例 + 8 个 rail 变体），无 `color/desktop` 残留。`#EAE8E6` 画布底板仍未升 token（§9 第 12 条）。

**命名对照（按官方博文 Introduction to tone-based surfaces 的角色名，A；本仓库一律用其 camelCase）**

| 官方角色名（博文原文） | 本仓库变量 | 桌面用途 |
|---|---|---|
| Surface Container Lowest | `color/surfaceContainerLowest` | **内容 pane（纯白）**；浮起卡 |
| Surface Container Low | `color/surfaceContainerLow` | **窗口底 / rail / NavigationBar**（2026-10-23 深夜提亮后）、分组卡、列表行 |
| Surface Container | `color/surfaceContainer` | 旧版 pane 底色（已由 Lowest 取代）；supporting pane 备用位 |
| Surface Container High | `color/surfaceContainerHigh` | **search bar / 输入类**（官方 A）；暗色 pane 与 rail |
| Surface Container Highest | `color/surfaceContainerHighest` | 暗色抽屉 / 最高强调容器 |
| Surface Dim | `color/surfaceDim` | 当前**不用于**桌面窗口（窗口与 rail 同色）；备用更暗层 |
| Surface | `color/surface` | **pane 顶栏条**（嵌套于 pane 之上） |
| Surface Bright | `color/surfaceBright` | 暗色提亮面 |
| Surface Tint | `color/surfaceTint`（= primary） | 只给浮层 level 2–5 |

官方五档的定位原文（A）：`"surface container" is the recommended default color role for a contained area against the "surface" color role`，可从 `surface container lowest`（对 surface 强调最低）到 `surface container highest`（强调最高）组合。本仓库**不设区域快捷键层**：区域直接绑上表角色，`01 Tokens` 里只有 46 个 `color/<role>`（外加 `stroke/*`），没有 `color/desktop/*`。「同一 region 跨断点用同一角色」由「同一区域始终绑同一角色」保证（A）。

### 2.6 桌面级差对照表（large / XL，供评审与 Figma 重上色）

> 前提别读反：tone-based surface **本来就是为大屏新增**的模型（官方博文副标题 `New surface color roles offer more flexibility for large screens`，A），它正是为了让大屏不必再靠 elevation 叠色分区。本节的结论是「**同一个梯级**铺到并列大区时级差不足」，正解是动用官方为大窗口开的 **区域级 add-on surface colors**（也就是用**更多** tone 角色），而不是退回阴影。完整推理见 `research/material-design-3/08-tone-based-surfaces.md` §0.5。

| 区域 | 亮色角色 | L\* | 暗色角色 | L\* | 相邻级差（亮 / 暗） |
|---|---|---:|---|---:|---|
| 窗口底 / 导航 rail | `surfaceContainerLow` `#FFF0F1` | 96.0 | `surfaceContainerLow` `#22191A` | 9.9 | rail→pane **4.03 / 7.2** |
| pane（列表 / 详情 / 支持栏） | `surfaceContainerLowest` `#FFFFFF` | 100.0 | `surfaceContainerHigh` `#312829` | 17.1 | — |
| pane 顶栏条 | `surface` `#FFF8F7` | 98.1 | `surface` `#191112` | 5.9 | 对 pane 1.93（嵌套条，不计入 T2） |
| 分组卡 / 列表行 | `surfaceContainerLow` `#FFF0F1` | 96.0 | `surfaceContainerLow` `#22191A` | 9.9 | 对 pane **4.03 / 7.2** |
| 搜索框 | `surfaceContainerHigh` `#F5E4E5` | 91.9 | `surfaceContainerHigh` `#312829` | 17.1 | 对 chrome 4.04 / 7.2 |

- 参考位：`design-system/example.png`（Google Chat 桌面改版）实测并列面板级差 **7.05 / 3.83**，同一手法、同一量级（B）。
- **chrome 往亮走（2026-10-23 深夜最终）**：用户观察「Gmail / Google 系产品桌面端耐看的一个原因是背景色大多偏亮」，要求把 pane 与 rail 各自**上调一级**。于是 chrome（窗口底 + rail + NavigationBar）= `surfaceContainerLow` 96.0、pane = `surfaceContainerLowest` 100.0（纯白）、pane 顶栏条 = `surface` 98.1、卡/列表行 = `surfaceContainerLow` 96.0、搜索框 = `surfaceContainerHigh` 91.9。chrome→pane **4.03** 仍过 T2 的 ≥4，pane→卡 4.03；1.93 那一档（顶栏条）属**嵌套条**，靠 56 高与内容基线区分，不计入并列区级差。
- **两版历史**：更早用 `surfaceDim`（87.0）做窗口是「太暗」被否的一版；中间「窗口=rail=`surfaceContainer` 94.0 / pane `surface` 98.1」是第二版；现在是第三版（整体再亮一级）。三次都只改区域绑定，46 角色 hex 一个未动。
- **暗色方向相反**：暗色没有更暗的 chrome，`surfaceDim` 在暗色等于 `surface`（#191112），因此 chrome 走 `surfaceContainerLow`（#22191A，9.9）、pane 走 `surfaceContainerHigh`（17.1），即「pane 比 chrome 亮」。暗色不出 Figma 稿（§2.5），代码层按此表实现后需实机复核。
- 级差只用于「无边界并列的面板」；带圆角/内边距的卡片用 4.03 一档（提亮后 pane→卡正好 4.03），嵌套条仍可 2 档，保持安静。

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
- 样张 frame `10:577`（页面 `02 Styles`）：左 baseline / 右 emphasized，30 行全量对照；仓库不存截图。

### 3.2 字体映射

| Figma style | FontWeight（Flutter） | 用途 |
|---|---|---|
| Regular | `w400` | display/headline/title-large/body 的 baseline |
| Medium | `w500` | title-medium/small、全部 label、emphasized 的 display/headline/title-large/body |
| Bold | `w700` | emphasized 的 title/label |
| Semibold | `w600` | 当前 30 样式未使用；留给自定义强调（谨慎新增） |

- 应用侧 `app/pubspec.yaml` 目前只有 `assets/fonts/MiSans-Regular.ttf`，迁移时必须补 Medium/Bold 资产并注册 `fontWeight`，否则层级会塌。
- CJK 行高：M3 2026 起会按 script 调整；本项目先按表中固定行高，等官方 Flutter 实现再对齐。

## 4. 形状 / 高度 / 动效 / 数值 token

### 4.1 Number tokens（Figma collection `Number`）

| 组 | 值 | 用法 |
|---|---|---|
| spacing | 0 / 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 | 4/8 体系；M3 未规定 spacing scale，属项目决策 |
| radius | none 0 / xs 4 / sm 8 / md 12 / lg 16 / xl 28 / **pane 20** / full 999 | 卡片 12、对话框 28、FAB 16、按钮与 chip = full；pane 20 = 官方 `large increased`（档位名 A、dp 值 B），桌面窗口内的容器用它（§2.5） |
| size | control 40 / touch 48 / list 56·72·88 / fab 56·80·96 / extended-fab 56 | 视觉高度可 40，触达不得小于 48 |
| state | hover 8% / focus 12% / pressed 12% / dragged 16% / disabled 38%·12% | 见 §4.4 |
| breakpoint | 600 / 840 / 1200 / 1600 | 见 §5 |
| icon | 20 / 24 / 40 | 默认 24 |
| elevation | 0 / 1 / 3 / 6 / 8 / 12 | 对应 level 0–5，见 §4.2 |

### 4.2 Elevation（Figma Effect Styles `elevation/level0–5`）

| level | dp | 阴影 | 表面角色 | 用途 |
|---|---:|---|---|---|
| 0 | 0 | 无 | surface | 静止背景 |
| 1 | 1 | 3 层 | surfaceContainerLow | 卡片 / hover |
| 2 | 3 | 3 层 | surfaceContainer | 菜单 / 拖拽 |
| 3 | 6 | 3 层 | surfaceContainerHigh | FAB / 对话框 |
| 4 | 8 | 3 层 | surfaceContainerHighest | hover 提升（仅交互中） |
| 5 | 12 | 3 层 | surfaceContainerHighest | dragged / 模态（仅交互中） |

- 阴影 dp 与 3 层黑色透明度（0.20 / 0.14 / 0.12）取自 Flutter `kElevationToShadow`（B 级官方实现）。
- **M3 的 elevation token 不含阴影**：高度主要靠 `surfaceContainer*` 色调表达；阴影是平台选择。桌面保留轻阴影，移动端可只留色调。
- Figma 中 Effect Style 只存阴影，色调必须在组件填充里绑对应 surface 角色。
- **上表的 level ↔ surfaceContainer 是 1:1 映射，只对浮层组件成立**（menu / dialog / side sheet / snackbar）。tone-based 模型（官方博文，A）已把 surface 与 elevation 解绑；pane 级容器按 §2.6 取角色，不按 level 取值。

### 4.3 Motion

| 场景 | 时长 | 曲线 |
|---|---:|---|
| enter（元素出现） | 400ms | Emphasized decelerate |
| exit（元素消失） | 200ms | Emphasized accelerate |
| 屏内状态变化 | 500ms | Emphasized |
| 通用过渡 | 300ms | Standard |
| 主曲线控制点 | — | 0.2, 0, 0, 1 |

- 桌面页面转场保留 fade-through（现有 `DesktopFadeThroughPageTransitionsBuilder`）。
- 所有位移/缩放必须受 reduce-motion 开关约束：开启时只保留淡入淡出。

### 4.4 状态反馈与 splash（D4 已定）

| 状态 | state layer 不透明度 | 说明 |
|---|---:|---|
| hover | 8% | 桌面指针悬停；移动端无 |
| focus | 12% | 键盘/焦点环之外的第二层反馈 |
| pressed | 12% | 按下瞬间；与 splash 二选一或叠加，避免双重变暗 |
| dragged | 16% | 拖拽/长按拖动 |

- **移动端（Android / iOS）**：保留平台默认 splash（ink ripple/sparkle）作为按压反馈；state layer 主要用于 selected/focus 等非瞬时态。
- **桌面端（Windows / macOS / Linux）**：关闭 splash（`NoSplash.splashFactory`），hover/pressed 全部由 state layer 提供；否则鼠标点击会出现与桌面习惯不符的扩散动画。
- 代码落点 `app/lib/shared/ui/theme/theme.dart:62-64`（现为 NoSplash + transparent highlight + `adaptivePlatformDensity`）；迁移时按 `Platform` 分支处理，并恢复 `visualDensity` 的触达最小值。
- 组件实现：`ButtonStyle.overlayColor` / `InkWell.hoverColor` / `MaterialStateProperty` 按上表取值；不要在组件里写死颜色，叠 `onSurface` 的 alpha。
- 触达尺寸：视觉高度可以 40，但可点击区不得小于 48×48（桌面与移动一致）。


## 5. 布局与断点

### 5.1 五档断点

| class | 宽度 (dp) | 代表 frame | 壳层 | 分栏 | 栅格 |
|---|---:|---|---|---|---|
| compact | < 600 | 390×844 | Navigation bar（高 80） | 1 | 4 列 / margin 16 / gutter 16 |
| medium | 600–839 | 800×1280 | Collapsed navigation rail（宽 80，menu 可切 expanded） | 1 (recommended) or 2 | 8 列 / margin 24 / gutter 24 |
| expanded | 840–1199 | 1024×768 | Collapsed rail（可换 standard expanded）+ **桌面标题栏** | 1 or 2 (recommended) | 12 列 / margin 24 / gutter 24 |
| large | 1200–1599 | 1440×900 | **Collapsed rail 80**（同屏 ≥3 栏）／Expanded rail 256（≤2 栏）+ **桌面标题栏** | 1 or 2 (recommended) | 12 列 / margin 24 / gutter 24 |
| extra-large | ≥ 1600 | 1920×1080 | 同上（rail 宽度由**同屏栏数**决定，不只由断点决定）+ **桌面标题栏** | 1 to 3 (recommended) | 12 列 / margin 24 / gutter 32 |

- 断点按**应用可用窗口**判断，不用设备类型；横竖屏、多窗口、折叠展开都会换档。
- 接缝测试：599/600、839/840、1199/1200、1599/1600 各出一张对照。
- 内容最大宽：large/XL 的正文区约 1200dp 居中，避免 1920 拉满；正文保持 40–60 字符/行。
- 代码现状 `app/lib/shared/ui/layout/app_layout_breakpoints.dart:10,13` 是 600/1024；迁移时改五档。
- 模板进度（五档齐全）：Compact 390×844 `41:1975`、Medium 600×800 `41:1824`、Expanded 1024×768 `41:1774`、Large 1440×900 `41:1578`。
- **详情模板（2026-10-23 已改/已建，见 `09` §7/§11.6）**：XL `72:1083`（`Template/Comic detail · Extra-large 1920`，rail 256 + 24 + pane 1616 + 24）、Large `67:509`（1440×900，rail 80 + 24 + pane 1312 + 24）、Expanded `72:900`（1024×768，pane 896）、Medium `72:961`（600×800，pane 472）、Compact `72:1022`（390×844，pane 全出血）。旧的 `41:2384`（书库 XL 三栏）、`67:431`（旧 expanded）与旧四屏 `67:587`/`67:649`/`67:677`/`67:752` 均已删除。
- **栏宽取值**：详情页三栏 = rail + 24 + 主区 + 24 + supporting + 24，主区 expanded 512 / large 876 / XL 1180，rail 80（XL 详情例外 256）；支撑栏宽见下条。**pane 间与帧右缘都留 24 画布底**（不照搬 `09` 参考图的 0 margin 全出血，用户要求支撑栏贴右但留白），pane 内 padding 24，分区靠 tone、不叠 1px 线。原「四栏 80+320+1108+412」方案**作废**（书库不走 inline list-detail）。
- **桌面底板（画布层，非 token）**：≥1200dp 的帧加底板（帧外扩 24、圆角 20、填充 `#EAE8E6`）+ 窗口 chrome（圆角 12、1dp `outlineVariant`、`0/2/6 @12%` 投影）。`#EAE8E6` 不在 46 个颜色角色里，代码中禁止使用。
- **pane 容器规则（2026-10-23 已全量铺开，10-23 深夜提亮后）**：≥600dp 的帧一律「帧底 **`color/surfaceContainerLow`（与 rail / NavigationBar 同色，96.0）** → rail（同色）→ **24 画布缝** → pane（圆角 20、**`color/surfaceContainerLowest`，100.0 纯白**，右/下各留 24）」，pane 顶栏条 `color/surface`（98.1），pane 内卡片 `color/surfaceContainerLow`（96.0）；pane 内内容自带 24 / 16 padding；**compact（<600dp，实际只在移动端出现）pane 全出血**：pane = 整帧 (0,0,W,H)、圆角 0、帧自身无圆角/描边/阴影，顶栏条与 NavigationBar 同样满宽——移动端没有窗口外壳，不要再套桌面留白。阅读器是例外：全出血阅读面 + toolbar / bottom bar 浮层，不套 pane。已套用：07 书库四档 `41:1578`/`41:1774`/`41:1824`/`41:1975` 与详情五档；08 非阅读器帧全部（pane id `74:1387`–`74:1398`）。
- **supporting pane 宽**：expanded **360**（官方 A 级）；large / XL **412**（官方 A 级）。旧文档统一写 360 是漏了 large/XL 的默认值，已按 `07-supporting-pane.md` §4.1 修正。
- **桌面 / 移动归属（2026-10-23 用户决策，覆盖此前「≥1200 才算桌面」）**：**expanded 1024 起算桌面**（桌面应用不全屏时 1024 很常见），**medium 600 / compact 390 算移动**。判据是「有没有窗口壳」：桌面帧有 56 高标题栏 + 三个窗口按钮，移动帧没有。连带：`08` 的区域取角色阈值从 ≥1200 下调为 **≥1024**。
- **桌面标题栏（2026-10-23 已落地 13 帧，两次加高后为 64 高版）**：高 **64**、与窗口/rail 同色（不设独立底色、不加分隔线）。垂直排布：搜索 40 高 → **y=12**（上下各 12），窗口按钮 32 高 → **y=16**（垂直居中），rail 的 menu 24 高 → **y=20**（中心 32 = 标题栏中线）。
  - **menu 归属 NavigationRail（用户明确）**：不建外置按钮。展开态用 rail 自带的 `menu-open`（rail 图标列 x=32、y=20，24 高），折叠态用 rail 自带的 `menu`（x=28、y=20）；13 个外置 `MenuButton` 实例已删（组件本身保留备他用）。**视觉上与窗控同一行，但它是 rail 的第 0 个 item**，hover 走 rail 的 state layer，rail 折叠/展开时随 rail 移动。
  - 中 **GlobalSearchBar 720×40 / r20**（fill `surfaceContainerHigh`）：**x = pane 左缘**（1440/1920 = 280，1024 = 104），与主 pane 严格左对齐；右端到窗口按钮前留空。
  - 右 **3 枚 WindowButton 32×32 圆形**（`y=16`、间距 4、右内边距 8，顺序 最小化 → 最大化 → 关闭；最大化后图标换 **Restore**，无官方图标、自绘双叠方块属 B 级社区惯例）。hover 只给关闭按钮上 `errorContainer`，其余用中性 8%（用户已定）。
  - 几何连带：pane 顶 24 → **80**、高 = **H−104**（底边仍 H−24）；pane 内全部内容整体 **+56**（相对加壳前），其中 Library1440 / Home1024 / Settings1440 / Settings1024 再压缩（累计 −28 / −24 / −24 / −28；Home1024 另重排「继续阅读」列表与卡组；Settings1024 三张分组卡按 192/404/581、高 198/163/163 重排）以免越出底边。
  - **rail 间距最终值（2026-10-23 深夜二次修正，覆盖此前 76/32 一版）**：menu 24 高 @ **y=20**（底 44）；**两种状态以第一个 item 的图标顶对齐 y=104**，即 menu 底 → 首个图标顶 **60dp**，展开/折叠完全一致（用户要求「上下间距在展开收缩状态时都应该保持一致」）。展开 256：indicator 88+68i（101×56）、icon 104+68i、label 106+68i；折叠 80：indicator 100+64i（56×32）、icon 104+64i、label 136+64i（icon 底 → label 顶 8）。折叠态此前首项 icon 56 / label 100（间距 20）是旧 bug，已随本次统一修正。
  - **「标题栏拖动区」是什么**：桌面窗口靠按住标题栏空白处拖动窗口，那层看不见的命中区就是拖动区。实现时把标题栏内**控件之外**的横向空白（rail 右侧到搜索框之间、搜索框与窗控之间、窗控右侧 8dp）交给平台 window drag，控件自身不参与拖动；Figma 画不出来，只在此记录。
- **桌面不再有页内搜索**：Home/Library 的 1440/1024 四帧删掉页内 SearchBar（由全局搜索取代）；**600/390 仍保留页内搜索**（移动端没有标题栏）。
- **桌面底板扩到 expanded**：凡桌面帧（含 1024）都加底板（帧外扩 24、圆角 20、`#EAE8E6`）；07 新增 `84:2301`（Library 1024）/`84:2302`（Detail 1024），08 新增 `84:2303`–`84:2306`（Home/Settings/History/Detail 1024）。
- **断点内边距与字号（2026-10-23 修正，25 帧全覆盖）**：
  - pane 外边距：**≥600 全档 24**（medium/expanded/large/XL；pane = (rail 右缘 + 24, 24)，尺寸 = 帧宽 − rail − 48 × 帧高 − 48）。依据是官方 canonical 原文 medium「margins of 24dp」、expanded「outer margin 24dp / spacer 24dp」（A，`07-supporting-pane.md` §4.1）。1440 / 1920 已于 2026-10-23 晚由 16 统一到 24。
  - pane 内 content = **水平 24 / 顶部 16**（medium / expanded / large）；compact 全出血，content 16。
  - 页面标题字号：large / XL **32**、expanded **28**、medium **24**、compact **24**；详情页标题单独一档 22 / 22 / 20 / 18（不跟页面标题走）。
  - 长文本（路径、URL 等）按 content 右缘截断：600 → 324、390 → 262，禁止越出 pane。
- **pane 底部内边距 24（2026-10-23 深夜，25 帧全量复查）**：任何内容的底边必须 ≤ **pane 底 − 24**；compact 全出血时距 NavigationBar 顶 **≥ 16**（FAB 例外，本就在 16 处）。超出时**优先裁剪次要信息**，不压字号、不靠滚动掩盖：书库章节目录删末行（1440 4→3 行、1024 保持 3 行整体上移 16）、详情资源 KV 末行并入右列（1024 删「添加时间」）、设置「数据」分组删末行并把卡高压到内容高（1440 180→156、1024 163→139）、Home 1024 少一张推荐卡 + hero 240→216、书库 1440 简介收到两句。滚动视口（medium 详情）不受此条约束。
  - medium 的详情页是**滚动视口**：内容可以低于 pane 底缘表示还能滚，不要为了塞进去压缩字号或行距。
  - 复核口径：每帧脚本检查 `contentIn`（首个子节点 x/y）、`contentMax`（max x+w / y+h）与 `outsidePane`，三者必须落在 pane 内（滚动视口末行例外）。
- **详情页文档流细节（2026-10-23 晚统一，五档模板 + 08 四屏）**：
  - 简介：单段 4 行 → **按断点截断**——large/XL/expanded 3 行、medium 2 行、compact 3 行（Figma `maxLines` + `ENDING` 省略号，高 = 行数 × 24）。
  - 「展开全文」：**紧跟简介末行**（间距 8），不再固定挂在 4 行高度下方；Figma 无「文字尾部自动换行吸附」，用「截断 + 紧随」模拟 Wrap 语义，实现层用 `Wrap`/`TextOverflow` + 按钮随文本流。
  - 资源 KV 排版（2026-10-23 深夜统一，9 个详情帧全覆盖）：**K（label：格式/大小/路径/更新时间/添加时间）= MiSans Medium 14**、**V（value）= MiSans Regular 14**；两者 **lineHeight 20 PIXELS、文本框高 20**、同一行 **y 相同 ⇒ 垂直中心对齐**；颜色 **K = `onSurfaceVariant`（`VariableID:10:60`）**、**V = `onSurface`（`VariableID:10:52`）**，全部绑变量（此前「添加时间」两枚是裸色 + `lineHeight AUTO`，已修）。同一行 KV 用同一 y 与同一高度，不靠目测对齐；390 的路径值收成单行 `D:\library\深海…`，因为两行会破坏行内居中。
  - pane header：← / 更多 / 编辑 在同一基线上（y = pane.y + 16，24 高文本框），系列 `‹ 3 / 5 ›` 右对齐（右缘 = pane 右 − 24 / compact 16，y = pane.y + 18），x 间距 24。
  - 390 字号：页面标题 24 **Bold**（书库此前是 Medium，已改）、设置行 15 → **14**（2026-10-24 设置页改 list-detail 后，四档**分类列表行统一 15 Regular**，390 的 14 只用于旧分组行）、历史组标签 12 Medium；设置 390 的副标题行已于 2026-10-23 深夜**删除**（四档统一不设副标题，见 §5.1），内容上移 20；各组与标题的间距统一 16。
  - **分区标题已移除**（2026-10-23）：详情页不再有「元数据」「资源信息」两个 section title；分区关系靠间距表达——元数据 4 行步距 40（1024 为 36、600 为 30、390 为 32），元数据块与资源 KV 之间 44，首行距「展开全文」底 28（1440/1920 因封面高度取 max(28, 封面底 + 32)）。
  - **Chip 规格（2026-10-23）**：高 **32**、圆角 **8**、未选 1dp `outline`（交互边界 ≥3:1，A）、选中 `secondaryContainer` + 18dp 勾；label 14 Medium；与所在 label 行**垂直居中**（chip y = label y − 6）；同组横向 gap **8**；metadata 值 chip 与 label 列间距 100。
  - **设置分组 SettingsGroup / SettingsRow（2026-10-23 深夜重做，颜色按官方 Lists specs，A/B）**：颜色角色严格按官方 List specs 的 Color 表（容器 `surface`、标签 `onSurface`、值/尾随图标 `onSurfaceVariant`、选中 `primaryContainer` + `onPrimaryContainer`）：**分组容器不填色（`set_fills([])` 透明，圆角 20 与内边距 8 只作几何占位，直接继承 pane 底色）**；**每行是一个 List item，容器填 `surfaceContainerLow`（96.0，`10:56`；官方 specs 的 item container 角色是 `surface` 98.1，评审后按用户要求换成更清楚的 96.0，B）、高 **56**（带 supporting text 时 **72**）、宽 = 组宽 − 16、x=8、**行间 gap 4**（pitch 60，露出 pane 白底——容器透明）、行 y = 36 + 60i；组高 = **32 + 60n**（n=1/2/3 → 92/152/212，模板只出 1–3 行）；行圆角 **Single 12 / First 12+4 / Middle 4 / Last 4+12**；组标题在容器内**左上 (8,8)**，12 Medium `onSurfaceVariant`；leading 图标 **24×24 @ (16, 行y+16)、`onSurfaceVariant`**；标签 MiSans **15 Regular `onSurface`** @x56、y=行y+18（带 supporting text 时 label y=行y+18、supporting 13 Regular `onSurfaceVariant` y=行y+40）；右侧为 **值（15 Regular `onSurfaceVariant`）+ 尾随图标双槽**：可选行「▾」、导航/数据行「›」（18，`onSurfaceVariant`）——值右对齐到 `W−24−chevW−12−valueW`，chevron 在 `W−24−chevW`。级差：行 96.0 对 pane 100.0 = **4.03**（满足 T2），行间 gap 4 露出 pane 白底，构成官方 contained list 的「填充行 + 分段间隙」形态（A）。states：Hover = `onSurface` 8% 叠加、Focus = 12% 叠加 + 2dp 主色环、Pressed = 12% 叠加、Disabled = 内容 38%——样张 `105:902`（五行）；72 高 supporting 行样张 `105:946`。官方对「item 高 56 / contained list 用 gap 不用 divider」有正文（A，见 §9 第 45 条与 09 文档 §13.14.2）。**设置页四档不设副标题**，页面标题下第一组间距 = 16。选中态按 specs 用 `primaryContainer`/`onPrimaryContainer`（本轮未出样张，见 §9 第 45 条）。**只用于设置页的 detail 栏**（list 栏已按附图改为透明胶囊列表，见下一条）；「首尾大圆角、中间小圆角」与「filled rows + gaps」是本项目形态决策（B），颜色角色来自官方 specs（A/B）。leading 图标已按 Google 官方 Material Symbols 矢量导入（见 §9 第 47 条）。
  - **设置页 = 单 pane 内 list-detail（2026-10-24 落地，A/B；参考用户附图与官方 list-detail canonical example 的 key use case「Settings + category detail」）**：**同背景、无边框、无分隔线**（用户明确要求 list 与 detail 不做区分），两栏都直接继承 pane 纯白 `surfaceContainerLowest`。**≥840dp（expanded 起）= 双栏**：主 pane 内容宽 W 内 **list : detail = 1 : 3、间距 24**（2026-10-24 用户要求「不要 fixed pane，改 flexible」）→ list = (W−24)/4（1440: **266** / 1024: **206**）、detail = W−24−listW（**798** / **618**）；**两栏标题顶对齐**（用户要求）：左栏第一个组标题与右栏分类标题同一 y = 页面标题底 + 20（1440/1024 均 **158**）。**detail 栏上方放分类标题**（MiSans **Medium 22/28**、`onSurface`、y = 组 y − 48，即 title-large-emphasized 档），**分组自身不再画组标题**（与栏标题重复）；无标题组高 = **8 + 56n + 4(n−1) + 8**（3 行 = 192），行 y = 8 + 60i；值右缘 = 行右 − 35、chevron 左缘 = 行右 − 32。**右栏保持填充行样式**（用户裁决：不改成附图的透明胶囊）。**左栏 list 按用户附图（HyperOS 设置页）重做**：组标题 MiSans **14/20 Medium、`primary` `VariableID:10:22`、x=16**；行**通栏**（宽 = 栏宽、x=0、行距 0、**未选中无填充**）、高 56；首行 y = 组标题 y + 32，组间 24（第二组标题 y = 上一行底 + 24）；行内图标 **24×24 @(16, 行y+16)**、label **15 Regular @(56, 行y+18)**；列表容器**透明、圆角 0**，本稿高 256（「通用」= 阅读 / 外观，2 行；「数据」= 数据，1 行）。**list 栏选中行 = 整行胶囊**：圆角 **28** + `primaryContainer` `10:25`，文字/图标 `onPrimaryContainer` `10:26`，尾随 **check 18×18 @x = 栏宽 − 34、y = 行y + 19**（官方 a11y「selection 需第二线索」，用户要求保留 ✓）；未选中行**无填充**（纯继承 pane 白）。**< 840dp = 单栏**：根页只有分类列表（无选中态，行尾 `›` @x = 栏宽 − 31、y = 行y + 17），进入后 **detail 整屏 + 返回箭头**（官方 Behavior：Back 只出现在单栏 detail、Selected 只出现在双栏 list）；390 二级页顶栏 = ← 24×24 @(16,20) + 标题 22/28 Medium @(56,18)，内容组 y = 72。**双栏阈值是 840 不是 600**（官方分栏表 Medium 600–839 = 1 pane 且为推荐），实现层 `AppLayoutBreakpoints.isCompact` 现仍以 600 为界，需改 840。**设计稿 3 类 vs 代码 4 类**：设计稿按「阅读 / 外观 / 数据」（对应用户附图），代码现有「个性化 / 元数据备份 / 诊断 / 关于」——落地时以代码功能为准套本布局（行高 / 圆角 / 选中态 / chevron 均不变）。**list 宽 266/206 低于官方推荐的 360/412**：rail 已占宽，且用户要求 list : detail 取 1 : 3 柔性比例（不走 fixed pane），接受该偏离。**本轮只改设计稿、未改代码**（用户：暂时不改代码，以设计稿为准）；list 侧是逐帧手工节点，`SettingsRow`/`SettingsGroup` 组件集 `101:925` 未重构（绝对定位，改宽不自适应）。帧：1440 `48:2663`、1024 `75:1417`、600 `75:1480`、390 根页 `48:2710`、390 二级页 `108:849`、600 二级页 `108:909`（后两帧本轮新增）。
  - **漫画库页（书库）= 页内头部 + 封面网格（2026-10-24 落地 08 第 5 行，A/B；信息与交互取自 `app/lib/features/library_browse/`）**：**头部单行 44 高**（同代码 `LibraryPageHeaderToolbar`）= 左「页面标题 + 计数芯片」、**tabs 绝对居中**（同代码 `LibraryDisplayTargetTabs`）、右 3 个 20dp 图标动作。标题字号随档 **32/28/24/24**。**计数芯片** = 高 28、圆角 8、`surfaceContainerLow` 96.0（`10:56`），内含 14dp Material Symbols 图标 + **12/16 `onSurfaceVariant`** 文案，两芯片间距 8：`1,284 本`（`library_books`，= `l10n.comicCount`）+ `96 个系列`（`bookmarks`，= `l10n.librarySeriesCount`）；单栏（390）只显示当前 tab 的一个（同代码 compact 规则）。**tabs** = 漫画 / 系列，**14/20**，选中 **Semibold `primary` + 2 高下划线**（宽 = 文字宽）、未选 Medium `onSurfaceVariant`，间距 24。**动作** = `filter_list`（筛选与排序）/ `more_horiz`（更多）/ `view_module`（每页数量），**20×20 `onSurfaceVariant`**，右对齐内容右缘，间距 8（expanded）/ 8（600）/ 4（390）。**桌面 1440 与 1024 不做页内搜索框**：标题栏 `GlobalSearchBar` 已覆盖，代码里 `LibrarySearchField` 提交只 `push('/searched?q=')`（跳全局搜索页），功能重复；**600 / 390 保留页内 `SearchBar` 56 高**。**1440/1024 头部单行；600 两行**（第二行 tabs 左对齐）；**390 tabs 放标题下方**——代码 compact 用底部 `ContentSwitcherBottomBar`，会与 NavigationBar 叠成两条，设计稿改顶部 tabs，**属有意偏离**（见 §9 第 49 条）。**网格**严格取代码公式 `列数 = ceil(内容宽 / (maxCrossAxisExtent + 间距))`：1440 内容 1088 → **6 列 × 168 / gap 16**（6×168+5×16 = 1088 正好）；1024 内容 848 → **4 列 × 200 / gap 16**（代码 maxExtent 188 会得 5 列，设计稿取 4 列让折行落在封面处，B）；600 内容 424 → **3 列 × 132 / gap 14**；390 内容 358 → **2 列 × 173 / gap 12**。**卡片**按代码 `CatalogCoverCardShell`：圆角 **12**、`surfaceContainerLow` 96.0、**封面 2:3 flush 顶部**（`surfaceContainerHigh` 10:58；本文件无真实封面图，用 tone 占位，与详情页 `72:1164` 同法）、下方 info 左右 12：标题 **15/20 Semibold `onSurface`**、间距 6、副标 **12/16 `onSurfaceVariant`**（漫画「N 页」= `comicDetailPageCount` / 系列「N 卷」= `seriesVolumeCountLabel`），底部 8；**卡高 = 封面高 + 62**。**竖向**：网格首行 y = 头部底 + 16（1440/1024 = **156**、600 = **200**、390 = **160**，后两档下方还有搜索框）；1440 两行 12 卡填满 156..800；1024 与 390 的第二行按**滚动视口**裁在 pane 底（744）与 NavigationBar 顶（764），1024 的网格容器底部两角取 **20** 跟随 pane 圆角。帧：1440 `109:1040` / 1024 `109:1110` / 600 `109:1180` / 390 `109:1218`。示例数据 12 本（深海图书馆 128 页 / 夜色下的图书馆 96 / 雨后便利店 64 / 海岛来信 112 / 第七号站台 80 / 猫与咖啡 48 / 山神的祭典 144 / 旧书店的夏天 72 / 潮汐笔记 56 / 无人知晓的森林 120 / 玻璃温室 88 / 午夜电台 40）。**未画**：筛选抽屉、多选工具栏、空状态、分页条、系列 tab 内容——见 §9 第 49 条。
  - **collapsed rail 显示文字标签**（2026-10-23 恢复）：80 宽 rail 的 首页/书库/历史/设置 文字不再隐藏（此前实例级 override 误隐藏，32 个标签已恢复）；1dp divider 仍关闭。

### 5.2 官方分栏与导航矩阵

| Breakpoint | Panes | Navigation | Communication | Action |
|---|---|---|---|---|
| Compact | 1 | Navigation bar；modal expanded rail | Simple / full-screen dialog | Bottom sheet |
| Medium | 1 (recommended) or 2 | Navigation bar；modal expanded rail | Simple dialog | Menu |
| Expanded | 1 or 2 (recommended) | Modal 或 standard expanded rail | Simple dialog | Menu |
| Large | 1 or 2 (recommended) | Modal 或 standard expanded rail | Simple dialog | Menu |
| Extra-large | 1 to 3 (recommended) | Modal 或 standard expanded rail | Simple dialog | Menu |

跨断点只做五件事：**reveal / divide / resize / reposition / swap**。不换功能不等价的组件（button↔chip、list item↔card 要谨慎）。Medium 两栏只用于低密度内容 + 清晰动作。

> 括号位置已按官方原文改正（`07-supporting-pane.md` §7）：官方的括号**修饰整个区间**（如 `1 or 2 (recommended)` = 推荐用 2 栏，但 1 栏合法），不是「推荐 2 栏、1 栏次选」。旧写法把 `(recommended)` 读成了对某个数字的修饰。

### 5.3 Canonical layouts

**List-detail**（书库、历史、设置）：compact 1 栏；medium 1（推荐）或 2（双栏时用 bottom nav 省横向空间）；expanded 起 2 栏。单栏时 detail 才有 back；双栏时 selected 只在 list；无选中时 detail 显示占位；单/双栏切换保持最近使用的 pane。

**Supporting pane**（详情页元数据、阅读进度）：compact/medium 放 primary **下方**（compact 可用 bottom sheet，A 级原文）；expanded 起转 leading/trailing 固定 **360dp**；large / XL 官方默认 **412dp**（A）。pane 间 spacer 24dp、外侧 margin 24dp（A）；本项目三档详情模板就取 24（不取参考图的 0），见 §5.1 页脚。**父子关系一律改用 list-detail**（supporting pane 不是父子导航）。

- 判据（`07` §2）：**「换对象 = list-detail；换视角 = supporting pane」**。同一对象的切面（元数据、进度、评论）才进 supporting pane。
- **本项目采纳（用户决策 m00431）**：`/comic/:id`、`/series/:id` 等详情路由**共用同一个详情模板**——主区（封面 220 + 标题 + 概要 + 阅读/隐身阅读 CTA + 简介 + 元数据 chip 行 + 资源 KV）+ trailing 支撑栏（阅读进度、资源信息）；compact/medium 时支撑内容落到 primary 下方（官方 A），expanded 起转 trailing 固定栏。
- **书库列表页不走 inline list-detail**（用户决策）：保持「列表 → 独立详情路由」，所以 XL 书库三栏（原 `41:2384`）不再有列表栏，该帧已删除，1920 以详情 `72:1083` 为参照。
- **设置页走 inline list-detail**（用户决策）：设置根页双栏（分类 + 内容，阈值 **≥840**），二级页（阅读 / 外观 / 数据）单栏；官方 key use cases 原文 `Settings + category detail` 归 list-detail，代码现为 600，需改 840。
- **不采纳**：阅读器 + 章节目录（无章节模型、无页缩略图管线、与沉浸式冲突 → 改「可召唤浮层 ≤360」，见 §5.4）。
- MVP 不做拖拽调宽；官方 resize 快照取 360 / 412 / split 三档，够用。

**Feed**（首页、搜索、历史列表）：网格卡片；compact 单列铺满，medium 起加列，expanded/large/XL 列数继续增加；用大小与位置表达层级，重排保持顺序。

### 5.4 页面 → 布局映射

| 页面 | Compact | Medium | Expanded | Large / XL |
|---|---|---|---|---|
| 首页 Home | feed 单列 | feed 2 列 | feed 3 列 | feed 4–5 列，内容限宽 |
| 书库 All libraries | 列表 → 详情路由 | 列表 → 详情路由（**不做 inline list-detail**） | 列表 → 详情路由 | 列表 → 详情路由；详情页走 §5.3 |
| 单本详情 Library | **文档流单栏**：封面 96 + 标题/概要/CTA/简介（**3 行截断 +「展开全文」紧随，间距 8**）/ 元数据 chip 行（无 section title，4 行 chip + label）/ 资源 KV（label 14 Medium、value 14 Regular，无 section title），pane 358 全出血（16 边距） | **文档流单栏**：折叠 rail 80 + pane 472，封面 140 + 右侧文本 260；简介 **2 行**截断保证首屏完整 | **文档流**：折叠 rail 80 + 24 + pane 896 + 24，内容 848（封面 220 + 24 + 文本 604）；简介 3 行 | large：rail 80 + 24 + pane 1312 + 24（主区 1120）；XL：rail 256 + 24 + pane 1616 + 24（主区 1324）；简介 3 行；KV 在宽档排两列 |
| 阅读器 Reader | 全屏单栏 | 全屏单栏 | 全屏 + **可选浮层 ≤360**（非常驻栏） | 同 expanded，阅读区限宽 |
| 历史 History | feed 单列 | 2 列 | 2 列 + 详情 | 双栏 |
| 搜索 Search | 单列结果 | 2 列 | 2 列 | 3 列，筛选常驻 |
| 设置 Settings | 单栏 | 1 或 2（低密度） | 双栏：分类 + 内容（breakpoint **≥840**） | 双栏 + 展开 rail |

### 5.5 连续性与输入

- 不缓存/硬编码窗口尺寸与方向；用 `MediaQuery.sizeOf` / `LayoutBuilder` 取当前约束。
- 鼠标 hover / 键盘 focus / 触摸 pressed 都要有可见反馈；焦点环 2px + 12% state layer；hover 不能是唯一入口。
- 交互目标 ≥ 48×48；桌面可收紧视觉密度，但不能缩点击区。
- 官方没有 spacing 数值表；项目用 4/8 体系（§4.1），桌面可放宽到 space/5–6。
- 详细依据与证据级别见 `research/material-design-3/06-adaptive-desktop.md`；supporting pane 采纳范围见 `07`，桌面级差见 `08`，桌面参考布局见 `09`。

### 5.6 导航组件解剖（官方 A 级）

来源：`m3.material.io/components/navigation-rail/` 的 overview / guidelines / accessibility（2025-05 起）。baseline navigation rail 已不再推荐，现行只有 **collapsed** 与 **expanded** 两种：collapsed 替代旧 rail，expanded 替代 navigation drawer。

| 项 | Collapsed（80） | Expanded（256） |
|---|---|---|
| 使用档位 | medium → XL；compact 必须用 navigation bar | large / XL（可作 modal 覆盖） |
| 条目数 | 3–7；不隐藏 | 3–7；可整体隐藏（沉浸式） |
| Menu（切换入口） | 顶部 `menu` 24 图标，`28,16`（与图标列同一 x） | `menu_open` 24 图标，`32,16`（与 destination 图标列同一 x，不是贴着 rail 左边缘）；点按收起 |
| Active indicator | 56×32，包住图标 | **101×56，贴合图标 + 文字**（不按 rail 宽度取比例） |
| 行距 | 64（顶部 52 起） | 68（顶部 64 起） |
| 命中区 | 整行 80 宽 | **整行 256 宽**（indicator 只是视觉贴合） |
| 选中图标 | **filled** + onSecondaryContainer | 同左 |
| 选中 label | secondary（官方唯一颜色变更） | onSurface |
| 未选中 label / 图标 | onSurfaceVariant，Label Medium | 同左 |
| Divider | 与内容相邻一侧 1px outlineVariant | 同左 |

官方原文要点：`The active indicator hugs the label text in the expanded nav rail`；`The target area should always span the full width`；indicator 从图标中心展开、rail 内只允许一个；label 必须一个词、不截断、不用省略号、不为长文案缩字号；文字放大时条目纵向增高、保留默认 padding，2× 内完整可见，超过才允许截断（样例见 09）。FAB 若存在只能顶部对齐、位于 destination 之上且 elevation 取 level 0；本项目建库低频，rail 不放 FAB。>5 destinations 时考虑 modal expanded rail；rail 与 navigation bar 不能同时出现。navigation bar 的选中图标同样用 filled。

证据缺口：官方 `/specs` 页为 JS 渲染，抓取只得 109 字符，尺寸表缺失；expanded indicator 101×56、行距 68 由官方截图按 2× 反推（B 级），collapsed 56×32 与已知实现值吻合。rail 容器 256 是项目取值，不是官方数值。

## 6. Figma 库结构

文件：`Hentai Library UI  (Material Design) v2`（`UI` 与 `(` 之间两个空格）。

| 页面 | id | 内容 | 状态 |
|---|---|---|---|
| 00 Cover · Changelog · Status | `0:1` | 封面、变更记录、建库进度 | 待补 |
| 01 Tokens | `9:9` | 6 个颜色集合 + A 亮/暗预览 + 44 Number token 总览 | 完成（`25:689`） |
| 02 Styles | `9:10` | 30 Text Style + 样张；6 Effect + 5 Grid Style 与卡片 | 完成（`25:1234`） |
| 03 Foundations | `9:11` | 角色用法、字阶、形状、elevation、motion、state、a11y 规则页 | 完成（`25:1314`） |
| 04 Icons & Assets | `9:12` | Material Symbols 24px 样本、尺寸 20/24/40、filled 态 | 完成（`25:1374`）；插画/占位图待补 |
| 05 Components | `9:13` | 无业务语义的原子组件 | 三个打样（`25:1428`：Button/Filled `25:1434`、IconButton/Standard `25:1438`、TextField/Filled `25:1442`）+ **Button 变体集 `39:1481`**（Filled/Tonal/Outlined/Text × Default/Disabled，8 变体）+ **NavigationBar 变体集 `41:1539`**（Selected=home/library-books/history/settings，4 变体）+ **NavigationRail 变体集 `41:1577`**（Type=Collapsed/Expanded × Selected=home/library-books/history/settings，8 变体；collapsed 与 expanded 分两行排布；**不含「新建」FAB**：业务是先选库根路径再扫描，建库低频；已按 §5.6 改版：顶部 menu 切换图标、选中图标 filled、collapsed 选中 label 用 secondary、expanded indicator 101×56 贴合内容、行距 68）；NavigationBar 同步改为 filled 选中图标；**FAB `41:1886`**（Regular 56 / Medium 80 / Large 96 / Extended 136×56）、**Chip 组件（2026-10-23 新建）**：`Chip/Filter` 组件集 `79:1721`（Unselected `79:1719` / Selected `79:1720`，宽 hug、高 32、radius 8、1dp `outline`）、`Chip/Assist` `79:1732`（+ 图标 primary）、`Chip/Suggestion` `79:1733`（仅 label）、`Chip/Input` `79:1734`（尾随 ✕，minWidth 88），TEXT 属性 `Label`；状态样张 `Chip/States · Light` `79:1753`（Enabled / Hover 8% / Focus 12% + 2dp primary 环 / Pressed 12% / Disabled 38%，覆盖层用 paint opacity 而非 color.a）。旧 `FilterChip 41:1895` 已删（无实例引用）、**ListItem `41:1920`**（Lines 1/2/3，56/72/88）、**Card `41:1933`**（Filled / Elevated / Outlined）、**Dialog/Basic `41:1939`**（320×220）；**页面已分组重排（2026-10-23）**：左列 260 宽标签栏（操作 Actions / 输入 Input / 选择 Chip / 卡片与列表 Card & List / 覆盖层 Overlays / 导航 Navigation / Proof 样张），内容从 x=320 起，每个组件下带 13 号 caption，Proof 样张移至最底 `25:1428`(320,3870)；40 个顶层节点重叠 0 |
| 06 Patterns | `9:14` | 有业务语义的组合（书籍行、漫画卡、章节行） | 已建：`BookListItem` `41:1946`（368×80，封面 48×64 + 标题 16 + meta 12 + 进度条）、`ComicCard` `41:1951`（160×276，封面 160×220）、`ChapterRow` `41:1955`（360×48）、`HistoryRow` `41:2498`（360×72）、`SettingsGroup` `101:1058`（360×212，3 行：容器**不填色**（20 圆角 + 8 内边距只作几何占位），行 `surfaceContainerLow` 96.0、56 高、gap 4、首尾 12 / 中间 4，行左 24×24 图标 + x56 标签、右侧「›」；旧 `SettingsSection 41:2496` 已删，规格见 §5.1 / §9 第 47 条）、`MetadataPanel` `41:2497`（320×240，5 组键值）、`ReaderToolbar` `41:2516`（1080×64）、`ReaderBottomBar` `41:2517`（1080×80：24 上一页 · 400 进度条 + 页码 · 24 下一页 · 24 设置，统一 28 垂直居中）；证明 frame `41:1956`。**页面分组（2026-10-23）**：左侧标签栏 + 行 = 分组、组内左起排布——①列表与卡片 y=200（BookListItem 320 / ComicCard 760 / ChapterRow 1000）②结构面板 y=560（MetadataPanel 320 / SettingsSection 700 / HistoryRow 1120）③阅读器外壳 y=920（ReaderToolbar 320,920 + ReaderBottomBar 320,1024 上下叠）④Proof 样张 `41:1956` (320,1200) 1440×900；⑤**标签与 Chip 组** y=2160（元数据行「作品 + chip」、筛选组「全部/未读/已收藏」、Assist「添加到标签」、Input「深海图书馆 ✕」）与 `Chip 类型` y=2300（Filter 未选 ×2、Suggestion ×2）；画布文字 `77:1698`–`77:1711` 与本批新增说明文字（页标题、副标题、5 个行名、组件名 × 尺寸）；节点重叠 0 |
| 07 Templates | `9:15` | 书库四档 + 详情五档 | **书库壳层**：Compact `41:1975`（390×844）/ Medium `41:1824`（600×800）/ Expanded `41:1774`（1024×768）/ Large `41:1578`（1440×900，rail 256）；**详情（文档流）**：XL `72:1083`（1920×1080）/ Large `67:509`（1440×900）/ Expanded `72:900`（1024×768）/ Medium `72:961`（600×800）/ Compact `72:1022`（390×844）；桌面底板 `67:749`/`67:750`/`67:751`；Reader 四帧已移 `12 Archive`；原 D 组卡组对照 `69:813` 与 `41:2384` 已删；顶层 9 帧重叠 0 |
| 08 Screens | `9:16` | 带真实内容的页面实例（五行 × 四列） | Home：1440 `41:2026` / 1024 `41:2209` / 600 `41:2160` / 390 `41:2314`；Settings：1440 `48:2663` / 1024 `75:1417` / 600 `75:1480` / 390 `48:2710`；History：1440 `48:2749` / 1024 `75:1543` / 600 `75:1613` / 390 `48:2803`；Comic detail：1440 `72:1160` / 1024 `72:1205` / 600 `72:1250` / 390 `72:1295`。四行四列已补齐，共 16 帧、重叠 0；**2026-10-24 新增第 5 行 Library（漫画库）：1440 `109:1040` / 1024 `109:1110` / 600 `109:1180` / 390 `109:1218`（行 y=4600），本页现 20 帧、五行四列、重叠 0。**Reader 四帧按用户要求撤出**（沉浸式、暂缓），移到 `12 Archive` |
| 09 States & Content Lab | `9:17` | loading/empty/error/offline、长文本、CJK、大图、密度、文字缩放 | 完成（`41:2520`）：loading 骨架 / empty / error / offline 缓存 / 长文本两行·三行截断 / 大图 16:9 / density 40·56 对照 / **Text scale `57:532`**（100% / 150% / 200% 三档导航项，行高随字号增长、不截断） |
| 10 Motion | `9:18` | 转场与时长标注 | 完成（`48:2574`）：Standard 300ms、Emphasized decelerate 400ms、accelerate 200ms、In-screen 500ms、reduce-motion 条 |
| 11 Handoff & A11y | `9:19` | token 映射、组件 API、do/don't、覆盖看板 | 完成（`48:2610`）：token→Flutter、组件→Flutter、a11y 验收与迁移顺序三列 |
| 12 Archive & Scratch | `9:20` | B/C 方向、Expressive 实验 | B/C 已移入 |

建库顺序：variables → text/effect/grid styles → primitives → patterns → templates × 断点 → screens → states/content → docs。

### 6.1 首批页面（节点索引，仓库不存截图）

截图不入库（避免仓库被位图撑大），直接在 Figma 文件 `Hentai Library UI  (Material Design) v2` 里按节点 id 查看：

| 页面 | Large 1440 | Expanded 1024 | Medium 600 | Compact 390 |
|---|---|---|---|---|
| 首页 | `41:2026` | `41:2209` | `41:2160` | `41:2314` |
| 阅读器 | `41:2097` | `41:2275` | `41:2139` | `41:2363` |
| 书库模板（**2026-10-24 起已过时**：行列表 + hero 详情，非网格；新稿见下表「漫画库 Screen」） | `41:1578` | `41:1774` | `41:1824` | `41:1975` |
| 设置 | `48:2663` | `75:1417` | `75:1480` | `48:2710` |
| 历史 | `48:2749` | `75:1543` | `75:1613` | `48:2803` |
| **详情 Screen** | `72:1160` | `72:1205` | `72:1250` | `72:1295` |
| **漫画库（Library）Screen** | `109:1040` | `109:1110` | `109:1180` | `109:1218` |

详情 **模板**在 07 Templates 页：XL `72:1083`（`Template/Comic detail · Extra-large 1920`，1920×1080，rail 256）、Large `67:509`（1440×900，rail 80）、Expanded `72:900`（1024×768）、Medium `72:961`（600×800）、Compact `72:1022`（390×844）。旧的 `41:2384`（书库三栏改造版）与旧 detail 屏 `67:587` / `67:649` / `67:677` / `67:752` 已删除；`69:813` 是 A/B 时的卡组版 B，保留作历史对照。模板帧的桌面底板仍是 `67:749` / `67:750` / `67:751`，08 的 5 个 1440 帧底板为 `67:781`–`67:785`。

**桌面窗口壳（2026-10-23，13 帧；两次加高后为 64）**：桌面帧（expanded 1024 / large 1440 / XL 1920）统一加 **64** 高标题栏——rail 自带 menu 40（不外置）、GlobalSearchBar 720（**x = pane 左缘**）、WindowButton 32×3（右内 8、y=12），pane 顶 72；桌面底板齐全（07 `67:749`/`67:750`/`67:751`/`84:2301`/`84:2302`，08 `67:781`/`67:783`/`67:784`/`67:785`/`84:2303`–`84:2306`）。移动帧（600/390）无标题栏、无窗控，保留页内搜索。

**画布矩阵（2026-10-23 修复重叠后）**：08 / 07 两页统一按「行 = 页面、列 = 断点」排布，避免帧互相压叠。

- 列 x = `320` / `1820` / `2920` / `3620` ↔ Large 1440 / Expanded 1024 / Medium 600 / Compact 390；左侧 `x=0` 留 260 宽标签栏（行名、列头文字，`74:1399`–`74:1416`）。
- 08 行 y = `200` / `1300` / `2400` / `3500` ↔ Home（首页）/ Settings（设置）/ History（历史）/ Comic detail（漫画详情）。**阅读器四帧已移出本页**（用户定「阅读器暂缓、走沉浸式」，现停 `12 Archive` 页 (0,1100) 起 2×2 排列）。**Settings / History 的 1024 与 600 已补齐**（`75:1417`、`75:1480`、`75:1543`、`75:1613`），本页现 20 帧、五行四列满格；**第 5 行 y=`4600` = Library（漫画库）**，底板沿用 `67:781`/`67:783`/`67:784`/`67:785`。
- 07 行 y = `200` / `1300` / `2500` / `3700` ↔ A 书库四档（`41:1578`/`41:1774`/`41:1824`/`41:1975`）/ B 详情 XL 1920（`72:1083`）/ C 详情四档（`67:509`/`72:900`/`72:961`/`72:1022`）/ D **已按用户要求删除**（原 `69:813` 卡组对照），D 行现为空。底板随帧平移：`67:749`(296,176)、`67:750`(296,1276)、`67:751`(296,2476)；08 底板 `67:781`/`67:783`/`67:784`/`67:785` 在 (296, 176/1276/2376/3476)。
- 两页顶层帧重叠数均为 0（2026-10-23 补齐后复测：07 九帧 0、08 十六帧 0）。

四个 P0 文档页的样张同样只在 Figma：Tokens 总览 `25:689`、Effect/Grid `25:1234`、Foundations `25:1314`、Material Symbols `25:1374`、Components Proof `25:1428`、Patterns Proof `41:1956`、States & Content Lab `41:2520`、Motion `48:2574`、Handoff & A11y `48:2610`。

## 7. 组件清单（规划）

P0 = 首批页面必需；P1 = 第二批。P0 原子组件已在 05 页建齐（Button / Icon Button / Text Field / Search Bar / Top App Bar / Snackbar / NavigationBar / NavigationRail / FAB / FilterChip / ListItem / Card / Dialog）；业务组合在 06（BookListItem / ComicCard / ChapterRow）。导航壳层按 §5 的五档矩阵落地：compact 用 Navigation bar，medium/expanded 用 collapsed rail，large/XL 用 expanded rail。

| 组件 | 优先级 | 关键 variant | Flutter 对照 / 风险 |
|---|---|---|---|
| Icon（Material Symbols） | P0 | outlined / filled × 20 / 24 / 40 | 自托管 SVG 或图标包；迁移时替换 `lucide_icons_flutter`；filled 只用于 selected/激活 |
| Button（filled/tonal/outlined/text/elevated） | P0 | emphasis × size × icon × state | `FilledButton` 等；已打样 filled 120×40 / radius full；需统一高度 40、圆角 full |
| Icon Button | P0 | standard/filled/tonal/outlined × toggle | 已打样 standard 40×40 + 24 图标；最小点击区 48 |
| FAB | P0 | size (56/80/96) × color × extended | 已建 `41:1886`：Regular 56/r16、Medium 80/r20、Large 96/r28、Extended 136×56；Flutter 只有 56，80/96 需自绘 |
| Text Field / Search Bar | P0 | filled/outlined × focus/error | 已打样 filled 320×56。`SearchBar` 组件集 **`79:1980`**（05 页 (320,440)，744×56）两变体：`State=Unfocused`（`48:2651`）与 `State=Focused`（`79:1976`）。**两态容器相同**：360×56、r28、fill **`surfaceContainerHigh`（`10:58`，#F5E4E5，L\*91.9）**、**无描边无阴影**，依据官方（A）`Search bars use the surface container high color role`、`In the contained style, the search bar container remains the same shape in both the unfocused and focused states`、`Lower elevation and no shadow by default`。差异只在图标与边距：Unfocused = 24dp 搜索图标 @16,16 + hint 文本 @56,18（指向性搜索图标，非按钮）；Focused = **同一个放大镜**（`85:2311`，24dp @16,16）+ clear ✕ `80:1983`（24dp @320,16，官方 focused 可选 clear）+ 容器外边距 24dp→**12dp**（A，官方 guidelines）。**2026-10-23 晚用户定「保留 clear、移除 back」**：原 focused back 箭头 `80:1981` 已删，leading 两态一致，返回/失焦交由页面层处理。建议/结果列表另置于 bar 下方（官方 anatomy 第 6 元素），输入文本保持可见。不做尾部筛选按钮（用户明确）。**上一版按 Gmail 做的「焦点=白底 + 1dp outlineVariant 描边」已作废**（与官方 contained 样式冲突）。**已回灌 8 帧**（Home/Library × 1440/1024/600/390，实例 `80:1985`/`80:1989`/`80:1993`/`80:1997`/`80:2001`/`80:2005`/`80:2009`/`80:2013`，沿用原槽位宽度、高度统一 56；右缘仍落在「pane 右缘 − 24」，24 规则不变）；**深色样张** `81:2017`（05 页 (1600,2600)，fill 绑暗色 `surfaceContainerHigh` `10:105`、图标与 hint 绑暗色 `onSurfaceVariant` `10:107`，说明 `81:2028`）。hint 文案未做 TEXT 属性（8 实例都用默认文案） |
| Top App Bar | P0 | small/medium/large × back/actions | 已建 `48:2658`：960×64，back 24 + title-large 22 + more_vert；大屏无阴影，滚动才上 tint |
| Navigation Bar / Rail | P0 | destinations 3–5 × selected | 已建：NavigationBar `41:1539`（390×80，4 变体，选中图标 filled）；NavigationRail `41:1577`（Collapsed 80 / Expanded 256，各 4 个 Selected 变体；顶部 menu 切换；collapsed 行距 64、indicator 56×32；expanded 行距 68、indicator 101×56 贴合内容；无新建 FAB）。解剖与官方依据见 §5.6，切换策略见 §5.2 |
| List Item | P0 | 1/2/3 line × leading/trailing | 已建 `41:1920`：56/72/88，leading 40 圆头像 + 文案 + trailing more_vert；书籍场景的 2:3 封面变体放 06 Patterns |
| Card | P0 | elevated/filled/outlined | 已建 `41:1933`：240×160/r12，Filled 用 surfaceContainerHighest、Elevated 用 surfaceContainerLow + level1、Outlined 用 surface + outlineVariant |
| Chip | P0 | assist/filter/input/suggestion × state | 已建四类（2026-10-23）：`Chip/Filter` 组件集 `79:1721`（`79:1719` 未选 = 透明底 + 1dp `outline` + 14 Medium `onSurfaceVariant`；`79:1720` 选中 = `secondaryContainer` 底 + 18dp 勾 + `onSecondaryContainer`）、`Chip/Assist` `79:1732`（+ primary 18dp）、`Chip/Suggestion` `79:1733`、`Chip/Input` `79:1734`（尾随 ✕，minWidth 88）；状态样张 `79:1753`（Enabled / Hover 8% / Focus 12% + 2dp primary 环 / Pressed 12% / Disabled 38%）。依据官方（A）四类定义、8dp 圆角、outline 定义边缘、不用 elevation 表达 pressed；描边色取 `outline` 而非 `outlineVariant`（T2 交互边界 ≥3:1） |
| Dialog | P0 | basic/full-screen × scrollable | 已建 `41:1939` Dialog/Basic：320×220/r28/surfaceContainerHigh，标题 24 + 正文 14 + 两个文本按钮；桌面宽度上限与 full-screen 变体后续 |
| Snackbar | P0 | 1/2 line × action | 已建 `48:2662`：344×48/r4，inverseSurface 底 + inverseOnSurface 文案 + inversePrimary 动作；桌面底部居中、移动端贴底 |
| 窗口控制 WindowButton | P0（桌面） | minimize / maximize / restore / close | 组件集 `84:2052`（32×32 圆形、icon 18、`onSurfaceVariant`）；状态样张 `84:2076`（Default / Hover 8% / Pressed 12% / Close hover = `errorContainer`）；**Restore 无官方图标，自绘双叠方块（B）**，与 Windows 惯例一致 |
| 菜单按钮 MenuButton | P0（桌面） | 单形态 | `84:2053`：40×40 圆形 + menu 24；放在标题栏的 rail 列，点击折叠/展开 rail |
| 全局搜索 GlobalSearchBar | P0（桌面） | 单形态（docked） | `84:2058`：400×40 / r20 / `surfaceContainerHigh`，搜索图标 20 + hint 14；桌面标题栏实例统一 **720×40、x = pane 左缘**（1440/1920 = 280、1024 = 104）；按官方只做 docked，不做 full-screen |
| Progress / Slider | P1 | linear/circular × determinate | Flutter `year2023` 默认值不等于现行外观 |
| Tabs / Menu / Tooltip / Divider / Badge | P1 | — | Tooltip 桌面最小高 24 |
| Segmented Button | 暂缓 | — | 官方 2025-05 起不再推荐，改用 connected button group |

业务组件放 `06 Patterns`，不混进 `05 Components`。已建 BookListItem / ComicCard / ChapterRow / HistoryRow / SettingsSection / MetadataPanel / ReaderToolbar / ReaderBottomBar；阅读器 overlay 由 toolbar + bottom bar 组合，不再做整屏组件（整屏属 08 Screens）。

### 7.1 组件状态矩阵（已定）

| 优先级 | Figma variant 状态 | 说明 |
|---|---|---|
| P0 | default / hover / pressed / disabled / selected | selected 只给可切换组件（Icon Button toggle、Chip、Navigation item）；focus 不单独出 variant，用 2px outline 焦点层 + 12% state layer，布尔属性控制显隐 |
| P1 | default / selected | 其余交互态由代码按 §4.4 生成，不出设计稿 |

- 状态 variant 控制在 5 个以内，避免 Button 类组件的组合爆炸（官方 kit 的 225 变体上限是反例）。
- 尺寸、图标有无、标签用 **component properties**（VARIANT / BOOLEAN / TEXT / INSTANCE_SWAP），不要用更多 state variant 表达。
- disabled：用**实色混合**表达 38% 内容 / 12% 容器，不要用 paint opacity（导出到透明底会发黑）。当前值：容器 `#E4DDDC`（surface + onSurface 12%）、容器上的文字 `#9B9393`（再叠 38%）、surface 上的文字 `#ABA3A3`（surface + onSurface 38%）。不改变形状与位置。

## 8. 代码映射（迁移前只读）

| 设计侧 | 代码侧（现状） | 迁移动作 |
|---|---|---|
| 颜色 46 角色 | `app/lib/shared/ui/theme/color/app_color_scheme.dart`（26 字段手工枚举，primary `#005FB8`） | 改为 `ColorScheme.fromSeed(seedColor: #E91E63, dynamicSchemeVariant: tonalSpot)` 或直接生成 46 角色；保留 `HentaiColorScheme` 扩展 |
| Text Style 30 | `tokens/app_text_tokens.dart`、`buildAppTheme` 的 `fontFamily: 'MI_Sans_Regular'` | 换 MiSans 四档资产；`TextTheme` 按 §3.1 重建 |
| 断点五档 | `layout/app_layout_breakpoints.dart`（600/1024） | 改 600/840/1200/1600；`isCompact/isMedium/isExpanded` 扩展为五档 |
| 自适应壳层 | 现有底部导航 / 桌面侧栏分散在各页面 | 按 §5.2 收口：compact NavigationBar，medium/expanded collapsed rail，large/XL expanded rail；书库/历史/设置用 list-detail，首页/搜索用 feed，详情/阅读器用 supporting pane |
| shape/elevation/motion | `tokens/app_radius_tokens.dart`、`app_shadow_tokens.dart`、`app_motion_tokens.dart` | 按 Figma 定稿值替换 |
| 组件状态 / splash | `theme.dart:62-64` 现为 NoSplash + transparent highlight + 桌面 compact density | 按 D4：**移动端保留平台 splash，桌面 `NoSplash` + state layer**；恢复 hover 8% / focus 12% / pressed 12% / dragged 16%；触达尺寸不得低于 48 |
| 图标 | `lucide_icons_flutter ^3.1.9`（全库使用） | 换 Material Symbols（outlined 默认 / filled 选中）；先替换导航、播放器、列表动作等 P0 图标 |
| 状态与内容分支 | 各页面自管 loading / error | 统一 enum（loading / empty / error / offline）→ 同一组件不同内容分支，见 09；空态/离线/缓存文案走 l10n，不硬编码 |

`app/test/project_layout_test.dart`（ADR-0029）断言本文件含 `## Directory charter`、正文含 `pages/[page-name].md`、`pages/` 目录存在；`pages/` 正文按路由待补，当前以 `pages/README.md` 占位满足 Gate。

## 9. 未决事项

1. **插图与占位图**：04 页目前只有图标；封面、占位构图、空态插图未定来源（自绘 / 授权素材）。
2. ~~**Grid margin**~~（**已关闭**）：compact 16 / medium 及以上 24 已由 `07-supporting-pane.md` §4 取到官方原文（A 级），不再是 C 级推断。Figma Grid Style 仍无 margin 参数，属工具限制，不影响决策。
3. **导航组件精确 dp**：navigation bar 高 80、collapsed rail 宽 80、indicator 56×32 有实现值佐证（B）；expanded indicator 101×56 与行距 68 由官方截图 2× 反推（B）；rail 宽 256 是项目取值。官方 `/specs` 页 JS 渲染抓取失败，若后续拿到数值，改组件集而非模板。
4. **rail 展开/收起的动效（2026-10-23 用户定「采用合适的 motion」）**：官方只说 indicator 从图标中心展开、未给时长（A 只到定性）。定为：展开用 **emphasized decelerate 300ms `cubic-bezier(0.05,0.7,0.1,1)`**（进入画面、缓出），收起用 **emphasized accelerate 250ms `cubic-bezier(0.3,0,0.8,0.15)`**（离开画面、缓入）；宽度 80↔256 与文字标签淡入淡出同一时长，标签 opacity 前 100ms 先行淡出。依据：官方 motion easing/duration 页给的四条曲线与时长档（A），把「展开=进入、收起=离开」映射到对应曲线是工程判断（C）。拿到 rail 专属数值再替换。
5. ~~**书库是否改 inline list-detail**~~（**已关闭，2026-10-23**）：用户定「书库不走 inline list-detail，设置页走」→ `41:2384` 改造为详情模板，large/XL 详情均为三栏；`09` §9.1 同步关闭。
6. **rail 用 80 还是 256 的切换规则**：`09` §3.2 提出「同屏 ≥3 栏 ⇒ 80」，是从官方产品截图反推（B），无官方条文。需在 1440 / 1920 两帧出图对比。
7. ~~**桌面 rail 取 `surfaceDim` 的玫瑰倾向**~~（**档位已改，色相倾向仍在**）：rail 已由 `surfaceDim`（87.0）改为 `surfaceContainer`（94.0），亮度问题解决；但 A 板 tonalSpot 在 tone 94 仍有低彩度（`#FBEAEB`，C\*≈5.4），整片铺 rail 会偏粉，属 §9 第 21 条的调色板决策。原记录：整片铺 rail 会偏粉。退路是 `surfaceContainerHighest`（tone 90）+ 1dp `outlineVariant`。**暗色 chrome 反向**（rail 用 `surfaceContainerHighest`）需设计评审确认。
8. **级差感知阈值无实测**：ΔL\* 2 / 4 / 7 的「能不能看清」是 C 级工程判断，官方只给对比度可访问性标准、不给分区级差规范。要做成规范需 5–8 人快速辨色测试。
9. **`MetadataPanel` 312 版**：组件现为固定 320 宽，装不进 expanded 支撑栏 360 的内容宽 312；出 312 版（或支持 16 内边距）之前，expanded 支撑栏只放阅读进度。
10. **详情页 rail 256 与 80 的对比**：XL 详情按用户指定用了 expanded 256，large/expanded 用 collapsed 80。需在 1920 上各出一版看详情 1180 是否过宽。
11. **`ChapterRow` 的「已读」不随行宽右对齐**：组件内固定 x=312，实例加宽后（XL 1132 / large 828）停在偏左；实例内子节点不能单独移动，需改组件布局属性。
12. **桌面底板 `#EAE8E6` 的定位**：现作为画布层（非 46 角色之一），是否要升为正式 token（例如 `color/canvasShell`）待评审——若升，需同时定暗色值。
13. ~~**详情页 A/B 选型**~~（**已关闭，2026-10-23**）：用户定**方案 1 · 文档流**（无支撑栏、无卡组），KV 按断点/宽度响应式，pane 圆角 20、卡 16，简介 4 行截断 + 「展开全文」；对照用的卡组版 `69:813` 已按用户要求**删除**（不再留作对照）。
14. ~~**pane 内卡片与 pane 的级差只有 2.1**~~（**已由提亮解决，2026-10-23 深夜**：pane 100.0 / 卡片 96.0 = **4.03**，过 T2。原记录：：窗口底 = rail = `surfaceContainer`（94.0），pane = `surface`（98.1），pane 内卡片 = `surfaceContainerLow`（96.0）。卡片对 pane 只有 2.1，靠 16 圆角与 24 内边距认边界（参考图同类手法级差 1.74）。评审需定：接受圆角认边界，还是给 pane 内卡片补 1dp `outlineVariant`——注意后者属于**组件层**做法（官方 cards 允许 outline 变体），不违反「区域级不加线」（§2.3 适用范围已按此收敛）。
15. ~~**Home / Reader 残留 `ChapterRow`**~~（**已关闭，2026-10-23**）：`9:16` 的 10 个实例已删；`ChapterRow` 组件定义保留给阅读器章节列表，本批页面不再使用。
16. **600 / 390 详情首屏装不下**：文档流按内容顺序排，600 的 pane 内容 424×752、390 为 310×812，资源 KV 末行贴着 pane 底；Figma 帧是「滚动视口」表现，超出部分被裁。评审要看的是滚动后是否仍成立（无二次留白断层）。
17. **collapsed rail 的文字标签**：Figma 里对 80 宽实例逐个 override 隐藏了 `首页/书库/历史/设置` 文字与左侧 1px 分隔线（实例级，不进组件）；Flutter 侧对应做法是 icon + tooltip，需在迁移任务里写明。
18. **圆角三层**：画布底板 20 / 窗口 frame chrome 12 / pane 20 / 卡 16 目前并存；底板与 frame 是「画布演示层」，pane/卡 才是产品层。评审若认为底板 20 会被误读成产品圆角，改成 12 或去掉。
19. ~~**阅读器不套 pane**~~（**已关闭，2026-10-23**）：用户定「阅读器页面暂时不做设计稿，阅读页要走沉浸式」，四帧（`41:2097`/`41:2275`/`41:2139`/`41:2363`）与底板 `67:782` 已从 08 移到 `12 Archive`，不再参与本批评审；恢复时按全出血 + 浮层 toolbar 重做，不套 pane。
20. ~~**medium / compact 的 pane 内边距未统一**~~（**已关闭，2026-10-23**）：600 / 1024 全部改成 pane 外边距 24 + 内容水平 24 / 顶部 16（compact 保持全出血 + 16）；字号同步成 32 / 28 / 24 / 24 四档，详见 §5.1「断点内边距与字号」。1440 / 1920 沿用既有 16 外边距（large 已验收），如评审要求全站统一到 24，需要再动 5 个 1440 帧 + 1 个 1920 帧。
21. **中性色相与参考图不同方向（已确认不是档位问题）**：与 `example.png` 逐像素比，L\* 档位已对齐（窗口底 87.0 vs 参考 rail 87.0；pane 98.1 vs 内容 97.9；卡片 96.0 vs 卡片 96.1），但色相相反——参考中性色 `a*≈-2.4, b*≈+4.6`（偏绿灰，C\*≈5.2），本项目 A 板 `a*≈+6.0, b*≈+1.6`（偏玫瑰粉，C\*≈6.2）。这是 D3「A 柔和玫瑰 + neutral chroma 6」的既定结果，**不是 tone 用错**。若要更接近参考的灰，需重生成 neutral 调色板（chroma 2–3 或色相归零），会改动 46 个 hex，属换调色板决策。
22. ~~**rail 用透明度调色**~~（**已关闭，2026-10-23**；rail 最终为 `surfaceContainerLow` 96.0）：用户提出「透明度也是一种影响因素」。按 CIELAB 算，surface(98.08) 叠在窗口底(86.99) 上：α=0.4→91.59（≈containerHigh 91.93）、α=0.6→93.54（≈container 94.04）、α=0.7→94.83（≈containerLow 95.97）——透明度只是在两档 tone 之间插值，落地必然等于某个既有角色（C）。所以直接用不透明 token 选档，也更符合官方「同一 region 跨断点同角色」（A）。最终 rail 定 `surfaceContainer` 94.0（变量 `color/surfaceContainer`；曾建别名 `color/desktop/rail`，2026-10-23 已删除）。
23. ~~**NavigationRail 右侧 1dp 边框**~~（**已关闭，2026-10-23**）：根因是 rail 组件内一个 1dp `divider` 子矩形（8 个变体各一，`41:1541`/`41:1559`/`41:1652`/`41:1669`/`41:1686`/`41:1703`/`41:1721`/`41:1739`，fill `outlineVariant`），已在**组件源**关闭（实例继承），19 个实例复查全部隐藏；07 里两条残留列间分隔线 `41:1616`/`41:1795` 同批隐藏。
24. **画布标签是画布层**：07/08 两页的列头与行名文字（`74:1399`–`74:1416`）仅用于评审阅读，不进产品、不做 token。
25. ~~**medium 详情首屏末行越界**~~（**已关闭，2026-10-23 晚**）：600 详情简介由 3 行收到 2 行、后续内容整体上移 24，末行「添加时间」现落在 pane 内（y≈738，pane 底 776），首屏完整；仍按滚动视口出图，但不再裁内容。
26. ~~**1440 / 1920 的 pane 外边距 16**~~（**已关闭，2026-10-23 晚**）：用户要求按 24 统一，`41:2026`/`48:2663`/`48:2749`/`41:1578` 四帧的 pane 改为 (280,24) 1136×852，子节点 +8/+8、右对齐项按「内容右缘 1392」重算；1920 `72:1083` 原本已是 24。官方依据见 §5.1（A）。
27. **窗口底色与 rail 同色（2026-10-23 定，深夜再提一级）**：用户定「窗口底色就用 NavigationRail 的背景色」，19 个桌面帧帧底与 19 个 rail 实例 + 8 个组件变体 + 4 个 NavigationBar 变体统一绑 **`surfaceContainerLow`（96.0）**；`surfaceDim`（87.0）不再用于窗口，只作更暗面备用。rail 与窗口底无级差，边界全靠 pane（现 100.0，差 **4.03**）与 24dp 画布缝。
28. **历史/设置/书库的 390 字号已复核**：书库标题由 24 Medium 改 **24 Bold**（与 Home/Settings/History 一致）并上移到 y=16；设置 390 的 20 处行文本 15 → **14 Regular**；历史 390 保持 24 Bold / 12 Regular 副标 / 12 Medium 组标签。仍缺：设置 390 无副标题行（其他三档有），见第 30 条。
29. **「展开全文」如何在 Figma 里表达 Wrap**：Figma 没有「按钮吸附在文本最后一行行尾、放不下才换行」的能力，当前用**截断（maxLines + ENDING）+ 按钮紧随（间距 8）**模拟；Flutter 侧必须用 `Wrap`（文本 + TextButton 同一 flow），断点换行行为以代码为准，Figma 只是视觉近似。
30. ~~**设置 390 缺副标题行**~~（**已关闭，2026-10-23**）：已补 12 Regular / onSurfaceVariant 副标题「深色模式跟随系统 · 柔和玫瑰」于 (16,52)，标题以下全部内容下移 26。
31. **Chip 高度 32dp 是 B 级**：官方 guidelines 只说「8dp 圆角、label 与按钮同字阶」，`/specs` 抓取失败（109 字符）未给高度；32 取自 Flutter/material-web 实现值。若拿到官方 specs，改组件 `79:1719` 等而非模板。
32. **元数据 chip 的语义**：Figma 里「作品/作者/角色/标签」的值 chip 复用 `Chip/Filter` 未选态（中性描边外观），但语义上是跳转/筛选入口，代码侧对应 `OutlinedMetaChip`，不是 `FilterChip`。迁移时不要按组件名硬套。
33. ~~**Chip 未接入暗色样张**~~（**已关闭，2026-10-23**）：用户定 Figma 不做暗色模式，暗色值在代码层实现，因此不再补暗色样张；Chip 的暗色对比度按 `08` 的 token 对照在实现阶段验收。
34. **SearchBar hint 文案未做成 TEXT 属性**：8 个回灌实例都显示组件默认的「搜索漫画、作者…」；按页面改文案前需要给 `79:1980` 加 `Hint` 属性，否则实例文案跟组件联动失效。
35. **focused 的容器外边距 24→12 属布局层**：官方要求聚焦时搜索栏更贴近容器，组件本身不内建（组件只有 56 高的容器）；迁移时要在页面侧按状态切换 padding，否则视觉上只有图标变化。
36. **标题栏拖动区（2026-10-23 用户问「拖动区是什么」）**：桌面帧标题栏里**控件之外的横向空白**是窗口拖动命中区（rail 右侧到搜索框之间、搜索框与窗控之间、窗控右侧 8dp）。Figma 画不出来，只能在代码层实现（Windows 用 `WS_CAPTION` + `WM_NCHITTEST` 返回 `HTCAPTION`，Flutter 走 `window_manager.dragToMove`/`bitsdojo_window` 一类），控件自身不参与拖动。属实现契约，不是视觉规范。
37. ~~**桌面标题栏高度与搜索贴顶**~~（**已关闭，2026-10-23 晚**）：用户指出「搜索框离窗口顶部太近」，标题栏 48 → **56**，搜索 y=8（上下各 8）、窗控 y=12（垂直居中）、menu 中心 28；pane 顶 64 → 72、高 H−96，内容累计 +48。
38. ~~**menu 是否外置**~~（**已关闭，2026-10-23 晚**）：用户明确「菜单按钮归 NavigationRail，只是视觉上像标题栏」→ 13 个外置 `MenuButton` 实例删除，改用 rail 自带 `menu-open`（展开）/`menu`（折叠），随 rail 折叠移动。
39. ~~**SearchBar focused 是否保留 back**~~（**已关闭，2026-10-23 晚**）：用户定「保留 clear、移除 back」→ `80:1981` back 箭头删除，focused leading 与 unfocused 同为放大镜（新 `85:2311`），尾随 clear ✕ 保留；返回/失焦由页面层处理。
40. ~~**标题栏最终高度与 rail 首项间距**~~（**已关闭，2026-10-23 深夜**）：标题栏 56 → **64**（搜索 y=12、窗控 y=16、menu 中心 32），pane 顶 **80** / 高 **H−104** / 内容累计 **+56**；rail 内 menu 与首个导航项间距由 20 加到 **32dp**（8 个变体 item 下移 12、行距仍 68）。最终几何见 `09` §13.9 / §13.10。
41. ~~**暗色模式是否出 Figma 设计稿**~~（**已关闭，2026-10-23**）：用户定「Figma 设计稿里不做暗色模式，约定好值之后在代码层实现」——`Theme/A · Dark` 46 角色值与 A Dark 预览保留作为约定，暗色页面/样张不再产出；`SearchBar · Dark` 样张 `81:2017` 与说明 `81:2028` 已 delete_nodes。
42. **chrome/pane 再提亮一级（2026-10-23 深夜，已执行）**：用户观察「Gmail / Google 系网站桌面端耐看，背景色大多偏亮」，要求 pane 与 rail 各上调一级 → chrome（窗口底 / rail / NavigationBar）= `surfaceContainerLow` 96.0，pane = `surfaceContainerLowest` 100.0（纯白），pane 顶栏条 = `surface` 98.1，卡 / 列表行 = `surfaceContainerLow` 96.0。89 处填充重绑（55 chrome + 25 pane + 9 顶栏），46 角色与 tone 分布零改动。级差：chrome→pane 4.03、pane→卡 4.03、chrome→搜索框 4.04，**唯一低于 T2 的是 pane→顶栏条 1.93**——按「嵌套条靠高度与基线区分」处理（与 M3 顶栏条 spec 一致）。暗色镜像（chrome `#22191A` 9.9 / pane `#312829` 17.1 / 顶栏 `#191112` 5.9）只写入 §2.5 与 `08` §4.1 建议表，Figma 不出暗色稿。
43. **pane 底部内边距与底部裁切（2026-10-23 深夜，已执行）**：用户要求「不要让组件贴 pane 底，可直接裁剪一些信息」。按 pane 底 − 24 复查 25 帧，越界的 7 帧已修：`41:1578`（章节目录删「第 9 话」、列间分隔线 712→688、简介收到两句、按钮文案移到 y=614）、`41:1774`（分隔线 580→556、章节目录整体上移 16）、`72:900`/`72:1205`（「更新时间」并入路径行右列，删「添加时间」）、`48:2663`（数据卡 180→156，删「清除缓存」）、`75:1417`（数据卡 163→139，删「清除缓存」）、`41:2209`（hero 240→216、「为你推荐」上移 24；**继续阅读 3 条 + 推荐 3 卡**，数量按可用空间响应式调整，不做固定条数）。规则写入 §5.1「pane 底部内边距 24」。
44. **资源 KV 排版统一与行内垂直居中（2026-10-23 深夜，已执行）**：用户指出两处问题——(1) KV 字号/字重在不同帧不一致（「添加时间」两枚是裸色 + `lineHeight AUTO`），要求 **V = 图一 Regular 14、K = 图二 Medium 14**；(2) 响应式布局下同一行 KV 仍要**垂直居中**。已对 9 个详情帧（`72:1083`/`67:509`/`72:900`/`72:961`/`72:1022`/`72:1160`/`72:1205`/`72:1250`/`72:1295`）的全部 KV 节点：统一字族/字号/字重、`lineHeight` 一律 **20**、文本框高 **20**、同 y，K 绑 `onSurfaceVariant` / V 绑 `onSurface`；390 路径值收成单行 `D:\library\深海…`。复查：9 帧里每行 K/V 中心 y 完全相等（1440 行 664/664、704/704、744/744；1024 行 652/652、688/688；600 行 617/617、647/647、677/677、707/707；390 行 559/591/623/655/687）。另将首页 1024 恢复为 3 条继续阅读 + 3 张推荐卡（数量响应空间）。
45. **设置分组重做与图标缺口（2026-10-23 深夜，已执行）**：用户要求按官方 Lists 为设置页重做分组——「分组是较大圆角容器、行间有间距、首尾行圆角大、中间行圆角小、行右一般是 action 不是值」。落地：分组容器**不填色**（`set_fills([])`，圆角 20 + 内边距 8 只作几何占位，继承 pane 底色；用户 m04110 明确要求「SettingsGroup 不需要背景色」）；每行填 **`surface`**（`VariableID:10:51`，98.1，官方 List item container 角色）、gap 4、行高 56、组高 32+60n、行圆角 12/12+4/4/4+12、右侧值 + chevron「›」双槽（值↔chevron 间距 12）。模板只留 1–3 行（`101:1042` 1 行 440×92、`101:861` 2 行 440×152、`101:869` 3 行 440×212），4/5 行模板与说明已删；`SettingsRow` 组件集 `101:925`（Single `101:912` / First `101:913` / Middle `101:917` / Last `101:921`，行底色同步为 `surface`，即官方 List specs 的 item container）。四档设置页的 12 个组已按新规格重建（1440 `101:926`/`101:937`/`101:948`、1024 `101:956`/`101:967`/`101:977`、600 `101:985`/`101:996`/`101:1004`、390 `101:1012`/`101:1023`/`101:1034`），06 Patterns 的 `101:1058` 同步替换旧 `SettingSection 41:2496`。官方引文见 §5.1；「首尾大圆角」属本项目决策（B）。**第二轮修正（同日深夜，用户 m04110）**：①容器改为**不填色**（16 个组容器 `set_fills([])`，透明继承 pane）；②设置页四档**删除副标题**（1440 `48:2686`、1024 `75:1424`、600 `75:1487`、390 `79:1910`），标题下第一组间距统一 16，四档组位置整体上移 30 / 30 / 48 / 20；③模板帧高度校正为 92 / 152 / 212（原 112 / 176 / 240），说明文字统一下移 16；④24 个屏内 chevron 与 6 个模板 chevron 补绑 `onSurfaceVariant`（原先实心黑 #000），并删掉模板里重复的 6 个 chevron；⑤`SettingsRow` 4 个变体的行矩形补绑 `surface`；⑥演示框 `101:1073` 底色改 `surfaceContainerLowest`。官方补充正文（A）：Overview「item 高 56dp / 72dp / 88dp」、guidelines「Use gaps for contained lists…」「Limit dividers to uncontained or complex lists…」、accessibility「Indicate selection with more than color…」。
46. ~~**设置行 leading 图标未采纳**~~（**已采纳，2026-10-23 深夜第三轮**）：用户要求「leading 图标后右侧 action 参考图一」+「图标使用 GoogleSymbols 的图标」，图标槽落 **24×24 @ (16, 行y+16)**、标签右移到 **x=56**；图标来源与导入方式见第 47 条。
47. **设置行的图标来源、行底色与状态（2026-10-23 深夜第三轮，已执行）**：①行底色由 `surface` 98.1 改为 **`surfaceContainerLow` `10:56`（96.0）**，对 pane 100.0 = **4.03**；②leading 图标 24×24 落在 **(16, 行y+16)**，颜色绑 `onSurfaceVariant`；③右侧分两类：可选行（字体大小/行距/翻页方向/主题/强调色/语言）用「值 + ▾」，导航/数据行（导出阅读进度/导入备份）用「值 + ›」，值↔尾随图标间距 12；④高度 56，带 supporting text 时 **72**（label y=行y+18、supporting 13 Regular y=行y+40，样张 `105:946`）；⑤补 states 样张 `105:902`：Enabled / Hover（`onSurface` 8%）/ Focus（12% + 2dp `primary` 环）/ Pressed（12%）/ Disabled（内容 38%），`SettingsRow` 四变体同步补 icon + ▾ + 96 底色；⑥图标不是字体字形也不是网络图片：从应用依赖 `material_symbols_icons-4.2960.0/lib/fonts/MaterialSymbolsOutlined.ttf` 抽字形轮廓、烘成 24×24 viewBox（视觉 20）的 `path`，用 `import_svg` 变矢量——Figma 插件 API 无「图标 URL 节点」，`import_image` 的 `url` 只出栅格，直接设字体 `Material Symbols Outlined` / `Google Symbols` 报 `INTERNAL_ERROR: The font ... could not be loaded`（实测，B）。已用图标：format_size / format_line_spacing / swap_horiz / dark_mode / palette / translate / file_upload / file_download。
48. **设置页 list 侧改「附图样式」+ 两栏比例改 flexible（2026-10-24，已执行）**：用户四条（m00320）：①暂时不改代码、以设计稿为准；②设计稿阶段不必对齐代码；③采纳单 pane，若「fixed pane」指 list/detail 宽度则**改为 flexible**；④**list 侧 lists 组件用附图左半的样式**；⑤**左 list 与右 detail 的标题顶对齐**。首轮我提议「行全透明 + 无分组 + 组标题小字 + 选中胶囊」并请用户裁决（m00324），用户回：**要分组、保留 ✓ 第二线索、右栏保持现状不学附图**（m00325）。落地：list 栏 = 组标题 14/20 Medium `primary` 10:22 + 透明通栏行（高 56、行距 0、未选中无填充）+ 选中整行胶囊 r28 `primaryContainer` 10:25 / `onPrimaryContainer` 10:26 / check 18 @栏宽−34；组「通用」(阅读/外观) +「数据」(数据)，首行 y=组标题 y+32，组间 24；栏宽改 **list : detail = 1 : 3、gutter 24**（1440 266/798、1024 206/618，detail 左移并重算右对齐：值右缘 = 行右−35、chevron = 行右−32）；两栏标题同 y=158。四档 1440 48:2663 / 1024 75:1417 / 600 75:1480 / 390 48:2710 全部重做，删旧组 101:926–101:1034 共 9 个、1440 detail 内残留组标题 108:543；390 三个图标原为「VECTOR 绝对坐标落在 24×24 frame 外被裁掉」，改为克隆 600 的图标 frame 后修复（新 id 108:1000/108:1002/108:1004）。600/390 二级页 108:909 / 108:849 保持原右栏样式。规则见 §5.1。
49. **漫画库页（2026-10-24 新增 08 第 5 行）的未画状态与有意偏离**：只出「漫画 tab + 12 本漫画卡」主态，**未画**：①筛选与排序抽屉（代码 `LibraryFilterSortDrawer` 共 12 组——年龄限制 / 媒体类型 / 连载状态 / 标签 / 作者 / 语言 / 原作 / 角色 / 整理 / 仅显示待补元数据 / 按系列展开 / 排序）；②多选模式工具栏（`CatalogSelectionHeaderSection`：取消 / 全选本页 / 清除选择 / 编辑元数据 / 已选 N 本）；③空态（`libraryEmptyTitle`「暂无漫画」、`libraryNoMatchTitle`「没有匹配结果」+ 清除筛选）；④分页条（`LibraryPaginationBar`，`totalPages > 1` 时上下各一条）；⑤系列 tab 的卡片内容（标题 = 系列名、副标 =「N 卷」，网格同漫画）。**有意偏离三处**：(1) 1024 取 **4×200** 而非代码公式的 5×188，让折行落在封面下沿（B）；(2) 390 tabs 由底部 `ContentSwitcherBottomBar` 改为标题下方顶部 tabs，避免与 NavigationBar 叠成两条；(3) 桌面 1440/1024 不画页内搜索框（与标题栏 `GlobalSearchBar` 重复，代码侧也只是跳转）。**07 Templates 的书库四档 `41:1578`/`41:1774`/`41:1824`/`41:1975` 仍是旧设计**（BookListItem 行 + hero 详情 + chips，非网格），本轮未改也不删，以 08 第 5 行为准。封面用 tone 占位，真实封面素材仍待（同第 1 条）。

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
| 数值 token | `Number` 集合 44 项（spacing/radius/size/state/breakpoint/icon/elevation）建成；spacing 4/8 体系获用户批准 |
| Styles | 6 个 Effect Style（elevation/level0–5）与 5 个 Grid Style（四档栅格 + 8pt baseline）建成；02 页出对照卡 |
| 断点内边距与字号（2026-10-23） | 25 帧审计：pane 外边距 16/8(Home)/24 三种混用 → medium/expanded 统一 24；content 内边距 8/16/24 三种 → 水平 24 / 顶部 16；页面标题 24–32 混乱 → 32/28/24/24 四档（详情 22/22/20/18）。逐帧改 Home/Settings/History/Library 的 1024 与 600、Library 1440、详情 600 的「展开全文」重叠与 1440/1920 标题框越界；07 九帧、08 十六帧重叠仍为 0 |
| 仓库不存截图 | 删除 `design-system/research/material-design-3/assets/` 下 42 张 PNG；MASTER 内的图片引用改为节点索引（§2.5、§3.1、§6.1）；截图仅在 Figma 内查看，`design-system/example.png` 保留 |
| 01–04 文档页 | Tokens 总览、Effect/Grid、Foundations 规则、Material Symbols 图标页建成并截图 |
| 05 打样 | Button/Filled、IconButton/Standard、TextField/Filled 三个 COMPONENT 建成并完成变量绑定；证明 token 可落地，variant 矩阵未展开 |
| 组件状态矩阵 | 定 P0 五态（default/hover/pressed/disabled/selected）、P1 两态；focus 用焦点层，不进 variant；其余组合交给 component properties |
| 叠字修复 | 01 Tokens 初版分批坐标复用导致重叠，整块重建为 147 文本 + 92 色卡 |
| 桌面/大屏 | 调研官方 breakpoints / spacing / canonical examples / 5-steps，写成 `06-adaptive-desktop.md`；§5 扩为五档壳层、分栏矩阵、canonical layouts、页面映射与连续性规则 |
| Button 变体集 | Figma `39:1481`：Filled/Tonal/Outlined/Text × Default/Disabled，8 变体；disabled 改实色混合避免透明底发黑 |
| 导航组件 | `41:1539` NavigationBar（390×80，Selected 4 变体）；`41:1577` NavigationRail（Collapsed 80 / Expanded 256，Type × Selected 8 变体；条目自顶部 16 起、64 间距；无新建 FAB）；indicator 需置底，否则盖住图标 |
| 桌面模板 | `41:1578` `Template/Library · Large 1440`：expanded rail 256 + 左侧列表 400 + 右侧详情；官方 large 分栏规则落地验证 |
| 详情页重做（文档流） | 详情四档模板重做：`67:509` 1440 / `72:900` 1024 / `72:961` 600 / `72:1022` 390，XL `72:1083`；结构 = 顶栏 56 + 封面 + 标题/概要/CTA/简介（4 行 + 展开）+ 元数据 chip 行 + 资源 KV 两列；删除章节目录（应用无该结构）与阅读进度（用户定不需要） |
| 桌面区域 token（已撤销） | 曾建 `color/desktop/{window,pane,paneHeader,card,field}`（Light `71:884`–`71:888` / Dark `71:889`–`71:893`）作为 46 角色的别名；**2026-10-23 按用户要求删除该分类，改为直接绑 46 角色**（见下「色彩分类撤销」行）。`radius/pane` 20 保留 |
| 窗口底色规则 | 窗口/rail 走 `desktop/window`、pane 走 `desktop/pane`、顶栏条与 pane 内卡片走 `desktop/paneHeader`/`card`（**别名层已于 2026-10-23 撤销，改为直绑角色**）；pane 之间与帧边缘留 24 gap，去掉 NavigationRail 左侧 1px 分隔线（实例级 override） |
| 08 Detail 行重建 | 08 Screens 第五行 Detail 换成本轮四帧并置 `(0/1500/2600/3300, 4000)`；旧 `67:587`/`67:649`/`67:677`/`67:752` 与旧模板 `67:431` 删除；07/08 顶层帧重叠复测均为 0 |
| 多断点模板 | `41:1774` Expanded 1024×768（collapsed rail 80 + 列表 304 + 详情）；`41:1824` Medium 600×800（collapsed rail 80 + 单栏列表 + 筛选 chips + FAB） |
| P0 组件补齐 | `41:1886` FAB 4 尺寸；`41:1895` FilterChip 2 态；`41:1920` ListItem 3 行数；`41:1933` Card 3 风格；`41:1939` Dialog/Basic；全部绑定 A-Light 变量 |
| 业务 Patterns | `41:1946` BookListItem、`41:1951` ComicCard、`41:1955` ChapterRow；证明 frame `41:1956`。业务语义不下沉到 05 |
| 五档模板 | 补 Compact 390×844 `41:1975` 与 XL 1920×1080 `41:2384`（三栏，官方 XL 3-pane 上限）；至此 compact/medium/expanded/large/XL 齐全 |
| 首批 Screens | 首页 `41:2026`(1440)/`41:2209`(1024)/`41:2160`(600)/`41:2314`(390)；阅读器 `41:2097`(1440)/`41:2275`(1024)/`41:2139`(600)/`41:2363`(390)；均用实例 + 真实文案，验证 supporting pane 与 feed |
| 06 业务组件补齐 | `41:2498` HistoryRow、`41:2496` SettingsSection、`41:2497` MetadataPanel、`41:2516` ReaderToolbar、`41:2517` ReaderBottomBar；阅读器 overlay 改为组合而非整屏组件 |
| 05 布局与对齐 | 05 页按 12 个组件分行排布，消除 proof 与 FAB/Chip、SearchBar/Snackbar 与 rail 的叠压；NavigationBar 16 个 label 按图标中线重排；rail expanded indicator 56→101 覆盖图标+文字；FilterChip 内容居中；ListItem 两行态垂直居中 |
| Rail 去新建入口 | 业务为「先选库根路径再扫描」，建库低频：8 个 rail 变体删除「新建」FAB，条目上移（顶部 16 起、64 间距），collapsed 80 / expanded 256 分两行排布 |
| Rail indicator 对齐 | 6 个主变体 indicator y 修正：collapsed 80/144/208、expanded 92/156/220（此前统一按首页 −80 位移，pill 落到 label 上或压住图标上沿）；collapsed label x 由 28 改 27.5 与 rail 中线对齐；实例自动跟随，无需逐个改 |
| Settings 分组样式 | `41:2496` 重做为「分组标题 + 每行一张 56 高圆角卡（leading 24 图标 + 文案 + trailing chevron）」；图标 tune/palette/download/database 取自 Material Symbols |
| Reader 底栏重排 | `41:2517` 与四档阅读器页面 `41:2129`/`41:2306`/`41:2152`/`41:2376` 统一为 24 上一页 · 居中进度 · 页码 · 下一页 · 设置；旋转复制的下一箭头换成 arrow_forward 正立图标，修复与齿轮的垂直错位 |
| 09 States & Content Lab | `41:2520` 七块内容实验：loading 骨架、empty、error、offline、长文本截断、大图占位、density；状态复用组件而非新建组件 |
| Chip 组件体系 | 新建 `Chip/Filter`（`79:1721` 两变体）/ Assist `79:1732` / Suggestion `79:1733` / Input `79:1734` + `Chip/States · Light` `79:1753`；TEXT 属性 `Label`；旧 `FilterChip 41:1895` 删除；Templates/Screens 的 54 个旧 chip 与 library 四帧的 rect+text chip 全部换为实例；06 Patterns 新增「标签与 Chip 组」与「Chip 类型」两个分组 |
| 详情分区标题移除 | 五档模板 + 08 四屏删掉「元数据」「资源信息」两个 section title；按断点重算间距（行步距 40/36/30/32、分区 44、首行距展开全文 28、宽档按封面底 +32 夹取）；KV value 文本框高统一 19（路径 40 保留） |
| Rail 标签恢复 | collapsed rail 实例的 首页/书库/历史/设置 文字由隐藏改为显示（32 个），divider 保持关闭；详情五档与 08 四屏同步 |
| 10 Motion | `48:2574` 四个时长/曲线卡 + reduce-motion 条；与 §4.3 表一致 |
| 11 Handoff & A11y | `48:2610` 三列交接页：token→Flutter、组件→Flutter、a11y 与迁移顺序 |
| P0 补组件 | `48:2651` SearchBar、`48:2658` TopAppBar、`48:2662` Snackbar；SearchBar 替代模板里手绘的搜索框 |
| Settings 与 History 页面 | `48:2663`/`48:2710` 设置（阅读/外观/数据三组，桌面卡片化、移动端分组列表）；`48:2749`/`48:2803` 历史（今天/昨天/更早分组，2 列/单列） |
| Rail 官方规范改版 | 按 2025-05 官方 rail 文档（替代 baseline rail / drawer）：8 个变体补顶部 menu 切换图标（collapsed 用 `menu` 居中、expanded 用 `menu_open` 并与 destination 图标同 x=32）；选中图标改 filled（home/library_books/history/settings 的 `_fill1_24px`）；collapsed 选中 label 改 secondary（`text.secondary`）、全部 label 用 Label Medium；expanded indicator 由 101×32 改 101×56 并提到行顶、行距 64→68；collapsed 行距 64、顶部 52 起。NavigationBar 4 变体同步改 filled 选中图标 |
| Rail menu 对齐 | expanded 的 menu 从 `(16,16)` 移到 `(32,16)`，与 destination 图标列对齐；图标换成 `menu_open`（收起语义），collapsed 仍是 `menu`。4 个 expanded 变体与所有模板/页面实例同步 |
| 文字缩放样例 | 09 页新增 `57:532` Text scale 卡：100% / 150% / 200% 三档导航项，行高随字号增长、保留 padding、不截断 |
| 桌面调研三篇 | `research/material-design-3/07-supporting-pane.md`（模式定义、断点形态、采纳判定、Flutter/Figma 落点）、`08-tone-based-surfaces.md`（官方博文 A 级原文 + tone 实测 + 三方案）、`09-desktop-layout-reference.md`（`design-system/example.png` 像素反推：1440×900 稿、rail 80 / 列表 296 / 主内容 632 / 支撑 412、纯 tone 无分隔线） |
| 桌面三区 tone 映射 | §2.3 新增「桌面三区映射」与「tonal elevation 与 pane 互斥」；新增 §2.6 桌面级差对照表；§4.2 注明 level↔surfaceContainer 的 1:1 只对浮层成立。**不改 46 个 hex、不新增 color 变量、不动 D3**，级差亮 7.0/4.0、暗 10.0/6.0 |
| §5 依据修正 | ①§5.1/§5.2 括号误读改为官方原文（`1 or 2 (recommended)` 等）；②supporting pane 补 large/XL 官方 412（原统一写 360）；③§5.4 阅读器由「可选 trailing 360」改「可选浮层 ≤360」；④设置双栏阈值写明 ≥840；⑤§5.1 补 large/XL/expanded 三档拦宽取值；⑥§9 关闭 Grid margin 未决项 |
| 画布矩阵修复 | 08 Screens 12 帧改「行 = 页面、列 = 断点」矩阵（列 x 0/1500/2600/3300，行 y 0/1000/2000/3000），消除 4 处重叠并修掉 Reader 1024 `41:2275` 的 y=−346；07 Templates 5 帧同列同规则重排（`41:1774`→1500、`41:1824`→2600、`41:1975`→3300、XL `41:2384`→(0,1100)），消除 `41:1824`∩`41:2384` 的 100×80 重叠。两页现均 0 重叠，截图仅在 Figma 内查看 |
| 详情模板改造 | XL `41:2384` 由「书库三栏（书库列表 + 详情 + 阅读进度）」改造为 `Template/Comic detail · Extra-large 1920`：删列表栏与 2 条 1px 分隔线，详情区改「封面 180×252 + 标题 + 元数据 + 3 chips + 简介 + 开始阅读 + 章节目录 3 行」，支撑栏加 `surfaceContainer` 底色矩形 `67:418`（纯 tone）+ `MetadataPanel` 实例 `67:419`；rail 保留 256（用户指定） |
| 详情模板补档 | 新增 `67:431` Expanded 1024（rail 80 + 24 + 512 + 24 + 360 + 24）与 `67:509` Large 1440（rail 80 + 24 + 876 + 24 + 412 + 24）；rail 换 collapsed 变体 `41:1651`。expanded 实测：主区内容 464，元数据删「共 24 话」后 208 可单行，`MetadataPanel` 320 装不进 312 → 暂不放 |
| 详情 Screens 行 | 08 Screens 加第 5 行 `Detail`（y=4000）：`67:587`(1440) / `67:649`(1024) / `67:677`(600 单栏) / `67:752`(390 单栏)；600/390 的元数据与阅读进度落到主内容下方（官方 compact/medium） |
| 桌面底板 | ≥1200dp 帧加画布层底板（外扩 24、圆角 20、`#EAE8E6`）+ 窗口 chrome（圆角 12、1dp `outlineVariant`、`0/2/6 @12%` 投影，OS 层不进 M3 elevation）：07 模板 `67:749`/`67:750`/`67:751`，08 `67:781`–`67:785`；两页顶层帧重叠数仍为 0 |
| §5 布局依据回填 | 用户决策（书库不走 inline list-detail、设置走 ≥840、支撑栏按官方 expanded 360 / large·XL 412、详情模板共用）写入 §5.3；§5.4 书库行改「列表 → 独立详情」；§5.1 模板进度与栏宽换成实际三栏详情几何 + 桌面底板规则；§6.1 索引表补详情行与模板 id；§9 关闭书库阻塞项并新增 4 条未决 |
| 详情页按应用真实结构改版 | 用户对照应用截图指出：应用是「系列详情页 + 网格」读多本漫画，**没有章节模型**。详情模板改为应用真实结构：顶栏（返回 / 更多 / 编辑 / 系列内 ‹ 3 / 5 ›）+ 封面 220 + 标题 22 + 概要（语言 ｜ 页数 · 日期）+ 阅读/隐身阅读 + 简介 4 行 + 元数据 chip 行（作品/作者/角色/标签）+ 资源 KV（格式/大小/路径/更新时间）；删光所有章节目录与 `ChapterRow` 实例（XL `41:2384`、`67:431`、`67:587`、`67:649`、`67:677`、`67:752` 共 15 个节点） |
| 窗口底色规则 | §2.3 新增「桌面窗口与 pane 取色」：窗口底/rail = `surfaceContainerHigh`、内容 = `surface`、顶栏条/列表/卡片 = `surfaceContainerLow`、支撑栏 = `surfaceContainer`、输入/浮起卡 = `surfaceContainerLowest`；pane 之间留 24dp 窗口底间隙而非相邻 tone 硬拼。参考图逐像素取样：`#F6E4E3`≈containerHigh、`#FFF0EF`≈containerLow、`#FFF8F7`=surface、`#FFDAD9`≈primaryContainer（B 级，`09` §11） |
| 详情页两版对照 | `67:509` 改为 A 版（supporting pane 412 + 窗口底/顶栏分色）；新增 `69:813` B 版（1440，无支撑栏，底部三张 `surfaceContainerLow` 圆角卡：元数据 / 资源 / 进度，卡宽 400）。07 顶层 8 帧重叠 0；截图只在 Figma 内查看（B 版后按用户要求删除） |
| pane 全量铺开 | 07 书库四档与 08 非阅读器帧补 `pane/content`：≥600dp 用 (rail 右缘+16, 16) 起、圆角 20、右/下 16，帧底改 `color/surfaceDim`（原经 `color/desktop/window` 别名，该别名已删）；新增 pane `74:1387`–`74:1398`（12 帧）。README/`09` 同步 |
| compact 全出血 | 用户指出 compact 只在移动端出现，不应有窗口留白：详情 compact `72:1022`/`72:1295` 的 pane 由 (16,16) 358×812 改为整帧 390×844、圆角 0，内容整体 -(24,24)，帧自身去圆角/描边/阴影；书库/首页/历史/设置的 390 帧 pane 同样全出血、帧去 chrome。移动端顶栏条与 NavigationBar 满宽 |
| 窗口底色改 `surfaceDim` | 用户质疑「真的用了 tone-based surface colors 吗、跟参考图差得多」：逐像素比对定因为窗口/rail 取 `surfaceContainerHigh`（91.9）比参考 rail（87.0）浅 4.9 L\*；`surfaceDim`（`VariableID:10:53`）成为窗口底，14 个桌面帧与 5 个 1440 屏跟随，46 角色不变。改后 rail→pane 级差 11.1、参考 7.05（当时经 `color/desktop/window` 别名，该别名已于同日撤销、改为直绑） |
| 色相差异定性 | 用 CIELAB 复核：档位已对齐，色相方向不同（参考 a\*≈-2.4/b\*≈+4.6 绿灰，A 板 a\*≈+6.0/b\*≈+1.6 玫瑰粉，C\*≈5.2 vs 6.2）→ 属 D3 调色板既定，写入 §9 第 21 条，是否重生成 neutral 待决策 |
| rail 底色统一 | 用户指出各模板/页面 NavigationRail 背景不一致：旧帧是 `surface`(10:51)、详情帧被 override 成 `surfaceContainerHigh`(10:58)。统一为窗口底同色（当时经 `color/desktop/window` 别名 = `surfaceDim`；参考图里 rail 与窗口就是同一面），共改 16 个实例（07 八 + 08 八，其中 69:813 随帧删除）+ `05 Components` 的 8 个 NavigationRail 变体（`41:1557`/`41:1576`/`41:1651`/`41:1668`/`41:1685`/`41:1702`/`41:1720`/`41:1738`），组件源与实例一致 |
| 命名对照入档 | 按官方博文角色名（Surface Container Lowest/Low/Container/High/Highest、Surface Dim/Bright、Surface Tint）落一张官方名 ↔ 本仓库变量名对照表（§2.5），46 角色与两个新增 `stroke/*` 均用官方名的 camelCase（当时另设 `color/desktop/*` 区域快捷键，已于同日撤销） |
| Settings / History 补档 | 补齐 1024 与 600：Settings `75:1417`（1024，rail 80 + pane 912，三张 section 宽 864、高 224/176/152）与 `75:1480`（600，pane 488，section 宽 440、高 232/176/152，值右对齐 528）；History `75:1543`（1024，两列行 420×72 @x=120/564）与 `75:1613`（600，单列 440×72，六行分三组）。08 现 16 帧、重叠 0 |
| D 组对照帧删除 | 原卡组对照 `69:813` 按用户要求删除，07 剩九帧（书库四 + 详情 XL + 详情四档） |
| rail 改 `surfaceContainer` | 用户反馈 rail「太暗」并质疑定位色：官方 `navigation-rail/specs` 抓不到正文（只回 109 字符），降级到 Flutter SDK（`navigation_rail.dart:1230` rail 默认 = `surface`，B）。rail 定 `color/surfaceContainer` 94.0（暗色 `surfaceContainerHigh` 17.1；当时经 `color/desktop/rail` 别名，别名已于同日撤销、改为直绑），19 个实例 + 8 个组件变体统一绑定；rail 与 pane 差 4.0（满足 T2）、与窗口底差 7.0。透明度方案经 CIELAB 计算否决（α 只是两档间插值，§9 第 22 条）；对照条 `75:1685` 留在 `12 Archive` 供复看 |
| rail 分隔线关闭 | 8 个 NavigationRail 变体各自 1dp `divider`（fill `outlineVariant`，x=79）在组件源 `set_visible(false)`，实例自动继承；另隐藏 07 残留列间线 `41:1616`/`41:1795`，实现「纯 tone 分区、零 1dp 线」（§9 第 23 条） |
| 07/08 页面分组重排 | 两页改「左侧标签栏 + 行 = 页面/分组 + 列 = 断点」：列 x 320/1820/2920/3620，08 行 y 200/1300/2400/3500，07 行 y 200/1300/2500/3700；新增列头与行名文字 `74:1399`–`74:1416`。阅读器四帧 + 底板 `67:782` 移到 `12 Archive`（沉浸式、暂缓）。重排后 07 十帧、08 十二帧重叠均为 0 |
| 06 Patterns 分组重排 | 原页面组件散在 x=40 与 x=1600 两簇、无分组。改为「左侧标签栏 + 行 = 分组」：①列表与卡片 y=200（BookListItem 320 / ComicCard 760 / ChapterRow 1000）②结构面板 y=560（MetadataPanel 320 / SettingsSection 700 / HistoryRow 1120）③阅读器外壳 y=920/1024（ReaderToolbar + ReaderBottomBar 上下叠）④Proof 样张 `41:1956` (320,1200)；新增页标题/副标题、4 个行名、8 条「组件名 · 尺寸」画布文字 `77:1698`–`77:1711`（MiSans，onSurface / onSurfaceVariant，不进产品）。节点重叠 0 |
| 窗口底色 = rail 色（2026-10-23 晚） | 用户看线框稿后定「窗口底色就用 NavigationRail 的背景色」：19 个桌面帧帧底由 `surfaceDim`（87.0）改绑 `color/surfaceContainer`（94.0，`VariableID:10:57`），compact 四帧保持 `surface`；rail 与窗口同色后，rail 边界靠 pane（98.1）与 24 画布缝。`surfaceDim` 退出窗口用途（§9 第 27 条） |
| 1440/1920 pane 外边距统一 24 | `41:2026`/`48:2663`/`48:2749`/`41:1578` 的 pane 改 (280,24) 1136×852，子节点 +8/+8、右对齐项按内容右缘 1392 重算；1920 `72:1083` 原已 24。官方依据：canonical 原文 medium「margins of 24dp」、expanded「outer margin 24dp / spacer 24dp」（A） |
| 详情 header 对齐 + 展开紧跟 + KV 字阶 | 9 帧 detail pane header：← / 更多 / 编辑 同基线（pane.y+16）、x 间距 24，系列 `‹ 3 / 5 ›` 右对齐（pane 右 − inset − 51）；简介按断点截断（3/2/3 行）后「展开全文」紧随 8dp；资源 KV 统一 label 14 Medium / value 14 Regular（原 value 16 Medium）。lib 390 与 1024/600/1440 标题由 Medium 改 Bold |
| 390 字号复核 | 设置 390 的 20 处行文本 15 → 14 Regular；书库 390 标题 24 Medium → 24 Bold 且 y 20 → 16；历史 390 已合规。设置 390 仍缺副标题行（§9 第 30 条） |
| 文档流滚动视口 | 600 详情首屏不再裁内容：简介 2 行、后续上移 24，末行「添加时间」落在 pane 内（§9 第 25 条关闭）；Figma 仍按 800 高视口出图 |
| 色彩分类撤销（不建 `color/desktop`） | 用户要求「不要造一个 color/desktop 色彩分类，尽量复用 01 Tokens 的 token；NavigationRail 与 NavigationBar 共用一个背景色」。做法：①把 86 处填充从 12 个 `color/desktop/*` 别名变量改为**直接绑 46 角色**——帧底 `surfaceDim`(`10:53`)（后改为 `surfaceContainer`，见下「窗口底色=rail 色」一行；compact 帧改 `surface` 以保持全出血语义）、pane `surface`(`10:51`)、顶栏条/卡 `surfaceContainerLow`(`10:56`)、rail `surfaceContainer`(`10:57`)，涉及 07/08 的 19 帧底 + 25 pane + 9 顶栏 + 19 rail 实例 + 8 rail 变体；②删除 12 个别名变量（Light `71:884`–`71:888` + `75:1683`、Dark `71:889`–`71:893` + `75:1684`），变量面板只剩 46 角色 + `stroke/*`；③NavigationBar 4 个变体与 4 个实例本已绑 `color/surfaceContainer`(`10:57`)，与 rail 同角色 → **共用一个背景色**已成立；④`radius/pane` 20 保留（数值 token，不属色彩分类）。`#EAE8E6` 画布底板仍未升 token |
| 05 Components 分组重排 | 用户指「Components 页面有点乱」：22 个顶层节点原散在 x=80..1450、y=0..2548，Chip 资产挤在 (1450, 2100–2548)、Proof 样张占 (0,0)。改为「左列 260 标签栏 + 行 = 类别」：操作 Actions y=200（Button `39:1481` / FAB `41:1886`）、输入 Input y=440（SearchBar `48:2651`）、选择 Chip y=640（Filter `79:1721` / Assist / Suggestion / Input，状态样张 `79:1753` @760）、卡片与列表 y=1020（Card `41:1933` / ListItem `41:1920` @1260）、覆盖层 y=1460（Dialog `41:1939` / Snackbar `48:2662` / TopAppBar `48:2658`）、导航 y=1780（NavigationBar `41:1539` / NavigationRail `41:1577` @1950）、Proof 样张 y=3870（`25:1428`）。内容从 x=320 起，每组件下 13 号 caption；40 个顶层节点两两求交 overlap 0 |
| SearchBar 焦点态变体 | 用户给 Gmail 顶部搜索框常态/焦点态截图（焦点=白底细描边、常态=灰蓝填充，尾部筛选按钮明确不参考）。`SearchBar` 由 COMPONENT 升级为 COMPONENT_SET `79:1980`：`State=Rest` `48:2651`（360×56 r28、fill `surfaceContainer`、无描边）与 `State=Focused` `79:1976`（fill `surfaceContainerLowest` #FFFFFF + 1dp `outlineVariant` 内描边），两变体并排 x=0/384、set 744×56。边界对比度：Gmail `#DADCE0`/白 1.37:1、本项目 `outlineVariant`/白 1.70:1（同量级略强），若评审要更清晰切 `outline` 4.48:1 |
| SearchBar 改回官方 M3（Gmail 版作废） | 用户改口径「算了，还是不参考Gmail了 根据官方文档来设计」。官方 A 级原文：`Search bars use the surface container high color role`、`In the contained style, the search bar container remains the same shape in both the unfocused and focused states`、`Lower elevation and no shadow by default`、外边距 unfocused 24dp / focused 12dp、back 释放焦点、focused 可带 clear ✕、建议列表在 bar 下方。`79:1980` 两变体改为**同色同形**：`State=Unfocused` `48:2651` / `State=Focused` `79:1976` 均 `surfaceContainerHigh`（`10:58`，91.9）、r28、无描边无阴影；差异只在 leading（搜索图标 → back 箭头 `80:1981`）与 trailing（无 → ✕ `80:1983`）。上一版「焦点白底 + 1dp outlineVariant」全部撤销（`MASTER` 组件表 §7 同步） |
| 「纯 tone 分隔」规则收敛到区域级 | 用户问「『纯 tone 分隔、容器不加阴影』这条桌面规则来源」，并说明本意是「pane / NavigationRail 这些用背景色区分而不是边框」。核查：官方只有「区域用容器角色分区」（A，tone-based 博文）与「elevation token 不含阴影」（A，elevation overview），**没有任何页面说所有容器一律无阴影**；原先把这句话写成跨全部容器是我的外推（C）。§2.3 新增「适用范围」bullet：区域级（窗口底 / rail / 列表 / pane / 详情列）靠级差 + 24dp 缝；组件按各自 specs（search 无阴影 A；FAB / Dialog / Menu / Snackbar 允许阴影）。§9 第 14 条、`08` §11.14.1、`README` 结论 14/25 同步 |
| SearchBar 回灌 + 深色样张（2026-10-23） | 用户要求「回灌成 79:1980 实例」「做深色态」「不需要建议/结果列表容器」。8 帧旧搜索框（Home `41:2047`/`41:2229`/`41:2180`/`41:2317`，Library `41:1598`/`41:1793`/`41:1843`/`41:1977` 及其文案）换成 `48:2651` 实例 `80:1985`/`80:1989`/`80:1993`/`80:1997`/`80:2001`/`80:2005`/`80:2009`/`80:2013`，宽度沿用槽位、高度统一 56、y 按中心对齐（390 书库单独下移到 68 避开 chips）。右缘本就 = pane 右缘 − 24，故 24dp 规则不变。深色样张 `81:2017` @05 页 (1600,2600) + 说明 `81:2028`，直接绑暗色变量（一 collection 一 mode，不能同帧切主题）。05/07/08 顶层重叠均 0 |
| §9 新增 | 34. SearchBar hint 文案未做 TEXT 属性；35. focused 的 24→12 容器外边距属布局层、组件不内建 |
| 桌面标题栏 + 窗口控制（2026-10-23） | 用户定「expanded 也算桌面、medium/compact 算移动」，桌面要有背景底板 + Windows 式窗口控制，并加全局搜索框（与主 pane 左对齐）。已建 `WindowButton` 组件集 `84:2052`（min/max/restore/close，32 圆形）、`MenuButton` `84:2053`（40 圆形）、`GlobalSearchBar` `84:2058`（40 高 r20 containerHigh）；13 个桌面帧各加标题栏（menu 40 + 搜索 720 + 窗控 32×3）、pane 顶 24→64 高 −40、内容 +40、四帧压缩 20/16/16/20；桌面四帧删页内搜索；1024 帧补底板 `84:2301`–`84:2306`；05 页新增「桌面窗口壳」行（`84:2059` 标题栏样张、`84:2076` 窗控状态、说明 `84:2307`–`84:2310`）|
| 桌面口径写进断点表 | 五档表 expanded/large/XL 的壳层列补「桌面标题栏」；§5.1 新增「桌面/移动归属」「桌面标题栏」「桌面无页内搜索」「底板扩到 expanded」四条；§2.5 区域表新增标题栏/全局搜索/窗口按钮三行；§6.1 补 13 帧与底板清单；§7 新增三个桌面组件 |
| 桌面壳重做（56 标题栏） | 用户四条反馈：menu 必须归属 NavigationRail（删 13 个外置实例，改用 rail 自带 `menu-open`/`menu`）、搜索框必须与 pane 左缘对齐（x 由 pane.x+24 改为 pane.x）、搜索离顶部太近（标题栏 48→56、搜索 y=8、窗控 y=12、pane 顶 72、高 H−96、内容 +48 与四帧累计压缩 −28/−24/−24/−28）、SearchBar focused 保留 clear 移除 back（`80:1981` 删、新放大镜 `85:2311`）；05 样张 `84:2059` 与说明 `84:2307`–`84:2310` 同步；rail 折叠 motion 定为 emphasized decelerate 300ms / accelerate 250ms |
| 桌面壳二轮（64 标题栏） | 用户参照网易云音乐桌面端「整体再往下移一点」，标题栏 56→**64**：搜索 y=8→**12**、窗控 y=12→**16**（32×32 尺寸不变、仍垂直居中）、rail menu 保持 24 高 @ y=20（中心 32 = 栏中线）；pane 顶 72→**80**、高 H−96→**H−104**、内容再 +8（累计 **+56**）。两处溢出修复：`41:1578` divider `41:1616` 高 744→712、`41:1774` divider `41:1795` 高 612→580；Settings1440 三卡重排 192..452 / 476..680 / 696..876、`48:2683` 高 204；Settings1024 `75:1417` 三卡 192·404·581（高 198·163·163）、值列右缘 944 |
| rail 首项间距加大 | 用户要求「NavigationRail 导航项和顶部菜单按钮之间的间距适当增加」：8 个 rail 变体里 y≥60 的子节点统一下移 **12**（menu 保持 24 高 @ y=20，首个 indicator 顶 64→**76**，icon/label 同步；menu 底到 indicator 顶 **32dp**，原 20；item 行距仍 68）。改组件源而非实例（实例内子节点不可 set_position），19 个实例自动继承 |
| 暗色模式移出 Figma | 用户定「Figma 设计稿中不做暗色模式，约定好值后代码层实现」：保留 `Theme/A · Dark` 46 角色值 + `01 Tokens` A Dark 预览作色彩约定，删除 05 页 `SearchBar · Dark` 样张 `81:2017`（说明 `81:2028` 同步删除/合并）；§2.5 记明暗色按 token 对照验收；§9 关闭第 33 条并新增第 41 条 |
| rail 间距最终值（2026-10-23 深夜） | 用户要求「menu 到导航项组的间距在展开/收缩状态保持一致」：改为以**首个可见图标顶 y=104** 对齐（menu 底 44 → 60dp，两态一致）。折叠 indicator 100+64i / icon 104+64i / label 136+64i；展开 indicator 88+68i / icon 104+68i / label 106+68i。同时修掉折叠首项 icon 56 / label 100（间距 20）的旧 bug；8 变体内改，19 实例继承 |
| 暗色不出图（2026-10-23 深夜） | 按用户决策删除 `SearchBar · Dark` 样张 `81:2017` 与说明 `81:2028`；Figma 只保留 `Theme/A · Dark` 46 角色值与 A Dark 预览作色彩约定，暗色在代码层实现 |
| 区域提亮一级（2026-10-23 深夜） | 用户观察「Gmail / Google 系网站桌面端耐看，背景色大多偏亮」，要求 pane 与 rail 各上调一级。89 处 `set_fills`（4 个 batch）：chrome（窗口底 / rail / NavigationBar / 标题栏）= `surfaceContainerLow` `10:56`（96.0），pane = `surfaceContainerLowest` `10:55`（100.0 纯白），pane 顶栏条 = `surface` `10:51`（98.1）；共 55 chrome + 25 pane + 9 顶栏。级差 chrome→pane 4.03、pane→卡 4.03、顶栏条对 pane 1.93（嵌套条不计 T2）。顺带修 Settings1440「外观」分组卡宽度 `48:2683` 220→800。§2.3/§2.5/§2.6/§5.1 与 `08` §4.1 同步；46 角色零改动 |
| 设置分组重设计（2026-10-23 深夜） | 用户要求按官方 Lists 重做 `SettingsGroup`/`SettingsRow`，并按 specs 的 Color 表钉死颜色角色。落地：分组容器**不填色**（`set_fills([])`，圆角 20 + 内边距 8 只作几何占位；第二轮按用户 m04110 从 `surfaceContainer` 94.0 改透明）+ 标题左上 (8,8)；行 = **`surface` `10:51`（98.1，官方 List item container）**、高 56、宽 W−16、gap 4、圆角 12/12+4/4/4+12；标签 `onSurface` 15、值 + chevron `onSurfaceVariant`（值↔chevron 12）；组高 32+60n，模板只留 1–3 行（`101:1042`/`101:861`/`101:869`，4/5 行模板已删）；`SettingsRow` 组件集 `101:925` 变体 Single/First/Middle/Last；四档设置页 12 个组（`101:926`–`101:1034`）与 06 Patterns `101:1058` 全部重建，旧 `SettingSection 41:2496` 删除；选中态预留 `primaryContainer`/`onPrimaryContainer`（未出样张）。规则见 §5.1、未决见 §9 第 45/46 条 |
| 设置行图标 / 行底色 / 状态（2026-10-23 深夜第三轮） | 用户四条：行换 `surfaceContainerLow`、leading 图标（GoogleSymbols）、行高随内容自适应、补 hover/press 等态。落地：行 96.0（对 pane 4.03）、图标 24×24 @(16,行+16) 绑 `onSurfaceVariant`、标签 x=56、右侧「值 + ▾（可选行）/ ›（导航行）」间距 12、56/72 两种高度（`105:946` 样张）；states 样张 `105:902`（Hover 8% / Focus 12% + 2dp 环 / Pressed 12% / Disabled 38%）；`SettingsRow` 四变体补 icon 与 ▾、底色改 96；16 个组（四档 12 + Patterns 1 + 模板 3）与 28 个行同步。图标来源：Material Symbols 字体抽轮廓 → SVG → `import_svg`（字体字形与 URL 图片两条路均不可行，实测） |
| 设置页 list 侧改附图样式（2026-10-24） | 用户：list 侧用附图左半样式、左右标题顶对齐、两栏改 flexible、暂不改代码。**list 栏** = 组标题 14/20 Medium `primary`（「通用」阅读/外观、「数据」数据）+ 透明通栏行（56 高、行距 0、未选中无填充）+ 选中整行胶囊 r28 `primaryContainer`/`onPrimaryContainer`/check 18 @栏宽−34（保留 ✓ 作第二线索）；**栏宽 1 : 3 + gutter 24**（1440 266/798、1024 206/618）；两栏标题同 y=158；**右栏保持填充行样式**（用户裁决）。四档重做、删 9 个旧组 + 1440 残留组标题 `108:543`；390 图标被 24×24 frame 裁掉，克隆 600 图标修复。详见 §9 第 48 条 |
| 漫画库页新增（2026-10-24） | 用户要求「08 Screens 新增漫画库页面」，并先「从代码侧获取库页面需要哪些信息和必要的交互逻辑」。代码侧事实：页头 44 高（`LibraryPageHeaderToolbar`：标题 + `MetaChip` 计数「N 本 / N 个系列」+ 居中 `LibraryDisplayTargetTabs` + listFilter / 更多 / 每页数量 32 图标）、页内搜索提交只 `push('/searched?q=')`、`CatalogCoverCardShell`（封面 2:3 + 标题 + 「N 页」）、`libraryGridMaxCrossAxisExtent` 168/188/200 与间距 12/14/16、`LibraryLayoutTier` 内容 padding 16/28/48。落地 08 第 5 行（y=4600）四帧：1440 `109:1040`（6×168 gap16、12 卡）、1024 `109:1110`（4×200 gap16、8 卡、网格底部两角随 pane 圆角）、600 `109:1180`（头部两行 + 页内 SearchBar + 3×132、6 卡）、390 `109:1218`（标题 24 Bold + 顶部 tabs + SearchBar + 2×173、4 卡）。头部 / 网格 / 卡片规格见 §5.1，未画状态与偏离见 §9 第 49 条 |
