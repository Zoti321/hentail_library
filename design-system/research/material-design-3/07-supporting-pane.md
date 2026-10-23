# 07 · Supporting pane 布局评估（M3 baseline）

> 状态：**评估底稿（非规范）**。证据等级沿用本目录规则：**A** = 官方规范原文；**B** = 官方实现／源码，或按截图反推；**C** = 工程推断。
> 抓取方式：`https://m3.material.io/...` 页面经 Firecrawl 云抓取转 Markdown，正文可达但**不是原始 HTML**（每页 warning 一致）；supporting pane 页与本地 `.scratch/m3docs/canonical-supporting-pane.json`（10714 字节，JSON keys = `summary/content/links/uncertainty/warnings`）逐字一致，故本文件引用以本地 JSON 为可复现锚点。本次**未写入任何截图/位图**。
> 影响面：本文只给方案，不改任何 Flutter 代码与 Figma 文件。

---

## 1. 模式定义（官方原文要点）

核心定义（A，supporting-pane 页）：

- `The supporting pane layout organizes content into primary and secondary areas.`
- `The primary area contains the main content and occupies the majority of the space. The secondary area contains supporting content.`
- `The window is divided between a focus pane and a supporting pane. Depending on the breakpoint, the supporting pane may appear below or beside the focus pane.`

面积比例（A，canonical examples overview 页）：primary `occupies the majority of the window (typically about two-thirds)`；secondary `takes up the remainder of the space`。

适用条件（A）：

- `Key use cases …: Productivity / Document editing and commenting / Content and media browsing`
- `Use the supporting pane layout when the secondary content is only meaningful in relation to the primary content.`

结构本质（A，scaffold panes 页）：`All layouts need at least one flexible pane`；pane 可为 Fixed 或 Flexible。supporting pane 组合 = **1 个 flexible focus pane + 1 个 fixed supporting pane**（见 §3 表）。

来源：
- https://m3.material.io/foundations/layout/canonical-examples/supporting-pane
- https://m3.material.io/foundations/layout/canonical-examples/overview
- https://m3.material.io/foundations/layout/scaffold/panes
- 本地：`.scratch/m3docs/canonical-supporting-pane.json`（与上述 supporting-pane 页一致）

---

## 2. 与 list-detail 的边界

官方用一句话把两者分开（A，supporting-pane 页）：

- supporting pane：`Use … when the secondary content is only meaningful in relation to the primary content.`
- list-detail：`For content with a parent-child relationship, use a list-detail layout instead.`

list-detail 官方 key use cases 原文含 `Settings + category detail`、`Musical artist + album detail`、`Text message + conversation`、`File browser + open folder`、`Email inbox + selected email`（A，list-detail 页）。注意其中 **Settings + category detail 明确归 list-detail**，这直接否掉了本项目「设置 + 分区预览」走 supporting pane 的想法（见 §4.3）。

### 判断规则（工程化，C，但每步都锚到 A）

按顺序问，第一问答「否」就换模式：

1. **次级内容离开主内容还有意义吗？** 有 → list-detail（选中 A 即换 B，B 可独立成为导航目标）；没有 → 继续。
2. **是「父—子」还是「同体—附属」？** 主内容换成另一条记录、次级内容随之整体替换 = 父子 → list-detail；次级内容只是同一主内容的另一种切面（元数据、注释、大纲、进度）→ supporting pane。
3. **次级内容是否需要独立深链/独立返回按钮？** 需要 → list-detail（官方：list-detail 单栏 detail 才有 back）。不需要 → supporting pane。
4. **窄屏下是否能压成「主内容下方的区段」？** 能 → supporting pane；不能（例如是可选中的对象列表）→ list-detail。

一句话版：**list-detail 是「换对象」，supporting pane 是「换视角」。**

---

## 3. 各断点形态

官方 supporting-pane 页只给了 Compact / Medium / Expanded 三节 + 一张 breakpoint 表；**该页没有 Large / XL 小节**（对比 list-detail 页明确有 `Expanded, large, & extra-large: Use a two-pane layout`）。因此 large/XL 的形态是外推。

| 断点（本项目五档） | 形态 | 尺寸 | 证据 |
|---|---|---|---|
| Compact <600 | 在主 pane **下方**（可折叠区段）；官方另给 bottom sheet 作为保持焦点的替代 | 官方无固定宽/高数值；本文件不编 | **A**（表 `Below / Flexible / Compact or Medium`；Compact 节 `should appear below the focus pane`；`A bottom sheet can be useful for keeping focus on the primary pane while providing access to supporting information.`） |
| Medium 600–839 | 仍在主 pane **下方**（弹性，占满宽度） | 区段边距 24dp | **A**（Medium 节 `should appear below the focus pane`；medium 页 `margins of 24dp`） |
| Expanded 840–1199 | **leading 或 trailing 固定栏**，主 pane 弹性 | **固定栏 360dp**；外侧 margin 24dp、pane 间 spacer 24dp | **A**（表 `Leading or trailing / Fixed (360 dp) / Expanded`；expanded 页 `the fixed pane should have a width of 360dp by default`、`leading and trailing margin of 24dp`、`spacer between panes is 24dp`） |
| Large 1200–1599 | 沿用 expanded 形态（固定栏 + 弹性主区）——官方无 supporting-pane Large 小节，属外推 | 官方 large+XL 页给固定栏 **412dp** 默认；本项目若继续用 360 属 C | 形态：**B/C**（外推）；412/24/24 数值：**A**（large-extra-large 页 `fixed pane should have a width of 412dp by default`） |
| XL ≥1600 | 官方允许在二栏基础上再加 1 个 pane，但第三栏**必须**是 standard side sheet | 第三栏 side sheet 默认最大 400dp；固定 pane 推荐 412dp；三栏总数上限 3 | 二栏推荐：**A**（breakpoints 主页 XL `1 to 3 (recommended)`、scaffold panes 表 XL `2`，third `1, 3`；`Don't use more than three panes.`）；side sheet 上限 400dp：**A**（`Note: Fixed panes at this breakpoint are recommended to be 412dp, but side sheets have a default maximum width of 400dp.`） |

### 关于「expanded 起固定 360dp」

- **A**：360dp 是官方给 supporting pane 固定栏在 **expanded** 档的默认值（上表两处原文）。
- **C**：把它沿用到 large/XL 是我们自己的取舍——官方 large/XL 默认是 412dp。**不许把「412 是通用值」或「360 是通用值」说成官方原话**：两个数各属不同断点。
- resize 相关（A，scaffold panes）：`At expanded, large, and extra-large breakpoints, two-pane layouts can be customized to snap to set widths: 360dp / 412dp / Split-pane with spacer centered visually`；且 `temporary resizing … is primarily used in supporting pane layouts where resizing is uncommon`，关闭重开后回到默认布局 → 本项目 MVP **不做拖拽调宽**，只做开/关。

---

## 4. 本项目页面逐个评估

### 4.1 书库详情 `/comic/:id` + 元数据/阅读进度侧栏 → **采纳（expanded 起）**

现状（B，读码）：
- 页面是独立路由 `/comic/:id`（`app/lib/features/bootstrap/presentation/views/routing/shared_content_routes.dart:33-43`，`buildDesktopFadeThroughPage`），不在书库列表内部渲染。
- 内容单列：`app/lib/features/library_browse/presentation/views/comic_detail_page/widgets/comic_detail.dart:22-81` = `ComicDetailHeader` + `SingleChildScrollView(Column[DetailPrimaryRowLayout(cover+title/摘要/操作/简介), ComicDetailMetadataBlock])`。
- `ComicDetailMetadataBlock`（`comic_detail_info_sections.dart:208-307`）= Parody → Author → Character → Tag 四组 chip 行 + Format/Size/Path/Added/Updated 五条 `ComicDetailInfoRow`（同文件 `:400`）。
- 也就是说**官方 compact/medium 的「下方」形态项目已经天然满足**：元数据本来就在主内容下方。

判定理由（对照 §2 规则）：
1. 元数据/阅读进度离开这本漫画无独立意义 → 不是父子，排除 list-detail。
2. 同一对象的不同切面（信息密度 / 进度）→ supporting pane 正解。
3. 不需要独立深链 / 返回。
4. 窄屏可压成下方区段（现状即是）。

因此：**compact/medium 保持现状（下方滚动区段，compact 可用折叠区段），expanded 起把 `ComicDetailMetadataBlock` 及「阅读进度」移入 trailing 固定栏（360dp）**。这与 MASTER §5.4「单本详情 = expanded 起 supporting pane(trailing 360)」、`06-adaptive-desktop.md` §7 一致。

派生收益：主区在 expanded 起不再被 4 组 chip 行与 5 条键值行拉长，封面 + 简介一屏可读；同时也是 Figma `41:2384` 第三栏（阅读进度 360）的代码落点。

**同构页面**：`/series/:id`（`series_detail_page/series_detail_page.dart`，`SeriesDetailMetadataBlock` 在 `series_detail_info_sections.dart:111`）结构相同 → **同样采纳**，同一套 widget 复用（系列详情支撑栏 = 元数据 + 集数/进度）。

### 4.2 阅读器 `/reader` + 章节目录（TOC） → **不采纳（当前版本），列为「有条件待议」**

现状（B，读码）：
- 沉浸式全屏：`reader_page.dart:307` 起一个 `Stack`，内容 `ReaderContent` + 两个 `AnimatedPositioned` 浮动栏（`reader_top_bar.dart:127`、`reader_bottom_bar.dart:155`），磨砂面板 `ReaderFloatingPanel`（`reader_floating_panel.dart:61-103`），宽度 `readerTargetBarWidth()`（`reader_floating_panel.dart:37-45`，compact 全宽 / 否则 `(viewport×0.8).clamp(560,1120)`）。
- **没有章节模型**：全库 `chapter|Chapter` 非生成代码命中仅 1 处（`read_session_providers.dart:43` 的一个 `String? chapterId` 形参），没有 Chapter 实体/路由/列表。
- **没有页面缩略图管线**：`thumbnail` 的 440 处命中全部是 FRB 生成的 DTO/stream（封面缩略图），不是页缩略图。
- 唯一的页码导航是底栏 slider（`reader_bottom_bar.dart:90-135`，min 1 / max totalPages）。
- 阅读器设置是对话框 `reader_settings_dialog.dart`。

判定理由：
1. supporting pane 的 key use case「Document editing and commenting」不覆盖「阅读器 + 目录」这种**同体导航**——目录是主内容内部跳转，不是「只相对于主内容才有意义的辅助内容」，语义更接近「同一文档的导航捷径」。
2. 前置条件缺失：无章节模型 → 目录只剩「页码 1..N」；无缩略图管线 → 目录退化为数字网格，价值低于现有 slider。要补是**功能立项**，不是布局改造。
3. 沉浸式阅读与常驻 360dp 侧栏冲突：官方 show-and-hide / levitate / reflow 三种策略里，阅读器场景更适合 levitate（悬浮）而非固定栏（B：scaffold panes 的策略节）。
4. 官方对 compact 的建议是 bottom sheet——本项目阅读器已经用对话框承担了「设置」这一支撑内容，形态已对齐。

结论：**不采纳**；若将来要做，前置条件是「章节（或页缩略图）数据 + 目录语义」，且形态建议为**可召唤的浮层（约 360dp，overlay）**而非固定栏。MASTER §5.4 写的「阅读器 = 单栏 + 可选 trailing 360」应改为「单栏 + 可选浮层」。

### 4.3 设置 `/settings` + 分区预览 → **不采纳 supporting pane；确认走 list-detail**

**用户决策（m00431）**：设置页**采用 inline list-detail**，范围由实现方定为「设置根页双栏（分类 + 内容，断点 ≥840）+ 二级页（阅读 / 外观 / 数据）单栏」；书库与历史仍走「列表 → 独立详情」。

理由（A + B）：
- 官方 list-detail key use cases 原文明确含 `Settings + category detail`（A）。分区切换 = 换对象，属父子关系。
- 官方判读句 `For content with a parent-child relationship, use a list-detail layout instead.`（A）。
- **代码里已经是 list-detail**：`settings_loaded_view.dart:133-144` 宽屏 `Row(SizedBox(width: kSettingsMasterPaneWidth, child: masterList), SizedBox(spacing.lg), Expanded(detailPane))`，窄屏 `_SettingsNarrowPaneSwitcher`（同文件 `:180-239`，滑入 + 淡入）；`kSettingsMasterPaneWidth = 260`（`settings_layout_constants.dart:9`）。

即：设置页**不需要**支持栏，需要的是**把切换阈值从 600 抬到 840**（现状 `final bool isWide = !AppLayoutBreakpoints.isCompact(viewportWidth)`，`settings_loaded_view.dart:56`）。M3 在 medium(600–839) 仍是单 pane（A：breakpoints 主页 Medium `1 (recommended) or 2`），现在 600 就分裂会造成 600–839 区间平板/窄窗出现 260 + Detail 的拥挤双栏。

### 4.4 额外候选（全部不采纳，各给一句理由）

| 候选 | 位置 | 判定 | 理由 |
|---|---|---|---|
| 书库列表 + 筛选器面板 | `library_page/widgets/library_filter_sort_drawer.dart`、`filter_popup_button.dart` | 不采纳 | 筛选是**并列控制**、不是「只相对于 primary 才有意义」，且需要随时遮罩主区；官方更倾向 show-and-hide（A：scaffold panes）。保持现状 drawer/popup。 |
| 元数据批量编辑 | `views/widgets/bulk_edit_metadata_panels.dart`、`edit_metadata_dialog*.dart` | 不采纳 | 模态编辑任务，读写同一批字段，属「任务面板」非「辅助视图」；supporting pane 会与主区抢编辑焦点。 |
| 历史记录 + 预览 | `home_page/history_page.dart` | 不采纳 | 列表→条目是父子，走 list-detail（与官方 `Email inbox + selected email` 同型）。 |
| 标签/作者/parody 管理 + 详情 | `metadata_page/` | 不采纳 | 同上，父子 → list-detail；且 `metadata_layout_constants.dart` 已在做三档常量。 |
| 阅读器设置 | `reader_settings_dialog.dart` | **保持对话框**（可选改 bottom sheet） | 官方 compact 允许 bottom sheet（A）；固定侧栏破坏沉浸。 |

---

## 5. Figma 落点

现有模板（B，MASTER §6 记录，本次未改动 Figma）：`07 Templates` 页 `9:15`

| 帧 | 尺寸 | 现有结构 |
|---|---|---|
| Compact `41:1975` | 390×844 | 单栏 + NavigationBar |
| Medium `41:1824` | 600×800 | collapsed rail 80 |
| Expanded `41:1774` | 1024×768 | collapsed rail 80 + 列表 304 + 详情 |
| Large `41:1578` | 1440×900 | expanded rail 256 + 列表 400 + 详情 |
| XL `41:2384` | 1920×1080 | expanded rail 256 + 列表 504 + 详情 + 阅读进度 360（**三栏**） |

### 结论：**已执行（2026-10-23 改造 `41:2384` + 新增 expanded / large 两帧）**

用户决策（m00431）：① `41:2384` 选 A——改造为详情模板；② XL 详情用 expanded rail **256**；③ 支撑栏贴右并保留 **24** 右侧留白；④ supporting pane 模板 **共用**（`/comic/:id`、`/series/:id`、作者/元数据等同一详情模板）；⑤ 宽度「采用官方的」→ expanded **360**、large/XL **412**。原先「新增帧、不改 `41:2384`」的建议作废。

| 帧 | id | 尺寸 | 结构 | 校验 |
|---|---|---|---|---|
| `Template/Comic detail · Extra-large 1920` | `41:2384`（改造） | 1920×1080 | rail 256 + 24 + 主区 1180 + 24 + 支撑栏 412 + 24 | 256+24+1180+24+412+24 = 1920 ✅，支撑栏 1484–1896，右留白 24 |
| `Template/Comic detail · Large 1440` | `67:509`（新增） | 1440×900 | rail 80 + 24 + 主区 876 + 24 + 支撑栏 412 + 24 | 80+24+876+24+412+24 = 1440 ✅，支撑栏 1004–1416 |
| `Template/Comic detail · Expanded 1024` | `67:431`（新增） | 1024×768 | rail 80 + 24 + 主区 512 + 24 + 支撑栏 360 + 24 | 80+24+512+24+360+24 = 1024 ✅，主区内容 464 = 封面 180 + 32 + 文本列 252 |

改造内容：删掉 `41:2384` 的书库三栏内容（书库标题 / Search 框 / 5 条 `BookListItem` / 2 条 1px 分隔线），详情区改为「封面 180×252 + 标题 + 元数据 + 3 chips + 简介 + 开始阅读 + 章节目录 3 行」；支撑栏 = `surfaceContainer` 底色矩形（`67:418`，纯 tone、零分隔线）+ 阅读进度键值 + `MetadataPanel` 实例（`67:419`）。large / expanded 用同一套子节点克隆后重排，组件全部复用（`MetadataPanel 41:2497`、`ChapterRow`、`Chip/*`、`NavigationRail`）。

**expanded 512 实测（B，Figma 出图 + MiSans 字体度量）**：

- 标题「深海图书馆」24 Semibold = **120**，文本列 252 够；
- 元数据原串「校园 · 悬疑 · 共 24 话 · 更新至第 12 话」14px = **256 > 252** → 删「共 24 话」后 **208** 可单行（large / XL 保留原串，主区宽）；
- 简介 63 字 14px 在 464 宽下 3 行，可读；章节行「第 12 话 · 闭馆之前」= **111**；
- **`MetadataPanel` 320 装不进 360 栏的内容宽 312** → expanded 支撑栏只放阅读进度，不放元数据卡（待办见 §8）。

**`08 Screens` 第 5 行 `Detail`（y = 4000）**：列 x `0` / `1500` / `2600` / `3300` ↔ 1440 / 1024 / 600 / 390；1440 与 1024 复用上面模板，600 / 390 为单栏详情（元数据与阅读进度按官方 compact/medium 落到主内容下方，见 §4.1）。

**桌面底板（用户提问后追加，large/XL 专用）**：≥1200dp 的帧加「桌面底板 + 窗口 chrome」以区分桌面窗口与移动屏幕——底板 = 帧外扩 24dp、圆角 20、填充 **#EAE8E6**（中性灰，**不属于 46 个颜色角色**，只是画布层，禁止在代码里当 token 用）；帧本身圆角 12 + 1dp `outlineVariant` 内描边 + `0/2/6 @12%` 投影（属 OS 窗口层，不参与 `MASTER §4.2` 的 M3 elevation 语义）。

---

## 6. Flutter 落点（只给方案，不改代码）

### 6.1 新增布局组件

建议新文件 `app/lib/shared/ui/layout/supporting_pane_layout.dart`：

```dart
class SupportingPaneLayout extends StatelessWidget {
  const SupportingPaneLayout({
    super.key,
    required this.primary,
    this.supporting, // null = 用户手动收起，走单列
    this.supportingWidth = 360,        // A：expanded 默认 360dp
    this.spacer = 24,                  // A：pane 间 spacer 24dp
    this.collapseBelowWidth = 840,     // A：expanded 起才用固定栏
  });

  final Widget primary;
  final Widget? supporting;
  final double supportingWidth;
  final double spacer;
  final double collapseBelowWidth;

  @override
  Widget build(BuildContext context) {
    final Widget? supporting = this.supporting;
    if (supporting == null) {
      return primary;
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < collapseBelowWidth) {
          // A：Compact / Medium → 在主 pane 下方
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              primary,
              SizedBox(height: spacer),
              supporting,
            ],
          );
        }
        // A：Expanded 起 → trailing 固定栏
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: primary),
            SizedBox(width: spacer),
            SizedBox(width: supportingWidth, child: supporting),
          ],
        );
      },
    );
  }
}
```

要点：
- **用 `LayoutBuilder` 判宽，不用 `MediaQuery`**：详情页嵌在 `ApplicationShell` 内（`ShellRoute`，`app_router.dart:34-38`），可用宽 ≠ 窗口宽（rail 已占 256/80）。用 `constraints.maxWidth` 才与 Figma 帧宽对得上。
- 360 / 24 只出现在这一个组件的参数里，不散落到页面。
- 支撑栏在 840 以下**不隐藏**，只是挪到下方（与官方一致）；若需要「用户手动收起」，传 `supporting: null` 走单列，而不是换路由。

### 6.2 断点切换不重建路由栈

现状风险已存在：详情是 `/comic/:id` 独立路由（`shared_content_routes.dart:33-43`）。规则：

1. **布局切换只发生在同一 widget 树里**：`SupportingPaneLayout` 的分支内外，`primary` 与 `supporting` 必须是**同一批 widget 实例 / 同一 state**，不做 `Navigator.push`，也不要用 `/comic/:id?pane=meta` 之类的 query 表达侧栏（改 URL 会触发 go_router 重建）。
2. 滚动位置：详情页把 `ScrollController` 提到页面级（`ComicDetailPage`），支撑栏给固定 `PageStorageKey`；跨 840 时 `SingleChildScrollView` 会被换成独立滚动体，靠 `PageStorageKey` 保位置（参考官方 list-detail 的「detail 保留滚动位置」行为，A）。
3. 折叠/展开态是**页面本地 state**，不进路由。
4. 复用既有先例：`settings_loaded_view.dart:53-150` 已是「同路由内 `isWide` 分支 + `Row` / `Switcher`」的写法，照抄其模式即可；差异只是它 master/detail，我们 primary/supporting，且它的阈值 600 需要改成 840。

### 6.3 与 `app_layout_breakpoints.dart` 的关系

现状（B，读码）：`app/lib/shared/ui/layout/app_layout_breakpoints.dart:10,13` → `compact = 600`、`medium = 1024`；三个判定 `isCompact`(<600) / `isMedium`(600≤x<1024) / `isExpanded`(≥1024)。

引用面（B，本次统计全库 `AppLayoutBreakpoints.` 计数）：`isCompact` **21**、`isMedium` **6**、`compact` **3**、`isExpanded` **2**、`minWindowWidth/minWindowHeight` 各 1。

改五档（600 / 840 / 1200 / 1600）的**关键坑**：把 `medium` 从 1024 改成 840 会让 600–839 区间从「medium」掉回「compact」，而 `isMedium` 正被 `responsive_app_shell.dart:48-54` 用来决定 rail vs drawer、被 `settings_layout_constants.dart:21-29` 决定档位。M3 是 **medium(600–839) 就该有 collapsed navigation rail**（A：medium 页配 navigation rail + 8 列），所以**不能直接改数值**。

建议（C）：
1. 对外只暴露语义化查询，不暴露裸常量：
   - `hasNavigationRail(width) => width >= 600`（A：medium 起 rail）
   - `supportsSupportingPane(width) => width >= 840`（A：expanded 起 fixed pane）
   - `isLarge(width) => width >= 1200`、`isExtraLarge(width) => width >= 1600`
2. 迁移期保持 `isCompact`（600）不动（21 处引用零改动），把现在的「≥1024」语义拆成 `isExpanded`(840–1199)，再逐页复核 6 处 `isMedium` 与 3 处 `compact` 常量：`detail_primary_row_layout.dart:12,56`、`page_header_layout.dart:16,19`、`home_page_constants.dart:13,16`、`metadata_layout_constants.dart:12,15`、`settings_layout_constants.dart:22,25`。
3. `page_content_width_layout.dart` 的 `kPageContentMaxWidth = 1280` 与支撑栏并存时要注意：主区内边距应由「主区宽度」算，不能再用整窗宽算，否则 XL（主区 1232）会被 1280 上限顶到与支撑栏视觉不齐。

---

## 7. 与五档断点矩阵的整合结论

| 档 | 导航 | 详情页（已采纳） | 阅读器（不采纳） | 设置（list-detail） | 证据 |
|---|---|---|---|---|---|
| compact <600 | NavigationBar | 元数据与阅读进度在主内容下方（现状） | 全屏 + 浮动栏 | 单栏，分类→详情滑入 | A |
| medium 600–839 | collapsed rail 80 | 同上（单栏，主内容下方） | 同上 | **单栏**（阈值从 600 改到 840） | A（medium `1 (recommended) or 2`） |
| expanded 840–1199 | collapsed rail 80 | **trailing 固定 360**（主区 512） | 全屏 + 可选浮层 | 双栏 260 + 详情（≥840） | A（360dp / 24 / 24） |
| large 1200–1599 | collapsed rail 80 | trailing 固定 **412**（主区 876） | 同上 | 双栏 | A（large 官方 412） |
| XL ≥1600 | expanded rail 256（用户指定） | trailing 固定 **412**（主区 1180） | 同上 | 双栏 | A（XL 412、≤3 pane） |

需要顺手在 MASTER 侧同步的三处**已同步**（2026-10-23，见 MASTER §5.2 / §5.3 / §5.4 / §9）：①§5.2 括号改为官方原文；②§5.4 阅读器改「可选浮层 ≤360」；③§9 关闭 Grid margin 未决项。

---

## 8. 剩余未决项（2026-10-23 更新）

已关闭：

1. ~~模板与路由的语义冲突~~ → 用户定 A：`41:2384` 改造为详情模板；书库列表页保持「列表 → 独立详情路由」，不做 inline list-detail。
2. ~~expanded 主区 512 是否够~~ → 实测够用，代价是元数据删「共 24 话」（§5）。
3. ~~360 vs 412~~ → 按官方分档：expanded 360、large/XL 412。
4. ~~`MetadataPanel` 320 vs 360 栏~~ → expanded 支撑栏暂不放元数据卡；出 312 版后再放。

仍开放：

1. **`MetadataPanel` 312 版或 16 内边距**：决定 expanded 支撑栏能否放元数据，也影响 360 栏的组件内边距规则。
2. **支撑栏开/关与跨断点记忆**：官方三策略（show-and-hide / levitate / reflow）未指定该用哪个；MVP 建议常驻、不做手动收起。
3. **a11y / 键盘**：焦点顺序（primary → supporting）、Tab 环、栏内 chip 行遍历未评估。
4. **阅读器目录**：前置条件「章节模型 / 页缩略图管线」未立项，形态定为可召唤浮层（≤360），不做固定栏。
5. **设置 list-detail 阈值迁移回归面**：`isWide` 判定 600 → 840 影响 shell、首页、设置、元数据页、header 共 6+3 处。

---

## 来源

官方（A 级，本次抓取）：
- supporting pane 模式：https://m3.material.io/foundations/layout/canonical-examples/supporting-pane
- canonical examples 总览（primary 约占 2/3）：https://m3.material.io/foundations/layout/canonical-examples/overview
- list-detail（Settings + category detail、父子关系）：https://m3.material.io/foundations/layout/canonical-examples/list-detail
- scaffold panes（pane 数、Fixed/Flexible、412dp、side sheet ≤400dp、resize 策略）：https://m3.material.io/foundations/layout/scaffold/panes
- breakpoints 主页（五档 pane 数表）：https://m3.material.io/foundations/layout/breakpoints
- compact / medium / expanded / large-extra-large 子页（16 / 24 / 360 / 412 数值）：https://m3.material.io/foundations/layout/breakpoints/compact 、.../medium 、.../expanded 、.../large-extra-large

本地：
- `.scratch/m3docs/canonical-supporting-pane.json`（与官方页一致的正文快照）
- `design-system/hentai-library/MASTER.md` §1 / §5.1–5.4 / §6（模板与节点 id）
- `design-system/research/material-design-3/06-adaptive-desktop.md` §3.2 / §7 / §10
- 代码（B 级，均本次读码）：`app/lib/shared/ui/layout/app_layout_breakpoints.dart`、`app/lib/shared/ui/layout/page_content_width_layout.dart`、`app/lib/shared/ui/layout/detail_primary_row_layout.dart`、`app/lib/shared/ui/shell/responsive_app_shell.dart`、`app/lib/shared/ui/widgets/settings/settings_layout_constants.dart`、`app/lib/features/app_settings/presentation/views/settings_page/widgets/settings_loaded_view.dart`、`app/lib/features/library_browse/presentation/views/comic_detail_page/widgets/comic_detail.dart`、`.../comic_detail_info_sections.dart`、`.../series_detail_info_sections.dart`、`app/lib/features/read_session/presentation/views/reader_page/reader_page.dart`、`.../widgets/reader_bottom_bar.dart`、`.../widgets/reader_floating_panel.dart`、`app/lib/features/bootstrap/presentation/views/routing/app_router.dart`、`.../routing/shared_content_routes.dart`
