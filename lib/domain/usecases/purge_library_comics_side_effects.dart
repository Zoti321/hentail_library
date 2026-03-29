import 'package:hentai_library/domain/repository/library_comic_repo.dart';
import 'package:hentai_library/domain/repository/library_series_repo.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';
import 'package:hentai_library/domain/repository/reading_session_repo.dart';

/// 删除漫画及其阅读历史、系列归属、阅读会话（顺序与无根清空分支一致）。
Future<void> purgeLibraryComicsFromApp({
  required LibraryComicRepository libraryComics,
  required ReadingHistoryRepository readingHistory,
  required LibrarySeriesRepository librarySeries,
  required ReadingSessionRepository readingSessions,
  required Iterable<String> comicIds,
}) async {
  final ids = comicIds.toList();
  if (ids.isEmpty) return;
  await readingHistory.deleteByComicIds(ids);
  await librarySeries.removeComicsFromSeries(ids);
  await readingSessions.deleteSessionsByComicIds(ids);
  await libraryComics.deleteByIds(ids);
}
