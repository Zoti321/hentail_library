import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/md3e_management_catalog_toolbar.dart';
import 'package:hentai_library/md3e/patterns/md3e_management_facet_chip_wrap.dart';
import 'package:hentai_library/md3e/patterns/md3e_management_named_facet.dart';
import 'package:hentai_library/md3e/patterns/md3e_management_page_header.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_pinned_header_delegate.dart';

/// 管理页 Lab 壳层：粘滞标题 + 胶囊维度条 + 流式 chip 列表。
class Md3eManagementBrowsePage extends StatefulWidget {
  const Md3eManagementBrowsePage({
    super.key,
    required this.facet,
    required this.facetCount,
    required this.chipLabels,
    required this.onFacetChanged,
    this.onChipPressed,
    this.title = '管理',
    this.scrollController,
  });

  final Md3eManagementNamedFacet facet;
  final int facetCount;
  final List<String> chipLabels;
  final ValueChanged<Md3eManagementNamedFacet> onFacetChanged;
  final ValueChanged<String>? onChipPressed;
  final String title;
  final ScrollController? scrollController;

  @override
  State<Md3eManagementBrowsePage> createState() =>
      _Md3eManagementBrowsePageState();
}

class _Md3eManagementBrowsePageState extends State<Md3eManagementBrowsePage> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;
  double? _headerExtent;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void didUpdateWidget(covariant Md3eManagementBrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _measureHeaderExtent(Duration _) {
    final RenderBox? box =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) {
      return;
    }
    final double height = box.size.height;
    if (_headerExtent != height) {
      setState(() => _headerExtent = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(viewportWidth);
    final double horizontal =
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(sizeClass);

    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: Md3eManagementPageHeader(title: widget.title),
      ),
    );

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        if (_headerExtent == null)
          SliverToBoxAdapter(child: header)
        else
          SliverPersistentHeader(
            pinned: true,
            delegate: Md3eLibraryPinnedHeaderDelegate(
              extent: _headerExtent!,
              child: header,
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            Md3eLibraryBrowsePageMetrics.catalogToolbarTopSpacing(sizeClass),
            horizontal,
            Md3eLibraryBrowsePageMetrics.catalogBodyTopSpacing(sizeClass),
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
                  height: Md3eLibraryBrowsePageMetrics
                      .catalogToolbarToViewModeSpacing(sizeClass),
                ),
                Md3eManagementFacetChipWrap(
                  labels: widget.chipLabels,
                  onLabelPressed: widget.onChipPressed,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Widgetbook / 预览用各维度示例数据。
abstract final class Md3eManagementBrowsePagePreviewData {
  static const Map<Md3eManagementNamedFacet, List<String>> sampleLabels =
      <Md3eManagementNamedFacet, List<String>>{
        Md3eManagementNamedFacet.authors: <String>[
          '村上水军',
          '比村兵長',
          '紺野アサラ',
          'みちきんぐ',
        ],
        Md3eManagementNamedFacet.parodies: <String>[
          '艦隊これくしょん',
          'Fate/Grand Order',
          '原神',
        ],
        Md3eManagementNamedFacet.characters: <String>[
          '島風',
          'マシュ',
          '雷電将軍',
          '甘雨',
          '胡桃',
        ],
        Md3eManagementNamedFacet.tags: <String>[
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

  static int sampleCountFor(Md3eManagementNamedFacet facet) {
    return sampleLabels[facet]?.length ?? 0;
  }

  static List<String> sampleChipsFor(Md3eManagementNamedFacet facet) {
    return List<String>.of(sampleLabels[facet] ?? const <String>[]);
  }
}
