import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/read_session/domain/comic_page_source_port.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';
import 'package:hentai_library/features/read_session/domain/reader_session_port.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/author_repository.dart';
import 'package:hentai_library/features/library_browse/domain/comic/comic_lookup_repository.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';
import 'package:hentai_library/features/library_browse/domain/comic/comic_thumbnail_repository.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_dictionary_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/features/library_browse/domain/series/series_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/tag_repository.dart';

Never _unimplemented(String name) =>
    throw UnimplementedError('$name 未注入，请在 bootstrap 中 override');

final Provider<ComicThumbnailRepository> comicThumbnailRepoProvider =
    Provider<ComicThumbnailRepository>(
      (Ref ref) => _unimplemented('comicThumbnailRepoProvider'),
    );

final Provider<ComicLookupRepository> comicLookupRepositoryProvider =
    Provider<ComicLookupRepository>(
      (Ref ref) => _unimplemented('comicLookupRepositoryProvider'),
    );

final Provider<ComicTrashRepository> comicTrashRepositoryProvider =
    Provider<ComicTrashRepository>(
      (Ref ref) => _unimplemented('comicTrashRepositoryProvider'),
    );

final Provider<SeriesRepository> seriesRepoProvider =
    Provider<SeriesRepository>(
      (Ref ref) => _unimplemented('seriesRepoProvider'),
    );

final Provider<TagRepository> tagRepoProvider = Provider<TagRepository>(
  (Ref ref) => _unimplemented('tagRepoProvider'),
);

final Provider<AuthorRepository> authorRepoProvider =
    Provider<AuthorRepository>(
      (Ref ref) => _unimplemented('authorRepoProvider'),
    );

final Provider<NamedFacetManagementRepository>
namedFacetManagementRepoProvider = Provider<NamedFacetManagementRepository>(
  (Ref ref) => _unimplemented('namedFacetManagementRepoProvider'),
);

final Provider<NamedFacetDictionaryRepository> parodyRepoProvider =
    Provider<NamedFacetDictionaryRepository>(
      (Ref ref) => _unimplemented('parodyRepoProvider'),
    );

final Provider<NamedFacetDictionaryRepository> characterRepoProvider =
    Provider<NamedFacetDictionaryRepository>(
      (Ref ref) => _unimplemented('characterRepoProvider'),
    );

final Provider<LibraryRepository> libraryRepoProvider =
    Provider<LibraryRepository>(
      (Ref ref) => _unimplemented('libraryRepoProvider'),
    );

final Provider<ReadingHistoryRepository> readingHistoryRepoProvider =
    Provider<ReadingHistoryRepository>(
      (Ref ref) => _unimplemented('readingHistoryRepoProvider'),
    );

final Provider<AppSettingRepository> appSettingRepoProvider =
    Provider<AppSettingRepository>(
      (Ref ref) => _unimplemented('appSettingRepoProvider'),
    );

final Provider<HomePageRepository> homePageRepoProvider =
    Provider<HomePageRepository>(
      (Ref ref) => _unimplemented('homePageRepoProvider'),
    );

final Provider<ReaderSessionPort> readerSessionPortProvider =
    Provider<ReaderSessionPort>(
      (Ref ref) => _unimplemented('readerSessionPortProvider'),
    );

final Provider<ComicPageSourcePort> comicPageSourcePortProvider =
    Provider<ComicPageSourcePort>(
      (Ref ref) => _unimplemented('comicPageSourcePortProvider'),
    );

final Provider<LibraryRevisionPort> libraryRevisionPortProvider =
    Provider<LibraryRevisionPort>(
      (Ref ref) => _unimplemented('libraryRevisionPortProvider'),
    );
