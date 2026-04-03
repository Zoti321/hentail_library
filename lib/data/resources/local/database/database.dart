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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? excutor]) : super(excutor ?? _openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
    onUpgrade: (m, from, to) async {
      if (from < 8) {
        await customStatement('DROP TABLE IF EXISTS reading_sessions');
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
