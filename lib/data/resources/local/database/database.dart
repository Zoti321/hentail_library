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
    ComicReadingHistories,
    Comics,
    Tags,
    ComicTags,
    SeriesTable,
    SeriesItems,
    SeriesReadingHistories,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? excutor]) : super(excutor ?? _openConnection());

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
    onUpgrade: (m, from, to) async {
      if (from < 11) {
        await customStatement('PRAGMA foreign_keys = OFF');
        await customStatement('''
          CREATE TABLE series_items_new (
            series_name TEXT NOT NULL,
            comic_id TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            PRIMARY KEY(series_name, comic_id),
            UNIQUE(comic_id),
            FOREIGN KEY(series_name) REFERENCES series(name) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE ON UPDATE CASCADE
          );
        ''');
        await customStatement('''
          INSERT INTO series_items_new (series_name, comic_id, sort_order)
          SELECT si.series_name, si.comic_id, si.sort_order
          FROM series_items AS si
          INNER JOIN comics AS c ON c.comic_id = si.comic_id;
        ''');
        await customStatement('DROP TABLE series_items;');
        await customStatement(
          'ALTER TABLE series_items_new RENAME TO series_items;',
        );
        await customStatement('PRAGMA foreign_keys = ON');
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
