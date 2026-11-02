import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/reading_history/presentation/models/history_card_item.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/history_list_item_cover.dart';
import 'package:hentai_library/shared/di/read_session_launch_providers.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item.dart';

int _historyListCurrentPage(int? pageIndex) {
  if (pageIndex == null || pageIndex <= 0) {
    return 1;
  }
  return pageIndex;
}

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
    final int currentPage = _historyListCurrentPage(item.pageIndex);
    void openReader() {
      ref
          .read(readSessionLaunchPortProvider)
          .openComic(comicId: item.comicId);
    }

    return Md3eReadingHistoryListItem(
      title: item.title,
      cover: HistoryListItemCover(comicId: item.comicId),
      currentPage: currentPage,
      totalPages: currentPage,
      lastReadTime: item.lastReadTime,
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
