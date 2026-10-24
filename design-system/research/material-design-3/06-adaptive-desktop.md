# Material 3 自适应布局与桌面/大屏策略（官方文档调研）

> 用途：把「同一套 Flutter 应用要同时跑手机与桌面」的布局规则钉在官方依据上，作为 07 Templates、08 Screens 与后续 `AppLayoutBreakpoints` 迁移的依据。
> 证据分级：**A** = m3.material.io 官方页面原文；**B** = 官方实现源码/规格值；**C** = 本项目决策或工程推断。
> 本文只覆盖**布局与自适应**；颜色/字阶/shape/elevation 见 `01-foundations.md`，组件规格见 `02-components-patterns.md`。

---

## 0 检索说明

用户给定 4 个入口：

1. https://m3.material.io/foundations/layout/canonical-layouts
2. https://m3.material.io/foundations/layout/grids-spacing/spacing
3. https://m3.material.io/foundations/layout/breakpoints
4. https://m3.material.io/blog/5-steps-large-screen-apps

抓取结果：

| 入口 | 结果 |
| --- | --- |
| `breakpoints` | 可读，19809 字符，含断点表、分栏/导航/沟通/动作矩阵、五问定义 |
| `grids-spacing/spacing` | 可读，10445 字符，**只有原则没有 dp 数值** |
| `blog/5-steps-large-screen-apps` | 可读，18860 字符；注意不带尾斜杠会返回 0 长度 |
| `canonical-layouts` 首页 | JS 渲染页，抓取为空正文 |
| `canonical-examples/feed`、`list-detail`、`supporting-pane` | 三页均可读（8212 / 11415 / 7990 字符），本文的 canonical layout 数值来自这里 |
| 原始抓取缓存 | `.scratch/m3docs/{breakpoints,spacing,5-steps,canonical-*}.json`（未入库） |

证据边界：M3 的 **grid 列数/margin/gutter 具体 dp** 在已抓到的页面里没有表格；本文中 4/8/12 列与 16/24/32 gutter 是 **本项目 Figma Grid Style 的取值（C）**，不是官方规范值。规范只要求「列网格 + 随断点重排 + 正文 40–60 字符/行」。

---

## 1 五档断点（A）

官方原文：

> There are five main breakpoints: compact, medium, expanded, large, and extra-large.
> A breakpoint (previously window size class) is the window size at which a layout needs to change to match available space, device conventions, and ergonomics.
> These apply to Android and web.

| Breakpoint | 宽度 (dp) | 官方给的常见设备 |
| --- | ---: | --- |
| Compact | < 600 | 手机竖屏 |
| Medium | 600–839 | 平板竖屏；折叠屏展开竖屏 |
| Expanded | 840–1199 | 手机横屏；平板横屏；折叠屏展开横屏；桌面 |
| Large | 1200–1599 | 桌面 |
| Extra-large | ≥ 1600 | 桌面；超宽屏 |

来源：https://m3.material.io/foundations/layout/breakpoints

要点：

- 术语已从 **window size class** 改为 **breakpoint**；但 Android API 仍叫 window size class。
- 断点按**应用可用窗口**判断，不按设备类型；同一台设备横竖屏、多窗口、折叠展开都会换档。
- 分栏数量随窗口增长：compact/medium 单栏；expanded/large 推荐两栏；extra-large 可三栏。
- 设计按断点出重排态，不要为每种设备各画一套。

**本项目落点（C）**：设计 frame 390 / 800 / 1024 / 1440 / 1920；接缝测试 599/600、839/840、1199/1200、1599/1600。代码现状 `app/lib/shared/ui/layout/app_layout_breakpoints.dart:10,13` 仍是 600/1024，迁移时改五档。

---

## 2 分栏、导航与组件置换（A）

### 2.1 官方矩阵

| Breakpoint | Panes | Navigation | Communication | Action |
| --- | --- | --- | --- | --- |
| Compact | 1 | Navigation bar；modal expanded navigation rail | Simple dialog；Full-screen dialog | Bottom sheet |
| Medium | 1（推荐）或 2 | Navigation bar；modal expanded navigation rail | Simple dialog | Menu |
| Expanded | 1 或 2（推荐 2） | Modal 或 standard expanded navigation rail | Simple dialog | Menu |
| Large | 1 或 2（推荐 2） | Modal 或 standard expanded navigation rail | Simple dialog | Menu |
| Extra-large | 1–3（推荐 3） | Modal 或 standard expanded navigation rail | Simple dialog | Menu |

来源：https://m3.material.io/foundations/layout/breakpoints

补充原文：

- 「On mobile, the navigation rail is collapsed by default.」
- 「On an expanded device, the navigation rail can be open by default, revealing more actions and features.」
- 「Collapsed navigation rails take up minimal space and are best for medium windows and larger.」
- 「Expanded navigation rails show text labels and an extended FAB, and can be default or modal.」

### 2.2 组件置换表（A）

| 组件类型 | Compact | Medium | Expanded |
| --- | --- | --- | --- |
| Navigation | Navigation bar | Collapsed navigation rail | Collapsed navigation rail |
| Navigation（展开态） | Modal expanded navigation rail | Modal expanded navigation rail | Standard expanded navigation rail |
| Communication | Basic / full-screen dialog | Basic dialog | Basic dialog |
| Supplemental selection | Bottom sheet | Menu | Menu |

### 2.3 五问：跨断点时改什么

官方要求在跨断点时逐项判断：

1. **Reveal** — 揭示之前放不下的内容（第二栏、辅助信息）。
2. **Divide** — 把一栏拆成两栏/三栏。
3. **Resize** — 放大元素、调整 margin 与字号。
4. **Reposition** — 把导航从底部移到侧边、把 FAB 放进 rail。
5. **Swap** — 换成功能等价的组件（navigation bar ↔ rail、bottom sheet ↔ menu）。

约束：

- **不要换功能不等价的组件**：官方明确提醒 button ↔ chip、list item ↔ card 这类替换要谨慎。
- Medium 用两栏只适合**低密度内容 + 清晰动作**；高信息密度两栏会降低可用性。
- 任何断点都让正文保持 **40–60 字符/行**（靠 margin 与 type style 调，不靠缩小字号）。
- 「Additional space doesn’t just mean making the same thing bigger.」

---

## 3 Canonical layouts（A）

官方把常见大屏结构归纳为 feed、list-detail、supporting pane 三类。canonical-layouts 首页抓不到，以下取自三个 example 子页。

### 3.1 List-detail

来源：https://m3.material.io/foundations/layout/canonical-examples/list-detail

| Breakpoint | 可见 pane |
| --- | --- |
| Compact (0–599) | 1 |
| Medium (600–839) | 1（推荐）或 2 |
| Expanded (840+) | 2 |
| Large (1200–1599) | 2 |
| Extra-large (1600+) | 2 |

行为规则（原文）：

- **Back**：单栏时只在 detail 出现返回；双栏不需要返回。
- **Selected state**：双栏时选中态只出现在 list。
- **Visual focus**：双栏用显式/隐式分组引导焦点。
- **No selected item**：单栏显示 list；双栏在 detail 显示占位内容。
- **切换单/双栏**：保持「最近使用的 pane」可见（多选等场景）。
- Medium 双栏时用 **bottom navigation bar** 省横向空间。

### 3.2 Supporting pane

来源：https://m3.material.io/foundations/layout/canonical-examples/supporting-pane

| Supporting pane 位置 | 宽度 | Breakpoint |
| --- | --- | --- |
| 下方 | 弹性 | Compact / Medium |
| Leading 或 trailing | 固定 360dp | Expanded |

- primary 区占主要空间，secondary 只在与 primary 相关时使用。
- Compact 可用 **bottom sheet** 承载 supporting 内容，保持 primary 焦点。
- 父子关系（列表→详情）应改用 list-detail，不要用 supporting pane。

### 3.3 Feed

来源：https://m3.material.io/foundations/layout/canonical-examples/feed

- 网格布局，卡片/列表都可；compact 单列铺满 pane，medium 可多列，expanded/large/XL **列数通常增加**。
- 用**大小与位置**表达层级（大卡 lead，小卡辅助）。
- 重排时保持内容顺序；顺序由位置决定。
- 可混用不同宽高比，但要有明确分组。

---

## 4 Grids 与 spacing（A 原则 + C 数值）

来源：https://m3.material.io/foundations/layout/grids-spacing/spacing

官方页面能读到的原则：

- 间距用于**分组内容、引导注意力、表达层级**。
- 桌面可以比移动更宽松；卡片之间的横向间距应一致。
- 大屏不是把同样的内容放大，而是用布局区域与间距重建层级。

**官方没有给 spacing scale 的 dp 值**（该页无数值表）。因此：

- 项目 spacing scale 取 **4/8 体系**：4、8、12、16、24、32、48、64（已写入 Figma `Number` collection 与 MASTER §4.1）。
- 4 只用于图标内边距、描边等细节；常规分组用 8 的倍数。
- 本项目 Grid Style（C）：

| Grid Style | 列数 | Gutter | 适用 |
| --- | ---: | ---: | --- |
| `grid/compact-600` | 4 | 16 | compact |
| `grid/medium-840` | 8 | 24 | medium |
| `grid/expanded-1200` | 12 | 24 | expanded / large |
| `grid/large-1600` | 12 | 32 | extra-large |
| `grid/baseline-8` | — | 8pt 基线 | 所有排版对齐 |

- 页面 margin 本项目取 **16（compact）/ 24（≥ medium）**；这是项目决策，不是官方 dp 表。
- 正文列宽用 40–60 字符约束，超宽窗口用**内容最大宽 + 居中**，不让文本拉满 1920。

---

## 5 连续性：窗口变了不要崩（A）

来源：https://m3.material.io/blog/5-steps-large-screen-apps

1. **先建立列网格** — 让元素相对网格对齐，而不是互相堆叠。
2. **建立 layout regions** — 用区域 + visual grouping / containment 组织内部层级。
3. **选对组件** — 允许 fixed / fluid 尺寸与组件置换。
4. **保持连续性** — 折叠/展开、多窗口会改变 `screenLayout`、`screenSize`、`smallestScreenSize`；**不要缓存或硬编码窗口尺寸/方向**，运行时重新取。
5. **测输入** — 触摸、键盘、鼠标都要测；硬件键盘弹出时输入框不能被遮住。

对 Flutter 的直接含义（C）：

- 用 `MediaQuery.sizeOf(context)` / `LayoutBuilder` 取**当前约束**，不要缓存成全局单例。
- 断点判断用可用宽度，不用 `Platform.isAndroid` 推断设备。
- 单/双栏切换只改布局，不重建路由栈；detail 的返回按钮只在单栏出现。

---

## 6 桌面与输入方式（A/C）

官方断点页与 5-steps 博客强调的桌面差异：

- **输入**：鼠标 hover、键盘 focus、触摸 pressed 三种都要有可见反馈；焦点必须可见。
- **hover 不是唯一入口**：hover 才出现的操作在触摸/键盘上不可达，必须另有菜单或常驻入口。
- **触达**：交互目标 ≥ 48×48；视觉高度可以是 40（例如按钮/输入框），但点击区补到 48。
- **文本选择/滚动**：桌面要支持鼠标滚轮、触控板、键盘 PageUp/Down；不要只依赖拖拽。
- **窗口**：桌面窗口可任意缩放，最小 360×480；任何宽度都不能出现横向溢出。
- **密度**：桌面可以用更紧的视觉密度，但**不能低于 48 的点击区**；项目当前 `visualDensity: adaptivePlatformDensity` 会在桌面返回 compact，迁移时只调视觉密度、不缩点击区。

来源：https://m3.material.io/foundations/layout/breakpoints；https://m3.material.io/blog/5-steps-large-screen-apps

---

## 7 本项目页面 → canonical layout 映射（C）

| 页面 | Compact | Medium | Expanded | Large / XL |
| --- | --- | --- | --- | --- |
| 首页 Home | feed 单列 | feed 2 列 | feed 3 列 | feed 4–5 列，内容限宽 |
| 书库 All libraries | feed 单列 | feed 2 列 | **list-detail 双栏**（列表 + 详情） | 双栏，list 固定 360–400 |
| 单本详情 Library | 单栏 detail | 单栏（可选 supporting 下方） | **supporting pane**：主内容 + trailing 360 元数据 | 同 expanded，rail 展开 |
| 阅读器 Reader | 单栏全屏 | 单栏全屏 | 单栏 + 可选 trailing 设置/缩略图 | 同 expanded，阅读区限宽 |
| 历史 History | feed/list 单列 | 2 列 | 2 列 + 详情 | 双栏 |
| 搜索 Search | 单列结果 | 2 列 | 2 列 | 3 列，筛选常驻 |
| 设置 Settings | list-detail 单栏 | 1（推荐）或 2（低密度） | 2 栏：分类 + 内容 | 2 栏 + 展开 rail |

判定依据：

- 书库/历史/设置是**父子关系**（分类→条目、列表→详情）→ list-detail。
- 详情页的章节/元数据是**只与主内容相关**的辅助信息 → supporting pane；expanded 起固定 360dp。
- 首页/搜索结果是无固定层级的浏览内容 → feed。
- 阅读器是沉浸式单栏，允许在所有断点保持单栏（官方视频通话例子同理）；设置面板在 compact 用 bottom sheet。

---

## 8 模板矩阵（C，供 07 Templates 使用）

首批模板（D7）按断点出：

| 模板 | Compact 390×844 | Medium 800×1280 | Expanded 1024×768 | Large 1440×900 | XL 1920×1080 |
| --- | --- | --- | --- | --- | --- |
| 主壳（导航） | bottom nav 80 | collapsed rail 80 | collapsed rail 80 | expanded rail 256 | expanded rail 256 |
| Home | 单列 | 2 列 | 3 列 | 4 列 + 限宽 | 5 列 + 限宽 |
| Library | 列表→详情路由 | 可选双栏 | 双栏 360+flex | 双栏 400+flex | 双栏 + 辅助栏 |
| Reader | 全屏单栏 | 全屏单栏 | 单栏 + trailing 360 | 单栏 + trailing 360 | 单栏 + trailing 360 |

导航落点（C）：

- **Compact**：`NavigationBar`，高 80，4 个目的地：首页 / 书库 / 历史 / 设置；选中用 filled 图标 + secondaryContainer indicator。
- **Medium / Expanded**：`NavigationRail` collapsed，宽 80；图标 24，选中 indicator 56×32；标签用 tooltip 或 expanded 态补。
- **Large / XL**：expanded rail，宽 256（Flutter `NavigationRail` 的 `minExtendedWidth` 默认 256），显示文字标签；FAB 可固定在 rail 顶部。
- 桌面窗口最小 360×480；rail 不压缩内容到 < 360。

> 尺寸 80/256/56×32 是实现值（B），用于 Figma 模板与 Flutter 迁移；官方规范页对这些组件的具体 dp 抓取失败，落地时以 Flutter/Compose 实现为基准并截图核对。

---

## 9 与现有设计系统的关系

- 断点：MASTER §5 的五档与本文一致；代码 `AppLayoutBreakpoints` 迁移时补 medium/expanded/large/XL 五个常量。
- 组件：本文只定义**壳层与分栏**；Button/TextField 等已在 05 Components；NavigationBar/NavigationRail/FAB/List Item/Card 待建（P0）。
- Figma：Templates 页按第 8 节矩阵出 5 个断点；每张模板内用 `grid/*` Grid Style + auto layout，不手摆坐标。
- 代码：先改设计稿，设计稿评审通过后再动 `app/lib/shared/ui/layout/` 与 `theme.dart`（m00103/m00146）。

---

## 10 待办与证据缺口

- [ ] Navigation bar / rail 的官方精确 dp（高度、indicator、destination 间距）——规范页抓取失败，待补官方 specs 页或 Flutter 源码核对。
- [ ] 桌面 top app bar 的官方高度与滚动行为（当前用 64 视觉高度，触达 48）。
- [ ] 官方 grid margin/gutter 数值表（当前为本项目 C 级取值）。
- [ ] Extra-large 三栏的具体拆分（内容 + 辅助 + 导航）需在 08 Screens 用真实内容验证。
- [ ] 多窗口/折叠屏在 Flutter 桌面端的最小窗口约束与恢复策略。
