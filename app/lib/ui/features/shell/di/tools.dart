import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'tools.g.dart';

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
