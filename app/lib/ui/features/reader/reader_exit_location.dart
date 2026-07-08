/// Resolves where to [go] when leaving the reader (not used when popping).
///
/// Priority: series detail → comic detail → library (`/local`).
String resolveReaderExitLocation({
  required String comicId,
  String? seriesId,
}) {
  final String? normalizedSeriesId = seriesId?.trim();
  if (normalizedSeriesId != null && normalizedSeriesId.isNotEmpty) {
    return '/series/${Uri.encodeComponent(normalizedSeriesId)}';
  }
  final String normalizedComicId = comicId.trim();
  if (normalizedComicId.isNotEmpty) {
    return '/comic/${Uri.encodeComponent(normalizedComicId)}';
  }
  return '/local';
}
