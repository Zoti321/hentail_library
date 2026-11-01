import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/patterns/md3e_management_catalog_toolbar.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/patterns/md3e_management_create_interaction.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/patterns/md3e_management_facet_chip_wrap.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/patterns/md3e_management_create_entity_dialog.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/patterns/md3e_management_draft_entity_chip.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/patterns/md3e_management_page_header.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/management_create_entity_fab.dart';

/// 管理页 Lab 壳层：粘滞标题 + 胶囊维度条 + 流式 chip 列表。
class Md3eManagementBrowsePage extends StatefulWidget {
  const Md3eManagementBrowsePage({
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
  final Md3eManagementCreateInteraction? createInteractionOverride;
  final String? title;
  final ScrollController? scrollController;

  @override
  State<Md3eManagementBrowsePage> createState() =>
      _Md3eManagementBrowsePageState();
}

class _Md3eManagementBrowsePageState extends State<Md3eManagementBrowsePage> {
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
  void didUpdateWidget(covariant Md3eManagementBrowsePage oldWidget) {
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
    showMd3eManagementCreateEntityDialog(
      context: context,
      facet: widget.facet,
      onCreate: _handleEntityCreated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(
      viewportWidth,
    );
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final double horizontal = layout.horizontalInset;

    final Md3eManagementCreateInteraction interaction =
        md3eManagementCreateInteractionOf(
          context,
          override: widget.createInteractionOverride,
        );
    final bool useMobileCreateDialog =
        interaction == Md3eManagementCreateInteraction.mobileDialog;
    final bool createEnabled = widget.onEntityCreated != null;
    final bool showFab = createEnabled;
    final bool showInlineCreate =
        createEnabled && !useMobileCreateDialog && _showInlineCreateField;

    final Widget header = Md3eManagementPageHeader(title: widget.title);

    final double scrollBottomPadding = createEnabled
        ? Md3eLibraryBrowsePageMetrics.scrollBottomInset(sizeClass)
        : layout.headerToBodyGap;

    return Stack(
      children: <Widget>[
        CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: Md3ePageHeaderDelegate(
                layout: layout,
                child: header,
              ),
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
                    Md3eManagementCatalogToolbar(
                      facet: widget.facet,
                      facetCount: widget.facetCount,
                      onFacetChanged: widget.onFacetChanged,
                    ),
                    SizedBox(
                      height:
                          Md3eLibraryBrowsePageMetrics.catalogToolbarToViewModeSpacing(
                            sizeClass,
                          ),
                    ),
                    Md3eManagementFacetChipWrap(
                      labels: widget.chipLabels,
                      onLabelPressed: widget.onChipPressed,
                      trailing: showInlineCreate
                          ? Md3eManagementDraftEntityChip(
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
        Md3eManagementCreateEntityFab(
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
abstract final class Md3eManagementBrowsePagePreviewData {
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
