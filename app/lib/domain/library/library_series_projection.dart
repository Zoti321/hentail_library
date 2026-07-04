import 'package:hentai_library/domain/library/library_comic_projection.dart';

/// 库页系列列表筛选条件（与 Rust [SeriesFilterDto] 对齐）。
class LibrarySeriesFilter {
  const LibrarySeriesFilter({
    required this.showR18,
    this.query,
    this.requireItems = true,
  });

  final bool showR18;
  final String? query;
  final bool requireItems;
}

/// 库页系列列表投影：intent 与健康模式 → [LibrarySeriesFilter]。
class LibrarySeriesProjection {
  const LibrarySeriesProjection();

  bool showR18({required bool isHealthyMode}) =>
      const LibraryComicProjection().showR18(isHealthyMode: isHealthyMode);

  LibrarySeriesFilter buildListFilter({
    required bool isHealthyMode,
    String? keyword,
  }) {
    final String? query = keyword?.trim().isEmpty ?? true
        ? null
        : keyword!.trim();
    return LibrarySeriesFilter(
      showR18: showR18(isHealthyMode: isHealthyMode),
      query: query,
      requireItems: true,
    );
  }
}
