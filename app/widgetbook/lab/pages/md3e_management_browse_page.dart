import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:hentai_library/features/named_metadata/public.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_header.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/management_create_entity_fab.dart';

/// 管理页 Lab 壳层：粘滞标题 + 胶囊维度条 + 流式 chip 列表。
class ManagementBrowsePage extends StatefulWidget {
  const ManagementBrowsePage({
    super.key,
    required this.facet,
    required this.facetCount,
    required this.chipLabels,
    required this.onFacetChanged,
    this.onChipPressed,
    this.onEntityCreated,
    this.createInteractionOverride,
    this.title,
    this.scrollController,
  });

  final ManagedNamedFacetKind facet;
  final int facetCount;
  final List<String> chipLabels;
  final ValueChanged<ManagedNamedFacetKind> onFacetChanged;
  final ValueChanged<String>? onChipPressed;
  final ValueChanged<String>? onEntityCreated;
  final ManagementCreateInteraction? createInteractionOverride;
  final String? title;
  final ScrollController? scrollController;

  @override
  State<ManagementBrowsePage> createState() =>
      _Md3eManagementBrowsePageState();
}

class _Md3eManagementBrowsePageState extends State<ManagementBrowsePage> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;
  bool _showInlineCreateField = false;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(covariant ManagementBrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.facet != widget.facet) {
      _showInlineCreateField = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _handleEntityCreated(String name) {
    widget.onEntityCreated?.call(name);
    if (_showInlineCreateField) {
      setState(() => _showInlineCreateField = false);
    }
  }

  void _onCreateFabPressed(bool useMobileCreateDialog) {
    if (!useMobileCreateDialog) {
      setState(() => _showInlineCreateField = true);
      return;
    }
    showManagementCreateEntityDialog(
      context: context,
      facet: widget.facet,
      onCreate: _handleEntityCreated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final WindowSizeClass sizeClass = WindowSizeClass.fromWidth(
      viewportWidth,
    );
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontal = layout.horizontalInset;

    final ManagementCreateInteraction interaction =
        managementCreateInteractionOf(
          context,
          override: widget.createInteractionOverride,
        );
    final bool useMobileCreateDialog =
        interaction == ManagementCreateInteraction.mobileDialog;
    final bool createEnabled = widget.onEntityCreated != null;
    final bool showFab = createEnabled;
    final bool showInlineCreate =
        createEnabled && !useMobileCreateDialog && _showInlineCreateField;

    final Widget header = ManagementPageHeader(title: widget.title);

    final double scrollBottomPadding = createEnabled
        ? LibraryBrowsePageMetrics.scrollBottomInset(sizeClass)
        : layout.headerToBodyGap;

    return Stack(
      children: <Widget>[
        CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: PageHeaderDelegate(layout: layout, child: header),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                layout.headerToBodyGap,
                horizontal,
                scrollBottomPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ManagementCatalogToolbar(
                      facet: widget.facet,
                      facetCount: widget.facetCount,
                      onFacetChanged: widget.onFacetChanged,
                    ),
                    SizedBox(
                      height:
                          LibraryBrowsePageMetrics.catalogToolbarToViewModeSpacing(
                            sizeClass,
                          ),
                    ),
                    ManagementFacetChipWrap(
                      labels: widget.chipLabels,
                      onLabelPressed: widget.onChipPressed,
                      trailing: showInlineCreate
                          ? ManagementDraftEntityChip(
                              onCommit: _handleEntityCreated,
                              onDismiss: () {
                                setState(() => _showInlineCreateField = false);
                              },
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ManagementCreateEntityFab(
          facet: widget.facet,
          horizontalPadding: horizontal,
          onPressed: () => _onCreateFabPressed(useMobileCreateDialog),
          hidden: !showFab,
        ),
      ],
    );
  }
}

/// Widgetbook / 预览用各维度示例数据。
abstract final class ManagementBrowsePagePreviewData {
  static const Map<ManagedNamedFacetKind, List<String>>
  sampleLabels = <ManagedNamedFacetKind, List<String>>{
    ManagedNamedFacetKind.author: <String>['村上水军', '比村兵長', '紺野アサラ', 'みちきんぐ'],
    ManagedNamedFacetKind.parody: <String>[
      '艦隊これくしょん',
      'Fate/Grand Order',
      '原神',
    ],
    ManagedNamedFacetKind.character: <String>['島風', 'マシュ', '雷電将軍', '甘雨', '胡桃'],
    ManagedNamedFacetKind.tag: <String>[
      '奇幻',
      '校园',
      '恋爱',
      '冒险',
      '治愈',
      '日常',
      '科幻',
      '悬疑',
      '搞笑',
      '百合',
    ],
  };

  static int sampleCountFor(ManagedNamedFacetKind facet) {
    return sampleLabels[facet]?.length ?? 0;
  }

  static List<String> sampleChipsFor(ManagedNamedFacetKind facet) {
    return List<String>.of(sampleLabels[facet] ?? const <String>[]);
  }
}
