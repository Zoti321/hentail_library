import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_events.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_exceptions.dart';

part 'reading_history.freezed.dart';

/// 阅读历史聚合根（按 [comicId] 唯一标识一条进度快照）。
///
/// 写入路径应通过 [ReadingHistory.recordSessionProgress] 构造，以集中校验。
@freezed
abstract class ReadingHistory with _$ReadingHistory {
  factory ReadingHistory({
    required String comicId,
    required String title,
    required DateTime lastReadTime,
    int? pageIndex,
    int? pageCount,
  }) = _ReadingHistory;

  const ReadingHistory._();

  /// 阅读会话落库：校验不变式并返回待持久化快照与领域事件。
  static ({ReadingHistory snapshot, ReadingHistoryProgressRecorded event})
  recordSessionProgress({
    required String comicId,
    required String title,
    required DateTime lastReadTime,
    required int pageIndex,
    int? pageCount,
  }) {
    final String id = comicId.trim();
    if (id.isEmpty) {
      throw ReadingHistoryException.emptyComicId();
    }
    final String snapshotTitle = title.trim();
    if (snapshotTitle.isEmpty) {
      throw ReadingHistoryException.emptyTitle();
    }
    if (pageIndex < 1) {
      throw ReadingHistoryException.invalidPageIndex(pageIndex);
    }
    if (pageCount != null && pageCount > 0 && pageIndex > pageCount) {
      throw ReadingHistoryException.pageIndexExceedsCount(
        pageIndex: pageIndex,
        pageCount: pageCount,
      );
    }

    final ReadingHistory snapshot = ReadingHistory(
      comicId: id,
      title: snapshotTitle,
      lastReadTime: lastReadTime,
      pageIndex: pageIndex,
      pageCount: pageCount,
    );
    final ReadingHistoryProgressRecorded event = ReadingHistoryProgressRecorded(
      comicId: id,
      pageIndex: pageIndex,
      lastReadTime: lastReadTime,
    );
    return (snapshot: snapshot, event: event);
  }

  /// 封面/列表进度条比例；缺少页码或总页数时返回 null。
  double? get readProgressRatio {
    final int? index = pageIndex;
    final int? total = pageCount;
    if (index == null || total == null || total <= 0) {
      return null;
    }
    if (index < 1) {
      return null;
    }
    return (index / total).clamp(0.0, 1.0);
  }

  bool get hasResumePage => pageIndex != null && pageIndex! >= 1;
}
