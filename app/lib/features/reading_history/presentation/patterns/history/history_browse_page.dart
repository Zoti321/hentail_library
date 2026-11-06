import 'package:flutter/material.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_browse_content.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_page_header.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_time_grouping.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_header.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读历史 browse 壳：粘滞页头 + 分桶列表（生产 / Widgetbook 共用）。
class HistoryBrowsePage<T> extends StatefulWidget {
  const HistoryBrowsePage({
    super.key,
    required this.items,
    required this.totalCount,
    required this.lastReadTimeOf,
    required this.itemBuilder,
    this.onClearAll,
    this.onOpenNavigation,
    this.onBack,
    this.scrollController,
    this.clock,
    this.searchField,
    this.emptyMessage,
    this.isLoadingMore = false,
    this.useLabBrowseCanvas = false,
  });

  final List<T> items;
  final int totalCount;
  final DateTime Function(T item) lastReadTimeOf;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback? onClearAll;
  final VoidCallback? onOpenNavigation;
  final VoidCallback? onBack;
  final ScrollController? scrollController;
  final DateTime? clock;
  final Widget? searchField;
  final String? emptyMessage;
  final bool isLoadingMore;

  /// 生产 `/history` 使用 lab browse 画布色；Widgetbook 预览可设为 false。
  final bool useLabBrowseCanvas;

  @override
  State<HistoryBrowsePage<T>> createState() => _HistoryBrowsePageState<T>();
}

class _HistoryBrowsePageState<T> extends State<HistoryBrowsePage<T>> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;
  List<HistoryTimeGroup<T>>? _cachedGroups;
  List<T>? _cachedGroupSourceItems;
  DateTime? _cachedGroupClock;

  List<HistoryTimeGroup<T>> _resolveGroups() {
    if (identical(_cachedGroupSourceItems, widget.items) &&
        _cachedGroupClock == widget.clock &&
        _cachedGroups != null) {
      return _cachedGroups!;
    }
    _cachedGroupSourceItems = widget.items;
    _cachedGroupClock = widget.clock;
    _cachedGroups = groupHistoryByTimeSection<T>(
      widget.items,
      widget.lastReadTimeOf,
      clock: widget.clock,
    );
    return _cachedGroups!;
  }

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
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
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontal = layout.horizontalInset;

    final List<HistoryTimeGroup<T>> groups = _resolveGroups();

    final Widget header = HistoryPageHeader(
      clearEnabled: widget.totalCount > 0,
      onClearAll: widget.onClearAll,
      onOpenNavigation: widget.onOpenNavigation,
      onBack: widget.onBack,
    );

    final Widget scrollView = CustomScrollView(
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
            layout.bodyBottomInset,
          ),
          sliver: HistoryBrowseContent<T>(
            totalCount: widget.totalCount,
            groups: groups,
            searchField: widget.searchField,
            emptyMessage: widget.emptyMessage,
            itemBuilder: widget.itemBuilder,
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
    );

    if (!widget.useLabBrowseCanvas) {
      return scrollView;
    }

    return ColoredBox(
      color: labBrowseCanvasColor(M3ETheme.of(context).colorScheme),
      child: scrollView,
    );
  }
}
