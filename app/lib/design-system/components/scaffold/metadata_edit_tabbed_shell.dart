import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/components/list_detail/list_detail_detail_transition.dart';
import 'package:hentai_library/design-system/components/list_detail/list_detail_nav_item.dart';
import 'package:hentai_library/design-system/components/scaffold/metadata_edit_form_scroll.dart';
import 'package:hentai_library/design-system/components/selection/segmented_capsule_bar.dart';
import 'package:hentai_library/design-system/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/design-system/layout/breakpoints.dart';

/// 元数据编辑 Tab：label 由调用方从 l10n 取，本壳不取任何业务文案。
typedef MetadataEditTab = ({String label, Widget body});

/// 元数据编辑 Tab 外壳：宽屏侧栏列表 / 窄屏顶部分段条 + 详情切换过渡。
///
/// 调用方只持有「当前选中索引」；切换方向（[ListDetailDetailTransition.reverse]）
/// 由本壳按新旧索引自行推导。
class MetadataEditTabbedShell extends StatefulWidget {
  const MetadataEditTabbedShell({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<MetadataEditTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<MetadataEditTabbedShell> createState() => _MetadataEditTabbedShellState();
}

class _MetadataEditTabbedShellState extends State<MetadataEditTabbedShell> {
  bool _reverse = false;

  @override
  void didUpdateWidget(covariant MetadataEditTabbedShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _reverse = widget.selectedIndex < oldWidget.selectedIndex;
    }
  }

  void _select(int index) {
    if (index == widget.selectedIndex) {
      return;
    }
    setState(() => _reverse = index < widget.selectedIndex);
    widget.onSelected(index);
  }

  Widget _scrollPane(Widget child) {
    return ScrollConfiguration(
      behavior: MetadataEditScrollBehavior(),
      child: SingleChildScrollView(primary: false, child: child),
    );
  }

  Widget _detailTransition(Widget child) {
    return ListDetailDetailTransition(
      switchKey: widget.selectedIndex,
      reverse: _reverse,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MetadataEditFormMetrics.detailContentHorizontalInset,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double gap = MetadataEditFormMetrics.sectionGap(sizeClass);
    final bool useSideTabs = sizeClass.index >= WindowSizeClass.medium.index;
    final Widget tabBody = widget.tabs[widget.selectedIndex].body;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight =
            MetadataEditFormMetrics.resolveTabbedViewportHeight(
              context,
              constraints,
            );

        if (useSideTabs) {
          return SizedBox(
            height: viewportHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: MetadataEditFormMetrics.sideTabColumnWidth,
                  child: _scrollPane(_buildSideTabs()),
                ),
                SizedBox(width: gap),
                Expanded(child: _detailTransition(_scrollPane(tabBody))),
              ],
            ),
          );
        }

        return SizedBox(
          height: viewportHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTopTabs(),
              SizedBox(height: gap),
              Expanded(child: _detailTransition(_scrollPane(tabBody))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < widget.tabs.length; index++)
          ListDetailNavItem(
            key: ValueKey<int>(index),
            label: widget.tabs[index].label,
            selected: widget.selectedIndex == index,
            onTap: () => _select(index),
          ),
      ],
    );
  }

  Widget _buildTopTabs() {
    return SegmentedCapsuleBar(
      segments: <SegmentedCapsuleSegment>[
        for (final MetadataEditTab tab in widget.tabs)
          SegmentedCapsuleSegment(label: tab.label),
      ],
      selectedIndex: widget.selectedIndex,
      onSelected: _select,
    );
  }
}
