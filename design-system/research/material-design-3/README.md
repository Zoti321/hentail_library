# Material 3 设计系统调研（索引与决策清单）

> 本目录是 **设计系统重写的调研底稿**，不是最终规范。旧 Fluent 设计系统文档（`design-system/hentai-library/` 24 个文件）已整体删除（`git rm` 暂存），目录保留，历史可从 HEAD 取回。
> 当前阶段：**Figma 设计稿阶段完成，待评审**（D1–D8 全部拍板；颜色 A 亮/暗、44 Number token、30 Text Style、6 Effect + 5 Grid Style、01–04 文档页；05 P0 原子组件（含 SearchBar / TopAppBar / Snackbar，12 个组件分行排布并完成图标/文字对齐）；06 八个业务组件（SettingsSection 改为分组卡样式、ReaderBottomBar 重排、rail 去掉新建入口）；07 五档模板 compact 390 / medium 600 / expanded 1024 / large 1440 / XL 1920；08 首页 + 阅读器四档出图，Settings 与 History 各 1440/390；09 States & Content Lab（含 Text scale 100/150/200% 样例）；10 Motion；11 Handoff & A11y；导航 rail 已按 2025-05 官方规范改版：collapsed/expanded 双形态、顶部 menu 切换、expanded active indicator 贴合内容 101×56、选中图标 filled、未选中 label 用 Label Medium）。**2026-10-23 桌面补强已完成 Figma 侧**：`41:2384` 由书库三栏改造为 XL 详情模板、新增 large / expanded 两档详情模板、08 Screens 加第 5 行 `Detail`、large/XL 帧加桌面底板（详见 `09` §7–§8）。代码仍未动，等设计稿评审。设计稿评审通过后才进入实现。
> 证据分级：**A** = 官方规范页/设计文档原文（含官方博文）；**B** = 官方源码/实现（Compose `*Tokens.kt`、material-web `tokens/v0_192`、Flutter SDK 源码）**或按官方产品截图逐像素反推**——数值可信但非规范页；**C** = 未核实/工程推断。抓不到的官方页面不编数值。各文档正文逐条标注。

## 文档索引

| 文件 | 行数 | 唯一官方 URL | 覆盖 | 最关键的结论 |
|---|---:|---:|---|---|
| `01-foundations.md` | 577 | 34 | tokens 三层、颜色（49 角色表）、state layer、排版（30 样式）、shape、elevation、motion、布局/断点、图标、a11y、官方工具 | baseline `surface` = Neutral98/6；`surface-tint` 恒等于 primary；断点 600/840/1200/1600；type scale 有 3 处跨实现 tracking 冲突 |
| `02-components-patterns.md` | 488 | 27 | 组件目录与逐项规格、导航/选择模式、大屏与桌面、Expressive 组件状态、组件级 a11y、state layer 落地 | Expressive 是**逐平台逐组件**可选，不是全局升级；SegmentedButton 自 2025-05 起官方不再推荐；Flutter 普遍停在 Expressive 之前 |
| `03-flutter-implementation.md` | 425 | 42 | Flutter M3 实现现状、规范差距、本仓库 theme/ADR 盘点、失效引用、迁移要点（附录性质） | 项目解析到 Flutter `>=3.38.0`；Expressive 无官方路径（#168813 Open）；主题装配点分散且有裸 `MaterialApp` |
| `04-figma-design-workflow.md` | 391 | 31 | 官方 Figma 资源核实、Variables vs Styles、文件/组件集结构、桌面 frame、Plugin API 与 figwright 映射、交接清单 | M3 Design Kit v1.20 起已并入 Expressive → **必须自建 Figma 库**；只借 Material Theme Builder 的色板；插件 API 无 `setVariableValue`，是 `setValueForMode` |
| `05-color-directions.md` | 117 | 0 | 粉色 A/B/C 取色、Figma 预览与切换方式、对比度、字体落地 | 免费版 1 collection 只能 1 mode → 建 6 个 collection，用三个 frame + 原型跳转切换；**已选定 A 柔和玫瑰**，亮/暗 frame 均已建；B/C 已移到 `12 Archive & Scratch` 作备选皮肤 |
| `06-adaptive-desktop.md` | 281 | 7 | 五档断点、分栏/导航矩阵、canonical layouts（list-detail / supporting pane / feed）、栅格与间距、连续性、桌面输入、页面映射、模板矩阵 | Compact 1 栏 / Medium 1 `(recommended)` or 2 / Expanded 起 2 栏；导航 compact=bar、medium/expanded=collapsed rail、large/XL=expanded rail；supporting pane expanded 固定 360dp；官方 spacing 页无数值，项目用 4/8 体系 |
| `07-supporting-pane.md` | 315 | 6 | supporting pane 定义与四问判据、五档形态、各断点宽（expanded 360 / large·XL 412）、XL 第三栏限制、本项目逐页采纳判定、Figma 与 Flutter 已执行落点、桌面底板规则、剩余未决 | 判据「**换对象 = list-detail，换视角 = supporting pane**」；**已执行**：`41:2384` 改造为 `Template/Comic detail · Extra-large 1920`，新增 large `67:509` / expanded `67:431`（共用详情模板）；阅读器章节目录不采纳（改可召唤浮层）；设置走 inline list-detail（根页 ≥840 双栏，二级页单栏） |
| `08-tone-based-surfaces.md` | 571 | 5 | 官方 tone-based 博文原文（旧/新模型、5 容器角色、迁移映射、两套共存）、官方 roles / elevation 两页的 hairline 与 add-on 条款、本仓库 46 角色 tone 与 tonal elevation 叠加实测、移动 vs 桌面根因、三方案优劣矩阵、区域级映射取值、token 清单、**硬口径 T1/T2/T3** | surface 与 elevation **已解绑**（+1→Low / +2→Container / +3→High / +4·5→Highest）；**硬口径**：桌面必须按区域取角色（T1）、相邻并列区 ΔL\* 亮 <4 / 暗 <6 必须叠 hairline 或提档（T2）、46 hex 不改只加 `stroke/hairline` 1dp 与 `stroke/focus` 2dp 且阴影只给浮层（T3）；区域映射级差亮 7.0 / 4.0、暗 10.0 / 6.0 |
| `09-desktop-layout-reference.md` | 507 | 0 | `design-system/example.png` 像素反推：窗口 1440×900、四区栏宽、导航形态、内容密度、留白与分组手法、模式判定、**已执行**的 Figma 落点（详情模板 / Detail 行 / 桌面底板）；§11 补用户线框样例的窗口底色规则（窗口底/rail `surfaceContainerHigh`、内容 `surface`、顶栏条/列表 `surfaceContainerLow`、支撑栏 `surfaceContainer`、pane 间留 24dp 窗口底间隙）、详情页 A/B 两版、§11.7 pane 全量铺开与 compact 全出血、§11.8 窗口底色改 `surfaceDim` 与色相定性、§11.9 页面分组重排、§11.10 rail 统一 / 命名对照 / Settings·History 补档、§11.11 rail 档位改 `surfaceContainer` 与分隔线归零 | 参考图 = rail **80** + 列表 **296** + 主内容 **632** + 支撑 **412**，**纯 tone 分隔、无分隔线**（级差 7.05 / 3.83，与 `08` 方案互证）；实际采纳的是它的「纯 tone + 三区级差 + rail 80（详情页）+ 支撑 412 + pane 内 24」，**不采纳 0 margin 全出血**（模板 pane 间与右缘留 24），**四栏 / 296 宽列表方案已作废**（书库不走 inline list-detail） |

行数与 URL 数按本地文件统计；各文档开头的「检索说明」记录了抓取失败与降级路径，引用前先看该节。

## 证据边界（重要）

- `m3.material.io` 大量页面是 JS 交互式 token 浏览器，抓取返回空正文；Firecrawl 多次 429；`web_fetch` 报 non-public IP；shell 直连 TLS 失败。
- 因此 **M3 规范页的原始 dp/字号/透明度数值大多没拿到**；文档中的数值主要来自官方实现源码（B 级），并与规范页可抓到的文字交叉验证。
- 设计稿阶段可以接受 B 级数值（最终落点是 Flutter），但凡是「规范值 vs 实现值」不一致处，文档已并列记录（如 type scale 的 3 处 tracking、rail destinations 3–7 vs 3–5）。
- 未能从官方文档确认的项：drawer modal/standard 判定、dialog vs full-screen、snackbar/badge/tooltip 取舍、chips/cards/carousel 官方分类、Switch/Radio 尺寸、M3 桌面快捷键、spacing 数值、grid margin/gutter 数值、navigation bar/rail 的精确 dp、图标推荐尺寸 20/24dp 等。详见各文档「证据薄弱」节与 `04` §7。
- 截图不入库：本目录 `assets/` 下的 42 张 PNG 已删除，样张与页面图只在 Figma 文件里按节点 id 查看（索引见 `../../hentai-library/MASTER.md` §6.1）。
- `m3.material.io/components/navigation-rail/specs` 是 JS 渲染（抓取仅 109 字符），rail 尺寸表缺失；collapsed pill 56×32 有实现值佐证（B），expanded pill 101×56 与行距 68 由官方截图按 2× 反推（B），rail 宽 256 为项目取值。规范文字部分（indicator 贴合内容、命中区整行、menu/FAB/badge/divider 位置、label 规则、文字缩放行为）来自 overview / guidelines / accessibility 三页原文（A）。

## 合并后的核心结论

1. **基线 = baseline M3，排除 Expressive。** Flutter 的 Expressive 支持（`flutter/flutter#168813`）仍 Open；Figma 官方 kit 已 Expressive 化。Expressive 的组件、shape morph、emphasized type、motion physics 均不进基线。
2. **颜色是 49 个角色的体系，不是 26 个字段。** 3.22 起 `background/onBackground/surfaceVariant` 弃用（**A**：docs.flutter.dev `release/breaking-changes/new-color-scheme-roles`，「In stable release: 3.22.0」），层级改用 tone-based `surfaceContainer*`；3.27（tokens v6.1）又把 4 个 `on*Container` 从 Tone10 改 Tone30，chip 边框由 `outline` 改 `outlineVariant`（**A**：`.../material-design-3-token-update`，「In stable release: 3.27」）。注意别被两处旁证带偏：Flutter `color_scheme.dart` 的 `@Deprecated` 注解写 `after v3.18.0-0.1.pre`（那是 **pre 落地版本**，不是 stable 发布版）；Compose `ColorLightTokens.kt` v0_210 仍 Tone10（**实现滞后**，不构成反证）。项目现在手工枚举 26 字段、0 处 `fromSeed/fromImageProvider`，需要重建。
3. **surface 不再与 elevation 绑定**：baseline `surface` = Neutral98/6（旧值 99/10 已过时），`surface-tint` 恒等于 primary；tonal elevation（0→0.00、1→0.05、3→0.08、6→0.11、8→0.12、12→0.14）只是可选实现，Flutter 仍保留 `applySurfaceTint`。
4. **排版 30 个样式**（15 baseline + 15 emphasized），字族需要 400/500/700 三档；当前 `MI_Sans_Regular` 只有单字重，撑不起 M3 字阶。Aug 2026 起 type scale 还会按语言 script height 调整行高。
5. **state layer 是 M3 的核心反馈机制**：hover 8% / focus 12% / pressed 12% / dragged 16%（material-web v0.192）；项目 `theme.dart:62-64` 的 `NoSplash` + `highlightColor: Colors.transparent` + 桌面 `visualDensity.compact` 等于把反馈和 48dp 触达一起关掉了。
6. **断点两套**：M3 规范 600/840/1200/1600；仓库 `app/lib/shared/ui/layout/app_layout_breakpoints.dart:10,13` 是 600/1024。M3 明确断点由**应用可用窗口**决定，不能写 `isTablet` 式判断。
7. **组件层存在「规范已退役、Flutter 仍在实现」的冲突**：SegmentedButton（官方 2025-05 起不再推荐，改用 connected button group）、扩展 FAB 尺寸（官方 56/80/96，Flutter 只有 56）、FAB menu / side sheet / toolbar / search app bar 在 Flutter 无对应。
8. **桌面实现细节与规范有落差**：`adaptivePlatformDensity` 在 Windows/macOS/Linux 返回 compact（`theme_data.dart:3233-3250`）；Tooltip 桌面最小高 24；modal bottom sheet maxWidth 640 / 圆角 28；桌面纵向滚动自动加 Scrollbar 且默认不支持鼠标拖拽。
9. **Figma 必须自建库**：官方 kit 只能当「baseline 语义参考图」，色板走 Material Theme Builder；Expressive-only 内容排除；字阶落 Text Style（Figma 无复合排版变量）；组件状态用 variant（Button 225 变体为上限）。
10. **figwright 已连接**（server/plugin 0.6.0，文件 `Hentai Library UI  (Material Design) v2`）。免费版每个 collection 只能 1 mode，颜色主题按「一主题一 collection」建；A/B/C 切换用三个 frame + Prototype 跳转，明细见 `05-color-directions.md`。
11. **自适应布局已有官方依据**：五档断点之外，分栏与导航要按 breakpoint 置换（compact bar → collapsed rail → expanded rail）；list-detail 在 compact 单栏、expanded 起双栏；supporting pane 在 expanded 固定 360dp、large/XL 默认 412dp；feed 随断点加列。代码迁移时不要缓存窗口尺寸，单/双栏切换只改布局不动路由栈。
12. **surface 与 elevation 已解绑（tone-based surfaces，2023-03 官方博文）**：5 个 `surfaceContainer*` 角色取代「elevation 叠 tint」，迁移映射为 +1→Low / +2→Container / +3→High / +4·+5→Highest（或 High / Surface Dim）；`surfaceVariant` 已弃用；浅色 `surface` 由 tone 99 改 98、neutral chroma 4→6、暗色略变暗。**两套模型长期共存**，详见 `08` §1。
13. **桌面端的口径是「必须用满 tone-based 的 add-on 能力」，不是「tone-based 够不够用」**（A + B）。官方博文副标题 `New surface color roles offer more flexibility for large screens and rich color features`——它本来就是为大屏新增的；但把**同一个**梯级（`surface` 98 + `container*` 96·94·92·90）铺到并列大区就是不合格用法：本仓库亮色相邻档差最小 **2.0**、全程仅 **10 个 tone 跨度**。**硬口径三条（评审逐条对照，`08` §0.0 / MASTER §2.3）**：**T1** 桌面按区域取色（rail `surfaceDim` / 列表与 supporting pane `surfaceContainer` / 内容 `surface`），以区域为参数不以组件为参数；**T2** 相邻并列区 ΔL\* 亮 **<4**、暗 **<6** 必须叠 1dp `outlineVariant` 或提一档，**2 个 L\* 不算分隔**；**T3** 46 个 hex 不改、只加 `stroke/hairline` 1dp 与 `stroke/focus` 2dp、阴影只给浮层 level 2–5 且 tint 全关。区域映射把级差拉到亮 **7.0 / 4.0**、暗 **10.0 / 6.0**，与官方桌面产品实测 **7.05 / 3.83** 同量级，**仍是 tone-based**。
14. **桌面结构以用户偏好为主**：`example.png`（Google Chat 桌面改版，1440×900）证明官方产品自己会用「rail 80 + 列表 296 + 主内容 632 + 支撑 412 + 纯 tone 分隔 + 全出血」。最终采纳的是它的**纯 tone 分隔、三区级差、rail 80（详情页）、支撑 412**；**不采纳**它的 0 margin 全出血（模板 pane 间与右缘保留 24）；**不采纳** 38dp 行距、296 宽内容列表、四栏列表+详情组合——因为用户已决定**书库不走 inline list-detail**（列表 → 独立详情路由）。**用户决策**：详情模板共用（`/comic/:id`、`/series/:id` 等）；支撑栏按官方 expanded 360 / large·XL 412；XL 详情 rail 用 expanded 256（对参考图 80 的例外）；设置走 inline list-detail（根页 ≥840 双栏）。**冲突时以用户偏好为准，官方规范让步并记理由。**
15. **详情页最终形态 = 方案 1 文档流（2026-10-23 定）**：不做常驻支撑栏、也不做页内卡组；pane 内纵向为「封面/标题/概要/CTA/简介（4 行 + 展开全文）→ 元数据 chip 行（label 88）→ 资源信息 KV（宽档两列）」，顶栏 56 高、pane 圆角 20（`radius/pane`）。桌面差异全部落在**区域别名层** `color/desktop/{window,pane,paneHeader,card,field}`（Light `71:884`–`71:888`、Dark `71:889`–`71:893`，值仍指向 46 角色），46 个 hex 一个未改。五档模板：`72:1022`(390) / `72:961`(600) / `72:900`(1024) / `67:509`(1440) / `72:1083`(1920)，`41:2384`、`67:431` 及旧四屏已删，详见 `09` §11.5/§11.6。
16. **「颜色不像参考图」要分两层查（2026-10-23）**：先查实现——窗口底曾映射到 `surfaceContainerHigh`（91.9），比参考 rail（87.0）浅 4.9 L\*，改指 `surfaceDim` 即对齐（`color/desktop/window` 别名，一个 hex 未改）；再查调色板——L\* 全对齐后残余差异是**色相方向**：参考中性色偏绿灰（a\*≈−2.4 / b\*≈+4.6），A 板偏玫瑰粉（a\*≈+6.0 / b\*≈+1.6），彩度几乎相同（5.2 vs 6.2），属 D3 的 neutral chroma 6，不是 tone 用法错误。详见 `09` §11.8。
17. **rail 的档位由「区域边界」决定，不由「透明度」决定（2026-10-23）**：官方实现里 rail 默认就是 `surface`（Flutter `navigation_rail.dart:1230`，B），本项目窗口底落在 `surfaceDim` 后 rail 若同色只剩 24dp 缝、实机闷；按 CIELAB 算，透明度只是相邻两档 tone 的插值（α=0.4→91.59、0.6→93.54、0.7→94.83，C），所以直接用不透明 token 选档：**rail = `surfaceContainer` 94.0，比 pane 低 4.0、比窗口底高 7.0**；暗色反向用 `surfaceContainerHigh` 17.1。rail 组件内那 1dp `outlineVariant` 分隔线已全部在组件源关闭，桌面分区彻底靠 tone + 24dp 缝。
18. **07 / 08 两页按「左标签栏 + 行=页面 + 列=断点」排布（2026-10-23 重排）**：列 x 320/1820/2920/3620，08 行 y 200/1300/2400/3500（Home / Settings / History / Detail），07 行 y 200/1300/2500/3700（书库四档 / 详情 XL / 详情四档 / 对照）；阅读器四帧按用户要求撤到 `12 Archive`（走沉浸式、暂缓），两页重叠均为 0。详见 `09` §11.9。

## 设计决策（D1–D8 已全部拍板）

| # | 决策 | 选项 | 建议默认 | 影响 |
|---|---|---|---|---|
| D1 | 断点体系 | A 沿用仓库 600/1024；B 采用 M3 五档 600/840/1200/1600；C 设计用 M3、代码暂留旧值 | **已定 B**（M3 官方五档 600/840/1200/1600，设计稿按五档出；代码后续改 `AppLayoutBreakpoints`） | 决定设计稿要出几个重排态、什么时候侧栏展开 |
| D2 | 正文字体 | A 继续 MiSans（补 400/500/700 字重）；B Roboto + Noto Sans SC；C Inter + Noto Sans SC | **已定 A**：本机已装 MiSans Regular/Medium/Semibold/Bold；Figma 字族 `MiSans`，style `Semibold` 无空格 | 字阶、行高、Figma Text Style 全依赖它 |
| D3 | 品牌色 | A 柔和玫瑰（#E91E63 tonalSpot）；B 品牌玫红（#E91E63 fidelity）；C 樱花粉（#F06C9B fidelity） | **已定 A · 柔和玫瑰**；B/C 变量与预览移到 `12 Archive & Scratch`，取色与对比度见 `05-color-directions.md` | 整个色板、暗色、对比度 |
| D4 | 状态反馈 | A 恢复 M3 state layer（hover/pressed/focus 蒙层），splash 可保留关闭；B 保持现状无反馈；C 自定义 hover 但不做 pressed | **已定 A + 平台策略**：恢复 state layer；**移动端开启 splash，桌面端关闭**（只写文档，代码未动） | 桌面可用性、a11y、组件状态矩阵 |
| D5 | Expressive | A 排除；B 局部引入 | **已按调研锁定 A**（Flutter 无官方支持；用户未反对） | 决定 Figma 组件集范围 |
| D6 | Figma 建库方式 | A 手工建库；B figwright 脚本建库（需先打开插件）；C 混合（手工骨架 + 脚本批量） | **采用 C**（本会话即此方式：手工定结构，figwright 批量写节点） | 建库速度与可重复性 |
| D7 | 首批设计稿 | A 桌面主壳+首页+书库+阅读器；B 先做组件库页；C 其他页面优先 | **已定 A**（1440×900 主稿，1024×768 验接缝，600×800 验紧凑） | 设计工作量与评审顺序 |
| D8 | 图标集 | A Material Symbols（M3 官方）；B Lucide（仓库现用 `lucide_icons_flutter`）；C 混用（导航/系统用 Symbols，业务用 Lucide） | **已定 A**：outlined 默认 / filled 选中；M3 组件的图标语义（optical size）依赖 Symbols，Lucide 无 filled 态 | 组件库、图标资产页、代码依赖 |

D1–D8 已全部拍板。D4 的 splash 平台策略只进了设计文档，代码仍保持现状，等设计稿定稿后的迁移窗口再改。

## 已知缺口与后续取证

- M3 规范页数值（type scale tracking、state layer 透明度、spacing/density、canonical layouts 的 pane 宽）——需人工在浏览器读 `m3.material.io` 的 token 浏览器，或另找官方 token 导出（`material-foundation/material-tokens` 的 DSP/JSON）。
- Figma 变量 mode 的套餐限额（help 文档 10/20/unlimited 三方冲突）、kit 发布者字段、`VariableAlias` 字段、MiSans 在 Figma 的可用性——`04` §7 列了 12 条，建库前需逐条核实。
- 本仓库 `app/test/project_layout_test.dart:36-54` 仍断言 `design-system/hentai-library/MASTER.md` 存在，MASTER 已重建且含 `## Directory charter`，但 `pages/` 目录尚未重建，该测试仍必失败；按「设计稿完成后再改代码」的约定，暂不修。
- 06 已补齐 HistoryRow / SettingsSection / MetadataPanel / ReaderToolbar / ReaderBottomBar，阅读器 overlay 由 toolbar + bottom bar 组合；09 States 覆盖 loading 骨架 / empty / error / offline 缓存 / 长文本两行·三行截断 / 大图 16:9 / density 40·56 对照 / Text scale 100·150·200%（`57:532`）。
- 08 已出首页/阅读器四档、设置/历史两档、详情五档（`72:1160`/`72:1205`/`72:1250`/`72:1295` + XL 模板）；系列详情、作者/元数据详情、搜索结果、XL 首页/阅读器仍未出图。
- 桌面剩余未决：pane 内卡片(96) 对 pane(98.1) 仅 **2.0 L\***（< T2 的 4，靠 16 圆角与 24 内边距认边界）；rail 档位已定为 `surfaceContainer`(94.0)、窗口底仍 `surfaceDim`(87.0)；色相方向（玫瑰粉 vs 参考绿灰）属 D3 调色板，要更灰必须重生成 neutral* 都低于 T2 的 4，是否补 hairline 待实机评审；桌面底板 `#EAE8E6` 是否升正式 token（暗色值未定）；rail 取 `surfaceDim` 的玫瑰倾向与暗色 chrome 反向；600/390 详情首屏装不下（帧按滚动视口裁切）；collapsed rail 用实例级 override 隐藏标签，代码侧对应 icon + tooltip。
- ~~`07` 第 1 号阻塞项（书库是否改 inline list-detail）~~ **已关闭（2026-10-23）**：用户定「书库不走 inline list-detail，设置页走」；详情页随后定为文档流（`09` §11.5），不使用常驻支撑栏。
- ~~`41:2384` 改造 / 支撑栏版详情~~ **已作废**：`41:2384`、`67:431` 已删除，五档详情模板全部重做为文档流（见结论 15）。

## 下一步（按序）

1. 已定：D1 五档、D2 MiSans、D3 A 柔和玫瑰、D4 state layer + 平台 splash、D5 排除 Expressive、D6 混合建库、D7 首批稿顺序、D8 Material Symbols。
2. `design-system/hentai-library/MASTER.md` 已建立（目录章程、颜色/字阶、断点、Figma 页面图、组件清单、代码映射）。
3. Figma：变量 6 集合 + Number 44 项、30 Text Style、6 Effect + 5 Grid Style、A 亮/暗预览、01–04 文档页已完成。
4. 05 已完成 P0 主体：Button 8 变体、IconButton、TextField、NavigationBar 4 变体、NavigationRail 8 变体、FAB 4 尺寸、FilterChip 2 态、ListItem 3 行数、Card 3 风格、Dialog/Basic。06 已建 BookListItem `41:1946`、ComicCard `41:1951`、ChapterRow `41:1955`、HistoryRow `41:2498`、SettingsSection `41:2496`、MetadataPanel `41:2497`、ReaderToolbar `41:2516`、ReaderBottomBar `41:2517`。NavigationRail `41:1577` 去除「新建」FAB（业务先选库根路径再扫描）、条目上移 64 间距；随后按官方 rail 文档改版：8 变体补顶部 menu、选中图标 filled、collapsed 选中 label 改 secondary、expanded indicator 101×56 贴合内容、行距 68；NavigationBar 4 变体同步改 filled 选中图标；09 补 Text scale 卡 `57:532`。07 五档齐全：Compact 390 `41:1975`、Medium 600 `41:1824`、Expanded 1024 `41:1774`、Large 1440 `41:1578`、XL 1920 `41:2384`（三栏）。08 首页 `41:2026`(1440)/`41:2209`(1024)/`41:2160`(600)/`41:2314`(390)、阅读器 `41:2097`/`41:2275`/`41:2139`/`41:2363`。09 `41:2520` 七块状态与内容实验；10 `48:2574` 四个时长卡 + reduce-motion；11 `48:2610` token/组件/a11y 三列交接；05 补 SearchBar `48:2651`、TopAppBar `48:2658`、Snackbar `48:2662`；08 补 Settings `48:2663`(1440)/`48:2710`(390)、History `48:2749`(1440)/`48:2803`(390)。**下一步：设计稿评审 → Flutter 迁移**（①theme ②shell/断点 ③组件 ④页面）；详情页（comic/series/author/metadata）与搜索结果为第二批。**桌面补强（Figma）已完成 2026-10-23**：五档详情模板 `72:1022`(390)/`72:961`(600)/`72:900`(1024)/`67:509`(1440)/`72:1083`(1920)，按方案 1 文档流 + 24 gap + pane 圆角 20 + 顶栏 56 + 区域别名 token；08 Screens 第 5 行 `Detail` 为 `72:1160`/`72:1205`/`72:1250`/`72:1295`（y=4000）；07 记 10 帧、08 记 16 帧，顶层重叠复测均为 0；**待评审**，评审通过后才动代码。
5. 组件状态矩阵（每组件出几态）在进入 05 前定；插画/占位图来源仍缺。
6. 设计稿定稿并评审通过后，才进入 Flutter 主题与页面改造（`03` 的清单可作为迁移附录）。

## 复现与更新

- `01-foundations.md`–`05-color-directions.md` 由并行的后台调研代理生成；`06-adaptive-desktop.md` 由主代理按用户给定的 4 个官方入口补抓 canonical examples 后写成；rail 规范由主代理按 `m3.material.io/components/navigation-rail/{overview,guidelines,accessibility}` 三页复核（`read_page` 可用、`web_fetch` 被 non-public IP 拒绝）；硬性要求：只引一手来源、逐条 URL、区分规范/实现/Expressive、中文、只写各自文件。Figma 落地顺序与截图见 `design-system/hentai-library/MASTER.md` §6。
- `07`–`09` 于 2026-10-23 写成：**07** 由后台子代理按 `supporting-pane` / `scaffold/panes` / `breakpoints` 三页原文写成（6 个官方 URL）；**08** 主源为用户提供的官方博文 `m3.material.io/blog/tone-based-surface-color-m3`（A），并补取 `/styles/color/roles` 与 `/styles/elevation/applying-elevation` 两页原文（A）；`/styles/color/system/overview` 抓取失败（JS 渲染、空正文），**没有从该页引用任何数值**——tone 数值全部由本仓库 46 个 hex 自行按 CIELAB 计算（B 级，可复现），实现源码（Flutter `color_scheme.dart`、Compose tokens）**只用于核实版本口径**，不用于取 tone 值；**09** 无外部 URL，为 `design-system/example.png` 像素反推（Pillow 扫纯色带 + 高/宽两维度互校得 1 px = 1.152 dp）。
- 更新某一份时，请同步改本索引的行数/结论，并在对应文档的「检索说明」里记录新抓取通道与失败原因。
- 引用规范数值到 MASTER/页面文档时，标注来源小节与证据级别（A/B），不要只写「M3 规定」。