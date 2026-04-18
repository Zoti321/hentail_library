import 'package:hentai_library/data/repository/app_setting_repo_impl.dart';
import 'package:hentai_library/data/repository/comic_repo_impl.dart';
import 'package:hentai_library/data/repository/series_repo_impl.dart';
import 'package:hentai_library/data/repository/author_repo_impl.dart';
import 'package:hentai_library/data/repository/tag_repo_impl.dart';
import 'package:hentai_library/data/repository/path_repo_impl.dart';
import 'package:hentai_library/data/repository/reading_history_repo_impl.dart';
import 'package:hentai_library/domain/repository/app_setting_repo.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';
import 'package:hentai_library/domain/repository/author_repo.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';
import 'package:hentai_library/domain/repository/series_repo.dart';
import 'package:hentai_library/domain/repository/tag_repo.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';
import 'package:hentai_library/presentation/providers/deps/database_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repos.g.dart';

@Riverpod(keepAlive: true)
ComicRepository comicRepo(Ref ref) => ComicRepositoryImpl(
  ref.read(comicDaoProvider),
  readingHistory: ref.read(readingHistoryRepoProvider),
  librarySeries: ref.read(librarySeriesRepoProvider),
);

@Riverpod(keepAlive: true)
SeriesRepository librarySeriesRepo(Ref ref) =>
    SeriesRepositoryImpl(ref.read(seriesDaoProvider));

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
AppSettingRepository appSettingRepo(Ref ref) => AppSettingRepoImpl();
