import 'package:hentai_library/core/constants/libraries_routes.dart';

/// Resolves where to [go] when leaving the reader (not used when popping).
String resolveReaderExitLocation({required String comicId}) {
  final String normalizedComicId = comicId.trim();
  if (normalizedComicId.isNotEmpty) {
    return '/comic/${Uri.encodeComponent(normalizedComicId)}';
  }
  return LibrariesRoutes.defaultBrowse;
}
