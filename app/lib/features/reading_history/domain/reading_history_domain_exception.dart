import 'package:hentai_library/shared/domain/exceptions/domain_rule_violation.dart';

/// 阅读历史限界上下文内的业务规则违反。
final class ReadingHistoryDomainException extends DomainRuleViolation {
  const ReadingHistoryDomainException._(super.message, {super.code});

  factory ReadingHistoryDomainException.emptyComicId() {
    return const ReadingHistoryDomainException._(
      '漫画标识不能为空',
      code: 'reading_history.empty_comic_id',
    );
  }

  factory ReadingHistoryDomainException.emptyTitle() {
    return const ReadingHistoryDomainException._(
      '历史标题不能为空',
      code: 'reading_history.empty_title',
    );
  }

  factory ReadingHistoryDomainException.invalidPageIndex(int pageIndex) {
    return ReadingHistoryDomainException._(
      '页码须为 1-based 正整数，收到 $pageIndex',
      code: 'reading_history.invalid_page_index',
    );
  }

  factory ReadingHistoryDomainException.pageIndexExceedsCount({
    required int pageIndex,
    required int pageCount,
  }) {
    return ReadingHistoryDomainException._(
      '页码 $pageIndex 超过总页数 $pageCount',
      code: 'reading_history.page_index_exceeds_count',
    );
  }
}
