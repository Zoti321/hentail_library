/// Batch Metadata refresh outcome (Series or Library).
///
/// 真源归 `library_admin`（ADR-0045）：返回类型属于
/// `LibraryMetadataRefreshCommandPort`；comic / series 只是调用方。
typedef MetadataRefreshBatchResult = ({
  int succeeded,
  int failed,
  bool cancelled,
  bool skipped,
  String? skipMessage,
});
