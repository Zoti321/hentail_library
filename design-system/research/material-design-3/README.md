# Material 3 设计系统调研（索引与决策清单）

> 本目录是 **设计系统重写的调研底稿**，不是最终规范。旧 Fluent 设计系统文档（`design-system/hentai-library/` 24 个文件）已整体删除（`git rm` 暂存），目录保留，历史可从 HEAD 取回。
> 当前阶段：**Figma 建库中**（D1–D8 全部拍板；颜色 A 亮/暗、44 Number token、30 Text Style、6 Effect + 5 Grid Style、01–04 文档页、05 三个打样组件 + Button 8 变体集 + NavigationBar 4 变体 + NavigationRail 8 变体、07 Large 1440×900 / Expanded 1024×768 / Medium 600×800 三个书库模板已建），代码未动。设计稿在 Figma 完成并经确认后，才进入实现。
> 证据分级：**A** = 官方规范页/设计文档原文；**B** = 官方源码/实现（Compose `*Tokens.kt`、material-web `tokens/v0_192`、Flutter SDK 源码）——数值可信但非规范页；**C** = 未核实/工程推断。各文档正文逐条标注。

## 文档索引

| 文件 | 行数 | 唯一官方 URL | 覆盖 | 最关键的结论 |
|---|---:|---:|---|---|
| `01-foundations.md` | 577 | 34 | tokens 三层、颜色（49 角色表）、state layer、排版（30 样式）、shape、elevation、motion、布局/断点、图标、a11y、官方工具 | baseline `surface` = Neutral98/6；`surface-tint` 恒等于 primary；断点 600/840/1200/1600；type scale 有 3 处跨实现 tracking 冲突 |
| `02-components-patterns.md` | 488 | 27 | 组件目录与逐项规格、导航/选择模式、大屏与桌面、Expressive 组件状态、组件级 a11y、state layer 落地 | Expressive 是**逐平台逐组件**可选，不是全局升级；SegmentedButton 自 2025-05 起官方不再推荐；Flutter 普遍停在 Expressive 之前 |
| `03-flutter-implementation.md` | 425 | 42 | Flutter M3 实现现状、规范差距、本仓库 theme/ADR 盘点、失效引用、迁移要点（附录性质） | 项目解析到 Flutter `>=3.38.0`；Expressive 无官方路径（#168813 Open）；主题装配点分散且有裸 `MaterialApp` |
| `04-figma-design-workflow.md` | 391 | 31 | 官方 Figma 资源核实、Variables vs Styles、文件/组件集结构、桌面 frame、Plugin API 与 figwright 映射、交接清单 | M3 Design Kit v1.20 起已并入 Expressive → **必须自建 Figma 库**；只借 Material Theme Builder 的色板；插件 API 无 `setVariableValue`，是 `setValueForMode` |
| `05-color-directions.md` | 117 | 0 | 粉色 A/B/C 取色、Figma 预览与切换方式、对比度、字体落地 | 免费版 1 collection 只能 1 mode → 建 6 个 collection，用三个 frame + 原型跳转切换；**已选定 A 柔和玫瑰**，亮/暗 frame 均已建；B/C 已移到 `12 Archive & Scratch` 作备选皮肤 |
| `06-adaptive-desktop.md` | 281 | 7 | 五档断点、分栏/导航矩阵、canonical layouts（list-detail / supporting pane / feed）、栅格与间距、连续性、桌面输入、页面映射、模板矩阵 | Compact 1 栏 / Medium 1（推荐）或 2 / Expanded 起 2 栏；导航 compact=bar、medium/expanded=collapsed rail、large/XL=expanded rail；supporting pane expanded 固定 360dp；官方 spacing 页无数值，项目用 4/8 体系 |

行数与 URL 数按本地文件统计；各文档开头的「检索说明」记录了抓取失败与降级路径，引用前先看该节。

## 证据边界（重要）

- `m3.material.io` 大量页面是 JS 交互式 token 浏览器，抓取返回空正文；Firecrawl 多次 429；`web_fetch` 报 non-public IP；shell 直连 TLS 失败。
- 因此 **M3 规范页的原始 dp/字号/透明度数值大多没拿到**；文档中的数值主要来自官方实现源码（B 级），并与规范页可抓到的文字交叉验证。
- 设计稿阶段可以接受 B 级数值（最终落点是 Flutter），但凡是「规范值 vs 实现值」不一致处，文档已并列记录（如 type scale 的 3 处 tracking、rail destinations 3–7 vs 3–5）。
- 未能从官方文档确认的项：drawer modal/standard 判定、dialog vs full-screen、snackbar/badge/tooltip 取舍、chips/cards/carousel 官方分类、Switch/Radio 尺寸、M3 桌面快捷键、spacing 数值、grid margin/gutter 数值、navigation bar/rail 的精确 dp、图标推荐尺寸 20/24dp 等。详见各文档「证据薄弱」节与 `04` §7。

## 合并后的核心结论

1. **基线 = baseline M3，排除 Expressive。** Flutter 的 Expressive 支持（`flutter/flutter#168813`）仍 Open；Figma 官方 kit 已 Expressive 化。Expressive 的组件、shape morph、emphasized type、motion physics 均不进基线。
2. **颜色是 49 个角色的体系，不是 26 个字段。** 3.22 起 `background/onBackground/surfaceVariant` 弃用，层级改用 tone-based `surfaceContainer*`；3.27（tokens v6.1）又把 4 个 `on*Container` 从 Tone10 改 Tone30。项目现在手工枚举 26 字段、0 处 `fromSeed/fromImageProvider`，需要重建。
3. **surface 不再与 elevation 绑定**：baseline `surface` = Neutral98/6（旧值 99/10 已过时），`surface-tint` 恒等于 primary；tonal elevation（0→0.00、1→0.05、3→0.08、6→0.11、8→0.12、12→0.14）只是可选实现，Flutter 仍保留 `applySurfaceTint`。
4. **排版 30 个样式**（15 baseline + 15 emphasized），字族需要 400/500/700 三档；当前 `MI_Sans_Regular` 只有单字重，撑不起 M3 字阶。Aug 2026 起 type scale 还会按语言 script height 调整行高。
5. **state layer 是 M3 的核心反馈机制**：hover 8% / focus 12% / pressed 12% / dragged 16%（material-web v0.192）；项目 `theme.dart:62-64` 的 `NoSplash` + `highlightColor: Colors.transparent` + 桌面 `visualDensity.compact` 等于把反馈和 48dp 触达一起关掉了。
6. **断点两套**：M3 规范 600/840/1200/1600；仓库 `app/lib/shared/ui/layout/app_layout_breakpoints.dart:10,13` 是 600/1024。M3 明确断点由**应用可用窗口**决定，不能写 `isTablet` 式判断。
7. **组件层存在「规范已退役、Flutter 仍在实现」的冲突**：SegmentedButton（官方 2025-05 起不再推荐，改用 connected button group）、扩展 FAB 尺寸（官方 56/80/96，Flutter 只有 56）、FAB menu / side sheet / toolbar / search app bar 在 Flutter 无对应。
8. **桌面实现细节与规范有落差**：`adaptivePlatformDensity` 在 Windows/macOS/Linux 返回 compact（`theme_data.dart:3233-3250`）；Tooltip 桌面最小高 24；modal bottom sheet maxWidth 640 / 圆角 28；桌面纵向滚动自动加 Scrollbar 且默认不支持鼠标拖拽。
9. **Figma 必须自建库**：官方 kit 只能当「baseline 语义参考图」，色板走 Material Theme Builder；Expressive-only 内容排除；字阶落 Text Style（Figma 无复合排版变量）；组件状态用 variant（Button 225 变体为上限）。
10. **figwright 已连接**（server/plugin 0.6.0，文件 `Hentai Library UI  (Material Design) v2`）。免费版每个 collection 只能 1 mode，颜色主题按「一主题一 collection」建；A/B/C 切换用三个 frame + Prototype 跳转，明细见 `05-color-directions.md`。
11. **自适应布局已有官方依据**：五档断点之外，分栏与导航要按 breakpoint 置换（compact bar → collapsed rail → expanded rail）；list-detail 在 compact 单栏、expanded 起双栏；supporting pane 在 expanded 固定 360dp；feed 随断点加列。代码迁移时不要缓存窗口尺寸，单/双栏切换只改布局不动路由栈。

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

## 下一步（按序）

1. 已定：D1 五档、D2 MiSans、D3 A 柔和玫瑰、D4 state layer + 平台 splash、D5 排除 Expressive、D6 混合建库、D7 首批稿顺序、D8 Material Symbols。
2. `design-system/hentai-library/MASTER.md` 已建立（目录章程、颜色/字阶、断点、Figma 页面图、组件清单、代码映射）。
3. Figma：变量 6 集合 + Number 44 项、30 Text Style、6 Effect + 5 Grid Style、A 亮/暗预览、01–04 文档页已完成。
4. 05 Components 已完成 Button / Icon Button / Text Field 打样；Button 8 变体、NavigationBar 4 变体、NavigationRail 8 变体（Type × Selected）已建。07 已建 Large 1440×900 `41:1578`（expanded rail + 列表-详情）、Expanded 1024×768 `41:1774`（collapsed rail + 双栏）、Medium 600×800 `41:1824`（collapsed rail + 单栏 + FAB）。下一步：FAB、List Item、Card、Chip、Dialog（P0）→ 06 Patterns → 07 compact 390×844 / XL 1920×1080 → 08 Screens（主壳 + 首页 + 书库 + 阅读器）→ 09 States → 10 Motion → 11 Handoff。
5. 组件状态矩阵（每组件出几态）在进入 05 前定；插画/占位图来源仍缺。
6. 设计稿定稿并评审通过后，才进入 Flutter 主题与页面改造（`03` 的清单可作为迁移附录）。

## 复现与更新

- 01–05 由并行的后台调研代理生成，06 由主代理按用户给定的 4 个官方入口补抓 canonical examples 后写成；硬性要求：只引一手来源、逐条 URL、区分规范/实现/Expressive、中文、只写各自文件。
- 更新某一份时，请同步改本索引的行数/结论，并在对应文档的「检索说明」里记录新抓取通道与失败原因。
- 引用规范数值到 MASTER/页面文档时，标注来源小节与证据级别（A/B），不要只写「M3 规定」。