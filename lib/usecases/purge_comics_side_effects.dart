import 'package:hentai_library/repository/comic_repository.dart';
import 'package:hentai_library/repository/reading_history_repository.dart';
import 'package:hentai_library/repository/series_repository.dart';

/// 删除漫画及其阅读历史、系列归属（顺序与无根清空分支一致）。
Future<void> purgeComicsFromApp({
  required ComicRepository libraryComics,
  required ReadingHistoryRepository readingHistory,
  required SeriesRepository librarySeries,
  required Iterable<String> comicIds,
}) async {
  final ids = comicIds.toList();
  if (ids.isEmpty) return;
  await readingHistory.deleteByComicIds(ids);
  await librarySeries.removeComicsFromSeries(ids);
  await libraryComics.deleteByIds(ids);
}
