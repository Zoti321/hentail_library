import 'package:hentai_library/shared/domain/exceptions/domain_exception.dart';

/// 阅读历史限界上下文内的业务规则违反。
final class ReadingHistoryException extends DomainException {
  const ReadingHistoryException._(super.message, {super.code});

  factory ReadingHistoryException.emptyComicId() {
    return const ReadingHistoryException._(
      '漫画标识不能为空',
      code: 'reading_history.empty_comic_id',
    );
  }

  factory ReadingHistoryException.emptyTitle() {
    return const ReadingHistoryException._(
      '历史标题不能为空',
      code: 'reading_history.empty_title',
    );
  }

  factory ReadingHistoryException.invalidPageIndex(int pageIndex) {
    return ReadingHistoryException._(
      '页码须为 1-based 正整数，收到 $pageIndex',
      code: 'reading_history.invalid_page_index',
    );
  }

  factory ReadingHistoryException.pageIndexExceedsCount({
    required int pageIndex,
    required int pageCount,
  }) {
    return ReadingHistoryException._(
      '页码 $pageIndex 超过总页数 $pageCount',
      code: 'reading_history.page_index_exceeds_count',
    );
  }
}
