import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/home/presentation/views/history_md3e/history_md3e_browse_entry.dart';
import 'package:hentai_library/features/home/presentation/views/history_md3e/history_md3e_list_item_cover.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item.dart';
import 'package:hentai_library/shared/di/read_session_launch_providers.dart';

int historyMd3eCurrentPage(int? pageIndex) {
  if (pageIndex == null || pageIndex <= 0) {
    return 1;
  }
  return pageIndex;
}

int historyMd3eTotalPages(int? pageIndex) {
  return historyMd3eCurrentPage(pageIndex);
}

class HistoryMd3eListItem extends ConsumerWidget {
  const HistoryMd3eListItem({
    super.key,
    required this.entry,
    required this.onDeleteRecord,
  });

  final HistoryMd3eBrowseEntry entry;
  final VoidCallback onDeleteRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final int currentPage = historyMd3eCurrentPage(entry.item.pageIndex);
    final int totalPages = historyMd3eTotalPages(entry.item.pageIndex);
    void openReader() {
      ref
          .read(readSessionLaunchPortProvider)
          .openComic(comicId: entry.item.comicId);
    }

    return Md3eReadingHistoryListItem(
      title: entry.item.title,
      cover: HistoryMd3eListItemCover(comicId: entry.item.comicId),
      currentPage: currentPage,
      totalPages: totalPages,
      lastReadTime: entry.item.lastReadTime,
      onTap: openReader,
      onContinueReading: openReader,
      moreMenuEntries: <Md3eReadingHistoryMoreMenuEntry>[
        Md3eReadingHistoryMoreMenuEntry(
          label: l10n.historyDeleteRecord,
          onSelected: onDeleteRecord,
        ),
      ],
    );
  }
}
