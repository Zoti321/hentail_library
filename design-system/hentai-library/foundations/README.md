# Foundations（P0 原型大纲）

> **状态：** Wayfinder [#324 原型 P0 foundations 专题大纲](https://github.com/Zoti321/hentail_library/issues/324) 产出；**非最终规范正文**。落盘与 MASTER 索引更新由 `/to-spec` + `ready-for-agent` 驱动。  
> **真源：** 语义与用法 → 本目录；数值 → `app/lib/shared/ui/theme/`；调研备忘 → [research/fluent2-flutter-feasibility.md](../research/fluent2-flutter-feasibility.md)。

## Agent 阅读顺序

1. 目标路由 `pages/<page>.md`（若有）
2. [MASTER.md](../MASTER.md)（速查、Anti-Patterns）
3. 本目录与任务相关的专题（下表）
4. 代码 `buildAppTheme` / `ThemeExtension`

| 任务类型 | 先读 |
|----------|------|
| 改色 / 表面 / 边框 | [color.md](./color.md) |
| 卡片 / 对话框 / 浮层阴影 | [elevation-shadow.md](./elevation-shadow.md) |
| 圆角 / 描边宽度 | [shape.md](./shape.md) |
| 字号 / 字重 / 行高 | [typography.md](./typography.md) |
| 间距 / 网格 / 断点 | [spacing-layout.md](./spacing-layout.md) |
| 动效 / 路由过渡 | [motion.md](./motion.md) |
| 对比度 / 焦点 / 减动效 | [accessibility.md](./accessibility.md) |
| 图标（Lucide） | [iconography.md](./iconography.md) |

## 采纳分层（Tier A/B/C）

决策：[#327 决策 Fluent 维度采纳分层](https://github.com/Zoti321/hentail_library/issues/327)。

| Tier | 含义 |
|------|------|
| **A** | 跨平台必须：solid 色与 stroke/shadow/token 基线、MI Sans、Lucide、无 ripple、Toast、a11y 对比度；断点 600/1024 |
| **B** | 可选：局部 Acrylic、路由 fade-through、focus ring、stagger、扩展 spacing/shadow 方程 |
| **C** | 不承诺：真 Mica、Windows 变亮 hover、Fluent 组件库 parity、Copilot、Material Icons、mobile 分树、全套 HC 主题 |

**Material：** Solid/Smoke → A；Acrylic → B；Mica → C。

P0 角色表请填写 **Tier** 列（A/B/C）。

## 共用：明暗对照表模板

P0 各专题的「角色表」统一列（**禁止在 Widget 中写裸 hex**；明暗列写语义与用法，具体色值指向代码测试/Widgetbook）：

| 文档角色名 | Fluent 2 概念（简述） | Light 用法 | Dark 用法 | Flutter 访问 |
|------------|----------------------|------------|-----------|--------------|
| _例：内容表面_ | Surface | 主内容区背景 | 同上 | `colorScheme.surface` |
| _例：细边框_ | Stroke subtle | 1px 分隔 | 同上 | `context.hentai.borderSubtle` |

可选附加列（按需）：**Tier**（A/B/C，见上节）、**Anti-Pattern**、**典型 Widget**。

## 共用：单文件章节骨架

每篇 `foundations/*.md` P0 正文应包含：

1. **Fluent 对齐意图**（1 段 + 官方链接到 [references.md](../references.md)）
2. **角色对照表（明暗）**（上表头）
3. **Do** / **Don't**（链 MASTER Anti-Patterns）
4. **与代码同步**（哪些 `ThemeExtension` 字段；P2 变更时同 PR 纪律）
5. **页面例外**（仅指向 `pages/*`，不重复整页）

---

## color.md 大纲

| 章节 | 内容 |
|------|------|
| Fluent 对齐意图 | Neutral / Shared / Brand；语义色；交互态；**Windows 与 Web 交互色方向差异**（文档说明产品取 Web+桌面 stroke 混合策略） |
| 角色对照表 | `primary`、`surface`、`winBackground`、`sidebarBackground`、`textPrimary`…`textTertiary`、`borderSubtle`…`borderStrong`、`destructive`、`success`/`warning`/`error`、reader/contextMenu 族 |
| M3 与 Hentai 分工 | 何时 `colorScheme.*` vs `context.hentai.*` |
| Don't | 裸 hex；非破坏性用 `error`；`colorScheme.hentai` 已废弃 |

**Flutter 索引：** `app_color_scheme.dart`、`hentai_color_scheme.dart`。

---

## elevation-shadow.md 大纲

| 章节 | 内容 |
|------|------|
| Fluent 对齐意图 | z 轴；key+ambient；**Windows 偏 stroke**；shadow 2/8/28 阶梯概念 |
| 预设角色表 | `catalogCardRest/Hover`、`dialog*`、`toast*`、`contextMenu`；`elevatedSurface()` |
| 与描边组合 | 目录卡 1px `borderSubtle` + 阴影变化、无 hover scale |
| Tier B/C | 品牌色 luminosity 方程、Mica（不承诺）→ 链 research |

**Flutter 索引：** `app_shadow_tokens.dart`、`app_shadow_palette.dart`。

---

## shape.md 大纲

| 章节 | 内容 |
|------|------|
| Fluent 对齐意图 | corner radius、stroke width（Figma design language） |
| 半径角色表 | `radius.xs`…`pill` + 典型组件（按钮 `md`、封面卡 `xs`、MetaChip 8px 等） |
| 描边 | 1px 标准；focus 加粗（链 accessibility） |

**Flutter 索引：** `app_radius_tokens.dart`。

---

## typography.md 大纲

| 章节 | 内容 |
|------|------|
| Fluent 对齐意图 | 多平台 type ramp；产品 **MI Sans** vs Fluent Segoe/native 策略（待 #327） |
| 字阶角色表 | `labelXs`、`bodySm/Md/Lg`、`titleSm/Md/Lg` + 建议字重 |
| 行高 | P0 表增加「建议 line-height」列；reader 等宽 `RobotoMono` |
| Don't | 组件内任意 `fontSize` |

**Flutter 索引：** `app_text_tokens.dart`、`buildAppTheme` `fontFamily`。

---

## spacing-layout.md 大纲

| 章节 | 内容 |
|------|------|
| Fluent 对齐意图 | 4px ramp；邻近律；12 列网格概念 |
| 间距角色表 | `spacing.xs`…`xl`；`layout.contentAreaPadding` |
| 断点对照 | `AppLayoutBreakpoints`（600/1024）vs Fluent size class（文档对照，不强制改代码） |
| 触控目标 | 44/48 与 compact 安全区 |

**Flutter 索引：** `app_spacing_tokens.dart`、`app_layout_tokens.dart`、`app_layout_breakpoints.dart`。

---

## motion.md 大纲

| 章节 | 内容 |
|------|------|
| Fluent 对齐意图 | 原则；duration+easing；Enter/Exit、Top-level fade、Container transform |
| 令牌角色表 | `durationFast`、`durationMedium`、`standardCurve` |
| 产品既定行为 | `DesktopFadeThroughPageTransitionsBuilder`；catalog 180–220ms |
| 减动效 | `MediaQuery.disableAnimations` / reduced motion（链 accessibility） |
| Tier B | stagger、共享元素 — 按路由选用 |

**Flutter 索引：** `app_motion_tokens.dart`、`shared/ui/motion/`。

---

## accessibility.md 大纲

| 章节 | 内容 |
|------|------|
| Fluent / WCAG | 对比度 4.5:1 / 3:1 大字；非色唯一信息 |
| 焦点 | 键盘顺序；focus 可见（描边加粗，Tier B 实现缝） |
| 响应式 | 320px / 缩放；单壳不藏内容 |
| 与 MASTER 关系 | Pre-Delivery Checklist 扩展指针 |

---

## iconography.md 大纲

| 章节 | 内容 |
|------|------|
| 产品决策 | **Lucide**（非 Fluent System Icons）；禁止 Material `Icons.*` |
| 尺寸规范 | 14 / 24 等上下文尺寸；与字阶对齐 |
| Fluent 对照 | 说明偏离原因与一致性要求（线宽、圆角风格） |

---

## P0 落盘检查清单（spec 用）

- [ ] 各 `foundations/*.md` 填满 §骨架章节
- [ ] [ROADMAP.md](../ROADMAP.md)、[references.md](../references.md) 创建并交叉链接
- [ ] [MASTER.md](../MASTER.md) 增加 Documentation index
- [ ] 与 `hentai_color_scheme_tokens_test` 抽样一致
- [ ] 不修改 `GLOSSARY.md` 实现细节
