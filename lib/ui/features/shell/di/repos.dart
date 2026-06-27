import 'package:hentai_library/ui/features/shell/di/database_dao.dart';
import 'package:hentai_library/data/repositories/app_setting_repository_impl.dart';
import 'package:hentai_library/data/repositories/author_repository_impl.dart';
import 'package:hentai_library/data/repositories/comic_repository_impl.dart';
import 'package:hentai_library/data/repositories/path_repository_impl.dart';
import 'package:hentai_library/data/repositories/reading_history_repository_impl.dart';
import 'package:hentai_library/data/repositories/series_repository_impl.dart';
import 'package:hentai_library/data/repositories/home_page_repository_impl.dart';
import 'package:hentai_library/data/repositories/tag_repository_impl.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/domain/repositories/author_repository.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/domain/repositories/tag_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repos.g.dart';

@Riverpod(keepAlive: true)
ComicRepository comicRepo(Ref ref) => ComicRepositoryImpl(
  ref.read(comicDaoProvider),
  ref.read(searchDaoProvider),
  readingHistory: ref.read(readingHistoryRepoProvider),
  librarySeries: ref.read(librarySeriesRepoProvider),
);

@Riverpod(keepAlive: true)
SeriesRepository librarySeriesRepo(Ref ref) => SeriesRepositoryImpl(
  ref.read(seriesDaoProvider),
  ref.read(searchDaoProvider),
);

@Riverpod(keepAlive: true)
TagRepository libraryTagRepo(Ref ref) =>
    TagRepositoryImpl(ref.read(tagDaoProvider));

@Riverpod(keepAlive: true)
AuthorRepository libraryAuthorRepo(Ref ref) =>
    AuthorRepositoryImpl(ref.read(authorDaoProvider));

@Riverpod(keepAlive: true)
PathRepository pathRepo(Ref ref) =>
    PathRepositoryImpl(ref.read(savedPathDaoProvider));

@Riverpod(keepAlive: true)
ReadingHistoryRepository readingHistoryRepo(Ref ref) =>
    ReadingHistoryRepositoryImpl(
      ref.read(readingHistoryDaoProvider),
      ref.read(seriesReadingHistoryDaoProvider),
    );

@Riverpod(keepAlive: true)
AppSettingRepository appSettingRepo(Ref ref) => AppSettingRepositoryImpl();

@Riverpod(keepAlive: true)
HomePageRepository homePageRepo(Ref ref) =>
    HomePageRepositoryImpl(ref.read(homePageDaoProvider));
