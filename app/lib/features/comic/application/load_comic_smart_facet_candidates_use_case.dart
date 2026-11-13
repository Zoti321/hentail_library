import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/smart_facet_match.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_form.dart';
import 'package:hentai_library/shared/application/contracts/find_series_reading_context_query.dart';
import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';

/// Scope for Smart facet match on Comic metadata form.
typedef ComicMetadataSmartFacetScope = ({
  String comicId,
  String title,
  String resourcePath,
  String? seriesId,
});

class LoadComicSmartFacetCandidatesUseCase {
  const LoadComicSmartFacetCandidatesUseCase({
    required this._listing,
    required this._isEnabled,
    required this._libraryRoots,
    required this._findSeriesReadingContext,
    required this._findComicById,
  });

  final NamedFacetFormListing _listing;
  final Future<bool> Function() _isEnabled;
  final Iterable<String> Function() _libraryRoots;
  final FindSeriesReadingContextQuery _findSeriesReadingContext;
  final Future<Comic?> Function(String) _findComicById;

  Future<List<SmartFacetMatchCandidate>> call({
    required ComicMetadataSmartFacetScope scope,
    required NamedFacetFormKind kind,
  }) async {
    final List<NamedFacetFormCandidate> catalog = await _listing
        .listForMetadataForm(kind);
    final bool enabled = await _isEnabled();
    if (!enabled) {
      return applySmartFacetMatch(
        candidates: catalog,
        matchedSourceCounts: const <String, int>{},
        enabled: false,
      );
    }

    final Map<String, int> matched = await _matchedSourceCountsForKind(
      scope: scope,
      kind: kind,
      catalog: catalog,
    );
    return applySmartFacetMatch(
      candidates: catalog,
      matchedSourceCounts: matched,
      enabled: true,
    );
  }

  Future<Map<String, int>> _matchedSourceCountsForKind({
    required ComicMetadataSmartFacetScope scope,
    required NamedFacetFormKind kind,
    required List<NamedFacetFormCandidate> catalog,
  }) async {
    switch (kind) {
      case NamedFacetFormKind.author:
        final String? libraryRoot = _libraryRootForPath(scope.resourcePath);
        final String? relative = libraryRoot == null
            ? null
            : relativeResourcePathUnderRoot(
                resourcePath: scope.resourcePath,
                libraryRoot: libraryRoot,
              );
        final AuthorSmartMatchPathSources pathSources =
            resolveAuthorSmartMatchPathSources(
              resourcePath: scope.resourcePath,
              relativeUnderLibraryRoot: relative,
              libraryRootKnown: libraryRoot != null,
            );
        return authorSmartMatchNames(
          dictionary: catalog,
          title: scope.title,
          filenameStem: pathSources.filenameStem,
          parentDirectorySegments: pathSources.parentDirectorySegments,
        );
      case NamedFacetFormKind.tag:
      case NamedFacetFormKind.parody:
      case NamedFacetFormKind.character:
        return _siblingMatchedNames(scope: scope, kind: kind, catalog: catalog);
    }
  }

  String? _libraryRootForPath(String resourcePath) {
    return resolveLibraryRootForResourcePath(
      resourcePath: resourcePath,
      libraryRoots: _libraryRoots(),
    );
  }

  Future<Map<String, int>> _siblingMatchedNames({
    required ComicMetadataSmartFacetScope scope,
    required NamedFacetFormKind kind,
    required List<NamedFacetFormCandidate> catalog,
  }) async {
    final String? seriesId = scope.seriesId;
    if (seriesId == null || seriesId.isEmpty) {
      return _siblingMatchSourceCounts(
        siblingSmartMatchNames(
          dictionary: catalog,
          siblingAttachedNames: const <String>{},
          isLibraryRootSeries: false,
        ),
      );
    }

    final SeriesReadingContext? context = await _findSeriesReadingContext(
      scope.comicId,
    );
    if (context == null) {
      return const <String, int>{};
    }

    final String? libraryRoot = _libraryRootForPath(scope.resourcePath);
    final bool rootSeries = isLibraryRootSeriesComicPath(
      resourcePath: scope.resourcePath,
      libraryRoot: libraryRoot,
    );
    if (rootSeries) {
      return _siblingMatchSourceCounts(
        siblingSmartMatchNames(
          dictionary: catalog,
          siblingAttachedNames: const <String>{},
          isLibraryRootSeries: true,
        ),
      );
    }

    final Set<String> siblingNames = <String>{};
    for (final String siblingComicId in context.orderedComicIds) {
      if (siblingComicId == scope.comicId) {
        continue;
      }
      final Comic? comic = await _findComicById(siblingComicId);
      if (comic == null) {
        continue;
      }
      switch (kind) {
        case NamedFacetFormKind.tag:
          siblingNames.addAll(comic.tags.map((t) => t.name));
        case NamedFacetFormKind.parody:
          siblingNames.addAll(comic.parodies);
        case NamedFacetFormKind.character:
          siblingNames.addAll(comic.characters);
        case NamedFacetFormKind.author:
          break;
      }
    }

    return _siblingMatchSourceCounts(
      siblingSmartMatchNames(
        dictionary: catalog,
        siblingAttachedNames: siblingNames,
        isLibraryRootSeries: false,
      ),
    );
  }

  Map<String, int> _siblingMatchSourceCounts(Set<String> matchedNames) {
    return <String, int>{for (final String name in matchedNames) name: 1};
  }
}
