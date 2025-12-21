import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hentai_library/data/database/tables.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

export 'tables.dart';

part 'database.g.dart';

// 数据库定义
@DriftDatabase(
  tables: [
    Comics,
    SeriesTable,
    SeriesItems,

    Tags,
    ComicTags,

    Authors,
    ComicAuthors,

    SavedPaths,

    ComicReadingHistories,
    SeriesReadingHistories,
    ComicThumbnails,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? excutor]) : super(excutor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.hadUpgrade && details.versionNow >= 2) {
        await _deleteLegacyArchiveCoverDiskCache();
      }
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(comicThumbnails);
      }
    },
  );

  static Future<void> _deleteLegacyArchiveCoverDiskCache() async {
    try {
      final Directory cacheDir = await getApplicationCacheDirectory();
      final Directory legacyDir = Directory(
        p.join(cacheDir.path, 'archive_cover_cache'),
      );
      if (await legacyDir.exists()) {
        await legacyDir.delete(recursive: true);
      }
    } catch (_) {}
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
