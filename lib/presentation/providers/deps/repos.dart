import 'package:hentai_library/data/repository/library_comic_repo_impl.dart';
import 'package:hentai_library/data/repository/library_series_repo_impl.dart';
import 'package:hentai_library/data/repository/library_tag_repo_impl.dart';
import 'package:hentai_library/data/repository/path_repo.dart';
import 'package:hentai_library/data/repository/reading_history_repo.dart';
import 'package:hentai_library/data/repository/reading_session_repo.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';
import 'package:hentai_library/domain/repository/library_comic_repo.dart';
import 'package:hentai_library/domain/repository/library_series_repo.dart';
import 'package:hentai_library/domain/repository/library_tag_repo.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';
import 'package:hentai_library/domain/repository/reading_session_repo.dart'
    as domain;
import 'package:hentai_library/presentation/providers/deps/database_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repos.g.dart';

@Riverpod(keepAlive: true)
LibraryComicRepository libraryComicRepo(Ref ref) =>
    LibraryComicRepositoryImpl(ref.read(libraryComicDaoProvider));

@Riverpod(keepAlive: true)
LibrarySeriesRepository librarySeriesRepo(Ref ref) =>
    LibrarySeriesRepositoryImpl(ref.read(librarySeriesDaoProvider));

@Riverpod(keepAlive: true)
LibraryTagRepository libraryTagRepo(Ref ref) =>
    LibraryTagRepositoryImpl(ref.read(libraryTagDaoProvider));

@Riverpod(keepAlive: true)
PathRepository pathRepo(Ref ref) =>
    PathRepositoryImpl(ref.read(savedPathDaoProvider));

@Riverpod(keepAlive: true)
ReadingHistoryRepository readingHistoryRepo(Ref ref) =>
    ReadingHistoryRepositoryImpl(ref.read(readingHistoryDaoProvider));

@Riverpod(keepAlive: true)
domain.ReadingSessionRepository readingSessionRepo(Ref ref) {
  return ReadingSessionRepositoryImpl(ref.read(readingSessionDaoProvider));
}
