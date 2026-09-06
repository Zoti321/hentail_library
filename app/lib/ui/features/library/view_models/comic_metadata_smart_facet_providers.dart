import 'package:hentai_library/data/repositories/named_facet_form_listing.dart';
import 'package:hentai_library/domain/library/smart_facet_match.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/named_facet_form_candidate.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/smart_facet_match_preference_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Scope for Smart facet match on Comic metadata form.
typedef ComicMetadataSmartFacetScope = ({
  String comicId,
  String title,
  String resourcePath,
  String? seriesId,
});

/// Author candidates with Smart facet match ranking for the open form.
final authorsSmartForComicMetadataFormProvider = FutureProvider.autoDispose
    .family<List<SmartFacetMatchCandidate>, ComicMetadataSmartFacetScope>((
      Ref ref,
      ComicMetadataSmartFacetScope scope,
    ) async {
      return _rankFacet(
        ref: ref,
        scope: scope,
        kind: NamedFacetFormKind.author,
      );
    });

/// Tag candidates with Smart facet match ranking for the open form.
final tagsSmartForComicMetadataFormProvider = FutureProvider.autoDispose
    .family<List<SmartFacetMatchCandidate>, ComicMetadataSmartFacetScope>((
      Ref ref,
      ComicMetadataSmartFacetScope scope,
    ) async {
      return _rankFacet(ref: ref, scope: scope, kind: NamedFacetFormKind.tag);
    });

/// Parody candidates with Smart facet match ranking for the open form.
final parodiesSmartForComicMetadataFormProvider = FutureProvider.autoDispose
    .family<List<SmartFacetMatchCandidate>, ComicMetadataSmartFacetScope>((
      Ref ref,
      ComicMetadataSmartFacetScope scope,
    ) async {
      return _rankFacet(
        ref: ref,
        scope: scope,
        kind: NamedFacetFormKind.parody,
      );
    });

/// Character candidates with Smart facet match ranking for the open form.
final charactersSmartForComicMetadataFormProvider = FutureProvider.autoDispose
    .family<List<SmartFacetMatchCandidate>, ComicMetadataSmartFacetScope>((
      Ref ref,
      ComicMetadataSmartFacetScope scope,
    ) async {
      return _rankFacet(
        ref: ref,
        scope: scope,
        kind: NamedFacetFormKind.character,
      );
    });

Future<List<SmartFacetMatchCandidate>> _rankFacet({
  required Ref ref,
  required ComicMetadataSmartFacetScope scope,
  required NamedFacetFormKind kind,
}) async {
  final List<NamedFacetFormCandidate> catalog =
      await listNamedFacetForMetadataForm(kind);
  final bool enabled = await ref.watch(
    smartFacetMatchPreferenceProvider.future,
  );

  if (!enabled) {
    return applySmartFacetMatch(
      candidates: catalog,
      matchedNames: const <String>{},
      enabled: false,
    );
  }

  final Set<String> matched = await _matchedNamesForKind(
    ref: ref,
    scope: scope,
    kind: kind,
    catalog: catalog,
  );
  return applySmartFacetMatch(
    candidates: catalog,
    matchedNames: matched,
    enabled: true,
  );
}

Future<Set<String>> _matchedNamesForKind({
  required Ref ref,
  required ComicMetadataSmartFacetScope scope,
  required NamedFacetFormKind kind,
  required List<NamedFacetFormCandidate> catalog,
}) async {
  switch (kind) {
    case NamedFacetFormKind.author:
      final String? libraryRoot = _libraryRootForPath(ref, scope.resourcePath);
      final String relative =
          relativeResourcePathUnderRoot(
            resourcePath: scope.resourcePath,
            libraryRoot: libraryRoot ?? '',
          ) ??
          _basename(scope.resourcePath);
      return authorSmartMatchNames(
        dictionary: catalog,
        title: scope.title,
        relativeResourcePath: relative,
      );
    case NamedFacetFormKind.tag:
    case NamedFacetFormKind.parody:
    case NamedFacetFormKind.character:
      return _siblingMatchedNames(
        ref: ref,
        scope: scope,
        kind: kind,
        catalog: catalog,
      );
  }
}

String? _libraryRootForPath(Ref ref, String resourcePath) {
  final CurrentLibraryState? state = ref
      .watch(currentLibraryProvider)
      .asData
      ?.value;
  if (state == null) {
    return null;
  }
  return resolveLibraryRootForResourcePath(
    resourcePath: resourcePath,
    libraryRoots: state.libraries.map((LocalLibrary l) => l.rootPath),
  );
}

Future<Set<String>> _siblingMatchedNames({
  required Ref ref,
  required ComicMetadataSmartFacetScope scope,
  required NamedFacetFormKind kind,
  required List<NamedFacetFormCandidate> catalog,
}) async {
  final String? seriesId = scope.seriesId;
  if (seriesId == null || seriesId.isEmpty) {
    return siblingSmartMatchNames(
      dictionary: catalog,
      siblingAttachedNames: const <String>{},
      isLibraryRootSeries: false,
    );
  }

  final SeriesRepository seriesRepo = ref.read(seriesRepoProvider);
  final Series? series = await seriesRepo.findById(seriesId);
  if (series == null) {
    return const <String>{};
  }

  final String? libraryRoot = _libraryRootForPath(ref, scope.resourcePath);
  final bool rootSeries = isLibraryRootSeriesFolder(
    seriesFolderPath: series.folderPath,
    libraryRoot: libraryRoot,
  );
  if (rootSeries) {
    return siblingSmartMatchNames(
      dictionary: catalog,
      siblingAttachedNames: const <String>{},
      isLibraryRootSeries: true,
    );
  }

  final ComicRepository comicRepo = ref.read(comicRepoProvider);
  final Set<String> siblingNames = <String>{};
  for (final SeriesItem item in series.items) {
    if (item.comicId == scope.comicId) {
      continue;
    }
    final Comic? comic = await comicRepo.findById(item.comicId);
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

  return siblingSmartMatchNames(
    dictionary: catalog,
    siblingAttachedNames: siblingNames,
    isLibraryRootSeries: false,
  );
}

String _basename(String path) {
  final String normalized = path.replaceAll('\\', '/');
  final int slash = normalized.lastIndexOf('/');
  if (slash < 0 || slash >= normalized.length - 1) {
    return path;
  }
  return normalized.substring(slash + 1);
}
