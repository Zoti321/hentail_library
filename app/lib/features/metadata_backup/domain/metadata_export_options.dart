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

  /// 单库导出时必须指定 [libraryId]。
  bool get isValid =>
      !currentLibraryOnly ||
      (libraryId != null && libraryId!.trim().isNotEmpty);

  MetadataExportOptions normalized() {
    if (!currentLibraryOnly) {
      return this;
    }
    final String? id = libraryId?.trim();
    return MetadataExportOptions(
      gzip: gzip,
      includeOrphanFacets: includeOrphanFacets,
      currentLibraryOnly: true,
      libraryId: id,
    );
  }
}
