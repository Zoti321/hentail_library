import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_reader_session_port.dart';
import 'package:hentai_library/features/comic/domain/comic_lookup_repository.dart';
import 'package:hentai_library/features/comic/domain/comic_thumbnail_repository.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';
import 'package:hentai_library/shared/domain/ports/remote_library_credentials_port.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/author_repository.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_dictionary_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/tag_repository.dart';

/// Repository / Port token 声明；实现由 bootstrap 经 owner `public/di` 注入。

final Provider<ComicThumbnailRepository> comicThumbnailRepoProvider =
    injectedDi('comicThumbnailRepoProvider');

final Provider<ComicLookupRepository> comicLookupRepositoryProvider =
    injectedDi('comicLookupRepositoryProvider');

final Provider<ComicTrashRepository> comicTrashRepositoryProvider = injectedDi(
  'comicTrashRepositoryProvider',
);

final Provider<SeriesRepository> seriesRepoProvider = injectedDi(
  'seriesRepoProvider',
);

final Provider<TagRepository> tagRepoProvider = injectedDi('tagRepoProvider');

final Provider<AuthorRepository> authorRepoProvider = injectedDi(
  'authorRepoProvider',
);

final Provider<NamedFacetManagementRepository>
namedFacetManagementRepoProvider = injectedDi(
  'namedFacetManagementRepoProvider',
);

final Provider<NamedFacetDictionaryRepository> parodyRepoProvider = injectedDi(
  'parodyRepoProvider',
);

final Provider<NamedFacetDictionaryRepository> characterRepoProvider =
    injectedDi('characterRepoProvider');

final Provider<LibraryRepository> libraryRepoProvider = injectedDi(
  'libraryRepoProvider',
);

final Provider<RemoteLibraryCredentialsPort>
remoteLibraryCredentialsPortProvider = injectedDi(
  'remoteLibraryCredentialsPortProvider',
);

final Provider<ReadingHistoryRepository> readingHistoryRepoProvider =
    injectedDi('readingHistoryRepoProvider');

final Provider<AppSettingRepository> appSettingRepoProvider = injectedDi(
  'appSettingRepoProvider',
);

final Provider<HomePageRepository> homePageRepoProvider = injectedDi(
  'homePageRepoProvider',
);

final Provider<NativeReaderPort> nativeReaderPortProvider = injectedDi(
  'nativeReaderPortProvider',
);

final Provider<ComicTrashNativeReaderPort> comicTrashNativeReaderPortProvider =
    injectedDi('comicTrashNativeReaderPortProvider');

final Provider<ComicPageSourcePort> comicPageSourcePortProvider = injectedDi(
  'comicPageSourcePortProvider',
);
