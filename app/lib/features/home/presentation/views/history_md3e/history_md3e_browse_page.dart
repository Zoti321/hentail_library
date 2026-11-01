import 'package:flutter/material.dart';
import 'package:hentai_library/features/home/presentation/views/history_md3e/history_md3e_browse_entry.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_browse_content.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_page_header.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_time_grouping.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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
  final Widget Function(BuildContext context, HistoryMd3eBrowseEntry entry)
  itemBuilder;
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
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(covariant HistoryMd3eBrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(
      viewportWidth,
    );
    final double horizontal =
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(sizeClass);

    final List<Md3eHistoryTimeGroup<HistoryMd3eBrowseEntry>> groups =
        groupHistoryByTimeSection<HistoryMd3eBrowseEntry>(
          widget.entries,
          (HistoryMd3eBrowseEntry entry) => entry.lastReadTime,
          clock: widget.clock,
        );

    final Widget header = Md3eHistoryPageHeader(
      clearEnabled: widget.totalCount > 0,
      onClearAll: widget.onClearAll,
      onOpenNavigation: widget.onOpenNavigation,
    );

    return ColoredBox(
      color: md3eLabBrowseCanvasColor(M3ETheme.of(context).colorScheme),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPersistentHeader(
            pinned: true,
            delegate: Md3ePageHeaderDelegate(
              pageHorizontal: horizontal,
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
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  }
}
