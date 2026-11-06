import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/list_detail_adaptive_layout.dart';
import 'package:hentai_library/shared/ui/layout/settings_page_metrics.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/motion/spring_curve.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_detail_panes.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_master_menu.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_page_header.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_detail_transition.dart';

export 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_detail_panes.dart';

/// 设置页 Lab：≥840 list–detail（Kazumi 风 master + 分组卡片详情）。
class SettingsLayout extends StatefulWidget {
  const SettingsLayout({
    super.key,
    this.initialCategory = SettingsCategory.personalization,
    this.masterGroupTitle,
    this.labState = const SettingsLabState(),
    this.onLabStateChanged,
    this.onBack,
    this.optionLabels = const SettingsOptionLabels(),
    this.showUnwiredTiles = true,
    this.visibleCategories,
    this.sectionsBuilder,
  });

  final SettingsCategory initialCategory;
  final String? masterGroupTitle;
  final SettingsLabState labState;
  final ValueChanged<SettingsLabState>? onLabStateChanged;

  /// 可选项文案（生产 Pilot 注入 l10n；Lab 使用默认值）。
  final SettingsOptionLabels optionLabels;

  /// 为 false 时隐藏尚未接入业务的 tile。
  final bool showUnwiredTiles;

  /// 为 null 时显示全部分类；否则只显示列表中的分类。
  final Set<SettingsCategory>? visibleCategories;

  /// 为 null 时使用 Lab mock 分类内容；生产注入真实 section。
  final SettingsSectionsBuilder? sectionsBuilder;

  /// 列表页（非 list-detail）返回：由外层决定回到哪里（壳层上一目的地 / 路由）。
  final VoidCallback? onBack;

  @override
  State<SettingsLayout> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsLayout> {
  late SettingsCategory _selected = widget.initialCategory;
  late SettingsLabState _labState = widget.labState;
  bool _showingNarrowDetail = false;
  bool _detailTransitionReverse = false;

  @override
  void didUpdateWidget(covariant SettingsLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labState != widget.labState) {
      _labState = widget.labState;
    }
  }

  void _updateLabState(SettingsLabState next) {
    setState(() => _labState = next);
    widget.onLabStateChanged?.call(next);
  }

  void _selectCategory(SettingsCategory category, {required bool wide}) {
    setState(() {
      _detailTransitionReverse =
          _settingsCategoryOrderIndex(category) <
          _settingsCategoryOrderIndex(_selected);
      _selected = category;
      if (!wide) {
        _showingNarrowDetail = true;
      }
    });
  }

  int _settingsCategoryOrderIndex(SettingsCategory category) {
    final List<SettingsCategory> visible =
        widget.visibleCategories?.toList(growable: false) ??
        kSettingsCategories
            .map((SettingsCategoryInfo e) => e.category)
            .toList(growable: false);
    final int index = visible.indexOf(category);
    return index >= 0 ? index : category.index;
  }

  /// 头部返回按钮与系统返回共用：窄屏详情先回分类列表，列表页交给 [SettingsLayout.onBack] 或路由。
  void _handleBack() {
    if (_showingNarrowDetail) {
      setState(() => _showingNarrowDetail = false);
      return;
    }
    final VoidCallback? onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    // list-detail 判断使用页面实际可用宽度（壳层 pane 可能窄于整窗），与主体布局保持一致。
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return _buildPage(
          context,
          listDetailWide: SettingsPageMetrics.useListDetail(
            constraints.maxWidth,
          ),
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, {required bool listDetailWide}) {
    final AppLocalizations l10n = context.l10n;
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontalPadding = layout.horizontalInset;

    return PopScope<Object?>(
      canPop:
          listDetailWide || (!_showingNarrowDetail && widget.onBack == null),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Builder(
              builder: (BuildContext context) {
                final SettingsCategoryInfo selectedInfo = kSettingsCategories
                    .firstWhere(
                      (SettingsCategoryInfo e) => e.category == _selected,
                    );
                final String? headerTitle =
                    (!listDetailWide && _showingNarrowDetail)
                    ? selectedInfo.label(l10n)
                    : null;
                return SettingsPageHeader(
                  title: headerTitle,
                  showBack: !listDetailWide,
                  onBack: _handleBack,
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                layout.headerToBodyGap,
                horizontalPadding,
                MediaQuery.viewPaddingOf(context).bottom +
                    layout.bodyBottomInset,
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool wide = SettingsPageMetrics.useListDetail(
                    constraints.maxWidth,
                  );

                  final String masterGroupTitle =
                      widget.masterGroupTitle ??
                      l10n.settingsMasterMenuGroupTitle;
                  final Widget master = SettingsMasterMenu(
                    key: const Key('_settings_master'),
                    wide: wide,
                    selected: _selected,
                    masterGroupTitle: masterGroupTitle,
                    visibleCategories: widget.visibleCategories,
                    onSelect: (SettingsCategory category) {
                      _selectCategory(category, wide: wide);
                    },
                  );

                  final Widget detail = SettingsDetailPane(
                    key: const Key('_settings_detail'),
                    category: _selected,
                    showTitle: wide,
                    labState: _labState,
                    onLabStateChanged: _updateLabState,
                    optionLabels: widget.optionLabels,
                    showUnwiredTiles: widget.showUnwiredTiles,
                    sectionsBuilder: widget.sectionsBuilder,
                  );

                  if (wide) {
                    return ListDetailAdaptiveLayout(
                      showPaneDivider: false,
                      listPaneFixedWidth: SettingsPageMetrics.masterPaneWidth,
                      paneGap: SettingsPageMetrics.paneGap,
                      listPane: master,
                      detailPane: ListDetailDetailTransition(
                        switchKey: _selected,
                        reverse: _detailTransitionReverse,
                        child: detail,
                      ),
                    );
                  }
                  return SettingsNarrowPaneSwitcher(
                    showingDetail: _showingNarrowDetail,
                    masterList: master,
                    detailPane: detail,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Narrow master ↔ detail transition (slide + fade).
class SettingsNarrowPaneSwitcher extends StatelessWidget {
  const SettingsNarrowPaneSwitcher({
    super.key,
    required this.showingDetail,
    required this.masterList,
    required this.detailPane,
  });

  final bool showingDetail;
  final Widget masterList;
  final Widget detailPane;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return showingDetail ? detailPane : masterList;
    }

    final Duration duration = LabMotion.motionDurationOf(
      context,
      LabMotion.routeTransitionDuration,
    );
    // 与 Lab 页面转场同款 M3E expressive spatial 弹簧：进场允许轻微过冲，退场沿反向曲线收回。
    final Curve springCurve = SpringCurve(
      motion: LabMotion.routeSpring,
      duration: LabMotion.routeTransitionDuration,
    );

    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        reverseDuration: duration,
        switchInCurve: springCurve,
        switchOutCurve: springCurve.flipped,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[...previousChildren, ?currentChild],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool isIncoming = child.key == ValueKey<bool>(showingDetail);
          final Offset begin = isIncoming
              ? (showingDetail ? const Offset(0.12, 0) : const Offset(-0.08, 0))
              : (showingDetail
                    ? const Offset(-0.08, 0)
                    : const Offset(0.12, 0));
          return SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<bool>(showingDetail),
          child: showingDetail ? detailPane : masterList,
        ),
      ),
    );
  }
}
