/// 阅读进度持久化后的领域事件（不含传输层类型）。
///
/// 订阅方可在应用层桥接为 Riverpod / Stream，本文件仅定义语义。
sealed class ReadingHistoryDomainEvent {
  const ReadingHistoryDomainEvent();
}

/// 某本漫画的阅读进度快照已更新（upsert）。
final class ReadingHistoryProgressRecorded extends ReadingHistoryDomainEvent {
  const ReadingHistoryProgressRecorded({
    required this.comicId,
    required this.pageIndex,
    required this.lastReadTime,
  });

  final String comicId;

  /// 1-based；与仓储契约一致。
  final int pageIndex;
  final DateTime lastReadTime;
}
