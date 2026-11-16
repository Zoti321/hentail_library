import 'package:flutter/foundation.dart';
import 'package:hentai_library/features/reading_history/presentation/models/history_card_item.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item.dart';

/// Widgetbook / 预览用阅读历史示例数据。
abstract final class Md3eHistoryBrowsePagePreviewData {
  static const List<String> sampleTitles = <String>[
    '只有神知道的世界',
    '葬送的芙莉莲',
    '迷宫饭',
    '彻夜之歌',
    '药屋少女的呢喃',
    '孤独摇滚',
  ];

  static List<ReadingHistoryMoreMenuEntry> sampleMoreMenuEntries({
    VoidCallback? onDeleteRecord,
  }) {
    return <ReadingHistoryMoreMenuEntry>[
      ReadingHistoryMoreMenuEntry(label: '删除记录', onSelected: onDeleteRecord),
      const ReadingHistoryMoreMenuEntry(label: '在资源管理器中显示'),
    ];
  }

  static List<HistoryCardItem> sampleItems({DateTime? clock}) {
    final DateTime now = clock ?? DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day, 14);
    final List<DateTime> times = <DateTime>[
      today.subtract(const Duration(hours: 1)),
      today.subtract(const Duration(hours: 5)),
      today.subtract(const Duration(days: 1, hours: 2)),
      today.subtract(const Duration(days: 3)),
      today.subtract(const Duration(days: 4)),
      today.subtract(const Duration(days: 14)),
    ];
    return List<HistoryCardItem>.generate(times.length, (int index) {
      final String id = 'preview-$index';
      return historyCardItem(
        id: id,
        title: sampleTitles[index % sampleTitles.length],
        lastReadTime: times[index],
        coverComicId: id,
        comicId: id,
        pageIndex: 12 + index,
      );
    }, growable: false);
  }
}
