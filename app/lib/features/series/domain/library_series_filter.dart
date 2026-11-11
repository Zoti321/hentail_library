/// 库页系列列表 filter（owner 规则，跨 Port 边界 DTO）。
class LibrarySeriesFilter {
  const LibrarySeriesFilter({
    required this.showR18,
    required this.r18Only,
    this.query,
    this.requireItems = true,
    this.serializationStatus,
    this.preferLibraryRootSeries = true,
    this.libraryId,
  });

  final bool showR18;
  final bool r18Only;
  final String? query;
  final bool requireItems;
  final String? serializationStatus;
  final bool preferLibraryRootSeries;
  final String? libraryId;
}
