import 'package:hentai_library/shared/data/repositories/app_setting_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/author_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/comic_thumbnail_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/comic_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/library_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/named_facet_dictionary_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/named_facet_management_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/reading_history_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/series_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/home_page_repository_impl.dart';
import 'package:hentai_library/shared/data/repositories/tag_repository_impl.dart';
import 'package:hentai_library/shared/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/shared/domain/repositories/author_repository.dart';
import 'package:hentai_library/shared/domain/repositories/comic_repository.dart';
import 'package:hentai_library/shared/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/shared/domain/repositories/library_repository.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_dictionary_repository.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/shared/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/shared/domain/repositories/series_repository.dart';
import 'package:hentai_library/shared/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/shared/domain/repositories/tag_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repos.g.dart';

@Riverpod(keepAlive: true)
ComicThumbnailRepository comicThumbnailRepo(Ref ref) =>
    ComicThumbnailRepositoryImpl(
      libraryRepository: ref.read(libraryRepoProvider),
    );

@Riverpod(keepAlive: true)
ComicRepository comicRepo(Ref ref) => const ComicRepositoryImpl();

@Riverpod(keepAlive: true)
SeriesRepository seriesRepo(Ref ref) => const SeriesRepositoryImpl();

@Riverpod(keepAlive: true)
TagRepository tagRepo(Ref ref) => const TagRepositoryImpl();

@Riverpod(keepAlive: true)
AuthorRepository authorRepo(Ref ref) => const AuthorRepositoryImpl();

@Riverpod(keepAlive: true)
NamedFacetManagementRepository namedFacetManagementRepo(Ref ref) =>
    const NamedFacetManagementRepositoryImpl();

@Riverpod(keepAlive: true)
NamedFacetDictionaryRepository parodyRepo(Ref ref) =>
    const NamedFacetDictionaryRepositoryImpl(NamedFacetKind.parody);

@Riverpod(keepAlive: true)
NamedFacetDictionaryRepository characterRepo(Ref ref) =>
    const NamedFacetDictionaryRepositoryImpl(NamedFacetKind.character);

@Riverpod(keepAlive: true)
LibraryRepository libraryRepo(Ref ref) => const LibraryRepositoryImpl();

@Riverpod(keepAlive: true)
ReadingHistoryRepository readingHistoryRepo(Ref ref) =>
    const ReadingHistoryRepositoryImpl();

@Riverpod(keepAlive: true)
AppSettingRepository appSettingRepo(Ref ref) => AppSettingRepositoryImpl();

@Riverpod(keepAlive: true)
HomePageRepository homePageRepo(Ref ref) => const HomePageRepositoryImpl();
