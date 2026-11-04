/// Metadata backup import 写入结果。
class MetadataImportResult {
  const MetadataImportResult({
    required this.applied,
    required this.skippedNotFound,
    required this.skippedAmbiguous,
    required this.errors,
  });

  final int applied;
  final int skippedNotFound;
  final int skippedAmbiguous;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;

  bool get isFullyApplied =>
      applied > 0 && skippedNotFound == 0 && skippedAmbiguous == 0 && !hasErrors;
}
