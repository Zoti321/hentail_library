import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_list_detail_adaptive_layout.dart';
import 'package:hentai_library/md3e/layout/md3e_settings_page_metrics.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
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
  });

  final Md3eSettingsCategory initialCategory;
  final String? masterGroupTitle;
  final Md3eSettingsLabState labState;
  final ValueChanged<Md3eSettingsLabState>? onLabStateChanged;

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

  void _onBack(BuildContext context, {required bool wide}) {
    if (!wide && _showingNarrowDetail) {
      setState(() => _showingNarrowDetail = false);
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(windowWidth);
    final AppLocalizations l10n = context.l10n;
    final double horizontalPadding =
        Md3eSettingsPageMetrics.contentHorizontalPadding(sizeClass);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Builder(
            builder: (BuildContext context) {
              final bool headerWide = Md3eSettingsPageMetrics.useListDetail(
                windowWidth,
              );
              final Md3eSettingsCategoryInfo selectedInfo =
                  kMd3eSettingsCategories.firstWhere(
                    (Md3eSettingsCategoryInfo e) => e.category == _selected,
                  );
              final String? headerTitle =
                  (!headerWide && _showingNarrowDetail)
                  ? selectedInfo.label(l10n)
                  : null;
              return Md3eSettingsPageHeader(
                title: headerTitle,
                onBack: () => _onBack(context, wide: headerWide),
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
      const Duration(milliseconds: 220),
    );

    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        reverseDuration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[...previousChildren, ?currentChild],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool isIncoming = child.key == ValueKey<bool>(showingDetail);
          final Offset begin = isIncoming
              ? (showingDetail
                    ? const Offset(0.12, 0)
                    : const Offset(-0.08, 0))
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
