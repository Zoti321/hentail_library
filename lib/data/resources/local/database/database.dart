import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hentai_library/data/resources/local/database/tables.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hentai_library/domain/enums/enums.dart';

export 'tables.dart';

part 'database.g.dart';

// 数据库定义
@DriftDatabase(
  tables: [
    Comics,
    Chapters,
    CategoryTags,
    ComicTags,
    SelectedDirectories,
    ReadingHistories,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? excutor]) : super(excutor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
    onUpgrade: (m, from, to) async {
      if (from < 2) await _migrateToV2(m);
      if (from < 3) await _migrateToV3(m);
      if (from < 4) await _migrateToV4(m);
    },
  );

  Future<void> _migrateToV2(Migrator m) async {
    await m.createTable(readingHistories);
  }

  Future<void> _migrateToV3(Migrator m) async {
    await m.addColumn(chapters, chapters.sourcePath);
  }

  Future<void> _migrateToV4(Migrator m) async {
    await m.addColumn(readingHistories, readingHistories.chapterId);
    await m.addColumn(readingHistories, readingHistories.pageIndex);
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
