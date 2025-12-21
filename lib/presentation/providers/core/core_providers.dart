import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'core_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

@Riverpod(keepAlive: true)
ComicDao comicDao(Ref ref) => ComicDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
CategoryTagDao categoryTagDao(Ref ref) =>
    CategoryTagDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
SelectedDirectoryDao dirDao(Ref ref) =>
    SelectedDirectoryDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
Talker logManager(Ref ref) {
  return LogManager.instance;
}

@Riverpod(keepAlive: true)
Future<LogFileWriter> logWriter(Ref ref) async {
  final talker = ref.watch(logManagerProvider);
  final logWriter = LogFileWriter(talker);
  await logWriter.init();
  return logWriter;
}
