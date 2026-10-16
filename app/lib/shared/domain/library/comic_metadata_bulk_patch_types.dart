/// Comic metadata bulk patch batch outcome from Rust core.
typedef ComicMetadataBulkPatchResult = ({
  int succeeded,
  int failed,
  int unchanged,
  bool cancelled,
  List<String> errorSamples,
});

enum ComicMetadataBulkMultiValueOp { add, remove, replace }

enum ComicMetadataBulkScalarOp { replace, clear }

class ComicMetadataBulkMultiValuePatch {
  const ComicMetadataBulkMultiValuePatch({
    required this.op,
    required this.values,
  });

  final ComicMetadataBulkMultiValueOp op;
  final List<String> values;
}

class ComicMetadataBulkDescriptionPatch {
  const ComicMetadataBulkDescriptionPatch.replace(this.value)
    : op = ComicMetadataBulkScalarOp.replace;

  const ComicMetadataBulkDescriptionPatch.clear()
    : op = ComicMetadataBulkScalarOp.clear,
      value = null;

  final ComicMetadataBulkScalarOp op;
  final String? value;
}

class ComicMetadataBulkPublishedAtPatch {
  const ComicMetadataBulkPublishedAtPatch.replace(this.value)
    : op = ComicMetadataBulkScalarOp.replace;

  const ComicMetadataBulkPublishedAtPatch.clear()
    : op = ComicMetadataBulkScalarOp.clear,
      value = null;

  final ComicMetadataBulkScalarOp op;
  final int? value;
}

class ComicMetadataBulkPatch {
  const ComicMetadataBulkPatch({
    this.tags,
    this.authors,
    this.languages,
    this.parodies,
    this.characters,
    this.contentRating,
    this.description,
    this.publishedAt,
  });

  final ComicMetadataBulkMultiValuePatch? tags;
  final ComicMetadataBulkMultiValuePatch? authors;
  final ComicMetadataBulkMultiValuePatch? languages;
  final ComicMetadataBulkMultiValuePatch? parodies;
  final ComicMetadataBulkMultiValuePatch? characters;
  final String? contentRating;
  final ComicMetadataBulkDescriptionPatch? description;
  final ComicMetadataBulkPublishedAtPatch? publishedAt;

  int get enabledFieldCount =>
      (tags != null ? 1 : 0) +
      (authors != null ? 1 : 0) +
      (languages != null ? 1 : 0) +
      (parodies != null ? 1 : 0) +
      (characters != null ? 1 : 0) +
      (contentRating != null ? 1 : 0) +
      (description != null ? 1 : 0) +
      (publishedAt != null ? 1 : 0);
}
