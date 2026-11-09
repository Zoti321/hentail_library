/// Leaves the reader after session cleanup.
///
/// Prefer [pop] so library → detail → reader keeps its stack. Only [go] when
/// there is nothing to pop (e.g. cold-opened `/reader`).
///
/// Returns `null` → caller should pop; otherwise → [go] that location.
String? resolveReaderExitNavigation({
  required bool canPop,
  required String comicId,
}) {
  if (canPop) {
    return null;
  }
  return resolveReaderExitLocation(comicId: comicId);
}

/// Fallback [go] target when the route stack cannot pop.
String resolveReaderExitLocation({required String comicId}) {
  final String normalizedComicId = comicId.trim();
  if (normalizedComicId.isNotEmpty) {
    return '/comic/${Uri.encodeComponent(normalizedComicId)}';
  }
  return '/home';
}
