import 'package:hentai_library/shared/domain/exceptions/domain_exception.dart';

/// Read session 规则违反（领域异常）。
final class ReadSessionException extends DomainException {
  const ReadSessionException._(super.message, {super.code});

  factory ReadSessionException.invalidPageIndex(int pageIndex) {
    return ReadSessionException._(
      '阅读页码须为 1-based 正整数，收到 $pageIndex',
      code: 'read_session.invalid_page_index',
    );
  }

  factory ReadSessionException.pageIndexExceedsTotal({
    required int pageIndex,
    required int totalPages,
  }) {
    return ReadSessionException._(
      '页码 $pageIndex 超过总页数 $totalPages',
      code: 'read_session.page_index_exceeds_total',
    );
  }
}
