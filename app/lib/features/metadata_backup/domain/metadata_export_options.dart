/// 手动导出元数据时的 UI 选项（gzip 在 Dart 层处理，FRB 仅传 JSON 字节）。
class MetadataExportOptions {
  const MetadataExportOptions({
    this.gzip = true,
    this.includeOrphanFacets = false,
    this.libraryId,
  });

  final bool gzip;
  final bool includeOrphanFacets;

  /// 非空时仅导出该 Library；为空则导出全部。
  final String? libraryId;

  bool get isValid => true;

  MetadataExportOptions normalized() {
    final String? id = libraryId?.trim();
    return MetadataExportOptions(
      gzip: gzip,
      includeOrphanFacets: includeOrphanFacets,
      libraryId: id == null || id.isEmpty ? null : id,
    );
  }
}
