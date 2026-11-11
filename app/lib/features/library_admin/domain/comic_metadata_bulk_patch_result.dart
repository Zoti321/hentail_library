/// Comic metadata bulk patch batch outcome from Rust core.
typedef ComicMetadataBulkPatchResult = ({
  int succeeded,
  int failed,
  int unchanged,
  bool cancelled,
  List<String> errorSamples,
});
