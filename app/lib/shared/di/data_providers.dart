import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';
import 'package:hentai_library/shared/domain/ports/reader_session_port.dart';
import 'package:hentai_library/shared/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/shared/domain/repositories/author_repository.dart';
import 'package:hentai_library/shared/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/shared/domain/repositories/comic_trash_repository.dart';
import 'package:hentai_library/shared/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/shared/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/shared/domain/repositories/library_repository.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_dictionary_repository.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/shared/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/shared/domain/repositories/series_repository.dart';
import 'package:hentai_library/shared/domain/repositories/tag_repository.dart';

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
