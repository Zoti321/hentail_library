import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hentai_library/data/resources/local/database/tables.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:path_provider/path_provider.dart';

export 'tables.dart';

part 'database.g.dart';

// 数据库定义
@DriftDatabase(
  tables: [
    SavedPaths,
    ReadingHistories,
    LibraryComics,
    LibraryTags,
    LibraryComicTags,
    LibrarySeries,
    LibrarySeriesItems,
    SeriesReadingHistories,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? excutor]) : super(excutor ?? _openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
    onUpgrade: (m, from, to) async {
      if (from < 8) {
        await customStatement('DROP TABLE IF EXISTS reading_sessions');
      }
      if (from < 9) {
        await customStatement('''
CREATE TABLE library_series_items_new (
  series_name TEXT NOT NULL,
  comic_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  PRIMARY KEY (series_name, comic_id),
  UNIQUE(comic_id),
  FOREIGN KEY(series_name) REFERENCES library_series(name) ON DELETE CASCADE ON UPDATE CASCADE
);
''');
        await customStatement(
          'INSERT INTO library_series_items_new SELECT * FROM library_series_items;',
        );
        await customStatement('DROP TABLE library_series_items;');
        await customStatement(
          'ALTER TABLE library_series_items_new RENAME TO library_series_items;',
        );
      }
      if (from < 10) {
        await customStatement('DROP INDEX IF EXISTS idx_read_time;');
        await customStatement('''
CREATE TABLE reading_histories_new (
  comic_id TEXT NOT NULL,
  title TEXT NOT NULL,
  last_read_time INTEGER NOT NULL,
  page_index INTEGER,
  PRIMARY KEY (comic_id)
);
''');
        await customStatement('''
INSERT INTO reading_histories_new (comic_id, title, last_read_time, page_index)
SELECT comic_id, title, last_read_time, page_index FROM reading_histories;
''');
        await customStatement('DROP TABLE reading_histories;');
        await customStatement(
          'ALTER TABLE reading_histories_new RENAME TO reading_histories;',
        );
        await customStatement(
          'CREATE INDEX idx_read_time ON reading_histories (last_read_time);',
        );
        await customStatement('''
CREATE TABLE series_reading_histories (
  series_name TEXT NOT NULL,
  last_read_comic_id TEXT NOT NULL,
  last_read_time INTEGER NOT NULL,
  page_index INTEGER,
  PRIMARY KEY (series_name),
  FOREIGN KEY(series_name) REFERENCES library_series(name) ON DELETE CASCADE ON UPDATE CASCADE
);
''');
        await customStatement(
          'CREATE INDEX idx_series_read_time ON series_reading_histories (last_read_time);',
        );
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
