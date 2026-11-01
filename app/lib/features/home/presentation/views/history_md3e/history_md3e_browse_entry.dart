import 'package:hentai_library/features/home/presentation/models/history_card_item.dart';

/// 生产阅读历史行数据（分桶用 [lastReadTime]）。
class HistoryMd3eBrowseEntry {
  const HistoryMd3eBrowseEntry({required this.item});

  final HistoryCardItem item;

  DateTime get lastReadTime => item.lastReadTime;
}
