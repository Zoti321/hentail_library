import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/module/comic_list_query/comic_list_query.dart';
import 'package:hentai_library/module/mapping/mapping.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'tools.g.dart';

@Riverpod(keepAlive: true)
MappingModule mappingModule(Ref ref) => const DefaultMappingModule();

@Riverpod(keepAlive: true)
ComicListQueryModule comicListQueryModule(Ref ref) {
  return const DefaultComicListQueryModule();
}

@Riverpod(keepAlive: true)
ComicMapper libraryComicMapper(Ref ref) {
  return ref.read(mappingModuleProvider).comic;
}

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
