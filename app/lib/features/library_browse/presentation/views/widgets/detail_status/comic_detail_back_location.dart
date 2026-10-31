/// Resolves where comic-detail back should [go] when the route stack cannot pop.
///
/// With a remembered series source → `/series/:id`.
/// Without → `null` (caller falls back to Current library browse).
String? resolveComicDetailBackLocation({String? returnSeriesId}) {
  final String normalized = returnSeriesId?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }
  return '/series/${Uri.encodeComponent(normalized)}';
}
