# 04 · Figma 侧 M3 设计系统落地工作流

> 目标：在 Figma 里把 Material 3（**baseline，排除 Expressive**）建成可维护的设计库，并产出桌面端首页设计稿；同时给出「插件 API / figwright MCP 程序化落地」的可行边界。
> 范围：只谈设计库与设计稿，不改 `app/`、`core/`。代码侧约束见同目录 `03-flutter-implementation.md`。
> 读者：先做设计稿、定稿后再改代码的人。

---

## 0. 检索方法与证据分级

本次调研的抓取通道全部实测过，结论如实体现在下文每一行的来源栏里。

| 通道 | 实测结果 | 影响 |
|---|---|---|
| `web_fetch` | 对 figma.com / help.figma.com / github.com / developer.android.com 一律报 `URL hostname ... resolves to a non-public IP address` | 无法取正文 |
| `read_page`（modsearch） | `firecrawl returned 429 Too Many Requests ... keyless free tier rate limit` | 无法取正文 |
| `pwsh Invoke-WebRequest` | `基础连接已经关闭: 接收时发生错误` | 无法取正文 |
| `web_search`（Keenable） | 可用，返回页面级 snippet | **本文唯一证据来源** |
| `mcp__figwright__ping` | 可用，但 `sessions.connectedCount = 0` | 见 §1 与 §4 |

证据分级（全文通用）：

- **官方**：Google（m3 / developer.android.com / developers.google.com）或 Figma（figma.com/community 官方条目、help.figma.com、developers.figma.com、github.com/figma）发布。
- **社区**：第三方个人/组织，可作参考，不采信为规范。
- **未核实**：仅凭 snippet 无法确认正文/数值，或与另一来源冲突。**凡是未核实的地方本文不填数值。**

> 说明：`m3.material.io` 是 JS 渲染页，本次所有抓取通道均无法取到正文，因此**本文不给出任何 M3 规格里的 px / sp / 色值**，需要那些数值时请人工在 m3.material.io 与 kit 里读。

---

## 1. 官方 Figma 资源与插件现状（逐项核实）

### 1.1 清单与判定

| 资源 | URL | 归属 | 与最新 M3 的关系 | 本项目可用性判定 |
|---|---|---|---|---|
| Material 3 Design Kit | https://www.figma.com/community/file/1035203688168086460 | 官方（Google）：页面内给出 Google 反馈邮箱 `m3-design-kit-feedback@google.com` 与 `@materialdesign` 渠道 | **v1.20 起已并入 Expressive**（见 1.2） | 只作视觉/分级参考；**不整包采用** |
| Material Theme Builder（Figma 插件） | https://www.figma.com/community/plugin/1034969338659738588 | 官方（Google / material-foundation） | baseline 的动态色 + 字阶生成器，与 Expressive 无关 | **采用**，见 §6 第 1 步 |
| Material Symbols 图标字体 | https://developers.google.com/fonts/docs/material_symbols | 官方（Google Fonts） | 与 M3 baseline 一致（可变字体轴） | **采用字体路线**，见 1.4 |
| Wear OS 设计 kits | https://developer.android.com/design/ui/wear/guides/get-started/design-kits | 官方（Google） | 页面明写 "support Material 3 Expressive" | **不可用**（形态不符 + Expressive） |
| Android UI Kit | https://www.figma.com/community/file/1237551184114564748 | 官方（Google），但页面自述 "This file will stop receiving updates and support" | 手机/系统 UI 形态，非桌面应用库 | **不采用** |
| Material 3 Expressive Design Kit（通用应用版） | — | — | 多轮检索只命中第三方件 | **未核实（疑似不存在）** |
| Figma 插件 "Material Symbols" | https://figmaplugins.co/plugins/material-symbols | **社区**（"published by Tomas Roggero in 2022"） | 第三方图标插入器，非官方 | 不用；见 1.4 |

Material 3 Design Kit 页面自述原文（snippet）：

> "The Material 3 Design Kit provides a comprehensive introduction to the design system, with styles and components to help you get started. … The Material 3 Design Kit is built to work with the Material Theme Builder Figma plugin. … Looking for icons? Try the Google Icons Library …"

（发布者名字段未在可读内容中出现 → **未核实**；"Google Icons Library" 的具体 URL 与官方性亦 **未核实**。）

### 1.2 关键结论：kit 已经不是纯 baseline

同一页面上的版本记录（snippet 原文）足以推翻"直接用 kit 就是 baseline"的假设：

> "V1.21 ⚠ Due to Buttons and Icon Buttons being rebuilt users may see resets to their component instances when accepting this update … Additions: • XR Toolbar … 05.13.25 V1.20 Major update: ⚠ M3 Expressive is an update to the Material 3 design system … New components: • Button groups • FAB menu • Split button • Loading indicator. Updated components: • App bars • Buttons • FAB • Extended FAB • Icon Buttons • Progress indicators • Navigation bars • Navigation rails • Sliders • Toolbar …"

因此：

1. **v1.20（2025-05-13）之后**，kit 里 Buttons / FAB / App bars / Navigation bars / Sliders 等已按 Expressive 规范重构，**页面默认状态就是 Expressive 形态**。
2. **v1.21** 又重建了 Buttons 与 Icon Buttons，并新增 XR Toolbar。
3. 旧版本（纯 baseline 快照）的可得性 **未核实**；Figma Community 文件通常只提供最新版，是否能回滚版本需人工确认。

### 1.3 因 Flutter 侧无 Expressive 支持，哪些内容必须排除

前提事实：`flutter/flutter#168813`（"Support M3 Expressive"）仍为 **Open**（opened 2025-05-14），即 Flutter 官方 Material 库无 Expressive 组件与 token（见 `03-flutter-implementation.md`）。

| kit 内容（v1.20+） | 状态 | 处理 |
|---|---|---|
| Button groups / FAB menu / Split button / Loading indicator | Expressive 新增组件 | **排除**。Flutter 侧无官方对应 widget（具体哪个版本落地 **未核实**；依据 #168813 仍是 Open） |
| Buttons / Icon Buttons / FAB / Extended FAB / App bars / Navigation bars / Navigation rails / Progress indicators / Sliders / Toolbar | 已按 Expressive 重构 | **不照抄变体矩阵与形状/尺寸**；只保留 baseline 语义（样式角色、状态集合） |
| 新 shape set / emphasized typography / 新 motion | Expressive 设计语言 | **排除**。仓库已有 `AppRadiusTokens`/`AppMotionTokens`，以代码为真 |
| XR Toolbar / XR App bars | XR 形态 | **排除**（无关形态） |
| 颜色角色、type scale、elevation、spacing | baseline | **可采用**（但 color 用 Material Theme Builder 生成，不搬 kit 的颜色样式） |

**一句话**：kit 现在只能当"baseline 语义的参考图"，不能当"可直接继承的库"。我们的 Figma 库必须**自建**，只借用 Material Theme Builder 的色板输出。

### 1.4 Material Symbols 在 Figma 的正确用法

官方定义（snippet 原文）：

> "Material Symbols are our newest icons, consolidating over 2,500 glyphs in a single font file with a wide range of design variants. Symbols are available in three styles and four adjustable variable font axes (fill, weight, grade, and optical size)."

Figma 里两条路线：

| 路线 | 做法 | 优劣 |
|---|---|---|
| 字体（推荐） | 在 Figma 用文本节点输入 codepoint，字体设为 Material Symbols；用 `FILL`/`wght`/`GRAD`/`opsz` 表达变体 | 与 Flutter 侧"字体渲染图标"一致；缺点：Figma 里不是矢量形状，导出/切图受限 |
| 第三方插件插入矢量 | 装社区插件（如 Tomas Roggero 的 "Material Symbols"，**社区**） | 得到矢量节点，但插件非官方、图标集版本与 Flutter 侧可能漂移 |

图标库入口：https://fonts.google.com/icons 。Figma 文件里图标尺寸建议与 Flutter 侧一致（`kMinInteractiveDimension = 48.0` 来自 `app/lib/shared/ui/theme/`，即图标视觉 24 / 触达 48 的组合，见 §5）。

---

## 2. Figma 概念选型：Variables vs Styles，以及三层 token

### 2.1 分工边界（官方依据）

| 维度 | Variables | Styles |
|---|---|---|
| 类型 | Color / Number / String / Boolean / Timing（"There are six types of variables"）— https://help.figma.com/hc/en-us/articles/14506821864087-Create-and-use-variables | Paints / Text / Effects / Layout guides — https://help.figma.com/hc/en-us/articles/360039238753-Styles-in-Figma |
| 适合 | 需要按 mode（Light/Dark）切换的值、需要 alias 分层、需要绑定到任意属性（width/padding/radius/gap） | 复合排版（字体族+字号+行高+字距一次性套用）、阴影/模糊组合、栅格 |
| 不适合 | 复合排版（无字体样式变量，见 2.3） | 需要"换 mode 自动换值"的场景（styles 没有 mode） |
| 容量 | 每 collection 上限 5,000 个变量（https://help.figma.com/hc/en-us/articles/15145852043927-Create-and-manage-variables） | 未查到上限（**未核实**） |

结论：**颜色 + 数值走 Variables，排版的复合部分走 Text Styles，阴影走 Effect Styles，栅格走 Grid Styles**。两者可以叠加（text style 的 fontSize/lineHeight 字段可各自绑变量，见 2.3）。

### 2.2 三层 token 在 Figma 的落地建议

| 层 | Figma 表达 | 命名 | mode |
|---|---|---|---|
| ref（原始值） | 独立 collection `ref` | `ref/palette/primary-40`、`ref/space/4`、`ref/radius/12` | 单 mode（不参与主题） |
| sys（语义） | collection `sys`，值为 **alias** 到 ref | `sys/color/primary`、`sys/space/gutter`、`sys/shape/corner` | `Light` / `Dark` 两个 mode |
| comp（组件级） | collection `comp`，值为 alias 到 sys | `comp/button/container/enabled`、`comp/list/item/height` | `Light` / `Dark` |

要点：

- **命名用斜杠分组**（Figma 变量面板按 `/` 折叠），**不要把 mode 名写进变量名**；mode 名只做上下文。
- **light/dark 用 modes，不要两个 collection**：官方变量模型的定位就是"value can change depending on the context … such as light and dark modes"（help 14506821864087）；两个 collection 会让 alias 与组件绑定翻倍，且不能在同一个组件实例上切换。
- **但要注意 plan 限制**：`addMode` 的报错原文是 `addMode: Limited to N modes only`（https://developers.figma.com/docs/plugins/api/VariableCollection）；help 的计划表写成 "Up to 10 modes per collection | Up to 20 modes per collection | Unlimited modes with extended collections"（https://help.figma.com/hc/articles/360040328273-Figma-plans-and-features），而 figma 官方 `mcp-server-guide` 的 variable-patterns 又写 "Free = 1 mode / Professional up to 4 / Organization+ 40+"。**三者冲突，标未核实**。实践含义：如果当前套餐只允许 1 个 mode，退路是 `sys-light` / `sys-dark` 两个 collection（此时 alias 要写两份），设计稿阶段仍只画一个模式，Dark 只保颜色。
- **alias 在插件 API 里是一个值对象**（`VARIABLE_ALIAS` 形状，figwright 的 `set_variable_value` 文档明确接受 alias）；`plugin-typings` 中 `VariableAlias` 的精确字段 **未核实**，写脚本前先在 Figma 里手工建一个 alias 再读回确认。

### 2.3 变量类型限制（必须接受的硬约束）

| 限制 | 原文/依据 | 应对 |
|---|---|---|
| 没有"字体样式"复合变量 | help 六类型表里只有 Color/Number/String/Boolean/Timing（14506821864087）；figma 官方 reference 亦写 "You cannot put typography into a single variable — there is no composite variable type" | 排版用 **Text Style**；字阶的单个数字可以用 Number 变量绑到 text style 的 fontSize/lineHeight |
| 颜色变量只绑 **SOLID** paint | 官方 reference："Only SOLID paints support color variable binding — gradients/images will throw" | 渐变/图片填充保留硬编码值，或在设计稿里禁止使用 |
| Text Style 不能带对齐 | 官方旧页原文 "Because text styles can't be created for text alignment, you must set alignment for each block individually." | 对齐在组件内用 auto-layout 表达，不进样式 |
| 组件级 token 不是一等公民 | 变量模型没有"component scope"，只有 collection 分组 | 见 2.4 |

### 2.4 组件级 token 怎么在 Figma 里近似

Variables 没有 component 作用域，可用的近似有两条（**建议，非官方**）：

1. **collection 分组法（推荐）**：新建 `comp` collection，按组件前缀分组（`comp/button/*`）。视觉上等价于 component token，语义上靠命名约定；缺点是 Figma 不会在组件面板里分组显示。
2. **直接绑 sys**：中小项目只做 ref/sys 两层，组件层不落变量，靠"组件变体 + sys 变量"表达。仓库现状（`HentaiColorScheme` 56 个字段、`AppTextTokens` 仅 7 个字号）更接近这一层，见 §5。

**取舍建议**：本项目做 **ref + sys 两层 + comp 命名空间（只对 Button/ListItem/TextField 三个高频组件开）**。全量 comp 层的维护成本高于收益。

---

## 3. Figma 文件结构、命名与桌面尺寸

### 3.1 Pages

| Page | 内容 | 谁维护 |
|---|---|---|
| `Cover` | 版本、变更记录、指向 03/04 文档的链接、kit 与 Expressive 排除声明 | 人工 |
| `Tokens` | 变量表可视化（ref/sys/comp 三层各一块），色板、间距、圆角、字阶 | 脚本生成 + 人工检查 |
| `Foundations` | 颜色语义示例、类型比例、elevation、图标尺寸 24/48、焦点环 | 人工 |
| `Components` | 组件集（Button、IconButton、TextField、ListItem、AppBar、NavigationRail、Dialog、Menu、Snackbar、Progress） | 脚本搭骨架 + 人工调 |
| `Patterns` | 组合模式：列表-详情、空状态、加载/错误、表单、设置页 | 人工 |
| `Screens` | 桌面端页面稿（首页优先），按 §3.4 尺寸放 | 人工（组件拼装可脚本） |
| `Archive` | 废弃稿、Expressive 参考截图（明确标注"不可用"） | 人工 |

**不要**把 Tokens 与 Components 放同一页：变量页会随组件增多而变慢，且组件页需要频繁发布。

### 3.2 命名规范

| 对象 | 规则 | 例 |
|---|---|---|
| 变量 collection | 小写单词：`ref` / `sys` / `comp` | — |
| 变量 | 斜杠分组、语义化、不含 mode | `sys/color/on-surface-variant` |
| Paint style | `sys/` 前缀 + 语义名 | `sys/surface-container-high` |
| Text style | `type/` + 角色 | `type/title-large` |
| Effect style | `elev/` + 等级 | `elev/level-2` |
| 组件 | PascalCase，与 Flutter widget 对齐 | `Button`、`NavigationRail` |
| 变体集 | 组件名 + `Set` 后缀可选；变体名用 `Property=Value` | `Button`，变体 `Style=Primary, Size=Medium` |
| Frame | `页面名 / 尺寸 / 主题` | `Home / 1440×900 / Light` |

依据：变体属性命名与"同一组件集内所有变体使用同一属性与取值"的要求见 https://help.figma.com/hc/en-us/articles/360056440594-Create-and-use-variants ；组件属性总览 https://help.figma.com/hc/en-us/articles/5579474826519 。

### 3.3 组件集与属性轴（Button 为例）

| 轴 | 类型 | 取值 | 说明 |
|---|---|---|---|
| `Style` | VARIANT | Filled / Tonal / Outlined / Text / Elevated | baseline 五种，与 `m3.material.io` 一致；**不含 Expressive 的 split/connected 形态** |
| `Size` | VARIANT | Small / Medium / Large（具体 px **未核实**，取自 m3 规格） | 桌面以 Medium 为默认 |
| `State` | VARIANT | Enabled / Hover / Pressed / Focus / Disabled | 桌面端 hover/focus 必须有，键盘可达性是桌面一等需求 |
| `Icon` | VARIANT 或 BOOLEAN | None / Leading / Trailing | 用 BOOLEAN 更省变体，但无法同时表达"有无图标"与"图标位置"；建议 **VARIANT**（2×3 组合可控） |
| `Label` | TEXT 属性 | 文本内容 | 用组件属性而非新建变体 |
| `Leading swap` | INSTANCE_SWAP | 图标实例 | 需要换不同图标时用 |

关键取舍（**建议，非官方**）：

- **状态用 variant，不用交互组件**。Figma 的交互式组件（prototype states / interactive components）适合演示，不适合做库：库需要被检索、被 swap、被批量改；variant 是唯一稳定可脚本化的表达（`combineAsVariants` 只吃 ComponentNode）。
- **变体组合必须穷举**。官方 reference 明写 "Every unique combination must exist as a child component — missing ones show as blank gaps in the variant picker"。5 Style × 3 Size × 5 State × 3 Icon = **225 个变体**，这是本方案的上限，超出就拆组件（例如 IconButton 独立）。
- BOOLEAN/TEXT/INSTANCE_SWAP 属性名在 API 里带 `#id` 后缀（`Label#2:0`），脚本里必须用带后缀的名字（https://developers.figma.com/docs/plugins/working-with-component-properties）。

### 3.4 桌面 frame 尺寸与断点对齐

官方 M3/Android window size classes（https://developer.android.com/develop/ui/views/layout/use-window-size-classes ，Compose 版同）：

| 类 | 宽度 | 本仓库 `app_layout_breakpoints.dart` |
|---|---|---|
| Compact | `width < 600dp` | `isCompact` = width < 600 |
| Medium | `600 ≤ width < 840` | 无独立档（被并入 medium） |
| Expanded | `840 ≤ width < 1200` | `isMedium` = 600 ≤ width < 1024（部分） |
| Large | `1200 ≤ width < 1600` | `isExpanded` = width ≥ 1024（含 Large） |
| Extra-large | `width ≥ 1600` | 同 `isExpanded` |

仓库只有三档（600 / 1024），把 M3 的 medium(600–839) 与 expanded(840–1199) 的前半段合并为 medium，把 large(1200+) 合并进 expanded。

**frame 建议（设计稿画这 4 张，不新增断点）**：

| Frame | 对应 | 用途 |
|---|---|---|
| 1440×900 | Large（1200–1599） | **主稿**。桌面笔记本主流分辨率，且落在本仓库 `isExpanded` |
| 1280×800 | Large 下沿 | 兼容检查（很多 Windows 笔记本的有效高度只有 720–800） |
| 1024×768 | Expanded 下沿（M3）/ 本仓库 medium 上沿 | **断点接缝检查**：1024 是本仓库切换到 expanded 的边界，必须单独验 |
| 600×800 | Compact 上沿（= 本仓库 compact/medium 边界） | 最小可用窗检查 |

**取舍建议**：

1. **以仓库三档为代码真值**，M3 的 5 档只作为"心理模型"，不引入代码。理由：`app_layout_breakpoints.dart` 已被 gate 与现有页面依赖，改档位是代码变更，不在本次设计稿范围。
2. 设计稿只需覆盖 **compact（600）/ medium（1024）/ expanded（1440）** 三个重排状态；**840 与 1200 作为内部检查点**（不单独出稿），用于发现"在 840 附近会不会挤"。
3. 1440 作为主稿的原因是它同时满足"够宽能看到 rail + 两栏"和"落在 expanded"，避免为 1600+ 出稿（桌面应用窗口很少那么宽）。

---

## 4. 程序化建库：Plugin API 能力与 figwright MCP 映射

### 4.1 Plugin API 能力对照表（方法名逐条核对官方文档）

| 能力 | 准确方法名 / 属性 | 出处 | 坑 |
|---|---|---|---|
| 建变量集合 | `figma.variables.createVariableCollection(name)` → `VariableCollection` | https://developers.figma.com/docs/plugins/api/figma-variables | 新建集合自带 1 个 `Mode 1`，先 `renameMode` |
| 建变量 | `figma.variables.createVariable(name, collection, resolvedType)` | 同上 | `resolvedType` 只能是 COLOR/FLOAT/STRING/BOOLEAN |
| 写值 | `variable.setValueForMode(modeId, value)` | https://developers.figma.com/docs/plugins/api/Variable | **不存在 `setVariableValue`**（figwright 的工具才叫 `set_variable_value`） |
| 加 mode | `collection.addMode(name)` → modeId | https://developers.figma.com/docs/plugins/api/VariableCollection | 受套餐限制时抛 `addMode: Limited to N modes only` |
| 重命名 mode | `collection.renameMode(modeId, newName)` | 同上 | — |
| 删 mode | `collection.removeMode(modeId)` | 同上 | — |
| 绑 paint | `figma.variables.setBoundVariableForPaint(paint, field, variable)` | https://developers.figma.com/docs/plugins/api/figma-variables | **返回新 paint，必须接住返回值**；只支持 SOLID；传 `null` 解绑 |
| 绑 effect | `setBoundVariableForEffect(effect, field, variable)` | 同上 | 同上 |
| 绑标量属性 | `node.setBoundVariable(field, variable)`（如 width/height/padding/radius） | 同上（SceneNode 混入） | 变量类型必须与字段类型匹配 |
| 建 paint style | `figma.createPaintStyle()` | developers.figma.com/docs/plugins/api 索引 | 建完要 `.paints = [...]` |
| 建 text style | `figma.createTextStyle()` | 同上 | 先 `await figma.loadFontAsync()`，否则抛异常 |
| 建 effect style | `figma.createEffectStyle()` | 同上 | 同上 |
| 建 grid style | `figma.createGridStyle()` | https://developers.figma.com/docs/plugins/api/GridStyle | — |
| 建组件 | `figma.createComponent()` | developers.figma.com/docs/plugins/api 索引 | 返回 ComponentNode |
| 合成变体集 | `figma.combineAsVariants(nodes, parent, index?)` → ComponentSetNode | https://developers.figma.com/docs/plugins/api/properties/figma-combineasvariants | **只接受 ComponentNode，Frame 会抛错**；"This API is only available in Figma Design"；不自动补缺失组合 |
| 建实例 | `component.createInstance()` | developers.figma.com/docs/plugins/api 索引 | — |
| 自动布局 | `frame.layoutMode = "HORIZONTAL" | "VERTICAL"`，`paddingLeft/itemSpacing/primaryAxisSizingMode` | 官方 reference（figma/mcp-server-guide component-patterns） | **没有 `setAutoLayout` 这个方法**；figwright 的 `set_auto_layout` 是 MCP 工具名 |
| 尺寸模式 | `node.layoutSizingHorizontal/Vertical = "HUG" | "FILL" | "FIXED"` | 同上 | HUG 需要 auto-layout 父级 |
| 组件属性 | `component.addComponentProperty(name, type, defaultValue)` | https://developers.figma.com/docs/plugins/working-with-component-properties | BOOLEAN/TEXT/INSTANCE_SWAP 名带 `#id`；VARIANT 只能加在 ComponentSetNode 上 |
| 设文本 | `await figma.loadFontAsync(font); text.characters = ...` | https://developers.figma.com/docs/plugins/working-with-text | 改 characters/fontSize/lineHeight 需加载该节点**已用的全部字体** |

### 4.2 插件 API 做不到的事

| 限制 | 依据 | 影响 |
|---|---|---|
| 没有复合排版变量 | help 14506821864087 六类型；figma reference "there is no composite variable type" | 字阶只能落 Text Style |
| 颜色变量只能绑 SOLID | figma reference | 渐变/图片填充无法 token 化 |
| 不能在低套餐上建多 mode | `addMode` 抛错原文 | 可能被迫用两个 collection |
| `combineAsVariants` 不补缺失组合 | figma reference | 225 变体必须逐个建，脚本量线性 |
| 文本样式不含对齐 | help 旧页原文 | 对齐只能靠 auto-layout |
| 批量变量写入走 REST 需企业版 | https://developers.figma.com/docs/rest-api/variables-endpoints （"available to full members of Enterprise orgs"） | 本项目只能用插件 API |
| 发布到 team library / 导入 community 文件 | 未找到 API 文档（**未核实**） | 人工点 UI |
| 原型 reactions 的 API 细节 | 具体方法名 **未核实** | 本文不建议用交互组件表达状态 |

### 4.3 figwright MCP 映射清单（按执行顺序）

前置事实：本次 `mcp__figwright__ping` 返回 `sessions.connectedCount = 0`、`plugin = null`、`server.version = "0.6.0"`、`role = "leader"`，即**当前没有任何 Figma 文件连着插件**。脚本化路线必须先在 Figma 里打开 Figwright 插件。

| # | 工具 | 作用 | 坑 |
|---|---|---|---|
| 0 | `ping` / `list_files` / `use_file` | 确认连接、锁定目标文件 | 多个文件同时打开时必须 `use_file` 认领，否则会写到前台那个文件 |
| 1 | `get_variable_defs` / `get_styles` | 先读现状，避免重复建 | 新文件返回空是正常的 |
| 2 | `create_variable_collection` | 建 `ref`/`sys`/`comp` | 自带默认 mode，返回 `defaultModeId` |
| 3 | `add_variable_mode` | `sys`/`comp` 加 `Dark` | 套餐受限会失败，退两个 collection |
| 4 | `create_variable` | 建三层变量 | 类型只能是 COLOR/FLOAT/STRING/BOOLEAN |
| 5 | `set_variable_value` | 按 mode 写值；alias 亦走这里 | **必须先建变量再写值**；alias 形状先在 UI 里建一个读回确认 |
| 6 | `create_paint_style` / `create_text_style` / `create_effect_style` | 语义样式 | 文本样式工具内部会加载字体，但 family 不存在仍会失败（`MI_Sans_Regular` 在 Figma 的可用性 **未核实**，回退 Inter） |
| 7 | `bind_variable_to_paint` / `bind_variable_to_node` | 把变量绑到样式与节点 | paint 只支持 SOLID；标量字段名要准（`cornerRadius` 可一次绑四角） |
| 8 | `create_component` | 建每个变体为一个组件 | 先建**所有**变体组件，再合成变体集 |
| 9 | `combine_as_variants` | 合成 ComponentSet | 需要 ≥2 个 ComponentNode；变体名用 `Style=Filled` 形式 |
| 10 | `create_instance` | 在页面里用组件 | 实例不能改结构，只能改属性/文本 |
| 11 | `set_auto_layout` → `set_layout_props` | 先布局再尺寸 | 顺序反了会得到 FIXED 尺寸的僵死 frame |
| 12 | `create_frame` / `create_text` | 搭 Screens | frame 尺寸用 §3.4 的 4 档 |
| 13 | `get_screenshot` / `get_design_context` | 自检与回读 | 自检**必须**做，脚本建的东西肉眼错位很常见 |

**三条硬顺序**：先建变量 → 再建样式并绑定 → 再建组件并实例化。反过来改造成本极高（变量改名会断开绑定）。

---

## 5. 设计稿 → 代码交接

### 5.1 命名映射到 Flutter

代码侧现状（`docs/adr/0028-design-system-theme-extensions.md`）：`buildAppTheme`（`app/lib/shared/ui/theme/theme.dart:38-87`）是唯一装配入口；`theme_tailor` 生成四个 ThemeExtension（`AppThemeTokens`/`HentaiColorScheme`/`AppShadowTokens`/`AppMotionTokens`），生成物 `*.tailor.dart` 提交仓库并由 gate-codegen-drift 校验；颜色是两层（`ColorScheme` + `HentaiColorScheme` 挂 `ThemeData.extensions`）。

| Figma | Flutter 目标 | 备注 |
|---|---|---|
| `ref/*` | 不落到代码 | 只作生成 source，代码里不引用原始色阶 |
| `sys/color/primary` 等 | `ColorScheme.primary` 等 | M3 角色名与 Flutter `ColorScheme` 字段名基本一一对应 |
| `sys/color/*` 中 `ColorScheme` 没有的角色（如 `surface-container-*` 的细粒度） | `HentaiColorScheme`（56 个字段） | 这是仓库既有的扩展通道 |
| `sys/color/*` mode Light/Dark | `buildAppTheme` 的两个 `ThemeData` | 代码里手工枚举，不用 `fromSeed`（见 03） |
| `type/*` Text Style | `AppTextTokens`（现仅 7 个字号，无字重/行高/字距） | **缺口**：设计稿若引入字重/行高，代码侧要先扩 token |
| `sys/space/*` | `AppSpacingTokens` / `AppLayoutTokens` | — |
| `sys/shape/corner` | `AppRadiusTokens` | — |
| `elev/*` Effect Style | `AppShadowTokens` | — |
| motion 参数 | `AppMotionTokens` | Figma 侧无对应变量类型，人工抄 |
| 断点 | `app_layout_breakpoints.dart`（600/1024） | **设计稿不要发明新断点** |

**ADR-0028 的硬约束**（`:9`）："不引入整包 M3 UI Kit，也不在阶段一抽取独立 `packages/design_system`"。所以 Figma kit 只作参考，**不得**把 kit 的组件命名/结构直接搬到代码，也不引入 `flutter` 侧第三方 M3 组件包。

### 5.2 Handoff 检查清单

| 项 | 判据 | 来源 |
|---|---|---|
| 文本对比度 | 正文 ≥ 4.5:1，大字号 ≥ 3:1（WCAG AA） | https://www.w3.org/WAI/WCAG22/Understanding/143.html |
| 触达尺寸 | 可交互元素触达区 ≥ 48×48；图标视觉 24 而触达 48 | https://developer.android.com/guide/topics/ui/accessibility/views/apps-views ；https://support.google.com/accessibility/android/answer/7101858 |
| 状态完整 | 每个组件集覆盖 Enabled/Hover/Pressed/Focus/Disabled；桌面必须有 focus 环 | 建议（非官方） |
| 断点重排 | 600 / 1024 / 1440 三档都出图，1024 接缝单独验 | 仓库断点 + M3 size classes |
| 图标 | 只用 Material Symbols；不混用 kit 里的 Expressive 形状图标 | 见 1.4 |
| 颜色 | 页面上不允许出现未绑定变量的硬编码颜色（Figma 里可用变量面板筛） | 建议（非官方） |
| Dark 平价 | Light 稿完成后切 Dark mode 自检一遍 | 见 2.2 |
| 无 Expressive 残留 | 组件集里没有 Button group / FAB menu / Split button / Loading indicator | 见 1.3 |
| 文本缩放 | 字号 +2 后不裁切 | 建议（非官方） |
| 交付物 | Tokens 页截图 + 变量清单 + 组件清单 + 页面稿 | — |

---

## 6. 从空文件到"第一张首页稿"的最短路线

| 步 | 动作 | 人工/脚本 | 产出 | 校验 |
|---|---|---|---|---|
| 1 | 新建 Figma 文件；装并运行 **Material Theme Builder**，选源色，生成 Light/Dark 主题 | **人工**（插件 UI） | 色板页 + color roles | 与仓库现有主色是否可接受（色值由 MTB 决定，**未核实**与仓库现值一致） |
| 2 | 打开 Figwright 插件（`ping` 确认 `connectedCount ≥ 1`） | **人工** | 连接 | `list_files` 能列出文件 |
| 3 | 建 `ref`/`sys`/`comp` collection、加 Dark mode、灌变量（从 MTB 输出抄值） | 脚本 | 三层变量 | `get_variable_defs` 回读 |
| 4 | 建 paint styles（sys 语义色）+ text styles（`type/*`）+ effect styles（`elev/*`） | 脚本 | 样式库 | `get_styles` 回读；字体不可用则回退 Inter |
| 5 | 建基础组件（Button/IconButton/TextField/ListItem/AppBar/NavigationRail）每个变体一个 ComponentNode，再 `combine_as_variants` | 脚本搭骨架 | 组件集 | `get_screenshot` 自检 |
| 6 | 补全状态与图标轴、修正命名、设 TEXT/BOOLEAN/INSTANCE_SWAP 属性 | **人工** | 可用组件集 | 变体选择器无空档 |
| 7 | 建 4 张 frame（1440×900 / 1280×800 / 1024×768 / 600×800），先用实例摆首页骨架 | 脚本 | 页面骨架 | 三档重排能跑通 |
| 8 | 内容、图像、留白打磨；Dark 切一遍 | **人工** | 首页稿 v1 | §5.2 清单 |
| 9 | 导出变量/样式清单 → 映射表（§5.1）→ 交回代码侧 | 脚本可导出，映射 **人工** | handoff 包 | 与 ADR-0028 的四层 token 对齐 |

**最短路径**：1 → 2 → 3 → 4 → 5 → 7 可以一天内跑完骨架；6 与 8 是不可压缩的人工时间。

**必须人工**：MTB 插件交互、Figma 插件启用、变体矩阵的视觉判断、内容排版、Dark 自检、发布 library。
**可脚本**：变量/样式批量创建与绑定、变体组件批量创建与合成、frame 与实例摆放、截图自检、清单导出。

---

## 7. 未核实清单

1. **kit 旧版本（纯 baseline 快照）是否仍可获取** —— 未核实。
2. **Material 3 Design Kit 的发布者字段**（snippet 里与第三方 scraper 记录冲突）—— 未核实。
3. **是否存在 Google 官方的通用（非 Wear/Android 手机）Material 3 Expressive Design Kit** —— 未核实，疑似不存在。
4. **"Google Icons Library" 的具体 URL 与官方性** —— 未核实。
5. **Figma 变量 mode 数量的套餐限额**：help 计划表（10/20/unlimited）、`addMode` 报错文案、figma reference（1/4/40+）三方冲突 —— 未核实哪个对当前套餐成立。
6. **`plugin-typings` 中 `VariableAlias` 的精确字段** —— 未核实（先人工建 alias 读回）。
7. **插件 API 是否能发布到 team library / 导入 community 文件** —— 未核实（未找到对应 API 文档）。
8. **原型 reactions 的 API 方法名** —— 未核实。
9. **`MI_Sans_Regular` 在 Figma 中是否可用** —— 未核实（不可用则回退 Inter，会影响 text style 的字体族）。
10. **M3 各组件具体尺寸/字号/色值** —— 因 m3.material.io 抓不到正文，本文**未给任何数值**；需人工读规格或从 kit 里量。
11. **Flutter 侧哪些 Expressive 组件会在未来版本落地** —— 未核实（依据 #168813 仍是 Open）。
12. **Material 3 Design Kit 的描述/版本记录** —— 仅 snippet 级证据，正文细节未核实。

---

## 8. 参考来源（按出现顺序）

- Figma — Material 3 Design Kit：https://www.figma.com/community/file/1035203688168086460
- Figma — Material Theme Builder 插件：https://www.figma.com/community/plugin/1034969338659738588
- GitHub — material-foundation/material-theme-builder：https://github.com/material-foundation/material-theme-builder
- Google Fonts — Material Symbols：https://developers.google.com/fonts/docs/material_symbols
- Android — Wear 设计 kits：https://developer.android.com/design/ui/wear/guides/get-started/design-kits
- Android — Android UI Kit：https://www.figma.com/community/file/1237551184114564748
- Figma — 变量总览：https://help.figma.com/hc/en-us/articles/14506821864087-Create-and-use-variables
- Figma — 创建管理变量：https://help.figma.com/hc/en-us/articles/15145852043927-Create-and-manage-variables
- Figma — Figma plans and features：https://help.figma.com/hc/articles/360040328273-Figma-plans-and-features
- Figma — Styles：https://help.figma.com/hc/en-us/articles/360039238753-Styles-in-Figma
- Figma — Create and use variants：https://help.figma.com/hc/en-us/articles/360056440594-Create-and-use-variants
- Figma — Component properties：https://help.figma.com/hc/en-us/articles/5579474826519
- Figma Plugin API — VariableCollection：https://developers.figma.com/docs/plugins/api/VariableCollection
- Figma Plugin API — Variable：https://developers.figma.com/docs/plugins/api/Variable
- Figma Plugin API — figma.variables：https://developers.figma.com/docs/plugins/api/figma-variables
- Figma Plugin API — combineAsVariants：https://developers.figma.com/docs/plugins/api/properties/figma-combineasvariants
- Figma Plugin API — GridStyle：https://developers.figma.com/docs/plugins/api/GridStyle
- Figma — Working with component properties：https://developers.figma.com/docs/plugins/working-with-component-properties
- Figma — Working with text：https://developers.figma.com/docs/plugins/working-with-text
- Figma — REST Variables endpoints：https://developers.figma.com/docs/rest-api/variables-endpoints
- Figma 官方参考仓库 figma/mcp-server-guide（variable-patterns / component-patterns / wwds-text-styles）：https://github.com/figma/mcp-server-guide
- Android — Use window size classes：https://developer.android.com/develop/ui/views/layout/use-window-size-classes
- Android — Accessibility（触达尺寸）：https://developer.android.com/guide/topics/ui/accessibility/views/apps-views
- Android 帮助 — 触达 48dp：https://support.google.com/accessibility/android/answer/7101858
- W3C — WCAG 1.4.3 Contrast：https://www.w3.org/WAI/WCAG22/Understanding/143.html
- 本仓库 — `docs/adr/0028-design-system-theme-extensions.md`
- 本仓库 — `app/lib/shared/ui/layout/app_layout_breakpoints.dart`
- 本仓库 — `design-system/research/material-design-3/03-flutter-implementation.md`
