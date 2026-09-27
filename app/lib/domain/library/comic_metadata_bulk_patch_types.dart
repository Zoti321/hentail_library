/// Comic metadata bulk patch batch outcome from Rust core.
typedef ComicMetadataBulkPatchResult = ({
  int succeeded,
  int failed,
  int unchanged,
  bool cancelled,
  List<String> errorSamples,
});

enum ComicMetadataBulkMultiValueOp { add, remove, replace }

class ComicMetadataBulkMultiValuePatch {
  const ComicMetadataBulkMultiValuePatch({
    required this.op,
    required this.values,
  });

  final ComicMetadataBulkMultiValueOp op;
  final List<String> values;
}

class ComicMetadataBulkPatch {
  const ComicMetadataBulkPatch({this.tags, this.authors});

  final ComicMetadataBulkMultiValuePatch? tags;
  final ComicMetadataBulkMultiValuePatch? authors;

  int get enabledFieldCount =>
      (tags != null ? 1 : 0) + (authors != null ? 1 : 0);
}
