import 'package:hentai_library/shared/domain/exceptions/domain_exception.dart';

final class ReadSessionRuleException extends DomainException {
  const ReadSessionRuleException._(super.message, {super.code});

  factory ReadSessionRuleException.invalidPageIndex(int pageIndex) {
    return ReadSessionRuleException._(
      '阅读页码须为 1-based 正整数，收到 $pageIndex',
      code: 'read_session.invalid_page_index',
    );
  }

  factory ReadSessionRuleException.pageIndexExceedsTotal({
    required int pageIndex,
    required int totalPages,
  }) {
    return ReadSessionRuleException._(
      '页码 $pageIndex 超过总页数 $totalPages',
      code: 'read_session.page_index_exceeds_total',
    );
  }
}
