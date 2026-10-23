import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/read_session/data/adapters/comic_page_source_frb_adapter.dart';
import 'package:hentai_library/features/read_session/data/adapters/reader_session_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/data/adapters/library_revision_frb_adapter.dart';
import 'package:hentai_library/features/app_settings/data/repositories/app_setting_repository_impl.dart';
import 'package:hentai_library/features/named_metadata/data/repositories/author_repository_impl.dart';
import 'package:hentai_library/features/library_browse/data/repositories/comic_repository_impl.dart';
import 'package:hentai_library/features/library_browse/di/comic_repository_providers.dart';
import 'package:hentai_library/shared/data/repositories/comic_thumbnail_repository_impl.dart';
import 'package:hentai_library/features/home/data/repositories/home_page_repository_impl.dart';
import 'package:hentai_library/features/library_admin/data/repositories/library_repository_impl.dart';
import 'package:hentai_library/features/named_metadata/data/repositories/named_facet_dictionary_repository_impl.dart';
import 'package:hentai_library/features/named_metadata/data/repositories/named_facet_management_repository_impl.dart';
import 'package:hentai_library/features/home/data/repositories/reading_history_repository_impl.dart';
import 'package:hentai_library/features/library_browse/data/repositories/series_repository_impl.dart';
import 'package:hentai_library/features/named_metadata/data/repositories/tag_repository_impl.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_dictionary_repository.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> dataProviderOverrides() => <Override>[
  comicThumbnailRepoProvider.overrideWith(
    (Ref ref) => ComicThumbnailRepositoryImpl(
      libraryRepository: ref.read(libraryRepoProvider),
    ),
  ),
  comicLookupRepositoryProvider.overrideWith(
    (Ref ref) => const ComicRepositoryImpl(),
  ),
  comicTrashRepositoryProvider.overrideWith(
    (Ref ref) => const ComicRepositoryImpl(),
  ),
  comicCatalogRepositoryProvider.overrideWith(
    (Ref ref) => const ComicRepositoryImpl(),
  ),
  comicUserMetadataRepositoryProvider.overrideWith(
    (Ref ref) => const ComicRepositoryImpl(),
  ),
  seriesRepoProvider.overrideWith((Ref ref) => const SeriesRepositoryImpl()),
  tagRepoProvider.overrideWith((Ref ref) => const TagRepositoryImpl()),
  authorRepoProvider.overrideWith((Ref ref) => const AuthorRepositoryImpl()),
  namedFacetManagementRepoProvider.overrideWith(
    (Ref ref) => const NamedFacetManagementRepositoryImpl(),
  ),
  parodyRepoProvider.overrideWith(
    (Ref ref) =>
        const NamedFacetDictionaryRepositoryImpl(NamedFacetKind.parody),
  ),
  characterRepoProvider.overrideWith(
    (Ref ref) =>
        const NamedFacetDictionaryRepositoryImpl(NamedFacetKind.character),
  ),
  libraryRepoProvider.overrideWith((Ref ref) => const LibraryRepositoryImpl()),
  readingHistoryRepoProvider.overrideWith(
    (Ref ref) => const ReadingHistoryRepositoryImpl(),
  ),
  appSettingRepoProvider.overrideWith((Ref ref) => AppSettingRepositoryImpl()),
  homePageRepoProvider.overrideWith(
    (Ref ref) => const HomePageRepositoryImpl(),
  ),
  readerSessionPortProvider.overrideWith(
    (Ref ref) => ReaderSessionFrbAdapter(
      libraryRepository: ref.read(libraryRepoProvider),
    ),
  ),
  comicPageSourcePortProvider.overrideWith(
    (Ref ref) => const ComicPageSourceFrbAdapter(),
  ),
  libraryRevisionPortProvider.overrideWith(
    (Ref ref) => const LibraryRevisionFrbAdapter(),
  ),
];
