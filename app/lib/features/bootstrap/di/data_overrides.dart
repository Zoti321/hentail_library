import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/bootstrap/di/adapters/comic_trash_reader_session_adapter.dart';
import 'package:hentai_library/features/reader/public.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/comic_trash/public.dart';
import 'package:hentai_library/features/named_metadata/public.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/series/public.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/home/public.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> dataProviderOverrides() => <Override>[
  remoteLibraryCredentialsPortProvider.overrideWith(
    (Ref ref) =>
        createRemoteLibraryCredentialsPort(ref.read(libraryRepoProvider)),
  ),
  comicThumbnailRepoProvider.overrideWith(createComicThumbnailRepository),
  comicLookupRepositoryProvider.overrideWith(
    (Ref ref) => createComicRepository(),
  ),
  comicTrashRepositoryProvider.overrideWith(
    (Ref ref) => createComicTrashRepository(),
  ),
  comicCatalogRepositoryProvider.overrideWith(
    (Ref ref) => createComicCatalogRepository(),
  ),
  comicUserMetadataRepositoryProvider.overrideWith(
    (Ref ref) => createComicUserMetadataRepository(),
  ),
  seriesRepoProvider.overrideWith((Ref ref) => createSeriesRepository()),
  tagRepoProvider.overrideWith(
    (Ref ref) => createTagRepository(
      namedFacets: ref.read(namedFacetManagementRepoProvider),
    ),
  ),
  authorRepoProvider.overrideWith((Ref ref) => createAuthorRepository()),
  namedFacetManagementRepoProvider.overrideWith(
    (Ref ref) => createNamedFacetManagementRepository(),
  ),
  parodyRepoProvider.overrideWith(
    (Ref ref) => createNamedFacetDictionaryRepository(NamedFacetKind.parody),
  ),
  characterRepoProvider.overrideWith(
    (Ref ref) => createNamedFacetDictionaryRepository(NamedFacetKind.character),
  ),
  libraryRepoProvider.overrideWith((Ref ref) => createLibraryRepository()),
  readingHistoryRepoProvider.overrideWith(
    (Ref ref) => createReadingHistoryRepository(),
  ),
  appSettingRepoProvider.overrideWith(
    (Ref ref) => createAppSettingRepository(),
  ),
  homePageRepoProvider.overrideWith((Ref ref) => createHomePageRepository()),
  nativeReaderPortProvider.overrideWith(createNativeReaderPort),
  comicTrashNativeReaderPortProvider.overrideWith(
    (Ref ref) =>
        ComicTrashReaderSessionAdapter(ref.read(nativeReaderPortProvider)),
  ),
  comicPageSourcePortProvider.overrideWith(createComicPageSourcePort),
  libraryRevisionPortProvider.overrideWith(
    (Ref ref) => createLibraryRevisionPort(),
  ),
];
