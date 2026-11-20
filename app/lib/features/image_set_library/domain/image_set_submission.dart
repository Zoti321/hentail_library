/// Catalog-only ordered membership subset inside one Image set (ADR-0064).
class ImageSetSubmission {
  const ImageSetSubmission({
    required this.submissionId,
    required this.libraryId,
    required this.imageSetId,
    required this.name,
    required this.memberImageIds,
  });

  final String submissionId;
  final String libraryId;
  final String imageSetId;
  final String name;
  final List<String> memberImageIds;
}
