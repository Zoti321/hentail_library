/// Metadata backup 文件 manifest（与 Core 导出摘要一致）。
class MetadataBackupManifest {
  const MetadataBackupManifest({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.comicCount,
    required this.includeOrphanFacets,
    this.libraryId,
  });

  final int schemaVersion;
  final String exportedAt;
  final String appVersion;
  final int comicCount;
  final bool includeOrphanFacets;
  final String? libraryId;
}
