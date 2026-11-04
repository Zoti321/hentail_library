import 'package:hentai_library/shared/domain/exceptions/domain_rule_violation.dart';

/// 阅读会话页码值对象（1-based）。
final class ReadSessionPageIndex {
  const ReadSessionPageIndex._(this.value);

  final int value;

  factory ReadSessionPageIndex.tryParse(int raw, {required int totalPages}) {
    if (raw < 1) {
      throw ReadSessionDomainException.invalidPageIndex(raw);
    }
    if (totalPages > 0 && raw > totalPages) {
      throw ReadSessionDomainException.pageIndexExceedsTotal(
        pageIndex: raw,
        totalPages: totalPages,
      );
    }
    return ReadSessionPageIndex._(raw);
  }
}

final class ReadSessionDomainException extends DomainRuleViolation {
  const ReadSessionDomainException._(super.message, {super.code});

  factory ReadSessionDomainException.invalidPageIndex(int pageIndex) {
    return ReadSessionDomainException._(
      '阅读页码须为 1-based 正整数，收到 $pageIndex',
      code: 'read_session.invalid_page_index',
    );
  }

  factory ReadSessionDomainException.pageIndexExceedsTotal({
    required int pageIndex,
    required int totalPages,
  }) {
    return ReadSessionDomainException._(
      '页码 $pageIndex 超过总页数 $totalPages',
      code: 'read_session.page_index_exceeds_total',
    );
  }
}
