class LibraryPagination {
  const LibraryPagination({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.isLoading,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final bool isLoading;
}

/// 兼容旧分页类型名。
typedef LibraryComicsPagination = LibraryPagination;
