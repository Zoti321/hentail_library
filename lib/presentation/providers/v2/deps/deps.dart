import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/domain/mappers/library_comic_mapper.dart';
import 'package:talker/talker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'database_dao.dart';
export 'repo_impl.dart';
export 'service.dart';
export 'usecase.dart';

part 'deps.g.dart';

// == mapper ==
@Riverpod(keepAlive: true)
LibraryComicMapper libraryComicMapper(Ref ref) => LibraryComicMapper();

// ==== log ====
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
