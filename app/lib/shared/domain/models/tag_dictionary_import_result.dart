class TagDictionaryImportResult {
  const TagDictionaryImportResult({
    required this.added,
    required this.skippedExisting,
    required this.skippedFilteredOrEmptyOrDedupe,
  });

  final int added;
  final int skippedExisting;
  final int skippedFilteredOrEmptyOrDedupe;
}
