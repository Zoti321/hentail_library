import 'package:hentai_library/features/comic/application/load_comic_smart_facet_candidates_use_case.dart';
import 'package:hentai_library/features/comic/domain/smart_facet_match.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_repository_providers.dart';
import 'package:hentai_library/features/comic_metadata/public/providers.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_form.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/presentation/providers/series_reading_context_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

export 'package:hentai_library/features/comic/application/load_comic_smart_facet_candidates_use_case.dart'
    show ComicMetadataSmartFacetScope;

/// Author candidates with Smart facet match ranking for the open form.
final authorsSmartForComicMetadataFormProvider = FutureProvider.autoDispose
    .family<List<SmartFacetMatchCandidate>, ComicMetadataSmartFacetScope>((
      Ref ref,
      ComicMetadataSmartFacetScope scope,
    ) {
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
    ) {
      return _rankFacet(ref: ref, scope: scope, kind: NamedFacetFormKind.tag);
    });

/// Parody candidates with Smart facet match ranking for the open form.
final parodiesSmartForComicMetadataFormProvider = FutureProvider.autoDispose
    .family<List<SmartFacetMatchCandidate>, ComicMetadataSmartFacetScope>((
      Ref ref,
      ComicMetadataSmartFacetScope scope,
    ) {
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
    ) {
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
}) {
  late final ComicLookupRepository comicRepository = ref.read(
    comicLookupRepositoryProvider,
  );
  final useCase = LoadComicSmartFacetCandidatesUseCase(
    listing: ref.read(namedFacetFormListingProvider),
    isEnabled: () async =>
        (await ref.watch(appSettingsProvider.future)).smartFacetMatchEnabled,
    libraryRoots: () =>
        ref
            .watch(librariesStateProvider)
            .asData
            ?.value
            .libraries
            .map((LocalLibrary library) => library.rootPath) ??
        const <String>[],
    findSeriesReadingContext: (comicId) =>
        ref.read(findSeriesReadingContextQueryProvider)(comicId),
    findComicById: (comicId) => comicRepository.findById(comicId),
  );
  return useCase(scope: scope, kind: kind);
}
