import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/reading_history/presentation/models/history_card_item.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/history_list_progress.dart';
import 'package:hentai_library/shared/di/read_session_launch_providers.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item.dart';

/// 生产 `/history` 列表行：打开阅读器 + 删除记录。
class HistoryListItem extends ConsumerWidget {
  const HistoryListItem({
    super.key,
    required this.item,
    required this.onDeleteRecord,
  });

  final HistoryCardItem item;
  final VoidCallback onDeleteRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final int currentPage = historyListCurrentPage(item.pageIndex);
    final int totalPages = historyListTotalPages(
      pageCount: item.pageCount,
      currentPage: currentPage,
    );
    void openReader() {
      ref.read(readSessionLaunchPortProvider).openComic(comicId: item.comicId);
    }

    return ReadingHistoryListItem(
      title: item.title,
      cover: ComicCoverContent(comicId: item.comicId),
      currentPage: currentPage,
      totalPages: totalPages,
      lastReadTime: item.lastReadTime,
      onTap: openReader,
      onContinueReading: openReader,
      moreMenuEntries: <ReadingHistoryMoreMenuEntry>[
        ReadingHistoryMoreMenuEntry(
          label: l10n.historyDeleteRecord,
          onSelected: onDeleteRecord,
        ),
      ],
    );
  }
}
