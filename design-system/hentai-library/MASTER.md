# Hentai Library · Material 3 设计系统（MASTER）

> 状态：**Figma 设计稿阶段完成，待评审**。本文件是设计系统的唯一规划入口；颜色方向 A 已定（亮/暗预览）、44 个 Number token、30 个 Text Style、6 个 Effect Style、5 个 Grid Style、01–04 文档页已建；05 已建齐 P0 原子组件集（Button / IconButton / TextField / SearchBar / TopAppBar / Snackbar / NavigationBar / NavigationRail / FAB / FilterChip / ListItem / Card / Dialog），06 有 8 个业务组件，07 五档模板齐全，08 首页与阅读器四档出图、Settings 与 History 各两档，09 States & Content Lab（含文字缩放样例）、10 Motion、11 Handoff & A11y 已建成。导航组件已按 2025-05 官方 rail 规范改版（menu 切换、active indicator 贴合内容、active 图标 filled）。代码未迁移。
> 代码未迁移：`app/` 仍是旧 Fluent 取向的主题与页面。设计稿评审通过后才改代码（见 §8）。
> 证据底稿：`design-system/research/material-design-3/`（01 基础、02 组件、03 Flutter 实现、04 Figma 工作流、05 粉色方向、06 自适应布局）。规范数值若与本文件冲突，先查底稿的证据级别（A 官方规范 / B 官方实现源码 / C 推断）。

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
- **桌面三区映射（large / XL，≥1200dp；官方「大窗口 add-on surface colors」，A）**：导航 rail 用 `surfaceDim`（暗色 `surfaceContainerHighest`）；导航列表与 supporting pane 用 `surfaceContainer`；主内容用 `surface`；面板内卡片 `surfaceContainerLow`（暗色 `surfaceContainerHigh`）。相邻级差亮色 7.0 / 4.0、暗色 10.0 / 6.0，**46 个 hex 一个不改**。**同一个 region 在它所存在的所有断点用同一角色**（官方「跨断点保持映射一致」，A；例如 rail 在 medium / large 都是 `surfaceDim`）。默认**纯 tone、不加线**（`example.png` 实测官方桌面产品即如此）；仅在「两个面板必须同 tone」或高环境光 / 低端屏时按需叠 1dp `outlineVariant`，**可交互边界改用 `outline`**（4.27 / 5.85 ≥ 3:1，而 `outlineVariant` 只有 1.62 / 1.99）。依据 `08` §4.1/§5、`09` §3.4。
- **tonal elevation 与 pane 互斥**：pane 级容器一律不叠 surfaceTint（`applySurfaceTint = false`）；tonal elevation 只留移动端组件级反馈与桌面浮层（menu / dialog / side sheet）。
- **桌面口径（硬，评审按此判定；完整版见 `08` §0.0）**：**T1 结构**——≥1200dp 的并列 pane 必须显式按区域取角色（rail `surfaceDim` / 列表与 supporting pane `surfaceContainer` / 内容 `surface`），以「区域」为参数而非以组件为参数；**T2 阈值**——相邻并列区域 ΔL\* 亮色 **< 4**、暗色 **< 6** 时必须叠 1dp `outlineVariant` 或提一档角色，**2 个 L\* 的档差不算分隔**；**T3 边界**——46 个 hex 不改、只新增 `stroke/hairline` 1dp 与 `stroke/focus` 2dp、阴影只给浮层 level 2–5 且 tint 全关、不回退 elevation-tint。桌面底板 `#EAE8E6` 是画布层，**不在 46 角色内**。
- **桌面窗口与 pane 取色（窗口底色规则，用户偏好 B 级）**：窗口底与 rail 同色 = `surfaceDim`（`#E7D6D7`，L\* 87.0），内容 pane = `surface`（`#FFF8F7`，98.1），pane 内顶栏条 / pane 内卡片 = `surfaceContainerLow`（`#FFF0F1`，96.0），输入框 / 浮起卡 = `surfaceContainerLowest`（`#FFFFFF`）。**pane 之间用 24dp 的窗口底间隙分隔**，不靠相邻 tone 硬拼（参考图里 18px 间隙即此手法，B）。**2026-10-23 修正**：窗口 / rail 由 `surfaceContainerHigh`（91.9）改为 `surfaceDim`（87.0）——参考图 rail 实测 L\* **87.0**，原来的 91.9 比参考浅 **4.9**，这是「明明用了 tone 角色却不像参考图」的唯一实现层原因；改后 rail→pane 级差 **11.1**（参考 7.05，同量级）。pane 顶栏条 96 对 pane 98.1 只有 2.1（< T2 的 4），pane 内卡片同样 2.0，靠圆角 + 内边距认边界（参考图卡片级差 1.74，同一手法）。

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
| 窗口底 / pane 间隙 | `surfaceDim` #E7D6D7 (`10:53`, 87.0) | `surfaceContainerLowest` #140C0D (`10:102`, 4.0) | 与参考图窗口边带同档（B） |
| 导航 rail **与 NavigationBar** | `surfaceContainer` #FBEAEB (`10:57`, 94.0) | `surfaceContainerHigh` #312829 (`10:105`, 17.1) | **两者共用同一角色**（2026-10-23 定）；与 pane 差 4.0 |
| 内容 pane | `surface` #FFF8F7 (`10:51`, 98.1) | `surfaceContainer` #261D1E (`10:104`, 11.9) | 最亮面，承载正文 |
| pane 顶栏条 / 分组卡 | `surfaceContainerLow` #FFF0F1 (`10:56`, 96.0) | `surfaceContainerHigh` #312829 (`10:105`, 17.1) | 与 pane 差 2.1，靠间距而非级差分隔 |
| 输入框 / 浮起卡 | `surfaceContainerLowest` #FFFFFF (`10:55`, 100.0) | `surfaceContainerHighest` #3C3233 (`10:106`, 21.9) | 搜索框、菜单、对话框 |

- 已清理：此前的 `color/desktop/{window,pane,paneHeader,card,field,rail}` 12 个别名变量（Light `71:884`–`71:888` + `75:1683`、Dark `71:889`–`71:893` + `75:1684`）**已全部删除**；86 处填充改为直接绑上表角色变量（07/08 共 19 帧底、25 个 pane、9 条顶栏、19 个 rail 实例 + 8 个 rail 变体），无 `color/desktop` 残留。`#EAE8E6` 画布底板仍未升 token（§9 第 12 条）。

**命名对照（按官方博文 Introduction to tone-based surfaces 的角色名，A；本仓库一律用其 camelCase）**

| 官方角色名（博文原文） | 本仓库变量 | 桌面用途 |
|---|---|---|
| Surface Container Lowest | `color/surfaceContainerLowest` | 输入框 / 浮起卡 / 暗色窗口底 |
| Surface Container Low | `color/surfaceContainerLow` | pane 顶栏条、pane 内卡片 |
| Surface Container | `color/surfaceContainer` | 列表面板、supporting pane、**亮色 rail 与 NavigationBar** |
| Surface Container High | `color/surfaceContainerHigh` | 高强调容器 |
| Surface Container Highest | `color/surfaceContainerHighest` | 暗色 rail / 抽屉 |
| Surface Dim | `color/surfaceDim` | **亮色窗口底**（作 rail 时偏暗，见下条） |
| Surface | `color/surface` | 内容 pane 底 |
| Surface Bright | `color/surfaceBright` | 暗色提亮面 |
| Surface Tint | `color/surfaceTint`（= primary） | 只给浮层 level 2–5 |

官方五档的定位原文（A）：`"surface container" is the recommended default color role for a contained area against the "surface" color role`，可从 `surface container lowest`（对 surface 强调最低）到 `surface container highest`（强调最高）组合。本仓库**不设区域快捷键层**：区域直接绑上表角色，`01 Tokens` 里只有 46 个 `color/<role>`（外加 `stroke/*`），没有 `color/desktop/*`。「同一 region 跨断点用同一角色」由「同一区域始终绑同一角色」保证（A）。

### 2.6 桌面级差对照表（large / XL，供评审与 Figma 重上色）

> 前提别读反：tone-based surface **本来就是为大屏新增**的模型（官方博文副标题 `New surface color roles offer more flexibility for large screens`，A），它正是为了让大屏不必再靠 elevation 叠色分区。本节的结论是「**同一个梯级**铺到并列大区时级差不足」，正解是动用官方为大窗口开的 **区域级 add-on surface colors**（也就是用**更多** tone 角色），而不是退回阴影。完整推理见 `research/material-design-3/08-tone-based-surfaces.md` §0.5。

| 区域 | 亮色角色 | L\* | 暗色角色 | L\* | 相邻级差（亮 / 暗） |
|---|---|---:|---|---:|---|
| 导航 rail | `surfaceContainer` `#FBEAEB` | 94.0 | `surfaceContainerHigh` `#312829` | 17.1 | rail→面板 **4.0 / 5.2**；rail→窗口底 **7.0 / 13.1** |
| 导航列表 · supporting pane | `surfaceContainer` `#FBEAEB` | 94.0 | `surfaceContainer` `#261D1E` | 11.9 | 面板→内容 **4.0 / 6.0** |
| 主内容 | `surface` `#FFF8F7` | 98.1 | `surface` `#191112` | 5.9 | — |
| 面板内卡片 | `surfaceContainerLow` `#FFF0F1` | 96.0 | `surfaceContainerHigh` `#312829` | 17.1 | 对所属面板 2.0 / 5.3 |
| 主内容浮起卡片 | `surfaceContainerLowest` `#FFFFFF` | 100.0 | `surfaceContainer` `#261D1E` | 11.9 | 对主内容 1.9 / — |

- 参考位：`design-system/example.png`（Google Chat 桌面改版）实测并列面板级差 **7.05 / 3.83**，同一手法、同一量级（B）。
- **rail 为何不用 `surfaceDim`（2026-10-23 修订）**：参考图里 rail 与窗口是同一面（都是 87.0），但本项目窗口底用 `surfaceDim` 后，rail 若同色就只剩一条 24dp 缝，实机偏闷（用户反馈「太暗」）。改为 `surfaceContainer`（94.0）后 rail 比 pane（98.1）低 4.0，恰好够 T2 的 ≥4，且与窗口底（87.0）拉出 7.0——**rail 取「比 pane 低一档、比窗口底高一档」**，两端都有边界。Flutter 官方实现里 rail 默认就是 `surface`（`navigation_rail.dart:1230`），本项目下移到 `surfaceContainer` 是有意的区域化取舍（B）。
- **暗色方向相反**：暗色没有更暗的 chrome，`surfaceDim` 在暗色等于 `surface`（#191112），因此 rail 走 `surfaceContainerHigh`（17.1，比窗口底 4.0 高 13.1）。
- 级差只用于「无边界并列的面板」；带圆角/内边距的卡片仍用 2 档级差，保持安静。

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
| expanded | 840–1199 | 1024×768 | Collapsed rail（可换 standard expanded） | 1 or 2 (recommended) | 12 列 / margin 24 / gutter 24 |
| large | 1200–1599 | 1440×900 | **Collapsed rail 80**（同屏 ≥3 栏）／Expanded rail 256（≤2 栏） | 1 or 2 (recommended) | 12 列 / margin 24 / gutter 24 |
| extra-large | ≥ 1600 | 1920×1080 | 同上（rail 宽度由**同屏栏数**决定，不只由断点决定） | 1 to 3 (recommended) | 12 列 / margin 24 / gutter 32 |

- 断点按**应用可用窗口**判断，不用设备类型；横竖屏、多窗口、折叠展开都会换档。
- 接缝测试：599/600、839/840、1199/1200、1599/1600 各出一张对照。
- 内容最大宽：large/XL 的正文区约 1200dp 居中，避免 1920 拉满；正文保持 40–60 字符/行。
- 代码现状 `app/lib/shared/ui/layout/app_layout_breakpoints.dart:10,13` 是 600/1024；迁移时改五档。
- 模板进度（五档齐全）：Compact 390×844 `41:1975`、Medium 600×800 `41:1824`、Expanded 1024×768 `41:1774`、Large 1440×900 `41:1578`。
- **详情模板（2026-10-23 已改/已建，见 `09` §7）**：XL `41:2384` 已由「书库三栏」改造为 `Template/Comic detail · Extra-large 1920`（rail 256 + 24 + 详情 1180 + 24 + supporting 412 + 24）；另新增 large `67:509`（rail 80 + 24 + 876 + 24 + 412 + 24）与 expanded `67:431`（rail 80 + 24 + 512 + 24 + 360 + 24）。
- **栏宽取值**：详情页三栏 = rail + 24 + 主区 + 24 + supporting + 24，主区 expanded 512 / large 876 / XL 1180，rail 80（XL 详情例外 256）；支撑栏宽见下条。**pane 间与帧右缘都留 24 画布底**（不照搬 `09` 参考图的 0 margin 全出血，用户要求支撑栏贴右但留白），pane 内 padding 24，分区靠 tone、不叠 1px 线。原「四栏 80+320+1108+412」方案**作废**（书库不走 inline list-detail）。
- **桌面底板（画布层，非 token）**：≥1200dp 的帧加底板（帧外扩 24、圆角 20、填充 `#EAE8E6`）+ 窗口 chrome（圆角 12、1dp `outlineVariant`、`0/2/6 @12%` 投影）。`#EAE8E6` 不在 46 个颜色角色里，代码中禁止使用。
- **pane 容器规则（2026-10-23 已全量铺开）**：≥600dp 的帧一律「帧底 `color/surfaceDim`（暗色 `surfaceContainerLowest`）→ rail（`color/surfaceContainer`，与 NavigationBar 同角色）→ 16 画布底 → pane（圆角 20、`color/surface`，右/下各留 16）」，pane 内内容自带 16–24 padding；**compact（<600dp，实际只在移动端出现）pane 全出血**：pane = 整帧 (0,0,W,H)、圆角 0、帧自身无圆角/描边/阴影，顶栏条与 NavigationBar 同样满宽——移动端没有窗口外壳，不要再套桌面留白。阅读器是例外：全出血阅读面 + toolbar / bottom bar 浮层，不套 pane。已套用：07 书库四档 `41:1578`/`41:1774`/`41:1824`/`41:1975` 与详情五档；08 非阅读器帧全部（pane id `74:1387`–`74:1398`）。
- **supporting pane 宽**：expanded **360**（官方 A 级）；large / XL **412**（官方 A 级）。旧文档统一写 360 是漏了 large/XL 的默认值，已按 `07-supporting-pane.md` §4.1 修正。

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
- **书库列表页不走 inline list-detail**（用户决策）：保持「列表 → 独立详情路由」，所以 `41:2384` 改造为详情模板、不再有列表栏。
- **设置页走 inline list-detail**（用户决策）：设置根页双栏（分类 + 内容，阈值 **≥840**），二级页（阅读 / 外观 / 数据）单栏；官方 key use cases 原文 `Settings + category detail` 归 list-detail，代码现为 600，需改 840。
- **不采纳**：阅读器 + 章节目录（无章节模型、无页缩略图管线、与沉浸式冲突 → 改「可召唤浮层 ≤360」，见 §5.4）。
- MVP 不做拖拽调宽；官方 resize 快照取 360 / 412 / split 三档，够用。

**Feed**（首页、搜索、历史列表）：网格卡片；compact 单列铺满，medium 起加列，expanded/large/XL 列数继续增加；用大小与位置表达层级，重排保持顺序。

### 5.4 页面 → 布局映射

| 页面 | Compact | Medium | Expanded | Large / XL |
|---|---|---|---|---|
| 首页 Home | feed 单列 | feed 2 列 | feed 3 列 | feed 4–5 列，内容限宽 |
| 书库 All libraries | 列表 → 详情路由 | 列表 → 详情路由（**不做 inline list-detail**） | 列表 → 详情路由 | 列表 → 详情路由；详情页走 §5.3 |
| 单本详情 Library | **文档流单栏**：封面 96 + 标题/概要/CTA/简介（4 行截断 + 展开全文）/ 元数据 chip 行 / 资源 KV，pane 358（16 边距） | **文档流单栏**：折叠 rail 80 + pane 472，封面 140 + 右侧文本 260 | **文档流**：折叠 rail 80 + 24 + pane 896 + 24，内容 848（封面 220 + 24 + 文本 604） | large：rail 80 + 24 + pane 1312 + 24（主区 1120）；XL：rail 256 + 24 + pane 1616 + 24（主区 1324）；KV 在宽档排两列 |
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
| 05 Components | `9:13` | 无业务语义的原子组件 | 三个打样（`25:1428`：Button/Filled `25:1434`、IconButton/Standard `25:1438`、TextField/Filled `25:1442`）+ **Button 变体集 `39:1481`**（Filled/Tonal/Outlined/Text × Default/Disabled，8 变体）+ **NavigationBar 变体集 `41:1539`**（Selected=home/library-books/history/settings，4 变体）+ **NavigationRail 变体集 `41:1577`**（Type=Collapsed/Expanded × Selected=home/library-books/history/settings，8 变体；collapsed 与 expanded 分两行排布；**不含「新建」FAB**：业务是先选库根路径再扫描，建库低频；已按 §5.6 改版：顶部 menu 切换图标、选中图标 filled、collapsed 选中 label 用 secondary、expanded indicator 101×56 贴合内容、行距 68）；NavigationBar 同步改为 filled 选中图标；**FAB `41:1886`**（Regular 56 / Medium 80 / Large 96 / Extended 136×56）、**FilterChip `41:1895`**（Unselected / Selected）、**ListItem `41:1920`**（Lines 1/2/3，56/72/88）、**Card `41:1933`**（Filled / Elevated / Outlined）、**Dialog/Basic `41:1939`**（320×220）|
| 06 Patterns | `9:14` | 有业务语义的组合（书籍行、漫画卡、章节行） | 已建：`BookListItem` `41:1946`（368×80，封面 48×64 + 标题 16 + meta 12 + 进度条）、`ComicCard` `41:1951`（160×276，封面 160×220）、`ChapterRow` `41:1955`（360×48）、`HistoryRow` `41:2498`（360×72）、`SettingsSection` `41:2496`（360×284：分组标题 + 4 张 56 高行卡，leading 24 图标 + 15 文案 + trailing 16 chevron）、`MetadataPanel` `41:2497`（320×240，5 组键值）、`ReaderToolbar` `41:2516`（1080×64）、`ReaderBottomBar` `41:2517`（1080×80：24 上一页 · 400 进度条 + 页码 · 24 下一页 · 24 设置，统一 28 垂直居中）；证明 frame `41:1956`。**页面分组（2026-10-23）**：左侧标签栏 + 行 = 分组、组内左起排布——①列表与卡片 y=200（BookListItem 320 / ComicCard 760 / ChapterRow 1000）②结构面板 y=560（MetadataPanel 320 / SettingsSection 700 / HistoryRow 1120）③阅读器外壳 y=920（ReaderToolbar 320,920 + ReaderBottomBar 320,1024 上下叠）④Proof 样张 `41:1956` (320,1200) 1440×900；画布文字 `77:1698`–`77:1711`（页标题、副标题、4 个行名、8 条组件名 × 尺寸说明），节点重叠 0 |
| 07 Templates | `9:15` | 五档壳层模板 | **五档齐全**：Compact 390×844 `41:1975`（导航栏 80 + 单栏列表 + FAB）、Medium 600×800 `41:1824`（collapsed rail 80）、Expanded 1024×768 `41:1774`（collapsed rail 80 + 列表 304 + 详情）、Large 1440×900 `41:1578`（expanded rail 256 + 列表 400 + 详情）、XL 1920×1080 `41:2384`（三栏：rail 256 + 列表 504 + 详情 + 阅读进度 360） |
| 08 Screens | `9:16` | 带真实内容的页面实例（四行 × 四列） | Home：1440 `41:2026` / 1024 `41:2209` / 600 `41:2160` / 390 `41:2314`；Settings：1440 `48:2663` / 1024 `75:1417` / 600 `75:1480` / 390 `48:2710`；History：1440 `48:2749` / 1024 `75:1543` / 600 `75:1613` / 390 `48:2803`；Comic detail：1440 `72:1160` / 1024 `72:1205` / 600 `72:1250` / 390 `72:1295`。四行四列已补齐，共 16 帧、重叠 0；**Reader 四帧按用户要求撤出**（沉浸式、暂缓），移到 `12 Archive` |
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
| 书库模板 | `41:1578` | `41:1774` | `41:1824` | `41:1975` |
| 设置 | `48:2663` | — | — | `48:2710` |
| 历史 | `48:2749` | — | — | `48:2803` |
| **详情 Screen** | `72:1160` | `72:1205` | `72:1250` | `72:1295` |

详情 **模板**在 07 Templates 页：XL `72:1083`（`Template/Comic detail · Extra-large 1920`，1920×1080，rail 256）、Large `67:509`（1440×900，rail 80）、Expanded `72:900`（1024×768）、Medium `72:961`（600×800）、Compact `72:1022`（390×844）。旧的 `41:2384`（书库三栏改造版）与旧 detail 屏 `67:587` / `67:649` / `67:677` / `67:752` 已删除；`69:813` 是 A/B 时的卡组版 B，保留作历史对照。模板帧的桌面底板仍是 `67:749` / `67:750` / `67:751`，08 的 5 个 1440 帧底板为 `67:781`–`67:785`。

**画布矩阵（2026-10-23 修复重叠后）**：08 / 07 两页统一按「行 = 页面、列 = 断点」排布，避免帧互相压叠。

- 列 x = `320` / `1820` / `2920` / `3620` ↔ Large 1440 / Expanded 1024 / Medium 600 / Compact 390；左侧 `x=0` 留 260 宽标签栏（行名、列头文字，`74:1399`–`74:1416`）。
- 08 行 y = `200` / `1300` / `2400` / `3500` ↔ Home（首页）/ Settings（设置）/ History（历史）/ Comic detail（漫画详情）。**阅读器四帧已移出本页**（用户定「阅读器暂缓、走沉浸式」，现停 `12 Archive` 页 (0,1100) 起 2×2 排列）。**Settings / History 的 1024 与 600 已补齐**（`75:1417`、`75:1480`、`75:1543`、`75:1613`），本页现 16 帧、四行四列满格。
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
| Text Field / Search Bar | P0 | filled/outlined × focus/error | 已打样 filled 320×56；SearchBar `48:2651`（360×56/r28，surfaceContainer + 24 搜索图标 + 16 占位）；桌面 hover/focus state layer |
| Top App Bar | P0 | small/medium/large × back/actions | 已建 `48:2658`：960×64，back 24 + title-large 22 + more_vert；大屏无阴影，滚动才上 tint |
| Navigation Bar / Rail | P0 | destinations 3–5 × selected | 已建：NavigationBar `41:1539`（390×80，4 变体，选中图标 filled）；NavigationRail `41:1577`（Collapsed 80 / Expanded 256，各 4 个 Selected 变体；顶部 menu 切换；collapsed 行距 64、indicator 56×32；expanded 行距 68、indicator 101×56 贴合内容；无新建 FAB）。解剖与官方依据见 §5.6，切换策略见 §5.2 |
| List Item | P0 | 1/2/3 line × leading/trailing | 已建 `41:1920`：56/72/88，leading 40 圆头像 + 文案 + trailing more_vert；书籍场景的 2:3 封面变体放 06 Patterns |
| Card | P0 | elevated/filled/outlined | 已建 `41:1933`：240×160/r12，Filled 用 surfaceContainerHighest、Elevated 用 surfaceContainerLow + level1、Outlined 用 surface + outlineVariant |
| Chip | P0 | assist/filter/input/suggestion | 已建 `41:1895` FilterChip：96×32/r8，未选 outline、选中 secondaryContainer + check 18；assist/input/suggestion 后续按需 |
| Dialog | P0 | basic/full-screen × scrollable | 已建 `41:1939` Dialog/Basic：320×220/r28/surfaceContainerHigh，标题 24 + 正文 14 + 两个文本按钮；桌面宽度上限与 full-screen 变体后续 |
| Snackbar | P0 | 1/2 line × action | 已建 `48:2662`：344×48/r4，inverseSurface 底 + inverseOnSurface 文案 + inversePrimary 动作；桌面底部居中、移动端贴底 |
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

已知阻塞：`app/test/project_layout_test.dart:36-54` 仍断言本文件存在且含 `## Directory charter`、`pages/` 目录存在；`pages/` 尚未重建，迁移窗口内该测试会失败，按约定暂不修。

## 9. 未决事项

1. **插图与占位图**：04 页目前只有图标；封面、占位构图、空态插图未定来源（自绘 / 授权素材）。
2. ~~**Grid margin**~~（**已关闭**）：compact 16 / medium 及以上 24 已由 `07-supporting-pane.md` §4 取到官方原文（A 级），不再是 C 级推断。Figma Grid Style 仍无 margin 参数，属工具限制，不影响决策。
3. **导航组件精确 dp**：navigation bar 高 80、collapsed rail 宽 80、indicator 56×32 有实现值佐证（B）；expanded indicator 101×56 与行距 68 由官方截图 2× 反推（B）；rail 宽 256 是项目取值。官方 `/specs` 页 JS 渲染抓取失败，若后续拿到数值，改组件集而非模板。
4. **rail 展开/收起的动效时长**：官方只说 indicator 从图标中心展开，未给时长；暂用 §4.3 的 Standard 300ms（`cubic-bezier(0.2,0,0,1)`），拿到官方数值再定。
5. ~~**书库是否改 inline list-detail**~~（**已关闭，2026-10-23**）：用户定「书库不走 inline list-detail，设置页走」→ `41:2384` 改造为详情模板，large/XL 详情均为三栏；`09` §9.1 同步关闭。
6. **rail 用 80 还是 256 的切换规则**：`09` §3.2 提出「同屏 ≥3 栏 ⇒ 80」，是从官方产品截图反推（B），无官方条文。需在 1440 / 1920 两帧出图对比。
7. ~~**桌面 rail 取 `surfaceDim` 的玫瑰倾向**~~（**档位已改，色相倾向仍在**）：rail 已由 `surfaceDim`（87.0）改为 `surfaceContainer`（94.0），亮度问题解决；但 A 板 tonalSpot 在 tone 94 仍有低彩度（`#FBEAEB`，C\*≈5.4），整片铺 rail 会偏粉，属 §9 第 21 条的调色板决策。原记录：整片铺 rail 会偏粉。退路是 `surfaceContainerHighest`（tone 90）+ 1dp `outlineVariant`。**暗色 chrome 反向**（rail 用 `surfaceContainerHighest`）需设计评审确认。
8. **级差感知阈值无实测**：ΔL\* 2 / 4 / 7 的「能不能看清」是 C 级工程判断，官方只给对比度可访问性标准、不给分区级差规范。要做成规范需 5–8 人快速辨色测试。
9. **`MetadataPanel` 312 版**：组件现为固定 320 宽，装不进 expanded 支撑栏 360 的内容宽 312；出 312 版（或支持 16 内边距）之前，expanded 支撑栏只放阅读进度。
10. **详情页 rail 256 与 80 的对比**：XL 详情按用户指定用了 expanded 256，large/expanded 用 collapsed 80。需在 1920 上各出一版看详情 1180 是否过宽。
11. **`ChapterRow` 的「已读」不随行宽右对齐**：组件内固定 x=312，实例加宽后（XL 1132 / large 828）停在偏左；实例内子节点不能单独移动，需改组件布局属性。
12. **桌面底板 `#EAE8E6` 的定位**：现作为画布层（非 46 角色之一），是否要升为正式 token（例如 `color/canvasShell`）待评审——若升，需同时定暗色值。
13. ~~**详情页 A/B 选型**~~（**已关闭，2026-10-23**）：用户定**方案 1 · 文档流**（无支撑栏、无卡组），KV 按断点/宽度响应式，pane 圆角 20、卡 16，简介 4 行截断 + 「展开全文」；对照用的卡组版 `69:813` 已按用户要求**删除**（不再留作对照）。
14. **pane 内卡片与 pane 的级差只有 2.0**（仍开放）：窗口底已改 `surfaceDim`（87.0）、rail 已改 `surfaceContainer`（94.0）、pane 仍是 `surface`（98.1）。现在 pane 内卡片 `surfaceContainerLow`（96.0）对 pane 只有 2.0（< T2 的 4），靠卡片的 16 圆角与 24 内边距认边界。评审需定：接受圆角认边界，还是给 pane 内卡片补 1dp `outlineVariant`（会打破「纯 tone 无分隔线」）。
15. ~~**Home / Reader 残留 `ChapterRow`**~~（**已关闭，2026-10-23**）：`9:16` 的 10 个实例已删；`ChapterRow` 组件定义保留给阅读器章节列表，本批页面不再使用。
16. **600 / 390 详情首屏装不下**：文档流按内容顺序排，600 的 pane 内容 424×752、390 为 310×812，资源 KV 末行贴着 pane 底；Figma 帧是「滚动视口」表现，超出部分被裁。评审要看的是滚动后是否仍成立（无二次留白断层）。
17. **collapsed rail 的文字标签**：Figma 里对 80 宽实例逐个 override 隐藏了 `首页/书库/历史/设置` 文字与左侧 1px 分隔线（实例级，不进组件）；Flutter 侧对应做法是 icon + tooltip，需在迁移任务里写明。
18. **圆角三层**：画布底板 20 / 窗口 frame chrome 12 / pane 20 / 卡 16 目前并存；底板与 frame 是「画布演示层」，pane/卡 才是产品层。评审若认为底板 20 会被误读成产品圆角，改成 12 或去掉。
19. ~~**阅读器不套 pane**~~（**已关闭，2026-10-23**）：用户定「阅读器页面暂时不做设计稿，阅读页要走沉浸式」，四帧（`41:2097`/`41:2275`/`41:2139`/`41:2363`）与底板 `67:782` 已从 08 移到 `12 Archive`，不再参与本批评审；恢复时按全出血 + 浮层 toolbar 重做，不套 pane。
20. **medium / compact 的 pane 内边距未统一**：现内容按 16 内边距排（pane 到内容），桌面档为 24；本轮只统一结构，padding 统一放到迁移时按 `space/*` token 处理。
21. **中性色相与参考图不同方向（已确认不是档位问题）**：与 `example.png` 逐像素比，L\* 档位已对齐（窗口底 87.0 vs 参考 rail 87.0；pane 98.1 vs 内容 97.9；卡片 96.0 vs 卡片 96.1），但色相相反——参考中性色 `a*≈-2.4, b*≈+4.6`（偏绿灰，C\*≈5.2），本项目 A 板 `a*≈+6.0, b*≈+1.6`（偏玫瑰粉，C\*≈6.2）。这是 D3「A 柔和玫瑰 + neutral chroma 6」的既定结果，**不是 tone 用错**。若要更接近参考的灰，需重生成 neutral 调色板（chroma 2–3 或色相归零），会改动 46 个 hex，属换调色板决策。
22. ~~**rail 用透明度调色**~~（**已关闭，2026-10-23**）：用户提出「透明度也是一种影响因素」。按 CIELAB 算，surface(98.08) 叠在窗口底(86.99) 上：α=0.4→91.59（≈containerHigh 91.93）、α=0.6→93.54（≈container 94.04）、α=0.7→94.83（≈containerLow 95.97）——透明度只是在两档 tone 之间插值，落地必然等于某个既有角色（C）。所以直接用不透明 token 选档，也更符合官方「同一 region 跨断点同角色」（A）。最终 rail 定 `surfaceContainer` 94.0（变量 `color/surfaceContainer`；曾建别名 `color/desktop/rail`，2026-10-23 已删除）。
23. ~~**NavigationRail 右侧 1dp 边框**~~（**已关闭，2026-10-23**）：根因是 rail 组件内一个 1dp `divider` 子矩形（8 个变体各一，`41:1541`/`41:1559`/`41:1652`/`41:1669`/`41:1686`/`41:1703`/`41:1721`/`41:1739`，fill `outlineVariant`），已在**组件源**关闭（实例继承），19 个实例复查全部隐藏；07 里两条残留列间分隔线 `41:1616`/`41:1795` 同批隐藏。
24. **画布标签是画布层**：07/08 两页的列头与行名文字（`74:1399`–`74:1416`）仅用于评审阅读，不进产品、不做 token。
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
| 色彩分类撤销（不建 `color/desktop`） | 用户要求「不要造一个 color/desktop 色彩分类，尽量复用 01 Tokens 的 token；NavigationRail 与 NavigationBar 共用一个背景色」。做法：①把 86 处填充从 12 个 `color/desktop/*` 别名变量改为**直接绑 46 角色**——帧底 `surfaceDim`(`10:53`，compact 帧改 `surface` 以保持全出血语义)、pane `surface`(`10:51`)、顶栏条/卡 `surfaceContainerLow`(`10:56`)、rail `surfaceContainer`(`10:57`)，涉及 07/08 的 19 帧底 + 25 pane + 9 顶栏 + 19 rail 实例 + 8 rail 变体；②删除 12 个别名变量（Light `71:884`–`71:888` + `75:1683`、Dark `71:889`–`71:893` + `75:1684`），变量面板只剩 46 角色 + `stroke/*`；③NavigationBar 4 个变体与 4 个实例本已绑 `color/surfaceContainer`(`10:57`)，与 rail 同角色 → **共用一个背景色**已成立；④`radius/pane` 20 保留（数值 token，不属色彩分类）。`#EAE8E6` 画布底板仍未升 token |
