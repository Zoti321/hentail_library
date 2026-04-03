import 'package:hentai_library/data/resources/local/database/dao.dart';
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
LibraryComicDao libraryComicDao(Ref ref) =>
    LibraryComicDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
LibrarySeriesDao librarySeriesDao(Ref ref) =>
    LibrarySeriesDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
LibraryTagDao libraryTagDao(Ref ref) =>
    LibraryTagDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
SavedPathDao savedPathDao(Ref ref) => SavedPathDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
ReadingHistoryDao readingHistoryDao(Ref ref) =>
    ReadingHistoryDao(ref.read(databaseProvider));
