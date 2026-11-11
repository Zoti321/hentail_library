import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/reading_history/presentation/models/history_card_item.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/history_list_progress.dart';
import 'package:hentai_library/shared/di/app_navigator_provider.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/reader_launch_providers.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item.dart';

/// 生产 `/history` 列表行：打开阅读器 + 删除记录。
class HistoryListItem extends ConsumerWidget {
  const HistoryListItem({
    super.key,
    required this.item,
    required this.onDeleteRecord,
    this.gridIndex,
    this.coverViewportScope,
  });

  final HistoryCardItem item;
  final VoidCallback onDeleteRecord;
  final int? gridIndex;
  final String? coverViewportScope;

  void _openComicDetail(WidgetRef ref) {
    ref.read(comicDetailReturnSeriesPortProvider).clear();
    ref.read(appNavigatorProvider).pushComicDetail(item.comicId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final int currentPage = historyListCurrentPage(item.pageIndex);
    final int totalPages = historyListTotalPages(
      pageCount: item.pageCount,
      currentPage: currentPage,
    );
    void openReader() {
      ref.read(readerLaunchPortProvider).openComic(comicId: item.comicId);
    }

    return ReadingHistoryListItem(
      title: item.title,
      cover: ComicCoverContent(
        comicId: item.comicId,
        gridIndex: gridIndex,
        coverViewportScope: coverViewportScope,
      ),
      currentPage: currentPage,
      totalPages: totalPages,
      lastReadTime: item.lastReadTime,
      onTap: openReader,
      onContinueReading: openReader,
      moreMenuEntries: <ReadingHistoryMoreMenuEntry>[
        ReadingHistoryMoreMenuEntry(
          label: l10n.historyGoToComicDetail,
          onSelected: () => _openComicDetail(ref),
        ),
        ReadingHistoryMoreMenuEntry(
          label: l10n.historyDeleteRecord,
          onSelected: onDeleteRecord,
        ),
      ],
    );
  }
}
