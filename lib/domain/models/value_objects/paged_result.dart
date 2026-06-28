/// 分页查询结果。
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages {
    if (totalCount <= 0) {
      return 0;
    }
    return (totalCount + pageSize - 1) ~/ pageSize;
  }

  bool get hasPreviousPage => page > 1;

  bool get hasNextPage => totalPages > 0 && page < totalPages;
}
