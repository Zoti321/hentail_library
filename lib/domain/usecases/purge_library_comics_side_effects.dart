import 'package:hentai_library/domain/repository/comic_repo.dart';
import 'package:hentai_library/domain/repository/series_repo.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';
import 'package:hentai_library/domain/repository/reading_session_repo.dart';

/// 删除漫画及其阅读历史、系列归属、阅读会话（顺序与无根清空分支一致）。
Future<void> purgeLibraryComicsFromApp({
  required ComicRepository libraryComics,
  required ReadingHistoryRepository readingHistory,
  required SeriesRepository librarySeries,
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
