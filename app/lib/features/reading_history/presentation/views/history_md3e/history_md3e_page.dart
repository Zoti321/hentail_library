import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/reading_history/presentation/models/history_card_item.dart';
import 'package:hentai_library/features/reading_history/presentation/view_models/history_load_more_throttle.dart';
import 'package:hentai_library/features/reading_history/presentation/view_models/history_paged_feed_controller.dart';
import 'package:hentai_library/features/reading_history/presentation/view_models/history_paged_feed_state.dart';
import 'package:hentai_library/features/reading_history/presentation/views/history_md3e/history_md3e_actions.dart';
import 'package:hentai_library/features/reading_history/presentation/views/history_md3e/history_md3e_browse_entry.dart';
import 'package:hentai_library/features/reading_history/presentation/views/history_md3e/history_md3e_browse_page.dart';
import 'package:hentai_library/features/reading_history/presentation/views/history_md3e/history_md3e_list_item.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double _kHistoryLoadMoreThreshold = 400;

/// 生产 `/history`：把 [HistoryPagedFeedController] 接到 MD3E 阅读历史 browse。
class HistoryMd3ePage extends ConsumerStatefulWidget {
  const HistoryMd3ePage({super.key});

  @override
  ConsumerState<HistoryMd3ePage> createState() => _HistoryMd3ePageState();
}

class _HistoryMd3ePageState extends ConsumerState<HistoryMd3ePage> {
  DateTime? _lastLoadMoreAttemptAt;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }
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
    final AsyncValue<HistoryPagedFeedState> feedAsync = ref.watch(
      historyPagedFeedControllerProvider,
    );

    return M3ETheme(
      data: md3eWithAppFontFamily(M3ETheme.of(context)),
      child: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace stackTrace) => Center(
          child: Text(
            context.l10n.shellLoadFailed,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        data: (HistoryPagedFeedState feed) {
          final List<HistoryMd3eBrowseEntry> entries = feed.items
              .map((HistoryCardItem item) => HistoryMd3eBrowseEntry(item: item))
              .toList(growable: false);

          return NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: HistoryMd3eBrowsePage(
              entries: entries,
              totalCount: feed.totalCount,
              isLoadingMore: feed.isLoadingMore,
              onOpenNavigation: appShellPageNavigationOpener(context),
              onClearAll: () => clearAllReadingHistory(context, ref),
              itemBuilder:
                  (BuildContext context, HistoryMd3eBrowseEntry entry) {
                    return HistoryMd3eListItem(
                      entry: entry,
                      onDeleteRecord: () => deleteReadingHistoryRecord(
                        context: context,
                        ref: ref,
                        comicId: entry.item.comicId,
                      ),
                    );
                  },
            ),
          );
        },
      ),
    );
  }
}
