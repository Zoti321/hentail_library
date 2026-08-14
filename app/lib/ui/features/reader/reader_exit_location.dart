import 'package:hentai_library/ui/features/shell/views/navigation/libraries_routes.dart';

/// Resolves where to [go] when leaving the reader (not used when popping).
///
/// Comic detail when [comicId] is set (ADR-0005); otherwise Current library
/// browse (or All libraries browse when unset).
String resolveReaderExitLocation({
  required String comicId,
  String? currentLibraryId,
}) {
  final String normalizedComicId = comicId.trim();
  if (normalizedComicId.isNotEmpty) {
    return '/comic/${Uri.encodeComponent(normalizedComicId)}';
  }
  return LibrariesRoutes.browsePathForCurrent(currentLibraryId);
}
