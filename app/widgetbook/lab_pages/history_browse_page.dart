import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';

import 'history_browse_entry.dart';

import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_browse_content.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_page_header.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_time_grouping.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';

export 'history_browse_entry.dart';

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
  final Widget Function(BuildContext context, Md3eHistoryBrowseEntry entry)
  itemBuilder;
  final VoidCallback? onClearAll;
  final ScrollController? scrollController;

  /// 分桶参照时间（测试 / Widgetbook 可注入）。
  final DateTime? clock;

  int get totalCount => entries.length;

  @override
  State<Md3eHistoryBrowsePage> createState() => _Md3eHistoryBrowsePageState();
}

class _Md3eHistoryBrowsePageState extends State<Md3eHistoryBrowsePage> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(covariant Md3eHistoryBrowsePage oldWidget) {
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
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final double horizontal = layout.horizontalInset;

    final List<Md3eHistoryTimeGroup<Md3eHistoryBrowseEntry>> groups =
        groupHistoryByTimeSection<Md3eHistoryBrowseEntry>(
          widget.entries,
          (Md3eHistoryBrowseEntry entry) => entry.lastReadTime,
          clock: widget.clock,
        );

    final Widget header = Md3eHistoryPageHeader(
      clearEnabled: widget.totalCount > 0,
      onClearAll: widget.onClearAll,
    );

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: Md3ePageHeaderDelegate(layout: layout, child: header),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            layout.headerToBodyGap,
            horizontal,
            layout.bodyBottomInset,
          ),
          sliver: Md3eHistoryBrowseContent<Md3eHistoryBrowseEntry>(
            totalCount: widget.totalCount,
            groups: groups,
            itemBuilder: widget.itemBuilder,
          ),
        ),
      ],
    );
  }
}
