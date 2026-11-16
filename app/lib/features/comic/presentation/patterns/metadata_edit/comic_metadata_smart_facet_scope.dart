import 'package:hentai_library/features/comic/domain/smart_facet_match.dart';
import 'package:hentai_library/features/comic/application/load_comic_smart_facet_candidates_use_case.dart'
    show ComicMetadataSmartFacetScope;

/// Builds a Lab or Widgetbook scope without a loaded Comic.
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

SmartFacetMatchCandidate facetCandidate(
  String name, {
  bool smartMatched = false,
}) {
  return (name: name, attachmentCount: 0, smartMatched: smartMatched);
}
