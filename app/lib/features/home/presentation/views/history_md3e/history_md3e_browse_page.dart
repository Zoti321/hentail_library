import 'package:flutter/material.dart';
import 'package:hentai_library/features/home/presentation/views/history_md3e/history_md3e_browse_entry.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_browse_content.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_page_header.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_time_grouping.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_pinned_header_delegate.dart';

/// 生产阅读历史页壳层：粘滞页头 + 正文（Lab 仍用 [Md3eHistoryBrowsePage]）。
class HistoryMd3eBrowsePage extends StatefulWidget {
  const HistoryMd3eBrowsePage({
    super.key,
    required this.entries,
    required this.totalCount,
    required this.itemBuilder,
    this.onClearAll,
    this.onOpenNavigation,
    this.scrollController,
    this.clock,
    this.searchField,
    this.emptyMessage,
    this.isLoadingMore = false,
  });

  final List<HistoryMd3eBrowseEntry> entries;
  final int totalCount;
  final Widget Function(
    BuildContext context,
    HistoryMd3eBrowseEntry entry,
  ) itemBuilder;
  final VoidCallback? onClearAll;
  final VoidCallback? onOpenNavigation;
  final ScrollController? scrollController;
  final DateTime? clock;
  final Widget? searchField;
  final String? emptyMessage;
  final bool isLoadingMore;

  @override
  State<HistoryMd3eBrowsePage> createState() => _HistoryMd3eBrowsePageState();
}

class _HistoryMd3eBrowsePageState extends State<HistoryMd3eBrowsePage> {
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
  void didUpdateWidget(covariant HistoryMd3eBrowsePage oldWidget) {
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

    final List<Md3eHistoryTimeGroup<HistoryMd3eBrowseEntry>> groups =
        groupHistoryByTimeSection<HistoryMd3eBrowseEntry>(
          widget.entries,
          (HistoryMd3eBrowseEntry entry) => entry.lastReadTime,
          clock: widget.clock,
        );

    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: Md3eHistoryPageHeader(
          clearEnabled: widget.totalCount > 0,
          onClearAll: widget.onClearAll,
          onOpenNavigation: widget.onOpenNavigation,
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
            child: Md3eHistoryBrowseContent<HistoryMd3eBrowseEntry>(
              totalCount: widget.totalCount,
              groups: groups,
              searchField: widget.searchField,
              emptyMessage: widget.emptyMessage,
              itemBuilder: widget.itemBuilder,
            ),
          ),
        ),
        if (widget.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}
