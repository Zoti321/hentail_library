import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';

/// Library 漫画/系列 Tab 共用的页码状态机与分页 fetch 骨架。
class CatalogPaginationEngine {
  int _pageIndex = 1;
  Object? _lastQueryKey;

  int get pageIndex => _pageIndex;

  /// query 变更时重置到第 1 页；返回页码是否发生变化。
  bool syncQueryKey(Object queryKey) {
    final bool queryChanged =
        _lastQueryKey != null && _lastQueryKey != queryKey;
    _lastQueryKey = queryKey;
    if (queryChanged && _pageIndex != 1) {
      _pageIndex = 1;
      return true;
    }
    return false;
  }

  bool setPage(int page) {
    if (page < 1 || page == _pageIndex) {
      return false;
    }
    _pageIndex = page;
    return true;
  }

  bool goToFirstPage() {
    if (_pageIndex == 1) {
      return false;
    }
    _pageIndex = 1;
    return true;
  }

  bool goToLastPage(int totalPages) {
    if (totalPages <= 0 || _pageIndex == totalPages) {
      return false;
    }
    _pageIndex = totalPages;
    return true;
  }

  bool goToPreviousPage() {
    if (_pageIndex <= 1) {
      return false;
    }
    _pageIndex -= 1;
    return true;
  }

  bool goToNextPage(int totalPages) {
    if (totalPages <= 0 || _pageIndex >= totalPages) {
      return false;
    }
    _pageIndex += 1;
    return true;
  }

  bool refresh() {
    _lastQueryKey = null;
    if (_pageIndex == 1) {
      return false;
    }
    _pageIndex = 1;
    return true;
  }

  Future<PagedResult<T>> fetchPage<T>({
    required int pageSize,
    required Future<PagedResult<T>> Function(PageRequest request) fetch,
  }) async {
    final PagedResult<T> result = await fetch(
      pageRequest(page: _pageIndex, pageSize: pageSize),
    );
    if (result.page != _pageIndex) {
      _pageIndex = result.page;
    }
    return result;
  }
}
