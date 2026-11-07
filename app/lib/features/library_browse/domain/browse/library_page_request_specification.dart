import 'package:hentai_library/shared/domain/exceptions/domain_exception.dart';

/// 库浏览筛选相关的领域规则违反。
final class LibraryBrowseException extends DomainException {
  const LibraryBrowseException._(super.message, {super.code});

  factory LibraryBrowseException.invalidPageRequest({
    required int page,
    required int pageSize,
  }) {
    return LibraryBrowseException._(
      '分页参数无效：page=$page pageSize=$pageSize（均须 ≥ 1）',
      code: 'library_browse.invalid_page_request',
    );
  }
}

/// 分页请求规约（与 [PageRequest] 对齐）。
abstract final class LibraryPageRequestSpecification {
  LibraryPageRequestSpecification._();

  static void assertValid({required int page, required int pageSize}) {
    if (page < 1 || pageSize < 1) {
      throw LibraryBrowseException.invalidPageRequest(
        page: page,
        pageSize: pageSize,
      );
    }
  }
}
