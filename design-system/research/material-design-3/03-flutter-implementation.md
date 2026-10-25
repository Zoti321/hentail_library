# Flutter 侧的 Material 3 实现现状与本项目迁移要点

> 范围：Flutter（Dart）对 Material 3 的实现现状、与 M3 规范的差距、与本仓库 app/lib/shared/ui/theme/ 现状的对照，以及迁移顺序建议。
> 本文不写实现代码；所有 API 行为以 api.flutter.dev / docs.flutter.dev 为准，规范侧以 m3.material.io 与 developer.android.com 为准（抓取限制见「检索说明」）。

## 1. 检索说明

### 1.1 抓取方式与限制（重要，影响本文可信度边界）

- 本次抓取只取一手来源：api.flutter.dev、docs.flutter.dev、developer.android.com、m3.material.io、pub.dev、github.com/flutter 与 github.com/flutter/website。
- **m3.material.io 全站抽取失败**：多次抓取（/foundations/layout/applying-layout/window-size-classes、/styles/motion/overview、/blog/building-with-m3-expressive）返回正文长度 0（该站为 JS 渲染）。凡涉及 M3 规范数值（window size class dp、shape scale、state layer 透明度、motion token）在本文中**一律不给数值**，改以 developer.android.com 的等价官方表述或标注「未能从官方文档确认」。
- docs.flutter.dev 在抓取中途被限流（HTTP 429），部分页面正文改从**同一官方仓库** flutter/website 的 Markdown 源（raw.githubusercontent.com/flutter/website/main/sites/docs/src/content/...）读取，正文与站点一致，引用时同时给出站点 URL。
- api.flutter.dev 的 dartdoc 路径规律：类为 X-class.html，enum/mixin 为 X.html（WidgetState 是 enum），命名构造为 X/X.maker.html。抓取中若干 URL 返回 404（如 Typography.material2021 的 -class 形式、MaterialShapes-class.html），**404 被本文当作「该 API 不存在」的弱证据**，并已注明。
- 不臆造当前日期；本文只记录页面自身显示的版本/更新线索（见 1.2）。

### 1.2 抓取到的官方页面与页面自身版本线索

| 页面（URL） | 页面自身显示的版本/线索 | 用途 |
| --- | --- | --- |
| api.flutter.dev/flutter/material/ThemeData/useMaterial3.html | 正文：This flag is true by default … In the long run this flag will be deprecated；实现为 final bool useMaterial3（抓取时未见 @Deprecated） | M3 默认状态 |
| docs.flutter.dev/release/breaking-changes/material-3-default | Timeline: Landed in version 3.13.0-4.0.pre；In stable release: 3.16 | M3 成为默认 |
| docs.flutter.dev/release/breaking-changes/material-3-migration | 正文：As of the Flutter 3.16 release (November 2023), useMaterial3 is true by default | 迁移指南 |
| docs.flutter.dev/release/breaking-changes/material-state | 正文：In stable release: 3.22.0 | WidgetState 重命名 |
| docs.flutter.dev/release/breaking-changes/new-color-scheme-roles | Timeline: Landed in version 3.21.0-4.0.pre；In stable release: 3.22.0 | tone-based surface 角色、surfaceTint 去化 |
| docs.flutter.dev/release/breaking-changes/material-design-3-token-update | Timeline: Landed in version 3.26.0-0.0.pre；In stable release: 3.27；正文：tokens v6.1（PR #153385 v5.0.0、#153722 v6.1.0） | 颜色 token 映射变更 |
| docs.flutter.dev/release/release-notes | 目录列 3.47.0 / 3.44.0 / 3.41.0 / 3.38.0 | 版本基线 |
| flutter.dev/blog/whats-new-in-flutter-3-38 | 3.38 变更说明（predictive back 默认开启、默认页面转场改 FadeForwards 等） | 3.38 行为 |
| flutter.dev/blog/whats-new-in-flutter-3-47 | 3.47：桌面 Impeller 默认、Dart 3.13、Material/Cupertino 解耦推进等 | 当前 CI 基线 |
| docs/engineering/flutter-3.47-migration.md | 本仓库 3.38.5→3.47.8 清单与 Gate 注意点 | 工程基线 |
| api.flutter.dev/flutter/material/PageTransitionsTheme-class.html | 正文分别描述 FadeUpwardsPageTransitionsBuilder / Zoom / FadeForwards 的角色，称 FadeForwards 为 default page transition | 转场默认值 |
| api.flutter.dev/flutter/material/Typography/Typography.material2021.html | Creates a typography instance using Material Design 3 2021 defaults；englishLike2021 / dense2021 / tall2021 | M3 排版 |
| api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html | 参数 dynamicSchemeVariant = DynamicSchemeVariant.tonalSpot；background/onBackground @Deprecated after v3.18.0-0.1.pre | 种子色 |
| api.flutter.dev/flutter/material/ColorScheme/fromImageProvider.html | static method，返回 Future<ColorScheme>，可选覆盖各角色 | 图片取色 |
| developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes | 正文给出 width 分档：<600dp / 600–840 / 840–1200 / 1200–1600 / ≥1600dp | window size classes |
| developer.android.com/develop/ui/views/theming/dynamic-colors | 正文：Dynamic Color, which was added in Android 12 | 动态取色平台范围 |
| developer.android.com/jetpack/androidx/releases/compose-material3?hl=en | 1.4.0 段落：LocalMotionScheme 移除、改用 MaterialTheme.motionScheme；TopAppBar/ButtonGroup/ToggleButtons/SearchBarState 等提升为 stable；MaterialShapes 与 LoadingIndicator 的 stable 提升被 revert | M3 Expressive 实现状态（Android 侧） |
| github.com/flutter/flutter/issues/168813 | 标题 Bring Material 3 Expressive to Flutter；状态 Open（页面显示 opened May 14, 2025） | Flutter 侧 Expressive 状态 |
| api.flutter.dev/flutter/material/NoSplash-class.html | 正文：defeat the default ink splash drawn by an InkWell or ButtonStyle | 本项目 splashFactory |
| api.flutter.dev/flutter/material/kMinInteractiveDimension-constant.html | const double kMinInteractiveDimension = 48.0 | 触达尺寸 |
| api.flutter.dev/flutter/material/VisualDensity-class.html | 正文：mobile 平台用 standard，desktop（macOS/Windows/Linux）用 compact | 密度 |

### 1.3 三类信息的标注约定

本文用下列标签区分信息类别，冲突时并列记录、不强行统一：

| 标签 | 含义 |
| --- | --- |
| ［规范］ | M3 设计文档/规格的意图与要求（m3.material.io、developer.android.com 设计页） |
| ［实现］ | Compose Material3 / Flutter Material / material-web 的实际 API、参数默认值、已发布行为 |
| ［Expressive］ | M3 Expressive（2025 起）内容；标注其在 Flutter 与 Compose 两侧的实际落地状态 |

## 2. 版本基线：本项目锁定在哪个 Flutter

| 事实 | 值 | 来源 |
| --- | --- | --- |
| Dart SDK 约束 | ^3.13.0 | app/pubspec.yaml |
| 解析出的 Flutter SDK 约束 | flutter: ">=3.47.0" | app/pubspec.lock `sdks` |
| CI 固定 SDK | 3.47.8 | `.github/workflows/gate.yml` → `FLUTTER_VERSION` |
| `material_color_utilities`（直接依赖） | 0.13.0 | app/pubspec.yaml / pubspec.lock |
| 官方 stable 目录（抓取时） | 3.47.0 等 | docs.flutter.dev/release/release-notes |

**结论（2026-10 起）：** 工程与 CI 基线为 **Flutter ≥3.47.0 / Dart 3.13.x**。下文 §3–§7 中大量条目写于 3.38 调研期，**API 下限仍以 pubspec.lock 为准**；3.38→3.47 的 breaking 与平台项见 `docs/engineering/research/flutter-official-upgrade-3.38-to-3.47.md`。

**3.47 起与本项目相关的官方行为（摘要，非穷尽）：**

- **桌面 Impeller** 在 Windows / macOS / Linux 上为默认渲染后端（发版与主题 smoke 时注意与 Skia 差异）。
- **Dart 3.13**、**MCU 0.13** 随 Flutter 3.47 工具链对齐；色板脚本若仍按 0.11 生成，需对照 `MASTER.md` §2 与 `app/lib/shared/ui/theme/`。
- **Material/Cupertino 解耦**仍在推进；Expressive 在 Flutter 侧仍无 stable 路径（#168813 Open）。

**仍适用于本仓库的 3.38 时代行为（未在 3.47 回滚）：**

- predictive back route transitions enabled by default in MaterialApp
- 默认页面转场为 FadeForwardsPageTransitionsBuilder（本项目 `theme.dart` 仍覆盖 android 为 FadeUpwards）
- WidgetState 迁移对既有主题代码无强制改动

## 3. Flutter 的 Material 3：［实现］现状

### 3.1 useMaterial3 默认值与归宿

| 项 | 结论 | 来源 |
| --- | --- | --- |
| 默认值 | true（自 stable 3.16 起） | api.flutter.dev/flutter/material/ThemeData/useMaterial3.html；docs.flutter.dev/release/breaking-changes/material-3-default（Timeline: stable 3.16） |
| 语义 | 文档称之为 temporary flag… used to opt-out of Material 3 features；长期将被弃用并移除 M2 | 同上 |
| 抓取时是否已 @Deprecated | 未见（实现行仍为 final bool useMaterial3） | 同上 |
| 官方明确 M2 归宿 | useMaterial3 flag _and_ the Material 2 implementation will eventually be removed as part of Flutter's deprecation policy | docs.flutter.dev/release/breaking-changes/material-3-migration |

对本项目：theme.dart:57 显式写了 useMaterial3: true。在 3.16+ 上这是**冗余但无害**；保留可以表达意图，但不要依赖它来「开启 M3」。

### 3.2 颜色：ColorScheme 的现代用法与已弃用角色

| API | 关键事实 | 来源 |
| --- | --- | --- |
| ColorScheme.fromSeed | required seedColor；dynamicSchemeVariant 默认 DynamicSchemeVariant.tonalSpot；brightness；几乎所有角色可单独 override（含 primaryFixed 系列） | api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html |
| ColorScheme.fromImageProvider | static Future<ColorScheme>；由 ImageProvider 派生 scheme，同样支持逐角色 override。官方迁移页原话：To generate a content-based dynamic color scheme, use the ColorScheme.fromImageProvider static method | api.flutter.dev/flutter/material/ColorScheme/fromImageProvider.html；docs.flutter.dev/release/breaking-changes/material-3-migration（Colors 段） |
| M3 角色全集（实现侧） | surfaceDim / surfaceBright / surfaceContainerLowest / Low / surfaceContainer / High / Highest；primaryFixed 系列；inverseSurface / onInverseSurface；surfaceTint；scrim | api.flutter.dev/flutter/material/ColorScheme-class.html |
| 已弃用角色 | background 与 onBackground @Deprecated(after v3.18.0-0.1.pre)；surfaceVariant @Deprecated(Use surfaceContainerHighest instead) | api.flutter.dev/flutter/material/ColorScheme-class.html |
| 弃用与替代（官方迁移页） | This update deprecates three existing color roles: background, onBackground, and surfaceVariant；background→surface、onBackground→onSurface、surfaceVariant→surfaceContainerHighest | docs.flutter.dev/release/breaking-changes/new-color-scheme-roles（stable 3.22.0） |
| surfaceTint 去化 | The default surfaceTintColor for all widgets is now null and their default background color is now based on the new tone-based surface colors；These changes help eliminate the use of widgets' surfaceTintColor | 同上 |
| token 版本更新 | tokens v6.1 已应用到 Flutter Material：onPrimaryContainer/onSecondaryContainer/onTertiaryContainer/onErrorContainer 由 Tone10 改为 Tone30；chip 边框由 outline 改为 outlineVariant | docs.flutter.dev/release/breaking-changes/material-design-3-token-update（stable 3.27） |

对本项目（事实）：颜色装配走 buildBaseColorScheme 手工枚举，**全仓无 ColorScheme.fromSeed / fromImageProvider 调用**（grep 'fromSeed|fromImageProvider|dynamic_color' 在 app/ 仅命中 0 处）。这是本项目与 M3 语义最大的结构性差距之一：手工 palette 不参与 tone 生成，无法得到 M3 的 tonal palette 关系。

### 3.3 文本：Typography 与 TextTheme

| 项 | 结论 | 来源 |
| --- | --- | --- |
| M3 排版构造器 | Typography.material2021：Creates a typography instance using Material Design 3 2021 defaults；默认 geometry 为 englishLike2021 / dense2021 / tall2021 | api.flutter.dev/flutter/material/Typography/Typography.material2021.html |
| 旧构造器仍在 | Typography.material2018（2018 defaults）、material2014 | api.flutter.dev/flutter/material/Typography/Typography.material2018.html |
| M3 下 textTheme 默认已变 | The default values for ThemeData.textTheme are updated to match the Material 3 defaults. Changes include updated font size, font weight, letter spacing, and line height | docs.flutter.dev/release/breaking-changes/material-3-migration（Typography 段） |
| 15 个 M3 名称 | displayLarge…labelSmall；旧名映射 body1/body2→bodyLarge/bodyMedium、caption→bodySmall、button→labelLarge | api.flutter.dev/flutter/material/TextTheme-class.html |
| dense/tall | Typography 的三套 geometry 用于 different scripts；dense 面向 Chinese/Japanese 等 dense scripts | api.flutter.dev/flutter/material/Typography-class.html |
| 弱证据 | ThemeData.typography 属性页只写 Defaults to a platform-appropriate typography，未写「useMaterial3 时取 material2021」 | api.flutter.dev/flutter/material/ThemeData/typography.html |

对本项目：theme.dart:65 用 fontFamily: 'MI_Sans_Regular' 覆盖全局字体，且 AppTextTokens（tokens/app_text_tokens.dart）只有 7 个字号、**没有字重/行高/letterSpacing**。M3 的 type scale 是「字号+字重+行高+字距」四元组，因此当前 token 无法表达 M3 的 type role，必须扩字段或改为直接使用 Theme.textTheme。

### 3.4 WidgetState（原 MaterialState）

| 项 | 结论 | 来源 |
| --- | --- | --- |
| 重命名 | MaterialState and its related APIs have been moved outside of the Material library and renamed to WidgetState | docs.flutter.dev/release/breaking-changes/material-state |
| 生效版本 | In stable release: 3.22.0 | 同上 |
| 所在库 | enum WidgetState 位于 widgets library（不是 material） | api.flutter.dev/flutter/widgets/WidgetState.html |
| 成员 | hovered / pressed / selected / disabled / focused / dragged / error 等，文档逐项链到 Material interaction states | 同上 |
| 解析接口 | WidgetStateProperty：Interface for classes that resolve to a value of type T based on [widget state] | api.flutter.dev/flutter/widgets/WidgetStateProperty-class.html |

对本项目：全仓 33 处使用 WidgetState（theme.dart:91-107、shared/ui/widgets/actions/ghost_button.dart:97-151、fluent_select_menu_widgets.dart:161-167、multi_select_menu.dart:334-340），**无 MaterialState 残留**。即这一轮迁移成本已付清，M3 重构应继续用 WidgetState/WidgetStateProperty 表达交互色。

### 3.5 ThemeExtension

| 项 | 结论 | 来源 |
| --- | --- | --- |
| 官方定位 | abstract ThemeExtension<T extends ThemeExtension<T>>；subclass ThemeExtension, define a number of fields, and implement the copyWith and lerp methods | api.flutter.dev/flutter/material/ThemeExtension-class.html |
| 挂载 | ThemeData.extensions: Iterable<ThemeExtension>（ThemeData 构造参数） | api.flutter.dev/flutter/material/ThemeData-class.html |
| 官方样例 | material.ThemeExtension.1 | api.flutter.dev/flutter/material/ThemeExtension-class.html |

对本项目：ADR-0028 已把 ThemeExtension 定为 token 主骨架（四个 extension 挂 theme.dart:85），这与 Flutter 官方机制一致，**不需要换机制**；需要换的是 extension 内部字段的语义（见 §6）。

### 3.6 组件覆盖：Flutter 已提供的 M3 组件与 API 要点

引入版本号除少数外**未能从官方文档确认**（本报告不给未确认的版本数字，见 §8）。

| 组件 | 存在 | 抓到的 API 要点（［实现］） |
| --- | --- | --- |
| NavigationBar | 是 | 文档原话 Creates a Material 3 Navigation Bar component；参数 animationDuration / selectedIndex=0 / destinations / indicatorColor / indicatorShape / height / labelBehavior / overlayColor / labelTextStyle / labelPadding / maintainBottomViewPadding；切换时 fade out/in 旧新页面 |
| NavigationRail | 是 | extended=false、leading / trailing、minWidth / minExtendedWidth、useIndicator、indicatorColor / indicatorShape、labelType、leadingAtTop=true、trailingAtBottom=false、scrollable、mainAxisAlignment |
| NavigationDrawer | 是 | Material Design Navigation Drawer component；NavigationDrawerDestination 被特判分组；onDestinationSelected；NavigationDrawerThemeData |
| SearchAnchor / SearchBar | 是 | SearchAnchor 管理 search view route；the search view only shows full screen on mobile platforms；SearchBar 形似 TextField，点击唤起 search view |
| MenuAnchor / MenuBar / SubmenuButton | 是 | MenuAnchor 定位 submenu 的矩形，slightly lower level interface than MenuBar；MenuBar 管理 cascading child menus |
| SegmentedButton | 是 | ButtonSegment + Set 选中语义；multiSelectionEnabled 可放宽单选；可逐段启用/禁用；视觉受 ButtonStyle 控制 |
| DropdownMenu | 是 | 以 TextField 作 anchor；enableFilter=false、enableSearch=true、requestFocusOnTap、selectOnly、closeBehavior=DropdownMenuCloseBehavior.all、maxLines=1、expandedInsets、filterCallback/searchCallback、menuHeight |
| CarouselView | 是 | CarouselView 与 CarouselView.weighted（itemExtent / flexWeights 控制主次卡宽）；不支持在无界高度内直接嵌套 |
| FilledButton / .tonal | 是 | A Material Design filled button；默认样式 FilledButton.defaultStyleOf；tonal 为变体 |
| Badge | 是 | label 为 null 时是 smallSize 直径圆点（small badge），否则是 StadiumBorder 形状的 large badge |
| BottomSheet | 是 | showModalBottomSheet 的 isScrollControlled 默认 false；有 showDragHandle；文档显式引用 The Material 3 spec at m3.material.io/components/bottom-sheets/overview |
| SliverAppBar.medium / .large | 是 | 迁移页描述 M3 medium/large app bar 用 headline 表现，滚动时用 surfaceTint 而非投影分隔 |
| TabBar（primary / secondary） | 是 | 迁移页：现在有两类 TabBar，secondary tabs 用于内容区内再分层；新增 TabBar.tabAlignment |

### 3.7 动效与转场

| 项 | 结论 | 来源 |
| --- | --- | --- |
| M3 motion 的官方说法 | Material 3 improves motion by using easing and duration tokens；Material 2 curves 被重命名带 legacy 前缀并最终弃用 | docs.flutter.dev/release/breaking-changes/material-3-default（Background 段） |
| 官方跟踪 issue | 该页 Relevant issues 列 Add support for M3 motion（flutter/flutter#129942） | 同上 |
| 默认页面转场（3.38） | 由 ZoomPageTransitionsBuilder 改为 FadeForwardsPageTransitionsBuilder；API 文档亦称 FadeForwards 为 default page transition | flutter.dev/blog/whats-new-in-flutter-3-38；api.flutter.dev/flutter/material/PageTransitionsTheme-class.html |
| 本项目覆盖 | pageTransitionsTheme 显式把 android 设为 FadeUpwardsPageTransitionsBuilder（Flutter 的旧 M2 转场，而非 3.38 默认的 FadeForwards）、桌面设为 DesktopFadeThroughPageTransitionsBuilder——后者是**项目自带类**，定义在 app/lib/shared/ui/motion/desktop_page_transition.dart:128（fade-through，kDesktopPageTransitionDuration = 280ms，:5），符合 ADR-0027 的 motion 层归属 | app/lib/shared/ui/theme/theme.dart:76-84 |

### 3.8 密度、触达尺寸与 splash

| 项 | 结论 | 来源 |
| --- | --- | --- |
| 默认密度随平台变 | mobile（Android/iOS/Fuchsia）用 VisualDensity.standard，desktop（macOS/Windows/Linux）用 VisualDensity.compact | api.flutter.dev/flutter/material/VisualDensity-class.html |
| 最小交互尺寸 | const double kMinInteractiveDimension = 48.0（Material 的最小可交互区域） | api.flutter.dev/flutter/material/kMinInteractiveDimension-constant.html |
| NoSplash 语义 | An InteractiveInkFeature that doesn't paint a splash；用于 defeat the default ink splash drawn by an InkWell or ButtonStyle | api.flutter.dev/flutter/material/NoSplash-class.html |

对本项目：theme.dart:62 splashFactory: NoSplash.splashFactory + :63 highlightColor: Colors.transparent + :64 visualDensity: VisualDensity.adaptivePlatformDensity，等于在桌面端同时关掉了 M3 的按下反馈（ink/state layer）并缩小了控件密度——这与 M3 的 interaction state 模型正面冲突（§5.6）。

### 3.9 动态取色的平台范围（dynamic color）

| 项 | 结论 | 来源 |
| --- | --- | --- |
| Android 动态取色起始版本 | Dynamic Color, which was added in Android 12（即 API 31 起） | developer.android.com/develop/ui/views/theming/dynamic-colors |
| Flutter 核心提供的替代 | ColorScheme.fromSeed（seed 派生）与 ColorScheme.fromImageProvider（图片派生），两者都是 Flutter 框架 API，跨平台 | api.flutter.dev 两页 + material-3-migration |
| dynamic_color 包 | 社区包（fluttercommunity/dynamic_color），**不是 Flutter 官方**；本仓库未依赖（pubspec.yaml 无该依赖）。本次 pub.dev 抓取失败，其平台支持矩阵未能从官方渠道确认 | pub.dev/packages/dynamic_color（抓取失败）；app/pubspec.yaml |
| Windows/Linux 桌面 | 未找到 Flutter 官方或 M3 官方关于桌面系统动态取色的说明；Android 设计文档只描述壁纸取色这一 Android 机制 | 检索 developer.android.com dynamic-colors 与 api.flutter.dev 未见桌面路径 |

结论（对本项目，多平台桌面为主）：**不应把 dynamic color 作为设计系统的必要条件**；可选项只有 ColorScheme.fromImageProvider（用封面图/品牌图生成）与 fromSeed（品牌色），二者都能在 Windows/Linux 上工作。

## 4. 规范 vs 实现：Flutter 未提供或行为不同的 M3 特性

逐条给证据。凡「规范要求」但本次拿不到 m3.material.io 正文的，只写实现侧缺口，不臆造规范数值。

### 4.1 ［Expressive］整套 M3 Expressive 尚未进入 Flutter

| 证据 | 内容 |
| --- | --- |
| flutter/flutter#168813（标题 Bring Material 3 Expressive to Flutter，状态 Open，页面显示 opened May 14, 2025） | we are not actively developing Material 3 Expressive right now, and we will not be accepting contributions for these features at this time；All new work for Material 3 Expressive will happen in the new packages once established in flutter/packages |
| 同一 issue 说明的机制 | Material/Cupertino 正被拆成独立 package（与 3.38 blog 的 Decoupling Material and Cupertino 一致），Expressive 会在新 package 里做 |
| Android 侧对照（developer.android.com/jetpack/androidx/releases/compose-material3，1.4.0 段） | 已有 MaterialTheme.motionScheme（并移除 LocalMotionScheme）、expressive TimePicker、Flexible TopAppBar 家族、ButtonGroup、ToggleButtons、SearchBarState 等提升为 stable；MaterialShapes / LoadingIndicator 的 stable 提升在同段记录中被 revert |

判定：**Expressive 的组件与 motion API 在 Flutter 侧目前没有官方落地路径**，本项目不应把 Expressive 组件写进设计系统基线；如需 expressive 观感，只能在既有 M3 widget 上用自建 shape/motion 近似，并在文档中标注非官方。

### 4.2 shape morph / MaterialShapes：Flutter 无对应 API（弱证据）

| 证据 | 内容 |
| --- | --- |
| api.flutter.dev/flutter/material/MaterialShapes-class.html | 返回 Page Not Found（404）；同站同类 API 均以 X-class.html 命名，故判定 Flutter material 库无 MaterialShapes |
| Compose 侧 | MaterialShapes 出现在 compose-material3 1.4.0 release notes（见 §4.1），说明该能力在 Android 侧已有实现 |

### 4.3 motion token / spring：Flutter 只有 duration+curve，没有 M3 motion scheme

- Flutter 侧可用的动效原语是 Duration + Curve（项目 AppMotionTokens 即 durationFast 180ms / durationMedium 200ms / Curves.easeOutCubic，tokens/app_motion_tokens.dart）。
- 官方把 M3 motion 的实现列为 tracked issue（Add support for M3 motion，flutter/flutter#129942，出现在 material-3-default 页的 Relevant issues），说明 M3 motion 在 Flutter 中**不是已完成能力**。
- Compose 侧已有 MotionScheme（MaterialTheme.motionScheme）与 expressive 动效（compose-material3 1.4.0 release notes），Flutter 无等价物。

### 4.4 surfaceTint 与 elevation 的表达方式已变（3.22 起）

- 官方：The default surfaceTintColor for all widgets is now null and their default background color is now based on the new tone-based surface colors；These changes help eliminate the use of widgets' surfaceTintColor（docs.flutter.dev/release/breaking-changes/new-color-scheme-roles）。
- 早期 M3 迁移指南仍把 surfaceTint 描述为 elevation 指示（api 页：A color used as an overlay on a surface color to indicate a component's elevation；实现 Color get surfaceTint => _surfaceTint ?? primary）。**两者是不同阶段的行为**：前者是 3.22+ 现状，后者是 3.16 时代的表述。写设计系统时应以 tone-based surface 分层（surface / surfaceContainerLow…Highest）表达层级，而不是靠 tint 叠加。
- 对本项目：theme.dart:113 把 AppBarTheme.surfaceTintColor 设为透明、:115 scrolledUnderElevation 0.0，即**主动放弃**了 M3 的滚动层级提示；而 color palette 仍保留 surfaceTint 字段（app_color_scheme.dart:57、:164；dark 值 0xFF1E1E1E）。迁移时应决定：要么恢复 tone-based surface 表达层级，要么在文档中明确「本项目不做 elevation tint」，不要两套并存。

### 4.5 默认密度/触达尺寸与 M3 无障碍要求冲突

- 事实：VisualDensity.adaptivePlatformDensity 在桌面返回 compact（api 页原文），而 Material 最小交互区域是 kMinInteractiveDimension = 48.0（api 页实现）。
- 结果：本项目在 Windows/Linux/macOS 上控件密度低于 48dp 触达基线，且这是 ThemeData 级别（theme.dart:64）的全局设置。
- **未确认项**：M3 规范页对触达尺寸/HIG 的原文表述未能取得（m3.material.io 抽取失败），本文只据 Flutter 官方 API 文档下结论。

### 4.6 splash 被全局关闭 → M3 交互状态（state layer）缺失

- Flutter：splashFactory: NoSplash.splashFactory 会 defeat the default ink splash（api.flutter.dev/flutter/material/NoSplash-class.html）；本项目 theme.dart:62 全局采用，并把 highlightColor 设为透明（:63）。
- 影响：M3 的 pressed/hover 反馈主要靠 state layer；关掉 splash 后只能靠自建 hover/active 色（项目确实自建了 hoverBackground/sidebarItemHover 等，见 HentaiColorScheme）。迁移时应把这类字段明确建模为 state layer 并统一透明度来源，而不是散落在 56 个字段里。
- **未能从官方文档确认**：M3 state layer 的官方透明度数值（m3.material.io/styles/color/state-layers 抓取失败）。

### 4.7 组件默认尺寸/规格与规范数值不可比

- Flutter 文档只声明参数（如 NavigationBar.height、NavigationRail.minWidth / minExtendedWidth），**不给默认 dp 值**；M3 规范页又抓不到正文。因此「Flutter 默认尺寸 vs M3 规范尺寸」的逐项对比本次无法给出可信数字，标为未确认（§8）。

### 4.8 window size classes：官方分档 vs 本项目断点

| 档位 | 官方 width 阈值（［实现］developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes） | 本项目 app_layout_breakpoints.dart |
| --- | --- | --- |
| compact | width < 600dp | isCompact: w < 600（compact = 600） |
| medium | 600dp ≤ width < 840dp | isMedium: 600 ≤ w < 1024（medium = 1024） |
| expanded | 840dp ≤ width < 1200dp | isExpanded: w ≥ 1024 |
| large | 1200dp ≤ width < 1600dp | 无 |
| extra large | width ≥ 1600dp | 无 |

差异性质：本项目把 M3 的 medium+expanded **合并**成「medium（600–1024）」，且**没有 large / extra large**。官方页同时给出建议：先为 expanded 优化布局（If you have an existing layout for compact screens, first optimize your layout for the expanded width size class）。

## 5. 本项目现状盘点（只读结论）

### 5.1 app/lib/shared/ui/theme/ 文件与职责

| 文件 | 职责 | M3 迁移关注点 |
| --- | --- | --- |
| theme.dart | buildAppTheme(Brightness) 唯一装配入口（:38）；appSystemUiOverlayStyle（:24-35）；三个私有 builder：_buildScrollbarTheme（:89）、_buildAppBarThemeData（:111）、_buildNavRailThemeData（:120） | ThemeData 级设置集中在 :56-86，是迁移的主战场 |
| color/app_color_scheme.dart | AppCorePalette（26 字段）+ _baseLightPalette / _baseDarkPalette + buildBaseColorScheme(brightness) + buildAppColorScheme({brightness, palette})，逐字段枚举 ColorScheme | 未用 fromSeed；surfaceTint 仍手填（:85 light 0xFF005FB8、:113 dark 0xFF1E1E1E、:164 palette.surfaceTint） |
| color/hentai_color_scheme.dart | @TailorMixin HentaiColorScheme extends ThemeExtension，56 个 Color 字段；static const light/dark；forBrightness() | 56 字段中大量是 state layer / 边界 / 阅读器专用色，需要按 M3 角色收敛（§6.2） |
| color/app_shadow_palette.dart | AppShadowPalette（catalogCardRest / catalogCardHover / contextMenu） | M3 以 tone-based surface 表达层级，阴影体系需重新定位 |
| extensions/theme_context_extensions.dart | ThemeDesignX on ThemeData、ThemeTokensX on BuildContext（tokens / shadows / motion / hentai）；ColorScheme.hentai 已 @Deprecated | 访问语法可保留；被访问的字段要换 M3 语义 |
| tokens/app_theme_tokens.dart | 聚合 text / radius / spacing / layout；light()/dark() 都返回 shared | 可保留为聚合层 |
| tokens/app_spacing_tokens.dart | xs4 sm8 md12 lg16 xl20 + 手写 lerp | 数值为自定，**与 M3 spacing 无对应关系**（规范数值未取得） |
| tokens/app_radius_tokens.dart | xs4 sm6 md8 lg12 pill999 | 与 M3 shape scale 档位/命名不同（数值未取得，不下结论） |
| tokens/app_text_tokens.dart | 7 个字号（12/13/14/16/16/18/22），无字重/行高/字距 | 无法表达 M3 type role（§3.3） |
| tokens/app_motion_tokens.dart | durationFast 180ms、durationMedium 200ms、standardCurve = Curves.easeOutCubic | M2 时代曲线；M3 用 easing/duration token，Flutter 无官方 M3 motion API（§4.3） |
| tokens/app_layout_tokens.dart | contentHorizontalPadding 48、contentVerticalPadding 16、contentAreaPadding | 属于页面栅格，需与 window size classes 一起重写（§4.8） |
| tokens/app_shadow_tokens.dart | 7 色字段 + catalogCard({highlighted})、elevatedSurface({isDark,opacity})、dialog/toast、raisedPanel、subtleRest、pinnedHeaderShadowGradient、contextMenuPanel；fromPalette | 阴影方法里混入了「层级」语义，M3 下应拆成「层级=tone surface」「阴影=可选装饰」 |
| *.tailor.dart | theme_tailor 生成的 copyWith/lerp，提交在仓库内，由 gate-codegen-drift 校验 | 改字段后必须重新生成并过 gate |

### 5.2 buildAppTheme 的结构（theme.dart:38-87，读代码后概述）

1) 先取四件东西：ColorScheme（buildBaseColorScheme）、HentaiColorScheme（forBrightness）、AppThemeTokens（light/dark）、AppShadowTokens（fromPalette）、AppMotionTokens（light/dark）——注意 tokens/motion 的 light/dark 实际都返回同一 shared 对象（tokens/app_theme_tokens.dart），即明暗差异只发生在颜色层。
2) 生成一个共享 buttonShape = RoundedRectangleBorder(radius.md)。
3) 返回 ThemeData：useMaterial3: true；colorScheme；scaffoldBackgroundColor / canvasColor = colorScheme.surface；dividerColor = outlineVariant；splashFactory = NoSplash；highlightColor = transparent；visualDensity = adaptivePlatformDensity；fontFamily = 'MI_Sans_Regular'；appBarTheme / navigationRailTheme / scrollbarTheme / filledButtonTheme / outlinedButtonTheme / inputDecorationTheme(hintMaxLines: 1)；pageTransitionsTheme（android FadeUpwards、iOS Cupertino、桌面用项目自带的 DesktopFadeThrough，定义于 shared/ui/motion/desktop_page_transition.dart:128）；extensions = [tokens, semantic, shadows, motion]。

**结构性观察：** ThemeData 只配了 6 个组件主题，其余组件（NavigationBar、SegmentedButton、DropdownMenu、SearchBar、MenuBar、Badge、TabBar、BottomSheet、Card、Chip…）全部走 Flutter 默认；同时项目自建了 75 处 Fluent 命名的 widget 承载控件外观（如 shared/ui/widgets/form/fluent_text_field.dart、overlays/dialog/*、actions/ghost_button.dart）。也就是说「M3 组件默认外观」与「自建外观」目前是两套并行体系。

### 5.3 主题装配点分散（迁移风险）

| 位置 | 事实 |
| --- | --- |
| app/lib/features/bootstrap/presentation/views/app.dart:63,70-71 | MaterialApp.router(theme: buildAppTheme(Brightness.light), darkTheme: buildAppTheme(Brightness.dark)) —— 唯一正式入口 |
| app/lib/features/read_session/presentation/views/reader_page/reader_page.dart:56,63 | 直接 buildAppTheme(Brightness.dark) 造 Theme 包裹 |
| app/lib/features/read_session/presentation/views/reader_page/widgets/reader_settings_dialog.dart:23,81 | 同上 |
| app/lib/main.dart:80,104 | bootstrap 失败/加载态用裸 MaterialApp（**无 theme**），因此这两屏用的是 Flutter 默认 M3 ThemeData，而不是本项目主题 |

含义：buildAppTheme 的任何签名/返回结构变化要做 5 处同步（app.dart、reader_page、reader_settings_dialog、两处 main.dart 若补主题），并且 main.dart 的两个裸 MaterialApp 是当前主题一致性的破口。

### 5.4 ThemeExtension 承载的类别

| Extension | 承载内容 | 类别 |
| --- | --- | --- |
| AppThemeTokens | text（AppTextTokens）/ radius / spacing / layout | 尺寸与排版 |
| HentaiColorScheme | 56 个颜色字段（state/hover、文本层级、边界、输入、图片骨架、语义色 success/warning/error、侧边栏、阅读器、右键菜单） | 颜色语义（M3 应大部分收敛为 ColorScheme 角色） |
| AppShadowTokens | 7 色 + 8 组阴影构造方法 | 层级表现（M3 用 tone surface 替代） |
| AppMotionTokens | durationFast / durationMedium / standardCurve | 动效 |

### 5.5 断点实现（全文 20 行文件）

- 文件：app/lib/shared/ui/layout/app_layout_breakpoints.dart；第 1 行注释即引用 design-system/hentai-library/MASTER.md（已失效）。
- 常量：minWindowWidth = 360、minWindowHeight = 480、compact = 600、medium = 1024；isCompact(w<600) / isMedium(600≤w<1024) / isExpanded(w≥1024)。与官方五档对比见 §4.8。

### 5.6 ADR 约束（迁移时不可越过）

| ADR | 约束要点 | 对本次迁移的含义 |
| --- | --- | --- |
| ADR-0027 | 四层 composition（Shell/Layout/Component/Feature）；shared/ui/{widgets,layout,shell,motion} 禁止 import features/；Motion 实现放 shared/ui/motion/，动效 token 仍在 theme/tokens | 换 M3 组件不得破坏分层与依赖门禁；第 64 行引用 MASTER.md 已失效 |
| ADR-0028 | theme_tailor + ThemeExtension 为骨架；color/ + tokens/ + extensions/ + buildAppTheme 唯一入口；两层颜色（ColorScheme + HentaiColorScheme）；ColorScheme.hentai @Deprecated；阴影集中 AppShadowTokens；widgetbook 在 app/widgetbook/main.dart 且 dev-only；明确「不引入整包 M3 UI Kit」「阶段一不抽 packages/design_system」 | 迁移**不应**引入第三方 M3 kit；结构可保留，只换语义；第 9、35 行引用 design-system/hentai-library 已失效 |
| ADR-0029 | design-system/hentai-library/ 三重角色；真源分层：规范文档=design-system/，可执行真值=app/lib/shared/ui/theme/ 与 shared/ui/widgets/，结构决策=docs/adr/；页面差异只写 pages/<name>.md | 新树应沿用这一分层（本文件即在 research/ 下，不属规范正文）；第 9、17、21、27、56 行引用已失效 |

## 6. 失效引用清单（design-system/hentai-library 已被清空）

design-system/ 现仅存 design-system/.gitkeep，MASTER.md 与 pages/ 均不存在，因此下列引用全部失效。

| file:line | 引用内容 | 失效原因 |
| --- | --- | --- |
| AGENTS.md:11 | Flutter UI → design-system/hentai-library/MASTER.md（+ pages/*） | 该路径不存在 |
| CONTRIBUTING.md:18 | design-system/hentai-library/（章程见 MASTER § Directory charter；ADR-0029） | 同上 |
| app/test/project_layout_test.dart:36-54 | 测试 design-system MASTER declares directory charter (ADR-0029)：:37-44 拼 design-system/hentai-library/MASTER.md、:45 断言 existsSync 为真、:47 断言含 '## Directory charter'、:48 断言含 'pages/[page-name].md'、:50-52 断言 pages 目录存在 | 文件与目录都已删除 → 该测试当前必然失败（这是 gate 级问题，不只是文档问题） |
| app/lib/shared/ui/layout/app_layout_breakpoints.dart:1 | 注释：响应式布局断点（与 design-system/hentai-library/MASTER.md 一致） | 目标文件不存在；且 §4.8 表明断点数值也与 M3 官方分档不一致 |
| docs/adr/0027-flutter-ui-shell-layout-component-layers.md:64 | References 指向 MASTER.md | 路径不存在 |
| docs/adr/0028-design-system-theme-extensions.md:9、:35 | 指向 design-system/hentai-library/ | 路径不存在 |
| docs/adr/0029-design-system-documentation-charter.md:9、:17、:21、:27、:56 | 章程本体与目录树描述 | 路径不存在 |
| app/test/shared/ui/theme/hentai_color_scheme_tokens_test.dart:51 | 测试名 spacing and radius match design-system table (sample)，断言 spacing.md=12、spacing.xl=20、radius.sm=6、radius.pill=999、contentHorizontalPadding=48 | 值仍成立（来自 token 实现），但「design-system table」已无对应文件；同文件 :38-49 断言四个 extension 非空、:69-71 断言 180ms/200ms/Curves.easeOutCubic |

补充：app/test/shared/ui/theme/ 下另有 theme 契约测试，迁移改字段会连带影响；改 token 前应先确认这些断言的归属（可执行真值是 theme/ 实现，不是文档）。

## 7. 迁移建议（只给顺序与取舍，不写实现）

### 7.1 ColorScheme/TextTheme/组件主题/ThemeExtension 的语义重构

| 现状 | M3 下的建议去向 | 依据 |
| --- | --- | --- |
| buildAppColorScheme 手工枚举 26 字段 | 改为 ColorScheme.fromSeed(seedColor: 品牌色, brightness: …) 再 copyWith 少量品牌偏移；或用 ColorScheme.fromImageProvider 从封面图派生 | 官方两 API 与迁移页推荐路径（§3.2） |
| AppCorePalette.surfaceTint 手填 | 删除该字段的「elevation 指示」含义；层级改用 surfaceContainerLowest…Highest | 3.22 起 surfaceTintColor 默认 null、改 tone-based surfaces（§4.4） |
| HentaiColorScheme 56 字段 | 分三簇收敛：(a) 直接映射 ColorScheme 角色（textPrimary→onSurface、textSecondary→onSurfaceVariant、borderSubtle/Medium/Strong→outlineVariant/outline/onSurface）；(b) 交互色改为 WidgetStateProperty 驱动的 state layer（hover/pressed/focus 统一来源）；(c) 保留真正领域专用的（reader*、win*、serializationHiatus、contextMenu*） | WidgetStateProperty 官方语义（§3.4）+ 项目 Read 场景 |
| AppTextTokens（仅字号） | 要么删掉、直接吃 Theme.textTheme（M3 material2021），要么补齐字重/行高/字距并显式对齐 M3 type role | §3.3 |
| fontFamily 'MI_Sans_Regular' | 保留（品牌要求）但必须同时提供 Typography 的 englishLike/dense 覆盖，否则中文/Roboto 混排字重与行高不可控 | Typography 三套 geometry（§3.3） |
| AppMotionTokens（180/200ms + easeOutCubic） | 保留为项目自有曲线，但改名标注「项目曲线，非 M3 motion token」；等待 Flutter 落地 M3 motion（#129942） | §4.3 |
| 组件主题只配 6 个 | 按页面用到的组件补齐 NavigationBar/NavigationRail/SegmentedButton/DropdownMenu/SearchBar/Badge/TabBar/BottomSheet/卡片与 chip 的 theme，避免散落 inline 覆盖 | §3.6 参数表 |
| splashFactory = NoSplash | 二选一：恢复默认 splash（获得 M3 state layer），或明确文档化「本项目用自绘 state 色、无 ink」并在 ThemeExtension 里只留一套 state 色 | §4.6 |

### 7.2 dynamic color 的取舍（多平台）

| 方案 | 平台可用性 | 建议 |
| --- | --- | --- |
| 系统动态取色（Android 壁纸） | 仅 Android 12+；Flutter 核心无此 API，需社区包 dynamic_color（本项目未依赖） | **不作为基线**（Windows/Linux 主场景无对应能力，会形成平台分裂） |
| ColorScheme.fromSeed | 全平台 | 作为**默认基线**：一个品牌 seed → 明暗两套 scheme |
| ColorScheme.fromImageProvider | 全平台 | 作为**可选特性**（例如按当前库封面生成主题），需在设置里可关闭，并保证对比度 |

### 7.3 分阶段落地顺序

| 阶段 | 内容 | 前置/完成判据 |
| --- | --- | --- |
| P0 清账 | 修 §6 的全部失效引用（AGENTS.md:11、CONTRIBUTING.md:18、project_layout_test.dart:36-54、app_layout_breakpoints.dart:1、ADR-0027/0028/0029 相关行、token 测试名）；同时确定 design-system/ 新树形状，让 gate 恢复绿 | gate（scripts/run-gate.sh）通过 |
| P1 底座 | 只改 theme/ 层：ColorScheme 走 fromSeed（品牌色不改观感前先做视觉对照）、补齐 Typography/TextTheme、把 visualDensity 与 48dp 触达尺寸定案、写清 splash 策略 | 现有页面外观不回归；theme 契约测试更新并绿 |
| P2 语义收敛 | HentaiColorScheme 56→N 字段分簇；建立 state layer 单一来源；surface 层级改 tone-based；AppShadowTokens 拆「层级/阴影」两种语义 | 组件不再直接引用 hover/cardHover 等零散字段 |
| P3 组件 | 按页面出现频率替换自建 Fluent 控件：选择器→SegmentedButton/DropdownMenu、搜索→SearchAnchor+SearchBar、右键菜单→MenuAnchor/MenuBar、底部导航→NavigationBar、抽屉→NavigationDrawer、侧边栏与 NavigationRail 的关系定案（desktop_sidebar.dart 是自建 256/72/36 尺寸体系，与 NavigationRail minWidth/minExtendedWidth 参数未对齐） | widgetbook 预览通过 + 页面回归 |
| P4 文档 | 以本研究的 01/02 规范篇 + 03 实现篇为输入，重写 MASTER.md 与 foundations/*、pages/*；ADR 增补一条「设计系统基准由 Fluent 2 改为 Material 3」并指向本目录 | ADR 与文档互链无死链 |

顺序理由：先动 token（P1）再动组件（P3）——组件的默认外观由 ThemeData/ColorScheme/TextTheme 决定，token 未定就改组件会反复返工；P0 必须在最前，因为 design-system/ 已清空而 gate 仍在断言旧路径。

## 8. 证据薄弱 / 与实现不一致之处（自查）

| 项 | 状态 |
| --- | --- |
| m3.material.io 全站正文 | **未取得**（三次抓取返回正文长度 0）。因此 window size class 的 dp 值、shape scale、state layer 透明度、M3 type scale 数值、Expressive 组件规格，本文均不引用其数值；window size class 改用 developer.android.com 的 Compose 官方页 |
| 各 M3 组件在 Flutter 的「引入版本号」 | **未能从官方文档确认**（除 useMaterial3=3.16、WidgetState=3.22、surface roles=3.22、tokens v6.1=3.27、3.38 转场变更外）。本文不给版本数字，避免编造 |
| Flutter M3 默认 typography 是否等于 material2021 | **证据链较弱**：迁移页说 default values for ThemeData.textTheme are updated to match the Material 3 defaults；Typography.material2021 存在且自称 M3 2021 defaults；但 ThemeData.typography 属性页只写 platform-appropriate。若要写入设计系统，建议以「实测 + 迁移页」表述，不要写成「文档明确规定」 |
| MaterialShapes 是否存在 | 以 404 作为弱证据（api.flutter.dev/flutter/material/MaterialShapes-class.html 不存在）。若需强证据应查 Flutter 源码/lib/material/，本次未做 |
| Compose 侧 MaterialShapes 稳定性 | compose-material3 1.4.0 release notes 同段既有 stable 提升、也有 Revert … promotions to stable，**状态不明**，本文不断言其为 stable |
| dynamic_color 平台矩阵 | pub.dev 抓取失败；本文只说「社区包、本项目未依赖」，不列平台清单 |
| Flutter 3.41/3.44/3.47 的 M3 相关变更 | 工程已升 3.47.8；M3 逐条差异以 `docs/engineering/research/flutter-official-upgrade-3.38-to-3.47.md` 为准，本文 §3 未逐条改写 |
| Flutter 是否把 FadeUpwardsPageTransitionsBuilder 标弃用 | 其专属文档页返回 404，但 PageTransitionsTheme 文档仍在描述它 → 只断言「仍被引用」，不断言弃用状态 |
| 「规范 vs 实现」的数值对比（组件高度/间距/圆角） | 双侧数值缺失（规范页抽取失败、Flutter 文档不给默认 dp），本文只做定性对比 |

## 9. 关键来源清单

| # | URL |
| --- | --- |
| 1 | https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html |
| 2 | https://docs.flutter.dev/release/breaking-changes/material-3-default |
| 3 | https://docs.flutter.dev/release/breaking-changes/material-3-migration |
| 4 | https://docs.flutter.dev/release/breaking-changes/material-state |
| 5 | https://docs.flutter.dev/release/breaking-changes/new-color-scheme-roles |
| 6 | https://docs.flutter.dev/release/breaking-changes/material-design-3-token-update |
| 7 | https://docs.flutter.dev/release/release-notes |
| 8 | https://flutter.dev/blog/whats-new-in-flutter-3-38 |
| 9 | https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html |
| 10 | https://api.flutter.dev/flutter/material/ColorScheme/fromImageProvider.html |
| 11 | https://api.flutter.dev/flutter/material/ColorScheme-class.html |
| 12 | https://api.flutter.dev/flutter/material/ColorScheme/surfaceTint.html |
| 13 | https://api.flutter.dev/flutter/material/Typography-class.html |
| 14 | https://api.flutter.dev/flutter/material/Typography/Typography.material2021.html |
| 15 | https://api.flutter.dev/flutter/material/TextTheme-class.html |
| 16 | https://api.flutter.dev/flutter/widgets/WidgetState.html |
| 17 | https://api.flutter.dev/flutter/widgets/WidgetStateProperty-class.html |
| 18 | https://api.flutter.dev/flutter/material/ThemeExtension-class.html |
| 19 | https://api.flutter.dev/flutter/material/ThemeData-class.html |
| 20 | https://api.flutter.dev/flutter/material/PageTransitionsTheme-class.html |
| 21 | https://api.flutter.dev/flutter/material/VisualDensity-class.html |
| 22 | https://api.flutter.dev/flutter/material/kMinInteractiveDimension-constant.html |
| 23 | https://api.flutter.dev/flutter/material/NoSplash-class.html |
| 24 | https://api.flutter.dev/flutter/material/NavigationBar-class.html |
| 25 | https://api.flutter.dev/flutter/material/NavigationRail-class.html |
| 26 | https://api.flutter.dev/flutter/material/NavigationDrawer-class.html |
| 27 | https://api.flutter.dev/flutter/material/SearchAnchor-class.html |
| 28 | https://api.flutter.dev/flutter/material/SearchBar-class.html |
| 29 | https://api.flutter.dev/flutter/material/MenuAnchor-class.html |
| 30 | https://api.flutter.dev/flutter/material/MenuBar-class.html |
| 31 | https://api.flutter.dev/flutter/material/SegmentedButton-class.html |
| 32 | https://api.flutter.dev/flutter/material/DropdownMenu-class.html |
| 33 | https://api.flutter.dev/flutter/material/CarouselView-class.html |
| 34 | https://api.flutter.dev/flutter/material/FilledButton-class.html |
| 35 | https://api.flutter.dev/flutter/material/Badge-class.html |
| 36 | https://api.flutter.dev/flutter/material/showModalBottomSheet.html |
| 37 | https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes |
| 38 | https://developer.android.com/develop/ui/views/theming/dynamic-colors |
| 39 | https://developer.android.com/jetpack/androidx/releases/compose-material3 |
| 40 | https://github.com/flutter/flutter/issues/168813 |
| 41 | https://github.com/flutter/flutter/issues/129942 |
| 42 | https://github.com/flutter/flutter/issues/91605 |

（40–42 为官方 issue/仓库引用，本文只转述页面可见的标题与状态，不引用评论细节。）

## 10. 与本项目相关的一页速查

| 场景 | 结论 |
| --- | --- |
| 要不要保留 useMaterial3: true | 可以保留（表达意图），但它不再是开关；3.16 起默认 true |
| 能不能用 M3 Expressive | Flutter 侧不能（#168813 明确不接贡献、不做），Compose 侧才有；不要写进基线 |
| 能不能做动态取色 | 桌面不能（无系统 API）；用 fromSeed 作默认、fromImageProvider 作可选 |
| 56 字段 HentaiColorScheme 要全保留吗 | 不要；只留领域专用，其余映射到 ColorScheme 角色与 WidgetStateProperty |
| 断点要改吗 | 要；官方五档 600/840/1200/1600，本项目 600/1024 且缺 large/xlarge |
| 阴影还要不要 | 层级用 tone-based surface 表达；阴影作为可选装饰保留（catalogCardHover 一类仍有用） |
| 主题改哪里 | 只改 buildAppTheme 及其输入；注意 reader_page.dart:56,63、reader_settings_dialog.dart:23,81 与 main.dart:80,104 的分散装配 |
