/// Batch Metadata refresh outcome (Series or Library).
typedef MetadataRefreshBatchResult = ({
  int succeeded,
  int failed,
  bool cancelled,
  bool skipped,
  String? skipMessage,
});
