# Fluent 2 设计语言 × Flutter 可行性调研

**Wayfinder:** [#320 调研 Fluent 2 官方 foundations 语义](https://github.com/Zoti321/hentail_library/issues/320)  
**地图:** [#319 Fluent 2 设计系统文档与分阶段 UI 改造路线](https://github.com/Zoti321/hentail_library/issues/319)  
**状态:** Research 备忘（非规范真源；P0 `foundations/` 落盘时吸收结论）  
**技术栈:** Flutter 单壳响应式 · `buildAppTheme` · `ThemeExtension`（ADR-0028）

## 1. 官方设计语言维度（不仅 color / shadow / shape / type / spacing）

Fluent 2 站点与「Design language」Figma 层按**多专题**组织。下列为路线图应覆盖的**完整清单**（含你未单列的维度）。

| 维度 | 官方入口 | 要点摘要 |
|------|----------|----------|
| **Design tokens** | [Design tokens](https://fluent2.microsoft.design/design-tokens) | 两层：global（原始值）+ alias（语义）；支撑 light/dark/品牌/对比度 |
| **Color** | [Color](https://fluent2.microsoft.design/color) | Neutral / Shared / Brand；语义色；交互态（hover/pressed/selected）；**Windows 交互态颜色方向与 Web 相反**；focus 用描边而非改填充色 |
| **Typography** | [Typography](https://fluent2.microsoft.design/typography) | 分 **Web / Windows / macOS / iOS / Android** 多套 type ramp；Segoe 为签名字体，但强调**各平台用系统原生字体** |
| **Layout** | [Layout](https://fluent2.microsoft.design/layout) | 4px spacing ramp（含 2/6/10 等非 4 倍数）；邻近律；12 列网格；断点 size class（320–1920+）；reposition/resize/reflow/show-hide/re-architect |
| **Elevation** | [Elevation](https://fluent2.microsoft.design/elevation) | z 轴层次；key + ambient 阴影方程；shadow 2/4/8/16/28/64 阶梯；彩色表面 **luminosity 方程**调 opacity；**Windows 用 stroke 替代 key shadow** |
| **Shape** | Design language Figma / Core kits | 与 spacing 并列：**corner radius、stroke width、size** tokens（见 [Get started – Design](https://fluent2.microsoft.design/get-started/design)） |
| **Material** | [Material](https://fluent2.microsoft.design/material) | **Solid / Acrylic / Mica / Smoke**；Mica 与桌面壁纸/窗口激活态绑定（Windows） |
| **Motion** | [Motion](https://fluent2.microsoft.design/motion) | 原则（Functional/Natural/Consistent/Appealing）；duration + easing；Enter/Exit、Elevation、Top-level fade、Container transform；stagger & hierarchy；**减少动效 / WCAG** |
| **Iconography** | [Iconography](https://fluent2.microsoft.design/iconography) | System（Regular/Filled）、Product、File；MIT system icons；尺寸与触控目标 |
| **Accessibility** | [Accessibility](https://fluent2.microsoft.design/accessibility) | 结构/标题；键盘与焦点；对比度；缩放到 400%/320px；替代文本；与组件 WCAG 2.1 AA 对齐 |
| **Components** | [fluent2.microsoft.design](https://fluent2.microsoft.design/) | 分 **Web / iOS / Android / Windows** 实现库；Figma Core 与代码对齐 |
| **Content** | 各组件 Usage + Content 指引 | 句式、大小写、语气（规范文档可链 Learn，不复制全文） |

**平台事实（影响可行性）：** Microsoft **没有**与 Fluent 2 Web/React 同等的**官方 Flutter UI 库**。Flutter 实现 = 自研 `shared/ui` + 主题 token，用 Fluent **原则与 token 角色**对齐，而非逐组件移植 `fluentui-react`。

---

## 2. 与本仓库 Flutter 实现的映射（现状）

| Fluent 维度 | 本仓库访问面 | 对齐程度 |
|-------------|--------------|----------|
| Color alias | `colorScheme` + `context.hentai` | 已有语义层；未完整覆盖 Fluent global/alias 命名 |
| Typography ramp | `context.tokens.text.*` + `MI_Sans_Regular` | **自定义阶梯**（12–22px），非 Segoe 全表；符合「产品字体」但非 Fluent 默认 ramp |
| Spacing | `context.tokens.spacing`（4–20） | **子集**；Fluent 有至 56+ 的 size 令牌 |
| Radius / shape | `context.tokens.radius` | 子集（xs–pill） |
| Elevation | `context.shadows` + 1px `borderSubtle` | 已走 **边框 + 软阴影**（贴近 Windows stroke 方向） |
| Material | `ReaderFloatingPanel`：`BackdropFilter` + 半透明色 | **Acrylic 近似**；全局 shell 多为 solid |
| Motion | `context.motion` + `DesktopFadeThroughPageTransitionsBuilder` | Top-level **fade-through** 与 Fluent「大面用 quick fade」一致；时长族 180–220ms |
| Interaction | `NoSplash`、Ghost hover | 符合 MASTER「桌面无 ripple」；**非** Fluent Web 默认填充变深交互 |
| Icons | Lucide | **刻意偏离** Fluent System Icons（MASTER Anti-Pattern 禁止 Material Icons） |
| Layout / 断点 | `AppLayoutBreakpoints` 600/1024 | 与 Fluent size class **数值不同**；单壳逻辑等价 |
| A11y | Semantics、对比度清单（MASTER） | 部分；无独立 high-contrast theme |

---

## 3. Flutter 可行性总表（RAG）

图例：**绿** 可稳定跨平台实现 · **黄** 可近似/有性能或平台差异 · **红** 不宜作为跨平台硬需求

| Fluent 2 能力 | Flutter 可行性 | 说明与建议 |
|---------------|----------------|------------|
| Solid surfaces + 语义色 token | **绿** | `ColorScheme` + `HentaiColorScheme`；文档写角色不写 hex |
| 1px stroke 分层（Windows elevation） | **绿** | `Border.all(hentai.borderSubtle)`；已是指定方向 |
| 多层 BoxShadow（key+ambient） | **绿** | `AppShadowTokens.elevatedSurface` / 扩展 preset；可对齐 shadow 2/8/28 |
| 品牌色表面阴影 luminosity 方程 | **黄** | 纯 Dart 可实现；需 P2 明确是否纳入 shadow token 生成 |
| Acrylic（毛玻璃菜单/浮层） | **黄** | `BackdropFilter` + 半透明 `Container`（已在 reader）；**GPU 成本**，移动端慎用大面积；Impeller 上需实测 |
| Smoke（模态遮罩） | **绿** | `hentai.overlayScrim` / `ModalBarrier` |
| Mica（壁纸 tint + 非激活中性色） | **红→黄** | **真 Mica 仅 Windows DWM**；跨平台用 `winBackground`/`sidebarBackground` **静态近似**；可选 `bitsdojo_window`/`flutter_acrylic` 仅桌面增强，**不要**作为 Gate 依赖 |
| Fluent 全量 spacing ramp（至 size560） | **绿** | 扩展 `AppSpacingTokens` 或文档映射表；非必须一次加全 |
| 12 列响应式网格 | **绿** | `LayoutBuilder` + `SliverGrid`；与 Fluent 断点可对表写进 `spacing-layout.md` |
| Fluent 断点（479/639/1023…） | **黄** | 可文档对齐或保持 600/1024 产品断点并说明差异 |
| Segoe UI Variable 全平台 | **黄** | Windows 可 bundling；macOS/iOS/Android 更宜 **系统字体**（Fluent 官方亦推荐 native）— 与现有 MI Sans 策略需 **grilling 决策** |
| Fluent type ramp（Caption2–Display） | **绿** | `TextTheme` / `AppTextTokens` 扩展；行高需显式 `TextStyle.height` |
| Motion：ease-out、短时长 | **绿** | 已有 `AppMotionTokens` |
| Enter/exit、stagger 列表 | **黄** | `AnimationController` / `flutter_animate`；注意 `MediaQuery.disableAnimations` |
| Container transform（共享元素） | **黄** | `Hero` / 自定义 `PageRoute`；成本高，按路由选用 |
| Focus 环（加粗 stroke、不改填充） | **黄** | `Focus` + `decorator` / 自定义 `OutlinedBorder`；需统一 widget 缝 |
| Windows 反向 hover（变亮） | **黄** | 与当前 Ghost「变深填充」不同；若采纳需改 `GhostButton` 语义 |
| Fluent System Icons | **黄** | 可用 `fluentui_system_icons` 等社区包，但与 **Lucide** 战略冲突—需产品决策 |
| High contrast theme | **黄** | Flutter `ThemeData` 无 Fluent 级 HC token 开箱；可后续 `Brightness`+扩展或平台 `MediaQuery.highContrast` |
| 组件库 1:1（Web Fluent UI） | **红** | 不现实亦无官方 Flutter；继续 **自有 widgets** + Fluent 模式描述 |
| Copilot / Labs UI kits | **红** | 与漫画库产品无关；**Out of scope** |

---

## 4. 结论：推荐的「Fluent 现代化」实现策略（供后续决策 ticket）

1. **文档层（P0）**  
   `foundations/` 应按 **上表 12+ 维度** 分文件或索引，不仅 5 个 token 专题；另增 **`research/fluent2-flutter-feasibility.md`（本文）的摘要节** 或 `foundations/platform-feasibility.md` 链到本文。

2. **视觉 fidelity 分层（建议在 map 新开 grilling）**  
   - **Tier A（必须）:** solid 色、stroke、shadow preset、spacing/radius/type、motion 基线、a11y 对比度、无 ripple、Toast 模式。  
   - **Tier B（选择性）:** acrylic 浮层、fade-through 路由、stagger 微动效、focus ring。  
   - **Tier C（仅桌面可选 / 不承诺）:** Mica、壁纸采样、Windows 专属 hover 极性。  
   - **Explicit non-goals:** Fluent React 组件 parity、Copilot UI、Material Icons、mobile 分树。

3. **技术风险**  
   - `BackdropFilter` 全屏或列表大量实例 → 帧率与电量。  
   - 阴影与描边叠加强调 **MASTER**「卡片仅阴影变化、无 scale」。  
   - Token 大改须与 `hentai_color_scheme_tokens_test` 同 PR（ADR-0028）。

4. **依赖 #321 / #324**  
   文档树与 P0 大纲应预留 **`platform-feasibility` 或 `foundations/README` 的 RAG 表**，避免 Agent 实现不可跨平台的 Mica/全量 Segoe。

---

## 5. 参考链接（一级来源）

- Fluent 2 首页: https://fluent2.microsoft.design/  
- Design tokens: https://fluent2.microsoft.design/design-tokens  
- Color / Typography / Layout / Elevation / Material / Motion / Iconography / Accessibility: 同上路径段  
- Windows 应用设计（壳层、Mica 等深入）: https://learn.microsoft.com/en-us/windows/apps/design/  
- 本仓库: `design-system/hentai-library/MASTER.md`, ADR-0028, `app/lib/shared/ui/theme/`

---

*备忘路径：`design-system/hentai-library/research/`（在 **`dev`** 维护；规范落盘见 wayfinder [#319](https://github.com/Zoti321/hentail_library/issues/319)）。*
