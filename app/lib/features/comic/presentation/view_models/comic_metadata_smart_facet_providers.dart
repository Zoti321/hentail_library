import 'package:hentai_library/features/named_metadata/public/named_metadata_form.dart';
import 'package:hentai_library/features/comic/domain/smart_facet_match.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/features/app_settings/public/di/app_settings_providers.dart';
import 'package:hentai_library/shared/di/series_reading_context_providers.dart';
import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/comic/di/comic_repository_providers.dart';

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
  // 智能匹配开关已并入 AppSetting（ADR-0046）；未加载/失败时按默认开启处理。
  final bool enabled = (await ref.watch(appSettingsProvider.future))
      .smartFacetMatchEnabled;

  if (!enabled) {
    return applySmartFacetMatch(
      candidates: catalog,
      matchedSourceCounts: const <String, int>{},
      enabled: false,
    );
  }

  final Map<String, int> matched = await _matchedSourceCountsForKind(
    ref: ref,
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
  required Ref ref,
  required ComicMetadataSmartFacetScope scope,
  required NamedFacetFormKind kind,
  required List<NamedFacetFormCandidate> catalog,
}) async {
  switch (kind) {
    case NamedFacetFormKind.author:
      final String? libraryRoot = _libraryRootForPath(ref, scope.resourcePath);
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
      return _siblingMatchedNames(
        ref: ref,
        scope: scope,
        kind: kind,
        catalog: catalog,
      );
  }
}

String? _libraryRootForPath(Ref ref, String resourcePath) {
  final LibrariesState? state = ref.watch(librariesStateProvider).asData?.value;
  if (state == null) {
    return null;
  }
  return resolveLibraryRootForResourcePath(
    resourcePath: resourcePath,
    libraryRoots: state.libraries.map((LocalLibrary l) => l.rootPath),
  );
}

Future<Map<String, int>> _siblingMatchedNames({
  required Ref ref,
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

  // 邻居语义归 series：只消费 owner 给出的成员顺序事实（#490）。
  final SeriesReadingContext? context = await ref
      .read(seriesReadingContextPortProvider)
      .getReadingContextByComicId(scope.comicId);
  if (context == null) {
    return const <String, int>{};
  }

  final String? libraryRoot = _libraryRootForPath(ref, scope.resourcePath);
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

  final ComicLookupRepository comicRepo = ref.read(
    comicLookupRepositoryProvider,
  );
  final Set<String> siblingNames = <String>{};
  for (final String siblingComicId in context.orderedComicIds) {
    if (siblingComicId == scope.comicId) {
      continue;
    }
    final Comic? comic = await comicRepo.findById(siblingComicId);
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
