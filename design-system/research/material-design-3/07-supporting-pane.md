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

### 结论：**新增模板帧，不改造 `41:2384`**

理由：
1. `41:2384` 表达的是 **list-detail + supporting** 的三栏（列表 504 / 详情 / 阅读进度 360），前提是「列表与详情同屏」。但代码里详情是独立路由 `/comic/:id`（§4.1），进入详情后**列表不在屏上**，三栏不成立；改造 `41:2384` 会把这个「书库三栏上限参照」的表达力弄丢。
2. 详情页级模板需要的是「rail + 详情主区 + 支撑栏」，与 `41:2384` 语义不同（一个是 3 个内容栏，一个是 2 个内容栏 + 导航）。
3. 新增帧成本更低、且不破坏 MASTER §6 已记录的页面↔模板对应关系。

建议新增（`07 Templates` 页，与既有帧并列，命名沿用既有风格）：

| 新帧 | 尺寸 | 结构 | 数值依据 |
|---|---|---|---|
| `XL Supporting Pane` | 1920×1080 | expanded rail **256** + margin **24** + 详情主区 **1232** + spacer **24** + 支撑栏 **360** + margin **24** | 校验：256+24+1232+24+360+24 = 1920 ✅。rail 256 = MASTER §5.1（B，项目既有）；margin/spacer 24 = **A**（expanded 页 `leading and trailing margin of 24dp` / `spacer between panes is 24dp`）；支撑栏 360 用于 XL 属 **C**（官方 large/XL 默认 412） |
| `Expanded Supporting Pane` | 1024×768 | collapsed rail **80** + margin **24** + 详情主区 **512** + spacer **24** + 支撑栏 **360** + margin **24** | 校验：80+24+512+24+360+24 = 1024 ✅。**风险**：主区 512 装 220 封面 + 文本列偏挤（`DetailPrimaryRowLayout` 的 `coverWidth = 220`，`detail_primary_row_layout.dart:11`），Figma 出图必须实测；若挤，expanded 档支撑栏改**可折叠**（默认收起） |
| `Medium / Compact`（不改帧，只标注） | 600×800 / 390×844 | 在既有 `41:1824` / `41:1975` 上加 `meta below primary` 注释层 | 形态 = **A**（下方） |

复用既有组件（不重画，B，MASTER §6 Patterns）：
- 支撑栏容器：`MetadataPanel 41:2497`（320×240，5 组键值）——**它是 320 宽，放进 360 栏需左右各 20 内边距（320+20×2=360）；若按项目 24 内边距则需 368 > 360，装不下**。这是出图前必须先解决的冲突（见 §8.8）。
- 阅读进度行：复用 `ChapterRow 41:1955`（360×48）与 `HistoryRow 41:2498`（360×72）的 360 宽基准 → 与 360 支撑栏正好贴合（B，Figma 组件尺寸）。
- 分区预览（设置）不需要新帧：既有 `SettingsSection 41:2496`（360×284）。

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

| 档 | 导航 | 详情页（采纳） | 阅读器（不采纳） | 设置（list-detail） | 证据 |
|---|---|---|---|---|---|
| compact <600 | NavigationBar | 元数据在下方（现状） | 全屏 + 浮动栏 | 单栏，分类→详情滑入 | A |
| medium 600–839 | collapsed rail 80 | 元数据仍在下方 | 同上 | **单栏**（现 600 就分裂，需改到 840） | A（medium `1 (recommended) or 2`） |
| expanded 840–1199 | collapsed rail 80 | **trailing 固定 360** | 单栏 + 可选浮层 | 双栏 260 + 详情 | A（360dp / 24 / 24） |
| large 1200–1599 | expanded rail 256 | trailing 固定 360（或 412，见 §8.3） | 同上 | 双栏 | 形态 B/C；数值 A（412） |
| XL ≥1600 | expanded rail 256 | trailing 固定 360；三栏仅在「列表同屏」场景（书库）成立 | 同上 | 双栏 | A（XL ≤3 pane、side sheet ≤400dp） |

需要顺手在 MASTER 侧修正的三处（本次**未改** MASTER，交主会话同步）：
1. **§5.2 的「推荐 2 / 推荐 3」是对官方括号的误读**。官方 breakpoints 主页原文是 `Medium: 1 (recommended) or 2`、`Expanded/Large: 1 or 2 (recommended)`、`XL: 1 to 3 (recommended)`——括号修饰的是**整个区间**（推荐落在 1–2 / 1–3），不是「恒推荐 2」「恒推荐 3」。
2. **§5.4 阅读器**「可选 trailing 360」建议改为「可选浮层」，理由见 §4.2。
3. **§9 未决项第 2 条（Grid margin 仍 C 级）可以关掉**：compact 16dp / medium+ 24dp 均已拿到官方原文（A）。

---

## 8. 剩余未决项

1. **模板与路由的语义冲突**：Figma 的 Expanded/Large/XL 模板都是「列表 + 详情」双/三栏（`41:1774` / `41:1578` / `41:2384`），而代码里详情是独立路由 `/comic/:id`。要么书库走 inline list-detail（与模板一致，但要动路由结构），要么承认模板只是「视觉上限参照」并为详情页新增 §5 的两帧。**这是采纳 supporting pane 前必须先定的第一件事。**
2. **expanded 主区 512dp 是否够**：需在 Figma 实测 220 封面 + 标题/摘要/操作列；不够就引入「支撑栏可折叠」（默认收起），而不是缩支撑栏（360 是 A 级官方值，不该动）。
3. **360 vs 412**：官方 expanded=360 / large+XL=412。统一 360 的理由是「单一常量、与 `41:2384` 的阅读进度栏一致」；用 412 的理由是「贴合官方 large/XL 默认」。当前倾向 360（C 级取舍），需 UI 评审签字。
4. **XL 三栏取舍**：官方 XL 表推荐 2 栏（3 属 other），正文说「考虑三栏」；项目已按三栏出图。若最终只做 2 栏 + rail，则 `41:2384` 的 504 列表栏在详情路由下无意义（见未决项 1）。
5. **支撑栏开/关 vs 自动切换**：官方提 show-and-hide / levitate / reflow 三策略，但没规定 supporting pane 该用哪个；本项目需决定「用户手动收起后是否跨断点保持」（官方只说临时改宽不持久）。
6. **断点迁移的回归面**：`isMedium` 语义变更影响 shell、首页、设置、元数据页、header 共 6+3 处；建议先加语义化查询（§6.3），再逐页换，不要一次性改常量。
7. **a11y / 键盘**：支撑栏固定后焦点顺序（primary → supporting）、Tab 环、360 栏内 chip 行的键盘遍历尚未评估。
8. **MetadataPanel 320 vs 360 栏**：Figma 组件 320 宽装不进 360 栏（需 20 内边距或改 360 版），出图前定，否则代码落地会二次返工。

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
