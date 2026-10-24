# Material 3 组件、交互模式与大屏适配

> 调研 02 / 供 `design-system/hentai-library/MASTER.md`、`foundations/*`、`pages/*` 与 Flutter 主题重写引用。
> 范围：组件规范、导航/层级模式选择、大屏与桌面适配、M3 Expressive 组件更新、内容设计与组件级无障碍、状态模型落地。
> 与 01（色彩/字体/token）、03（动效/图标）等其它报告的边界：本文件只管「组件与交互」，不重复 token 数值体系。

---

## 0. 检索说明

### 0.1 抓取环境与限制（必读，决定本文的证据强度）

- `tools.web_fetch` 在本会话对所有目标域名失败（返回 `URL hostname resolves to a non-public IP address`）：
  `m3.material.io`、`developer.android.com`、`docs.flutter.dev`、`api.flutter.dev`、`raw.githubusercontent.com`、`api.github.com` 全部不可用。
  实际抓取改走 modsearch 桥（`read_page`），其 firecrawl 引擎负责渲染 JS 站点。
- **m3.material.io 的抓取窗口有限**：中段起 firecrawl 免费额度耗尽（`429 Too Many Requests`，`retry_after_seconds` 约 3569–3798）。该站为客户端渲染，local 引擎返回 200 但正文长度 0，
  因此 m3 侧只拿到限流前的 **17 个组件页**；此后所有 m3 页面（含全部 `/specs` 数值页、`/guidelines`、`/accessibility`、`foundations/*`）在本会话内无法再取。
- GitHub 仓库页面（material-components / material-tokens / material-symbols）经 `read_page` 报 `Every engine for the web source failed`；shell 内直连 HTTP 亦被拦（curl 0 字节）。
  → **官方 GitHub 仓库这一路一手来源本次无法使用**，token 级数值以 Flutter SDK 源码替代（见 1.3）。
- `docs.flutter.dev` 的 local fetch 时好时坏（`Request failed ... fetch fail`）。已成功取到 `/ui/design/material`、`/ui/adaptive-responsive` 两页的**站点导航与标题**，正文段落未稳定取到 → 本文不从这两页引用任何结论，仅记为「未能从官方文档确认」的尝试目标。
- 未臆造当前日期。下文「页面更新线索」均为页面自身文本（如 `M3 Expressive update · May 2025`、`November 2025`、`December 2025`）。
- Flutter 侧实现级证据来自本机 SDK 源码树，根为 `E:\flutter sdk\flutter\`；下文简写为 `material/xxx.dart:NN`（即 `packages/flutter/lib/src/material/xxx.dart`）。

### 0.2 抓取成功的页面与页面自身更新线索

| # | 页面 | 页面自身显示的更新/版本线索 | 取到的可用内容 |
|---|---|---|---|
| 1 | [m3 /components](https://m3.material.io/components) | 无日期；组件目录 | 组件清单（本文唯一权威清单来源） |
| 2 | [m3 /components/app-bars/overview](https://m3.material.io/components/app-bars/overview) | **M3 Expressive update · May 2025** | 四变体、更名 app bar、可用性矩阵 |
| 3 | [m3 /components/app-bars/guidelines](https://m3.material.io/components/app-bars/guidelines) | 无日期 | 312dp search container 规则；唯一 Do/Don't |
| 4 | [m3 /components/app-bars/specs](https://m3.material.io/components/app-bars/specs) | 交互式 token 浏览器 | 仅 token 名（无数值） |
| 5 | [m3 /components/buttons/overview](https://m3.material.io/components/buttons/overview) | **M3 Expressive update · May 2025** | 5 尺寸、5 configurations、toggle |
| 6 | [m3 /components/icon-buttons/overview](https://m3.material.io/components/icon-buttons/overview) | May 2025 | 尺寸/形状/宽度、toggle |
| 7 | [m3 /components/segmented-buttons/overview](https://m3.material.io/components/segmented-buttons/overview) | May 2025 | **不再推荐**，改用 connected button group |
| 8 | [m3 /components/floating-action-button/overview](https://m3.material.io/components/floating-action-button/overview) | May 2025 | medium 尺寸；tone 颜色；small 不再推荐 |
| 9 | [m3 /components/extended-fab/overview](https://m3.material.io/components/extended-fab/overview) | May 2025 | 56 / 80 / 96 dp |
| 10 | [m3 /components/fab-menu/overview](https://m3.material.io/components/fab-menu/overview) | May 2025 | 新组件；仅 Compose Expressive 可用 |
| 11 | [m3 /components/lists/overview](https://m3.material.io/components/lists/overview) | **December 2025**（另有一段未标月） | expressive list、standard/segmented 视觉 |
| 12 | [m3 /components/menus/overview](https://m3.material.io/components/menus/overview) | **November 2025** | vertical menus、standard/vibrant |
| 13 | m3 badges / cards / carousel / checkbox / chips / dialogs / divider 的 overview | 均无 Expressive 更新块 | 各自一句话用途定义 |
| 14 | [developer.android.com /develop/ui/compose/components](https://developer.android.com/develop/ui/compose/components) | 无日期 | Compose 侧组件清单（与 m3 目录对照） |
| 15 | [.../compose/components/navigation-bar](https://developer.android.com/develop/ui/compose/components/navigation-bar) | 无日期 | bar 的适用条件（3–5 destinations / compact） |
| 16 | [.../compose/components/navigation-rail](https://developer.android.com/develop/ui/compose/components/navigation-rail) | 无日期 | rail 的适用条件（3–7 / tablet·desktop） |
| 17 | [.../compose/layouts/adaptive/use-window-size-classes](https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes) | 无日期 | 尺寸等级阈值、非设备判定 |
| 18 | [.../compose/layouts/adaptive/canonical-layouts](https://developer.android.com/develop/ui/compose/layouts/adaptive/canonical-layouts) | 无日期 | list-detail / feed / supporting pane |
| 19 | [.../compose/designsystems/material3](https://developer.android.com/develop/ui/compose/designsystems/material3) | 提及 Material 3 Expressive | `@ExperimentalMaterial3Api` opt-in |
| 20 | [.../guide/topics/ui/accessibility/apps](https://developer.android.com/guide/topics/ui/accessibility/apps) | 无日期 | 对比度 4.5:1 / 48dp 触控目标 |
| 21 | api.flutter.dev：NavigationRail / NavigationDrawer / SearchAnchor / SearchBar / SegmentedButton / CarouselView / MenuAnchor / Badge 的 class 页 | 对应本机 SDK | 类级用途说明 |
| 22 | docs.flutter.dev /ui/adaptive-responsive、/ui/design/material | — | 仅取到标题与导航，**正文未取到** |

> 第 15–20 行 URL 前缀即 `https://developer.android.com`，为排版紧凑未重复；引用时以该前缀补全。

### 0.3 证据分级（全文统一）

| 级别 | 含义 | 本文典型来源 |
|---|---|---|
| **A** | Material 3 规范/设计文档（设计意图与规格） | m3.material.io 组件 overview / guidelines / specs |
| **B** | 实现（实际 API 与默认值） | developer.android.com Compose 页、api.flutter.dev、Flutter SDK 源码 |
| **C** | M3 Expressive（较新：官方页面标注 May 2025 起，或 Nov/Dec 2025 增量） | m3 页面内的 M3 Expressive update 块、可用性矩阵的 *Expressive* 列 |

**三类冲突时本文并列记录，不做统一。** 特别注意一个容易误判的结构事实：

- Expressive 在 m3 可用性矩阵里是**按平台分列的**：Flutter / Compose / Compose Expressive / MDC-Android / MDC-Android Expressive / Web / Web Expressive（[app-bars/overview](https://m3.material.io/components/app-bars/overview) 表格）。
  即「Expressive」不是一次全局版本升级，而是**逐平台、逐组件的可选实现**。例：FAB menu 只有 `Compose Expressive Available`，其余皆 Unavailable，且压根没有 Flutter 行（[fab-menu/overview](https://m3.material.io/components/fab-menu/overview)）。
- 因此写文档时「组件是否可用」必须写成「平台 × 是否 Expressive」的二维判定，不能写「M3 支持 X」。

---

## 1. 组件清单：以 m3.material.io/components 实际目录为准（A）

### 1.1 官方目录全部条目（不增不减）

| 官方分组 | 目录条目 | 备注 |
|---|---|---|
| 单列组件 | App bars、Badges、Cards、Carousel、Checkbox、Chips、Date pickers、Dialogs、Divider、Lists、Menus、Navigation bar、Navigation drawer、Navigation rail、Radio button、Search、Side sheets、Sliders、Snackbar、Switch、Tabs、Text fields、Time pickers、Toolbars、Tooltips | — |
| Buttons 子组 | Button groups、Buttons、Extended FABs、FAB menu、FABs（slug 为 `floating-action-button`）、Icon buttons、Segmented buttons、Split button、All buttons | 目录把 FAB 家族并入 buttons 组 |
| 命名不统一 | `Loading indicator` 与 `Progress indicators` 并存；`Bottom sheets` 与 `Side sheets` 分开 | 引用时以 slug 为准 |

官方目录还给出了六个属性分类：**Action、containment、communication、navigation、selection、text input**。
> **未能从官方文档确认**：哪个组件归属哪一类（目录页仅列出六类名称，本会话抓取文本未保留逐组件映射）。

### 1.2 m3 侧与 Compose 侧范围对照（B）

[Compose 组件索引](https://developer.android.com/develop/ui/compose/components) 实际列出：App bars、Badges、Bottom sheets（含 Partial bottom sheet）、Button（含 FAB / Icon button / Segmented button）、Card、Carousel、Checkbox、Chip、Date pickers、Dialog、Divider、Menus、Navigation bar / drawer / rail、Progress indicators、**Pull to refresh**、Radio button、Scaffold、Search bar、Slider、Snackbar、Switch、Tabs、Time pickers（Overview / Time picker dialogs）、Tooltip。

| m3 目录有 / Compose 索引无 | Compose 索引有 / m3 目录无 |
|---|---|
| Side sheets、Toolbars、Button groups、Split button、FAB menu、Extended FABs（独立条目）、Loading indicator（独立条目）、Search view（作为 Search 子形态） | **Pull to refresh**、**Scaffold**（Compose 侧是组件，m3 侧是 layout 概念） |

### 1.3 Flutter 侧（B：本机 SDK 源码，可复现）

| 事实 | 证据 |
|---|---|
| 触控目标下限常量 48.0 | `material/constants.dart:27` `kMinInteractiveDimension = 48.0` |
| App bar 默认高度 56.0 | `material/constants.dart:30` `kToolbarHeight = 56.0`；`material/app_bar.dart:685` 默认取它；`app_bar.dart:43` `_kLeadingWidth = kToolbarHeight` |
| NavigationBar 高度 80.0、指示器 32×64 | `material/navigation_bar.dart:29-30`；`_NavigationBarDefaultsM3`（:1427）`:1430 height: 80.0` |
| NavigationRail 宽 80.0、展开宽 256、图标 24、elevation 0 | `material/navigation_rail.dart` `_NavigationRailDefaultsM3`；M2 旧值 `:1176 minWidth 72.0` |
| NavigationDrawer tile 高 56、指示器 336×56、elevation 1.0 | `material/navigation_drawer.dart` `_NavigationDrawerDefaultsM3` |
| FAB：regular 56×56 / small 40×40 / large 96×96 / extended 高 56 | `material/floating_action_button.dart` `_FABDefaultsM3`；圆角 16/12/28/16；elevation 6.0（hover 8.0）；extended 图标标签间距 8.0 |
| 图标按钮默认最小 40×40，再由 padding 补到 48 | `material/icon_button.dart:1131-1132`；`:39 _kMinButtonSize = kMinInteractiveDimension` |
| SegmentedButton 文本态最小高 40.0 | `material/segmented_button.dart:670`；`:672-682` 用 densityAdjustment 补足点击目标 |
| Chip 高 32、圆角 8、图标 18、label 14 | `material/chip.dart:36` `_kChipHeight = 32.0`；`_ChipDefaultsM3` |
| ListTile 单/双/三行高 56 / 72 / 88 | `material/list_tile.dart:738` 注释原文；contentPadding 16/24、minLeadingWidth 24、minVerticalPadding 8 |
| Dialog：elevation 6.0、圆角 28.0、actions padding 24 | `material/dialog.dart` `_DialogDefaultsM3`；`Dialog.fullscreen` 在 `:86/:91`（底部按钮区默认 surface，:118） |
| Bottom sheet：顶部圆角 28.0、maxWidth 640、drag handle 32×4、禁用滚动时最大高比 0.5625 | `material/bottom_sheet.dart` `_BottomSheetDefaultsM3`；`:30 _defaultScrollControlDisabledMaxHeightRatio = 9.0/16.0` |
| Tab 高 46 / 图标+文本 72、分隔线 1.0 | `material/tabs.dart:30-31` |
| Tooltip **桌面**最小高 24.0、移动 32.0 | `material/tooltip.dart:226-227`；`:794` macOS/linux/windows 分支 24.0；垂直偏移 24.0（:480） |
| TextField 边框 非聚焦 1dp / 聚焦 2dp；enabled 用 onSurface 12%；disabled 0.38、填充 0.04 | `material/input_decorator.dart` `_InputDecoratorDefaultsM3` |
| Slider 新 M3 track 高 16.0（旧 4.0）、track 最小长 144.0 | `material/slider.dart:2218`、`:1219` |
| Progress 新版尺寸 41.0、stroke 4.0、stop indicator 半径 2.0；**默认仍旧外观** | `material/progress_indicator.dart` ；`:583 year2023 ?? indicatorTheme.year2023 ?? true` |
| Checkbox 边长 18.0 | `material/checkbox.dart:406` |
| 菜单项最小 64×48 | `material/menu_anchor.dart:3636` |
| Chip 家族类 | `material/action_chip.dart:89`、`choice_chip.dart:59`、`filter_chip.dart:65`、`input_chip.dart:79`、`chip.dart:687 Chip` |
| 底部弹层 API | `material/bottom_sheet.dart:73 class BottomSheet`、`:1238 showModalBottomSheet` |
| 选择器 API | `material/date_picker.dart:196 showDatePicker`、`:1165 showDateRangePicker`；`material/time_picker.dart:3254 showTimePicker` |
| **无 Toolbar 组件** | `material/` 下对 `^class Toolbar` 检索无命中 → 官方 Toolbars（A）在 Flutter 需自建 |

---

## 2. 组件逐项：用途、规格要点、状态与交互、常见误用

> 规格列只在有来源时给数字。m3 `/specs` 页为交互式 token 浏览器，本次**拿不到任何数值**（只能取到 token 名，如 `App bar medium container height`、`App bar medium title font`、`App bar medium icon button size`）。
> 误用列：官方 guidance 未取到者明确标「未取得」，不以实现推断冒充规范。

### 2.1 App bars（A 取到，B 有）

**用途（A）**：置于页面顶部，帮助用户理解当前位置并访问关键操作；官方要求聚焦「当前页面 + 1–2 个必要操作」，页面级操作应放到 Toolbars（[app-bars/overview](https://m3.material.io/components/app-bars/overview)）。

| 变体 | 状态 | 说明（A） |
|---|---|---|
| Search app bar | **C，May 2025 新增** | 图标可在搜索条内/外，文本居中；点击打开 search view |
| small | 现行 | Expressive 后获得同样改进 |
| medium flexible | **C，取代旧 medium** | 旧 medium **不再推荐** |
| large flexible | **C，取代旧 large** | 旧 large **不再推荐** |

- 更名：组件由 **Top app bar** 更名为 **app bar**（页面 title 仍为 "Top app bar"，正文标题为 "App bars" —— 抓到的页面本身就不一致，引用时注意）。
- 与 M2 的差异（A）：新颜色映射 + 动态色；滚动分隔由阴影改为填充分隔；默认字号更大；**默认高度更小**。
- 唯一可引用的数值（A，guidelines）：*"The search container of the search app bar should fill 100% of the space between leading and trailing app bar elements until it reaches **312dp**. Then, it should only grow further to fill 50% of that space."*
- 唯一 Do/Don't（A）：*"Don't make an app bar shorter than its default height"*。
- **B（Flutter）**：默认 `toolbarHeight = kToolbarHeight` 即 56.0（`material/app_bar.dart:685`，`:43` 同值）。Flutter 只有 `AppBar` 一种结构，**没有 medium/large flexible、没有 search app bar** → A/C 变体需自建。

### 2.2 Navigation bar / rail / drawer（A 未取到组件页；B 有明确条件）

这是本文最需小心的一处：m3 的 nav 三页未抓取，条件来自 Compose 页面（B），并发现**跨来源数字冲突**。

| 模式 | 官方（B）适用条件 | 来源 |
|---|---|---|
| Navigation bar | Three to five destinations of equal importance；**Compact window sizes**；Consistent destinations across app screens | [compose/components/navigation-bar](https://developer.android.com/develop/ui/compose/components/navigation-bar) |
| Navigation rail | Top-level destinations accessible anywhere；**Three to seven** main destinations；**Tablet or desktop layouts** | [compose/components/navigation-rail](https://developer.android.com/develop/ui/compose/components/navigation-rail) |
| Navigation drawer | 「a persistent and convenient way to switch between primary destinations」；未给数量阈值 | [api.flutter.dev NavigationDrawer](https://api.flutter.dev/flutter/material/NavigationDrawer-class.html) |

**冲突记录（不强行统一）**：

| 来源 | rail 的 destinations 建议 |
|---|---|
| Compose / Android（B） | 3–7 |
| Flutter `NavigationRail` class doc（B） | 「a small number of views, **typically between three and five**」，并明确 wide viewports（desktop web / tablet landscape），小屏改用 bottom navigation（[链接](https://api.flutter.dev/flutter/material/NavigationRail-class.html)） |

→ 本项目为桌面 shell，若沿用 M3 命名与结构，**rail 数量上限按 3–5（Flutter 侧）更保守**；3–7 是 Android 侧说法。文档应写「两源取值不同」，不要写单一数字。

- Flutter 默认尺寸（B）：NavigationBar 高 80.0、指示器 32×64（`material/navigation_bar.dart:29-30, :1430`）；NavigationRail 宽 80.0 / 展开 256（`material/navigation_rail.dart`）；NavigationDrawer tile 56、指示器 336×56（`material/navigation_drawer.dart`）。
- **drawer 的 modal / standard 判定条件未能从官方文档确认**（m3 `navigation-drawer/overview` 与 `/guidelines` 未取得；Compose `/components/navigation-drawer` 抓取只返回站点导航，正文未取到）。

### 2.3 Buttons（A 取到，含 C 增量）

**用途（A）**：*"Buttons prompt most actions in a UI."*

| 维度 | 取值（A/C） | 说明 |
|---|---|---|
| 尺寸（C，May 2025） | extra small、small（**默认**）、medium、large、extra large | small 为既有默认尺寸 |
| 颜色样式（C） | 改称 **configurations**：elevated、filled、tonal、outlined、text | 「颜色样式」说法被 configurations 取代 |
| 形状（C） | round / square；按下与选中会 **morph** | 形状变化是 Expressive 核心表现 |
| 变体（C） | default / toggle（selection） | toggle 为 Expressive 新增能力 |
| small 的内边距（C） | **16dp（推荐）** / 24dp（不再推荐） | 官方给出的唯一按钮数值 |

- 可用性（A 表格）：Flutter Available、Compose Available、Compose Expressive Available、MDC-Android Available、MDC-Android Expressive Available、**Web Available**、Web Expressive Unavailable。
- **B（Flutter）**：`minimumSize` 由 `ButtonStyle.minimumSize` 解析（`material/button_style_button.dart:422-476`）；`scaledPadding`（:294）受 `visualDensity` 影响 → 与本项目 `visualDensity: VisualDensity.adaptivePlatformDensity` 直接相关（见 §4.3）。Flutter **没有** five sizes、没有 toggle morph、没有 round/square 动画 → C 部分需自建或放弃。

### 2.4 Icon buttons / Segmented buttons / Button groups / Split button

| 组件 | 关键事实 | 来源级别 |
|---|---|---|
| Icon buttons | default/toggle；filled、tonal、outlined、standard 四种 configuration；round/square；五尺寸（small 默认）；宽度 narrow/default/wide | A（[icon-buttons/overview](https://m3.material.io/components/icon-buttons/overview)），May 2025 = C |
| Segmented buttons | **May 2025 起不再推荐（no longer recommended）**，官方指向 connected **button group** | A，C |
| Button groups | 存在于官方目录并为 segmented 的替代；**规格/Guidelines 页未能取得** | A（仅目录存在性） |
| Split button | 存在于官方目录；**细节未能从官方文档确认** | A（仅目录存在性） |

- **B（Flutter）**：`IconButton` 的 M3 `minimumSize` 为 40×40，再由 padding 补足 48（`material/icon_button.dart:1131-1132, :39`）；`SegmentedButton` 文本态最小高 40.0（`material/segmented_button.dart:670`）。
  → **时序冲突**：Flutter 仍在实现 `SegmentedButton`，而 M3（C）已标其为「不再推荐」。本项目需在 ADR 明确「用 SegmentedButton 还是等 button group」，不要两边都写。

### 2.5 FAB 家族（A 取到，含 C）

| 组件 | 关键事实（A） | 可用性（A 表格） |
|---|---|---|
| FABs | May 2025：**新增 medium** 尺寸；**small 不再推荐**；FAB/large FAB 尺寸不变；变体按**尺寸**而非颜色；新增 **tone** 颜色（primary/secondary/tertiary）；既有 tonal 颜色改名对齐 token 名（primary→primary container 等，**值未变**）；**surface 颜色 FAB 不再推荐** | Flutter/Compose/Compose Expressive/MDC/MDC Expressive Available；Web Unavailable |
| Extended FABs | May 2025：三尺寸 **small 56dp / medium 80dp / large 96dp**，字号更大；baseline extended FAB（56dp）与 surface extended FAB 不再推荐 | 同上 |
| FAB menu | May 2025 **新组件**：一个 menu 尺寸配任意 FAB；**取代 speed dial 与 stacked small FABs**；对比色关闭按钮与 item 颜色；支持动态色 | **仅 Compose Expressive Available**；MDC Expressive / Web Expressive Unavailable；**无 Flutter 行** |

- **B（Flutter）**：`_FABDefaultsM3` 只覆盖 regular 56、small 40、large 96、extended 高 56（`material/floating_action_button.dart`）→ 对应 **Expressive 之前的基线**；A/C 的 medium、三档 extended（56/80/96）、tone 颜色、FAB menu 在 Flutter 均**不存在**。

### 2.6 Chips（A 仅用途；四类命名需谨慎）

- 用途（A）：*"Chips help people enter information, make selections, filter content, or trigger actions."*
- 四类语义（assist / filter / input / suggestion）——**m3 chips 页本次抓取文本未保留分类命名段，未能从官方文档确认**；但 Flutter 实现层一一对应可见：
  `ActionChip`（assist 语义）、`FilterChip`、`InputChip`、`ChoiceChip`（单选）——见 `material/action_chip.dart:89`、`filter_chip.dart:65`、`input_chip.dart:79`、`choice_chip.dart:59`。
  → 建议写「四种语义 + Flutter 四个类 + 第五个 `Chip` 为无交互容器」，括注「m3 侧命名本次未确认」。
- 规格（B）：高 32.0（`material/chip.dart:36`）、圆角 8、图标 18、label 14、padding 8（`_ChipDefaultsM3`）。

### 2.7 Text fields（A 未取到；B 有状态细节）

- **A 侧未取得**：`text-fields/overview`、`/specs`、`/guidelines` 均在 429 之后。因此 filled / outlined 的规范差异、容器高度、label 行为**未能从官方文档确认**。
- **B（Flutter）**：`_InputDecoratorDefaultsM3`（`material/input_decorator.dart`）：
  - 非聚焦边框/下划线 **1dp**，聚焦 **2dp**（源码注释：*focused state increases border width (2dp)*）；
  - enabled 状态边框/下划线用 `onSurface` **12% 透明度**；
  - disabled 用 **0.38**、填充 **0.04**。
  - filled 与 outlined 由 `InputDecoration.filled` + `border` 选择，二者**共用**同一状态机。
- 误用：官方 guidance 未取得 → 不列。

### 2.8 选择控件：Checkbox / Radio / Switch / Slider

| 组件 | B 规格（Flutter） | 备注 |
|---|---|---|
| Checkbox | 边长 18.0（`material/checkbox.dart:406`）；点击目标 padded 到 48 | 18 是**绘制**尺寸，不是点击尺寸 |
| Radio | 未取到数值 | m3 侧页未抓取 |
| Switch | 尺寸由 `SwitchConfig` 提供；`MaterialTapTargetSize.padded / shrinkWrap` 两分支（`material/switch.dart`） | track 宽高本次未取到 |
| Slider | 新 M3 track 高 **16.0**（旧 4.0）、track 最小长 **144.0**、thumb 4×44 区域（`material/slider.dart:2218, :1219`） | 见 §8.4 的 `year2023` 开关 |

### 2.9 Dialog / Bottom sheet / Side sheet

| 组件 | B 规格（Flutter） | A 侧 |
|---|---|---|
| Dialog（basic） | elevation 6.0、圆角 **28.0**、actions padding 左右 24 / 底 24（`material/dialog.dart` `_DialogDefaultsM3`）；用途（A）：*"provide important prompts in a user flow"* | overview 已抓，无更多数值 |
| Dialog（full-screen） | `Dialog.fullscreen` 存在（`dialog.dart:86/:91`），底部按钮区默认 `ColorScheme.surface`（:118 注释） | basic vs full-screen 的**选用条件未取得** |
| Bottom sheet（standard） | `BottomSheet` 类（`bottom_sheet.dart:73`） | m3 页未抓取 |
| Bottom sheet（modal） | `showModalBottomSheet`（`:1238`）；顶部圆角 **28.0**、**maxWidth 640**、drag handle **32×4**、禁用滚动控制时最大高比 **0.5625**（`:30`） | 同上 |
| Side sheet | **Flutter 无内置组件**（`material/` 无对应类）；m3 目录有该组件但页面未抓取 | 需自建（`Scaffold.endDrawer` 或自绘容器） |

> **桌面含义**：`maxWidth 640`（B）意味着 modal bottom sheet 在宽窗口不会拉伸到全宽，可直接依赖。

### 2.10 Snackbar / Tooltip / Badges / Divider / Progress

| 组件 | 关键事实 |
|---|---|
| Snackbar | A 用途页未抓取；B：单行垂直 padding 14.0（`material/snack_bar.dart:27`）；可设 `width`，且「Width and margin can not be used together」（源码注释） |
| Tooltip | B：**桌面最小高 24.0 / 移动 32.0**、垂直偏移 24.0（`material/tooltip.dart:226-227, :480, :794`） |
| Badges | A 用途：*"Badges show notifications, counts, or status information"*；四端 Available。B：`Badge` 类（[api](https://api.flutter.dev/flutter/material/Badge-class.html)） |
| Divider | A 用途：*"thin lines that group content in lists or other containers"*；B：默认占位高 16.0，thickness 取 `DividerThemeData`（`material/divider.dart`） |
| Progress indicators | B：新版 `_indicatorSize 41.0`、stroke 4.0、linear 最小高 4.0、track gap 4.0、stop indicator 半径 2.0、圆角 2.0；**默认仍走 year2023 旧外观**（`material/progress_indicator.dart:583`） |

### 2.11 Menus / Search / Lists / Cards / Carousel / Tabs

| 组件 | 关键事实 |
|---|---|
| Menus | **C，November 2025**：新增 **vertical menus**（推荐新设计），新形状/颜色样式/选中态、改进子菜单动效；颜色样式 **standard / vibrant**（vibrant 让选中项突出）；Android 上用 gaps 做更灵活布局；baseline menu 仍可用（[menus/overview](https://m3.material.io/components/menus/overview)）。B：菜单项最小 **64×48**（`material/menu_anchor.dart:3636`），入口 `MenuAnchor`（[api](https://api.flutter.dev/flutter/material/MenuAnchor-class.html)） |
| Search | m3 侧分 **search bar** 与 **search view**（search app bar 点击后进入 search view，A）。B：`SearchBar`（[api](https://api.flutter.dev/flutter/material/SearchBar-class.html)）、`SearchAnchor`（[api](https://api.flutter.dev/flutter/material/SearchAnchor-class.html)）——`SearchAnchor` 正是「展开成 search view」的载体 |
| Lists | **C，December 2025**：新增 **expressive list**（推荐新设计），baseline list 仍可用；新视觉 **standard / segmented**、**highlighted selection states**、flexible slots；平台仅 MDC-Android 与 Compose Expressive（[lists/overview](https://m3.material.io/components/lists/overview)）。B：ListTile 单/双/三行高 **56/72/88**、contentPadding 16/24、minLeadingWidth 24、minVerticalPadding 8（`material/list_tile.dart:738` 及 `_LisTileDefaultsM3`，源码类名有 typo） |
| Cards | A 用途：*"display content and actions about a single subject"*；Flutter Available / **Web Unavailable**。B：M3 圆角 12.0、elevation 1.0（`material/card.dart:171` 注释） |
| Carousel | A 用途：*"show a collection of items that can be scrolled on and off the screen"*；Flutter Available / Web Unavailable。B：`CarouselView`（[api](https://api.flutter.dev/flutter/material/CarouselView-class.html)）。**三类的官方分类（hero/多宽/全宽）本次未取得，不写** |
| Tabs | B：tab 高 **46.0**，图标+文本 **72.0**，分隔线 1.0（`material/tabs.dart:30-31`）；A 侧页未抓取 |

### 2.12 Date pickers / Time pickers / Toolbars / Pull to refresh

| 组件 | 关键事实 |
|---|---|
| Date pickers | B：`showDatePicker`（`material/date_picker.dart:196`）、`showDateRangePicker`（`:1165`）。A 侧页未抓取 |
| Time pickers | B：`showTimePicker`（`material/time_picker.dart:3254`）。A 侧页未抓取 |
| Toolbars | A 侧仅确认**目录存在**，且 app bars 指南要求把页面操作放到 Toolbars；B 侧 **Flutter 无 Toolbar 组件**（`material/` 检索 `^class Toolbar` 无命中） |
| Pull to refresh | **仅 Compose 索引有**（Pull to refresh），m3 目录无独立条目 → 跨端范围差异，记录不统一 |

---

## 3. 选择与层级模式

### 3.1 导航模式：bar vs rail vs drawer

| 判定维度 | bar（B） | rail（B） | drawer（B） |
|---|---|---|---|
| 数量 | 3–5，重要性相等 | 3–7（Compose）/ 3–5（Flutter class doc） | 未给阈值 |
| 窗口 | **Compact** | **Tablet or desktop** | 未给 |
| 稳定性 | 跨页面一致 | 顶层、随处可达 | 顶层 destination 切换 |
| 本项目倾向 | 窄窗降级才用 | **主用**（桌面 shell） | 二级/工具面板 |

- 依据：[navigation-bar](https://developer.android.com/develop/ui/compose/components/navigation-bar) / [navigation-rail](https://developer.android.com/develop/ui/compose/components/navigation-rail)；Flutter 侧同义表述见 [NavigationRail class](https://api.flutter.dev/flutter/material/NavigationRail-class.html)。
- **「三种模式如何二选一」的统一决策树未能从官方文档确认**（m3 nav 三页的 overview/guidelines 均未抓取成功）。上表只汇总可引用的**条件**，不做官方背书。

### 3.2 模态 vs 非模态、对话框 vs 全屏、反馈取舍

| 决策 | 可用依据 | 缺口 |
|---|---|---|
| modal vs non-modal | B：`showModalBottomSheet`（阻塞 + scrim）与 `BottomSheet`（可常驻）两种 API 明确区分（`material/bottom_sheet.dart:73, :1238`） | m3「何时用 modal」规范文字未取得 |
| dialog vs full-screen dialog | B：`Dialog` 与 `Dialog.fullscreen` 并存（`dialog.dart:86-106`） | **选择条件未取得**（guidance 页 429） |
| dialog vs bottom sheet | — | 未确认 |
| snackbar vs badge vs tooltip | A 已给三者用途定位：badge「notifications, counts, or status information」、tooltip 属补充说明、snackbar 属反馈 | 取舍规则未确认 |

> 写作建议：本章只写「条件表 + 标注缺口」，不要凭经验补一张看似权威的决策树。

### 3.3 层级与返回（B）

- **list-detail 的返回语义（可直接引用）**：窄屏只显示 detail 时，返回键应回到列表，且官方明确这种返回 **not part of the overall app navigation**（[canonical-layouts](https://developer.android.com/develop/ui/compose/layouts/adaptive/canonical-layouts)）。
- 本项目是桌面 shell：若采用 list-detail，需把「detail 内部返回」与「应用级返回/面包屑」分开建模 —— 可与 `docs/adr/0027-flutter-ui-shell-layout-component-layers.md` 的层级划分对齐（shell 层管目的地切换，页面层管 pane 内返回）。

---

## 4. 大屏与桌面（本项目重点）

### 4.1 窗口尺寸等级（B，唯一权威阈值来源）

| 轴 | compact | medium | expanded | large | extra-large |
|---|---|---|---|---|---|
| 宽 | <600dp | 600–840dp | 840–1200dp | 1200–1600dp | ≥1600dp |
| 高 | <480dp | 480–900dp | ≥900dp | — | — |

- 来源：[use-window-size-classes](https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes)。
- **关键语义（原文）**：等级由**窗口**决定，*"explicitly not determined by the size of the device screen"* → 不要写 `isTablet` 或按 `Platform.isWindows` 判断；分屏、桌面窗口缩放、折叠都会改变它，且运行期可变。
- large / extra-large 需 `supportLargeAndXLargeWidth = true` 才启用（同上）；官方称这三档对应 Material layout guidance 的 compact/medium/expanded，另加 large/x-large 面向桌面与 connected displays。

### 4.2 Canonical layouts（B）

| 布局 | 结构 | 窄屏降级 | 状态保留规则 |
|---|---|---|---|
| list-detail | expanded 双栏（list + detail）；medium/compact 单栏 | 单栏 | expanded→变窄：**detail 保持可见、list 隐藏**；仅 detail 可见且变宽：同时显示 list+detail，list 标示选中项；仅 list 可见且变宽：list + placeholder detail |
| feed | 等价内容元素进可配置网格，单列→多列 | 单列 | 适合 news / social |
| supporting pane | 主区约 **2/3** + 次区 | 次区放主内容**下方**或 **bottom sheet** | 次区内容「only meaningful in relation to primary content」即 supporting；反之（可独立成立）属 list-detail 的 detail |

- 来源：[canonical-layouts](https://developer.android.com/develop/ui/compose/layouts/adaptive/canonical-layouts)。
- 实现 API（Android，仅供参考）：`ListDetailPaneScaffold` + `rememberListDetailPaneScaffoldNavigator`（需 `@OptIn(ExperimentalMaterial3AdaptiveApi::class)`）、`SupportingPaneScaffold`。
- **reflow 的通用规则**：官方只给了上述三种布局的降级/升宽行为，**没有给「任意页面如何 reflow」的通用公式**；m3 `foundations/adaptive` 未取得（429）。

### 4.3 桌面交互：hover / focus / 键盘 / 右键 / 密度（B）

| 交互 | Flutter 事实 | 证据 |
|---|---|---|
| hover | `WidgetState.hovered` 为正式状态位；`InkWell.hoverColor` / `onHover` | `material/ink_well.dart:320, 328, 433, 441`；`material/widget_state.dart:184` |
| focus | `WidgetState.focused` | `material/widget_state.dart:192` |
| 键盘 | `FocusableActionDetector` / Shortcuts 体系；**Material 未定义桌面快捷键表** | 未能从官方文档确认快捷键规范 |
| 右键菜单 | `TextField.contextMenuBuilder`（`material/text_field.dart:325`，默认 `_defaultContextMenuBuilder`）；通用区域需 `SelectableRegion` 或自建 | 实现级 |
| 密度 | `VisualDensity.adaptivePlatformDensity` = 桌面（macOS/Windows/Linux）→ **VisualDensity.compact**，移动 → standard | `material/theme_data.dart:3233-3244`，注释 3246-3250 明确平台映射 |
| 滚动条 | `MaterialScrollBehavior.buildScrollbar` 在 linux/macOS/windows 的**纵向**滚动自动套 `Scrollbar`，横向不套 | `material/app.dart:848-860` |
| 滚轮/拖拽 | 默认 `ScrollBehavior.dragDevices` 不含 mouse（`_kTouchLikeDeviceTypes`）→ 鼠标拖拽不滚动 | `widgets/scroll_configuration.dart:120` |
| Tooltip | 桌面最小高 24.0 / 移动 32.0 | `material/tooltip.dart:226-227, :794` |

### 4.4 与本项目（桌面风格 Flutter shell）的对应点

| 官方/实现结论 | 项目现状 | 含义 |
|---|---|---|
| 尺寸等级由窗口决定，非设备（§4.1） | 断点逻辑在 shell 层；token 侧 `AppLayoutTokens.contentHorizontalPadding = 48`、`contentVerticalPadding = 16`（`app/lib/shared/ui/theme/tokens/app_layout_tokens.dart`） | 断点必须基于窗口宽度；48 的内容内边距在 compact（<600dp）下偏大，宜按等级分级（分级数值属本项目自定，M3 未给 content padding 数值） |
| rail 是 desktop/tablet 模式（§3.1） | `buildAppTheme` 已定制 `navigationRailTheme`（`app/lib/shared/ui/theme/theme.dart:38`） | 方向与官方一致，可直接以 rail 主导航，bar 仅窄窗降级出现 |
| rail 宽 80 / 展开 256（§1.3） | 同上 | 侧栏宽度应引用这两个值，不自拟 |
| modal bottom sheet maxWidth 640（§2.9） | `AppLayoutTokens` 无对应上限 | 宽窗下弹层不会过宽；更窄表单弹层需另定 |
| 桌面 → VisualDensity.compact（§4.3） | `buildAppTheme` 用 `visualDensity: VisualDensity.adaptivePlatformDensity` | 桌面上所有按钮/控件比移动更紧；这是 Flutter 平台默认，不是 M3 规定（M3 density 规范本次未取得），文档必须写明 |
| 桌面自动 Scrollbar、mouse 不能拖拽滚动（§4.3） | 已定制 `scrollbarTheme` | 自绘滚动区需显式 `Scrollbar`，否则鼠标拖拽会「失效」 |
| Toolbars 组件（A）Flutter 无实现（§2.12） | — | 需要工具栏时自建组件并单立规格 |
| M3 无桌面快捷键规范 | — | 快捷键表属产品决策，标为「本项目自定」 |

### 4.5 M3 Expressive 动效在 Flutter 的落地状态（一条硬证据）

- `material/page_transitions_theme.dart:711` 注释：*"Android is using Material 3 Expressive springs that are not currently [implemented]"* → **Flutter 尚未实现 Expressive 弹簧动效**。
- 但 Flutter **已有** Expressive 的**配色**变体：`DynamicSchemeVariant.expressive`（`material/color_scheme.dart:51`）与 `SchemeExpressive`（`:2217`）。
- 结论：Expressive 在 Flutter 是「颜色可用、组件/动效不可用」的**半可用**状态 → 设计系统文档应写「颜色层可开，组件层暂缓」，并给生效条件（§5）。

---

## 5. M3 Expressive：本次可确认的组件更新清单

| 组件 | 更新（官方页面原文要点） | 页面线索 | 状态判定 |
|---|---|---|---|
| App bars | 新 search app bar；medium/large **flexible** 取代 medium/large；更名 app bar；subtitle / 居中文本 / 换行 / 更多槽位 | May 2025 | 已发布；Flutter/Compose 均 Available |
| Buttons | 五尺寸、configurations、round/square、toggle、morph | May 2025 | 已发布；**Web Expressive Unavailable** |
| Icon buttons | 五尺寸、四 configuration、三宽度、toggle、可在 button groups 中互操作 | May 2025 | 已发布；Flutter Available |
| Segmented buttons | **不再推荐**，改用 connected button group | May 2025 | 已发布（属退役而非新增） |
| FABs | 新增 medium；small 不再推荐；变体按尺寸；tone 颜色；surface FAB 不再推荐 | May 2025 | 已发布 |
| Extended FABs | 56 / 80 / 96 dp 三尺寸 | May 2025 | 已发布 |
| FAB menu | 新组件，取代 speed dial / stacked small FABs | May 2025 | **仅 Compose Expressive**；无 Flutter 行 → **预览级** |
| Lists | expressive list、segmented 视觉、highlighted selection、flexible slots | **December 2025**（另一段未标月） | 仅 MDC-Android 与 Compose Expressive → **预览级** |
| Menus | vertical menus、standard/vibrant、子菜单动效 | **November 2025** | 同上；新设计推荐但 baseline 仍可用 |

**「已发布 vs 实验/预览」判据（本文采用）**：

1. 页面是否以 *M3 Expressive update* 块正式发布（是 → 已发布）；
2. 可用性矩阵中**除 *Expressive* 列外**是否至少有一个平台 Available（是 → 该平台有稳定实现）；
3. Compose 是否要求 `@ExperimentalMaterial3Api` / `@ExperimentalMaterial3AdaptiveApi`（是 → API 层仍实验）——见 [Compose Material 3](https://developer.android.com/develop/ui/compose/designsystems/material3)。

> 目录中存在但**细节未能从官方文档确认**的 Expressive 相关组件：**Button groups、Split button、Loading indicator、Toolbars**（页面文本未取到）。不要凭组件名推测规格。

---

## 6. 内容设计（content design）与文案语气

- **官方内容页未取得**：`m3.material.io/foundations/content-design`（及 `/writing` 等子页）在 429 之后，**全部未能从官方文档确认**。
- 本次唯一可引用的一手结构约束来自 app bars：app bar 聚焦当前页面 + 1–2 个必要操作，页面操作移至 Toolbars（[app-bars/overview](https://m3.material.io/components/app-bars/overview)）。
- 可用的**组件级文案约定**（来自组件用途定义，A）：badge 只承载 notification / count / status；divider 是分组线而非装饰；dialog 是「important prompts in a user flow」→ 只用于需要中断的确认。

> 建议：content design 章节先留占位，并在 ADR-0029 的文档治理里标注「需二次抓取 m3 foundations/content-design 后补全」，不要用二手写作指南填充。

---

## 7. 无障碍（组件级）

| 要点 | 官方要求（B） | 来源 |
|---|---|---|
| 触控目标 | **至少 48dp × 48dp**，*"Larger is even better"*；*"For precise input (mouses and trackpads), the touch target can be smaller."* | [accessibility/apps](https://developer.android.com/guide/topics/ui/accessibility/apps) |
| 文本对比度 | 正文 **≥ 4.5:1**；其他文本（大字号）**≥ 3:1** | 同上 |
| Flutter 对应 | `kMinInteractiveDimension = 48.0`（`material/constants.dart:27`）；IconButton 视觉 40×40、点击区补到 48（`icon_button.dart:1131-1132, :39`）；SegmentedButton 用 densityAdjustment 补足（`segmented_button.dart:672-682`） | 实现级 |

- **组件级 a11y 的规范侧内容未取得**：m3 每个组件页都有独立 `/accessibility` tab（结构上确认存在），但本会话全部在限流后 → **未能从官方文档确认**各组件（开关语义角色、tab label 规则等）的官方要求。
- 可确认的语义实现路径（B）：Flutter 用 `Semantics` / `WidgetState` 表达 selected、disabled、toggled；`WidgetState` 枚举（`material/widget_state.dart:180` 起）含 `hovered`、`focused`、`pressed`、`dragged`。
- **桌面例外**：官方明确鼠标/触控板属 precise input，触控目标可小于 48 → 桌面端不应机械套 48dp 于所有图标按钮，但仍建议保留 48 的**命中区**以兼容触屏笔记本（这是产品判断，不是官方结论）。

---

## 8. 状态模型（state layer）在组件上的落地

### 8.1 可确认的状态集合（B）

`WidgetState` 枚举（`material/widget_state.dart:180-197`）：`hovered`、`focused`、`pressed`、`dragged` 等（disabled/selected 系列由各组件 `ButtonStyle` / `overlayColor` 消费）。
→ M3 的「state layer + 状态」在 Flutter 的实现载体是 **`WidgetStateProperty` / `overlayColor`**，不是一层独立遮罩 widget。

### 8.2 各状态的表现方式（B，按组件）

| 状态 | Flutter 实现载体 | 证据 |
|---|---|---|
| hover / focus / pressed | `InkWell.overlayColor`（`hoverColor`/`highlightColor` 为特例） | `material/ink_well.dart:328, 441, 554` |
| disabled | 透明度：TextField 0.38 / 填充 0.04（`input_decorator.dart`）；多数组件用 onSurface 12%/38% 组合 | 实现级 |
| selected | `selected` 布尔 + 主题色切换（NavigationBar/rail 指示器、SegmentedButton、Chip） | 各自 defaults 类 |
| dragged | `WidgetState.dragged` 存在；由可拖拽组件自行映射 | `material/widget_state.dart` |

### 8.3 与本项目的一处**实质冲突**（必须记录）

`app/lib/shared/ui/theme/theme.dart:38` 的 `buildAppTheme` 中：

- `splashFactory: NoSplash.splashFactory`
- `highlightColor: Colors.transparent`

→ 这两项**移除了 pressed/ripple 反馈**，而 pressed 是 M3 state layer 体系最基础的反馈层（A 侧 state layer 规范页本次未取得；Flutter 实现载体明确：`ink_well.dart` 的 `overlayColor`）。
**结论**：主题当前实现与「保留 M3 状态反馈」在设计意图上冲突。重写 Material 3 主题时必须显式决策（保留无 ripple 的桌面观感 vs 恢复 state layer），并在 MASTER 记录理由 —— 这是迁移中最容易漏的一条。

### 8.4 版本开关导致的「默认即旧外观」（B，三处）

| 组件 | 开关 | 默认 | 后果 |
|---|---|---|---|
| Progress indicator | `year2023` | **true**（`progress_indicator.dart:583`） | 默认**没有** stop indicator、track gap、圆角；需 `year2023: false` 才启用新外观 |
| Slider | `year2023` | 由 widget ?? theme ?? true | 默认 4.0 track 而非 16.0 |
| 全部 Material | `ThemeData.useMaterial3` | 本机 SDK 未确认（grep 未命中） | 本项目显式 `useMaterial3: true`，无风险 |

→ 写「M3 组件默认外观」时必须注明：**Flutter 的若干 M3 刷新是 opt-in 的**，`useMaterial3: true` 不等于 m3 规范当前外观。

---

## 9. 跨来源范围差异汇总（不强行统一）

| 主题 | m3（A/C） | Compose（B） | Flutter（B） |
|---|---|---|---|
| Side sheet | 有独立组件 | 索引无独立条目 | 无内置组件 |
| Toolbars | 有独立组件，且 app bars 指南指定其承载页面操作 | 索引无 | 无 `Toolbar` 类 |
| Button groups / Split button | 目录有 | 索引未单列（Segmented button 在列） | 无 |
| FAB menu | C，仅 Compose Expressive | 有（Expressive） | 无 |
| Extended FAB 尺寸 | C：56/80/96 三档 | 跟随 Expressive | 仅 56 高一档 |
| Segmented buttons | C：**不再推荐** | 仍在文档体系内 | 仍在实现（40.0 最小高） |
| rail destinations | 未取得 | 3–7 | 「typically between three and five」 |
| Pull to refresh | 无独立条目 | 有独立组件页 | `RefreshIndicator` 存在（未逐一取证） |
| Expressive 动效 | A/C：springs | 有（Expressive） | **未实现**（`page_transitions_theme.dart:711`） |
| Expressive 配色 | C | 有 | **有**：`DynamicSchemeVariant.expressive`（`color_scheme.dart:51`） |

---

## 10. 证据薄弱 / 未能确认清单（照抄，不要补编）

1. **m3 全部 `/specs` 数值**：交互式 token 浏览器，只能取 token 名（如 `App bar medium container height`），**无 dp/字号数值**。
2. **m3 全部 `/guidelines` 与 `/accessibility` 子页**（除 app-bars/guidelines）：429，未取得。
3. **m3 `foundations/*`**（adaptive、content design、interaction states、accessibility、layout）：全部未取得 → 「state layer 官方规格」「reflow 定义」「语气规则」均空缺。
4. **官方 GitHub 仓库**（material-components / material-tokens / material-symbols）：HTML 抓取全部失败 → **token 权威数值未取得**，本文数值均来自 Flutter SDK。
5. **drawer modal/standard 判定、dialog vs full-screen 选用条件、snackbar/tooltip/dialog 取舍**：未取得。
6. **Chips 四类官方命名、Cards 三类官方分类、Carousel 三类规格**：页面文本未保留对应段落，未确认。
7. **`ThemeData.useMaterial3` 默认值**：本机 SDK grep 未命中，未确认（项目已显式 true，不影响）。
8. **Switch track 尺寸、Radio 尺寸**：未取到数值。
9. **M3 桌面快捷键规范**：官方未见该文档（m3 触控优先；desktop 指南页未取得）。
10. 尝试过但未成功的页面（供后续重试）：`m3.material.io/foundations/adaptive-design/*`、`/foundations/content-design/*`、`/foundations/interaction/states`、`/components/{navigation-bar,navigation-rail,navigation-drawer,text-fields,side-sheets,bottom-sheets,search,snackbar,tooltip,tabs,sliders,switch,radio-button,date-pickers,time-pickers,progress-indicators,toolbars,button-groups,split-button}/*`、`developer.android.com/develop/ui/compose/designsystems/material3-expressive`（**404**）、`docs.flutter.dev/ui/design/material`（正文）、`docs.flutter.dev/ui/adaptive-responsive/*`（子页）。

---

## 11. 对本项目的含义（摘要，供 MASTER 起草）

1. **导航**：以 `NavigationRail` 为主（官方判定 desktop/tablet，宽 80 / 展开 256），窄窗降级到 bar；`navigationRailTheme` 已在 `app/lib/shared/ui/theme/theme.dart` 定制。
2. **尺寸等级**：用「窗口宽度」而非平台判定（§4.1 原文），让 `AppLayoutTokens`（`theme/tokens/app_layout_tokens.dart`，48/16）随等级分级；分级数值属本项目自定，须标注。
3. **状态反馈是最大隐性冲突**：`NoSplash.splashFactory` + `highlightColor: transparent` 关掉了 pressed state layer（§8.3），迁移时必须显式决策并写进 MASTER/ADR，不要静默继承。
4. **默认外观 ≠ 规范外观**：`year2023` 默认 true（Progress/Slider）、`VisualDensity.adaptivePlatformDensity` 在桌面变 compact、Dialog/BottomSheet 的 28 圆角与 640 上限 —— 都要以「实现默认值」口径记录。
5. **Expressive 只开颜色层**：`DynamicSchemeVariant.expressive` 可用，组件与弹簧动效未实现（§4.5），文档写「适用范围：配色」并列出未实现项。
6. **需自建**：Side sheet、Toolbars、Button groups、Split button、FAB menu、search app bar、medium/large flexible app bar、三档 Extended FAB —— 有官方目录条目但 Flutter 无实现，若要使用须在 `design-system/hentai-library/` 内单独立规格（与 `ThemeExtension` 体系并存，勿散落魔法值）。
