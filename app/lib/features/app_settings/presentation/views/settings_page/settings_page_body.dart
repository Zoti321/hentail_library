import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/settings_page_metrics.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_detail_panes.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_master_menu.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_page_header.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_narrow_pane_switcher.dart';

export 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_detail_panes.dart';
export 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_narrow_pane_switcher.dart';

/// 设置页 Lab：≥840 list–detail（Kazumi 风 master + 分组卡片详情）。
class SettingsLayout extends StatefulWidget {
  const SettingsLayout({
    super.key,
    this.initialCategory = SettingsCategory.appearance,
    this.labState = const SettingsLabState(),
    this.onLabStateChanged,
    this.onBack,
    this.optionLabels = const SettingsOptionLabels(),
    this.showUnwiredTiles = true,
    this.visibleCategories,
    this.sectionsBuilder,
  });

  final SettingsCategory initialCategory;
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

  /// 窄屏列表页的系统返回：由外层决定回到哪里（壳层上一目的地 / 路由）。
  /// 顶栏返回仅在窄屏二级详情显示；一级列表不再展示返回按钮（medium- 用底部导航）。
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
    final List<SettingsCategory> visible = settingsCategoryOrder(
      visibleCategories: widget.visibleCategories,
    );
    final int index = visible.indexOf(category);
    return index >= 0 ? index : category.index;
  }

  void _handlePopInvoked(bool didPop, Object? result) {
    if (!didPop) {
      _handleBack();
    }
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
        return _SettingsPageBody(
          host: this,
          listDetailWide: SettingsPageMetrics.useListDetail(
            constraints.maxWidth,
          ),
        );
      },
    );
  }
}

class _SettingsPageBody extends StatelessWidget {
  const _SettingsPageBody({required this.host, required this.listDetailWide});

  final _SettingsPageState host;
  final bool listDetailWide;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontalPadding = layout.horizontalInset;

    return PopScope<Object?>(
      canPop:
          listDetailWide ||
          (!host._showingNarrowDetail && host.widget.onBack == null),
      onPopInvokedWithResult: host._handlePopInvoked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Builder(
              builder: (BuildContext context) {
                final SettingsCategoryInfo selectedInfo = settingsCategoryInfo(
                  host._selected,
                );
                final String? headerTitle =
                    (!listDetailWide && host._showingNarrowDetail)
                    ? selectedInfo.label(l10n)
                    : null;
                return SettingsPageHeader(
                  title: headerTitle,
                  showBack: !listDetailWide && host._showingNarrowDetail,
                  onBack: host._handleBack,
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

                  final Widget master = SettingsMasterMenu(
                    key: const Key('_settings_master'),
                    wide: wide,
                    selected: host._selected,
                    visibleCategories: host.widget.visibleCategories,
                    onSelect: (SettingsCategory category) =>
                        host._selectCategory(category, wide: wide),
                  );

                  final Widget detail = SettingsDetailPane(
                    key: const Key('_settings_detail'),
                    category: host._selected,
                    showTitle: wide,
                    labState: host._labState,
                    onLabStateChanged: host._updateLabState,
                    optionLabels: host.widget.optionLabels,
                    showUnwiredTiles: host.widget.showUnwiredTiles,
                    sectionsBuilder: host.widget.sectionsBuilder,
                  );

                  if (wide) {
                    return ListDetailAdaptiveLayout(
                      showPaneDivider: false,
                      listPaneFixedWidth: SettingsPageMetrics.masterPaneWidth,
                      paneGap: SettingsPageMetrics.paneGap,
                      listPane: master,
                      detailPane: ListDetailDetailTransition(
                        switchKey: host._selected,
                        reverse: host._detailTransitionReverse,
                        child: detail,
                      ),
                    );
                  }
                  return SettingsNarrowPaneSwitcher(
                    showingDetail: host._showingNarrowDetail,
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
