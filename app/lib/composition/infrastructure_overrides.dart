import 'package:hentai_library/shared/presentation/providers/comic_read_query_provider.dart';
import 'package:hentai_library/composition/modules/comic/comic_browse_repository_factory.dart';
import 'package:hentai_library/composition/modules/comic/comic_read_query.dart';
import 'package:hentai_library/composition/modules/comic/comic_thumbnail_repository_factory.dart';
import 'package:hentai_library/composition/modules/comic_metadata/comic_metadata_repository_factory.dart';
import 'package:hentai_library/composition/modules/comic_trash/comic_trash_repository_factory.dart';
import 'package:hentai_library/composition/modules/home/home_page_repository_factory.dart';
import 'package:hentai_library/composition/modules/library_admin/remote_library_credentials_port_factory.dart';
import 'package:hentai_library/composition/modules/library_admin/library_repository_factory.dart';
import 'package:hentai_library/composition/modules/reader/comic_page_source_port_factory.dart';
import 'package:hentai_library/composition/modules/reader/native_reader_port_factory.dart';
import 'package:hentai_library/composition/modules/reading_history/reading_history_repository_factory.dart';
import 'package:hentai_library/composition/modules/series/series_repository_factory.dart';
import 'package:hentai_library/composition/platform_overrides.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/composition/adapters/comic_trash_reader_session_adapter.dart';
import 'package:hentai_library/features/reader/public.dart';
import 'package:hentai_library/features/comic_trash/public.dart';
import 'package:hentai_library/features/comic_metadata/public.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/series/public.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/home/public.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> infrastructureOverrides() => <Override>[
  ...platformOverrides(),
  remoteLibraryCredentialsPortProvider.overrideWith(
    (Ref ref) =>
        createRemoteLibraryCredentialsPort(ref.read(libraryRepoProvider)),
  ),
  comicThumbnailRepoProvider.overrideWith(createComicThumbnailRepository),
  comicLookupRepositoryProvider.overrideWith(
    (Ref ref) => createComicRepository(),
  ),
  comicReadQueryProvider.overrideWith(
    (Ref ref) => createComicReadQuery(ref.read(comicLookupRepositoryProvider)),
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
  authorRepoProvider.overrideWith(
    (Ref ref) => createAuthorRepository(
      namedFacets: ref.read(namedFacetManagementRepoProvider),
    ),
  ),
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
  homePageRepoProvider.overrideWith((Ref ref) => createHomePageRepository()),
  nativeReaderPortProvider.overrideWith(createNativeReaderPort),
  comicTrashNativeReaderPortProvider.overrideWith(
    (Ref ref) =>
        ComicTrashReaderSessionAdapter(ref.read(nativeReaderPortProvider)),
  ),
  comicPageSourcePortProvider.overrideWith(createComicPageSourcePort),
];
