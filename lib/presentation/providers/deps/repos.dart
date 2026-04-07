import 'package:hentai_library/data/repository/comic_repo_impl.dart';
import 'package:hentai_library/data/repository/series_repo_impl.dart';
import 'package:hentai_library/data/repository/tag_repo_impl.dart';
import 'package:hentai_library/data/repository/path_repo.dart';
import 'package:hentai_library/data/repository/reading_history_repo.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';
import 'package:hentai_library/domain/repository/series_repo.dart';
import 'package:hentai_library/domain/repository/tag_repo.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';
import 'package:hentai_library/presentation/providers/deps/database_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repos.g.dart';

@Riverpod(keepAlive: true)
ComicRepository libraryComicRepo(Ref ref) => ComicRepositoryImpl(
  ref.read(libraryComicDaoProvider),
  readingHistory: ref.read(readingHistoryRepoProvider),
  librarySeries: ref.read(librarySeriesRepoProvider),
);

@Riverpod(keepAlive: true)
SeriesRepository librarySeriesRepo(Ref ref) =>
    SeriesRepositoryImpl(ref.read(librarySeriesDaoProvider));

@Riverpod(keepAlive: true)
TagRepository libraryTagRepo(Ref ref) =>
    TagRepositoryImpl(ref.read(libraryTagDaoProvider));

@Riverpod(keepAlive: true)
PathRepository pathRepo(Ref ref) =>
    PathRepositoryImpl(ref.read(savedPathDaoProvider));

@Riverpod(keepAlive: true)
ReadingHistoryRepository readingHistoryRepo(Ref ref) =>
    ReadingHistoryRepositoryImpl(
      ref.read(readingHistoryDaoProvider),
      ref.read(seriesReadingHistoryDaoProvider),
    );

