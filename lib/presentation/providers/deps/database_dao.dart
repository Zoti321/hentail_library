import 'package:hentai_library/data/resources/local/database/dao/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_dao.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

@Riverpod(keepAlive: true)
ComicDao comicDao(Ref ref) => ComicDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
SeriesDao seriesDao(Ref ref) => SeriesDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
TagDao tagDao(Ref ref) => TagDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
AuthorDao authorDao(Ref ref) => AuthorDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
SavedPathDao savedPathDao(Ref ref) => SavedPathDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
ReadingHistoryDao readingHistoryDao(Ref ref) =>
    ReadingHistoryDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
SeriesReadingHistoryDao seriesReadingHistoryDao(Ref ref) =>
    SeriesReadingHistoryDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
HomePageDao homePageDao(Ref ref) => HomePageDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
SearchDao searchDao(Ref ref) => SearchDao(ref.read(databaseProvider));
