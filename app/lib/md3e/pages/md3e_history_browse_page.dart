import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_history_browse_entry.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_browse_content.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_page_header.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_time_grouping.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_pinned_header_delegate.dart';

export 'package:hentai_library/md3e/pages/md3e_history_browse_entry.dart';
export 'package:hentai_library/md3e/pages/md3e_history_browse_page_preview_data.dart';

/// 阅读历史页 Lab 壳层：粘滞页头 + [Md3eHistoryBrowseContent]。
class Md3eHistoryBrowsePage extends StatefulWidget {
  const Md3eHistoryBrowsePage({
    super.key,
    required this.entries,
    required this.itemBuilder,
    this.onClearAll,
    this.scrollController,
    this.clock,
  });

  final List<Md3eHistoryBrowseEntry> entries;
  final Widget Function(
    BuildContext context,
    Md3eHistoryBrowseEntry entry,
  ) itemBuilder;
  final VoidCallback? onClearAll;
  final ScrollController? scrollController;

  /// 分桶参照时间（测试 / Widgetbook 可注入）。
  final DateTime? clock;

  int get totalCount => entries.length;

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

    final List<Md3eHistoryTimeGroup<Md3eHistoryBrowseEntry>> groups =
        groupHistoryByTimeSection<Md3eHistoryBrowseEntry>(
          widget.entries,
          (Md3eHistoryBrowseEntry entry) => entry.lastReadTime,
          clock: widget.clock,
        );

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
            child: Md3eHistoryBrowseContent<Md3eHistoryBrowseEntry>(
              totalCount: widget.totalCount,
              groups: groups,
              itemBuilder: widget.itemBuilder,
            ),
          ),
        ),
      ],
    );
  }
}
