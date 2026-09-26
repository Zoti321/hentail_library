/// 手动导出元数据时的 UI 选项（gzip 在 Dart 层处理，FRB 仅传 JSON 字节）。
class MetadataExportOptions {
  const MetadataExportOptions({
    this.gzip = true,
    this.includeOrphanFacets = false,
    this.currentLibraryOnly = false,
    this.libraryId,
  });

  final bool gzip;
  final bool includeOrphanFacets;
  final bool currentLibraryOnly;
  final String? libraryId;
}
