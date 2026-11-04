import 'package:hentai_library/shared/domain/exceptions/domain_rule_violation.dart';

/// 库浏览筛选相关的领域规则违反。
final class LibraryBrowseDomainException extends DomainRuleViolation {
  const LibraryBrowseDomainException._(super.message, {super.code});

  factory LibraryBrowseDomainException.invalidPageRequest({
    required int page,
    required int pageSize,
  }) {
    return LibraryBrowseDomainException._(
      '分页参数无效：page=$page pageSize=$pageSize（均须 ≥ 1）',
      code: 'library_browse.invalid_page_request',
    );
  }
}

/// 分页请求规约（与 [PageRequest] 对齐）。
void assertValidLibraryPageRequest({required int page, required int pageSize}) {
  if (page < 1 || pageSize < 1) {
    throw LibraryBrowseDomainException.invalidPageRequest(
      page: page,
      pageSize: pageSize,
    );
  }
}
