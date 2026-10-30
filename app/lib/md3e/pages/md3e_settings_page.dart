import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_list_detail_adaptive_layout.dart';
import 'package:hentai_library/md3e/layout/md3e_settings_page_metrics.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_curve.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_catalog.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_detail_panes.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_master_menu.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_page_header.dart';

export 'package:hentai_library/md3e/patterns/settings/md3e_settings_detail_panes.dart';

/// 设置页 Lab：≥840 list–detail（Kazumi 风 master + 分组卡片详情）。
class Md3eSettingsPage extends StatefulWidget {
  const Md3eSettingsPage({
    super.key,
    this.initialCategory = Md3eSettingsCategory.personalization,
    this.masterGroupTitle = '应用',
    this.labState = const Md3eSettingsLabState(),
    this.onLabStateChanged,
    this.onBack,
  });

  final Md3eSettingsCategory initialCategory;
  final String? masterGroupTitle;
  final Md3eSettingsLabState labState;
  final ValueChanged<Md3eSettingsLabState>? onLabStateChanged;

  /// 列表页（非 list-detail）返回：由外层决定回到哪里（壳层上一目的地 / 路由）。
  final VoidCallback? onBack;

  @override
  State<Md3eSettingsPage> createState() => _Md3eSettingsPageState();
}

class _Md3eSettingsPageState extends State<Md3eSettingsPage> {
  late Md3eSettingsCategory _selected = widget.initialCategory;
  late Md3eSettingsLabState _labState = widget.labState;
  bool _showingNarrowDetail = false;

  @override
  void didUpdateWidget(covariant Md3eSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labState != widget.labState) {
      _labState = widget.labState;
    }
  }

  void _updateLabState(Md3eSettingsLabState next) {
    setState(() => _labState = next);
    widget.onLabStateChanged?.call(next);
  }

  void _selectCategory(Md3eSettingsCategory category, {required bool wide}) {
    setState(() {
      _selected = category;
      if (!wide) {
        _showingNarrowDetail = true;
      }
    });
  }

  /// 头部返回按钮与系统返回共用：窄屏详情先回分类列表，列表页交给 [Md3eSettingsPage.onBack] 或路由。
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
          listDetailWide: Md3eSettingsPageMetrics.useListDetail(
            constraints.maxWidth,
          ),
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, {required bool listDetailWide}) {
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(
      windowWidth,
    );
    final AppLocalizations l10n = context.l10n;
    final double horizontalPadding =
        Md3eSettingsPageMetrics.contentHorizontalPadding(sizeClass);

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
                final Md3eSettingsCategoryInfo selectedInfo =
                    kMd3eSettingsCategories.firstWhere(
                      (Md3eSettingsCategoryInfo e) => e.category == _selected,
                    );
                final String? headerTitle =
                    (!listDetailWide && _showingNarrowDetail)
                    ? selectedInfo.label(l10n)
                    : null;
                return Md3eSettingsPageHeader(
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
                0,
                horizontalPadding,
                MediaQuery.viewPaddingOf(context).bottom + 16,
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool wide = Md3eSettingsPageMetrics.useListDetail(
                    constraints.maxWidth,
                  );

                  final Widget master = Md3eSettingsMasterMenu(
                    key: const Key('md3e_settings_master'),
                    wide: wide,
                    selected: _selected,
                    masterGroupTitle: widget.masterGroupTitle,
                    onSelect: (Md3eSettingsCategory category) {
                      _selectCategory(category, wide: wide);
                    },
                  );

                  final Widget detail = Md3eSettingsDetailPane(
                    key: const Key('md3e_settings_detail'),
                    category: _selected,
                    showTitle: wide,
                    labState: _labState,
                    onLabStateChanged: _updateLabState,
                  );

                  if (wide) {
                    return Md3eListDetailAdaptiveLayout(
                      showPaneDivider: false,
                      listPaneFixedWidth:
                          Md3eSettingsPageMetrics.masterPaneWidth,
                      paneGap: Md3eSettingsPageMetrics.paneGap,
                      listPane: master,
                      detailPane: detail,
                    );
                  }
                  return Md3eSettingsNarrowPaneSwitcher(
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
class Md3eSettingsNarrowPaneSwitcher extends StatelessWidget {
  const Md3eSettingsNarrowPaneSwitcher({
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

    final Duration duration = Md3eMotion.motionDurationOf(
      context,
      Md3eMotion.routeTransitionDuration,
    );
    // 与 Lab 页面转场同款 M3E expressive spatial 弹簧：进场允许轻微过冲，退场沿反向曲线收回。
    final Curve springCurve = Md3eSpringCurve(
      motion: Md3eMotion.routeSpring,
      duration: Md3eMotion.routeTransitionDuration,
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
