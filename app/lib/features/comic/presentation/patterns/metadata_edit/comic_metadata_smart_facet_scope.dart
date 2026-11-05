import 'package:hentai_library/features/comic/domain/smart_facet_match.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';

/// Builds [ComicMetadataSmartFacetScope] for metadata edit UI.
ComicMetadataSmartFacetScope comicMetadataSmartFacetScopeForComic(
  Comic comic, {
  String? seriesId,
}) {
  return (
    comicId: comic.comicId,
    title: comic.title,
    resourcePath: comic.path,
    seriesId: seriesId,
  );
}

/// Lab / Widgetbook scope when no [Comic] entity is loaded.
ComicMetadataSmartFacetScope labComicMetadataSmartFacetScope({
  required String title,
  String comicId = 'lab-comic-id',
  String resourcePath = '/lab/library/example/comic.cbz',
  String? seriesId,
}) {
  return (
    comicId: comicId,
    title: title,
    resourcePath: resourcePath,
    seriesId: seriesId,
  );
}

SmartFacetMatchCandidate facetCandidate(String name, {bool smartMatched = false}) {
  return (name: name, attachmentCount: 0, smartMatched: smartMatched);
}
