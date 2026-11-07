import 'package:flutter/material.dart';
import 'package:hentai_library/features/reading_history/presentation/models/history_card_item.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_browse_page.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../preview/md3e_history_browse_page_preview_data.dart';
import '../lab/navigation/md3e_lab_reader_navigation.dart';
import '../preview/md3e_reader_page_preview_data.dart';

/// Lab / Widgetbook：preview 阅读历史 + 清空全部（M3E 确认 → 清内存列表，不写 FRB）。
class HistoryBrowsePageLabHost extends StatefulWidget {
  const HistoryBrowsePageLabHost({
    super.key,
    this.initialItems,
    this.clock,
  });

  final List<HistoryCardItem>? initialItems;
  final DateTime? clock;

  @override
  State<HistoryBrowsePageLabHost> createState() =>
      _Md3eHistoryBrowsePageLabHostState();
}

class _Md3eHistoryBrowsePageLabHostState
    extends State<HistoryBrowsePageLabHost> {
  static const int _previewTotalPages = 48;

  late List<HistoryCardItem> _items = List<HistoryCardItem>.of(
    widget.initialItems ??
        Md3eHistoryBrowsePagePreviewData.sampleItems(clock: widget.clock),
  );

  void _clearAllPreviewEntries() {
    setState(() => _items = <HistoryCardItem>[]);
  }

  void _deletePreviewEntry(HistoryCardItem item) {
    setState(
      () => _items = List<HistoryCardItem>.of(_items)..remove(item),
    );
  }

  void _openReader(BuildContext context, HistoryCardItem item) {
    openLabReader(
      context,
      preview: ReaderPagePreviewData(
        title: item.title,
        totalPages: _previewTotalPages,
        initialPage: item.pageIndex ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return HistoryBrowsePage<HistoryCardItem>(
      items: _items,
      totalCount: _items.length,
      lastReadTimeOf: (HistoryCardItem item) => item.lastReadTime,
      clock: widget.clock,
      onClearAll: _clearAllPreviewEntries,
      itemBuilder: (BuildContext context, HistoryCardItem item) {
        void openReader() => _openReader(context, item);
        return ReadingHistoryListItem(
          title: item.title,
          currentPage: item.pageIndex ?? 1,
          totalPages: _previewTotalPages,
          lastReadTime: item.lastReadTime,
          onTap: openReader,
          onContinueReading: openReader,
          moreMenuEntries:
              Md3eHistoryBrowsePagePreviewData.sampleMoreMenuEntries(
                onDeleteRecord: () => _deletePreviewEntry(item),
              ),
          cover: ColoredBox(
            color: scheme.surfaceContainerHigh,
            child: Icon(
              Icons.image_outlined,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
