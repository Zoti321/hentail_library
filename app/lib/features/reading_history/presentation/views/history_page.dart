import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/reading_history/presentation/models/history_card_item.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_browse_page.dart';
import 'package:hentai_library/features/reading_history/presentation/view_models/history_load_more_throttle.dart';
import 'package:hentai_library/features/reading_history/presentation/view_models/history_paged_feed_controller.dart';
import 'package:hentai_library/features/reading_history/presentation/view_models/history_paged_feed_state.dart';
import 'package:hentai_library/features/reading_history/presentation/views/history_page_actions.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/history_list_item.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double _kHistoryLoadMoreThreshold = 400;

/// 生产路由 `/history`：分页 feed + browse 壳。
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  DateTime? _lastLoadMoreAttemptAt;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) {
      return false;
    }
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= 0) {
      return false;
    }
    final bool nearBottom =
        metrics.pixels >= metrics.maxScrollExtent - _kHistoryLoadMoreThreshold;
    if (!nearBottom) {
      return false;
    }
    final DateTime now = DateTime.now();
    if (!shouldAttemptHistoryLoadMore(
      lastAttemptAt: _lastLoadMoreAttemptAt,
      now: now,
    )) {
      return false;
    }
    _lastLoadMoreAttemptAt = now;
    ref.read(historyPagedFeedControllerProvider.notifier).loadMore();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool initialLoading = ref.watch(
      historyPagedFeedControllerProvider.select(
        (AsyncValue<HistoryPagedFeedState> async) =>
            async.isLoading && !async.hasValue,
      ),
    );
    final Object? loadError = ref.watch(
      historyPagedFeedControllerProvider.select(
        (AsyncValue<HistoryPagedFeedState> async) =>
            async.hasError ? async.error : null,
      ),
    );

    return M3ETheme(
      data: md3eWithAppFontFamily(M3ETheme.of(context)),
      child: initialLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? Center(
              child: Text(
                context.l10n.shellLoadFailed,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: const _HistoryBrowseFeed(),
            ),
    );
  }
}

/// 仅订阅列表与分页 UI 相关字段，避免 `isLoadingMore` 触发整页 rebuild。
class _HistoryBrowseFeed extends ConsumerWidget {
  const _HistoryBrowseFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<HistoryCardItem> items = ref.watch(
      historyPagedFeedControllerProvider.select(
        (AsyncValue<HistoryPagedFeedState> async) =>
            async.asData?.value.items ?? const <HistoryCardItem>[],
      ),
    );
    final int totalCount = ref.watch(
      historyPagedFeedControllerProvider.select(
        (AsyncValue<HistoryPagedFeedState> async) =>
            async.asData?.value.totalCount ?? 0,
      ),
    );
    final bool isLoadingMore = ref.watch(
      historyPagedFeedControllerProvider.select(
        (AsyncValue<HistoryPagedFeedState> async) =>
            async.asData?.value.isLoadingMore ?? false,
      ),
    );

    return HistoryBrowsePage<HistoryCardItem>(
      items: items,
      totalCount: totalCount,
      lastReadTimeOf: (HistoryCardItem item) => item.lastReadTime,
      isLoadingMore: isLoadingMore,
      useLabBrowseCanvas: true,
      onOpenNavigation: appShellPageNavigationOpener(context),
      onClearAll: () => clearAllReadingHistory(context, ref),
      itemBuilder: (BuildContext context, HistoryCardItem item) {
        return HistoryListItem(
          key: ValueKey<String>(item.comicId),
          item: item,
          onDeleteRecord: () => deleteReadingHistoryRecord(
            context: context,
            ref: ref,
            comicId: item.comicId,
          ),
        );
      },
    );
  }
}
