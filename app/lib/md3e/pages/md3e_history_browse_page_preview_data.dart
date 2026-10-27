import 'package:hentai_library/md3e/pages/md3e_history_browse_entry.dart';

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

  static List<Md3eHistoryBrowseEntry> sampleEntries({DateTime? clock}) {
    final DateTime now = clock ?? DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day, 14);
    return <Md3eHistoryBrowseEntry>[
      Md3eHistoryBrowseEntry(
        lastReadTime: today.subtract(const Duration(hours: 1)),
      ),
      Md3eHistoryBrowseEntry(
        lastReadTime: today.subtract(const Duration(hours: 5)),
      ),
      Md3eHistoryBrowseEntry(
        lastReadTime: today.subtract(const Duration(days: 1, hours: 2)),
      ),
      Md3eHistoryBrowseEntry(
        lastReadTime: today.subtract(const Duration(days: 3)),
      ),
      Md3eHistoryBrowseEntry(
        lastReadTime: today.subtract(const Duration(days: 4)),
      ),
      Md3eHistoryBrowseEntry(
        lastReadTime: today.subtract(const Duration(days: 14)),
      ),
    ];
  }
}
