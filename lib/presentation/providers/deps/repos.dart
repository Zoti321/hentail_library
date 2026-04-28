import 'package:hentai_library/presentation/providers/deps/database_dao.dart';
import 'package:hentai_library/repository/app_setting_repository.dart';
import 'package:hentai_library/repository/author_repository.dart';
import 'package:hentai_library/repository/comic_repository.dart';
import 'package:hentai_library/repository/path_repository.dart';
import 'package:hentai_library/repository/reading_history_repository.dart';
import 'package:hentai_library/repository/series_repository.dart';
import 'package:hentai_library/repository/tag_repository.dart';
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
