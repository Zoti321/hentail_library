import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/layout/md3e_reading_history_list_layout.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_page_header.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_record_summary.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_pinned_header_delegate.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读历史页 Lab 壳层：粘滞页头 + 记录摘要 + 响应式历史列表。
class Md3eHistoryBrowsePage extends StatefulWidget {
  const Md3eHistoryBrowsePage({
    super.key,
    required this.totalCount,
    required this.itemCount,
    required this.itemBuilder,
    this.onClearAll,
    this.scrollController,
  });

  final int totalCount;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback? onClearAll;
  final ScrollController? scrollController;

  @override
  State<Md3eHistoryBrowsePage> createState() => _Md3eHistoryBrowsePageState();
}

class _Md3eHistoryBrowsePageState extends State<Md3eHistoryBrowsePage> {
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
  void didUpdateWidget(covariant Md3eHistoryBrowsePage oldWidget) {
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
        child: Md3eHistoryPageHeader(
          clearEnabled: widget.totalCount > 0,
          onClearAll: widget.onClearAll,
        ),
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
            Md3eLibraryBrowsePageMetrics.scrollBottomInset(sizeClass),
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Md3eHistoryRecordSummary(totalCount: widget.totalCount),
                SizedBox(
                  height: Md3eLibraryBrowsePageMetrics.catalogBodyTopSpacing(
                    sizeClass,
                  ),
                ),
                if (widget.itemCount == 0)
                  _Md3eHistoryEmptyBody()
                else
                  Md3eReadingHistoryListLayout(
                    itemCount: widget.itemCount,
                    itemBuilder: widget.itemBuilder,
                    horizontalInset: 0,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Md3eHistoryEmptyBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.xl),
      child: Center(
        child: Text(
          context.l10n.historyEmpty,
          style: theme.typeScale.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Widgetbook / 预览用示例标题。
abstract final class Md3eHistoryBrowsePagePreviewData {
  static const List<String> sampleTitles = <String>[
    '只有神知道的世界',
    '葬送的芙莉莲',
    '迷宫饭',
    '彻夜之歌',
    '药屋少女的呢喃',
    '孤独摇滚',
  ];
}
