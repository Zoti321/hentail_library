/// Resolves where to [go] when leaving the reader (not used when popping).
///
/// Always comic detail → library (`/local`) when comicId is blank (ADR-0005).
String resolveReaderExitLocation({required String comicId}) {
  final String normalizedComicId = comicId.trim();
  if (normalizedComicId.isNotEmpty) {
    return '/comic/${Uri.encodeComponent(normalizedComicId)}';
  }
  return '/local';
}
