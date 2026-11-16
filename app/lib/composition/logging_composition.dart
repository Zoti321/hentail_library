import 'package:hentai_library/infrastructure/logging/flutter_log_output.dart';
import 'package:hentai_library/infrastructure/logging/diagnostic_logging.dart';
import 'package:hentai_library/infrastructure/logging/log_file_writer.dart';
import 'package:logging/logging.dart';

LogFileWriter? _appLogFileWriter;

Future<void> flushAppLogs() async {
  await _appLogFileWriter?.flush();
}

Future<LogFileWriter> configureAppLogging() async {
  Logger.root.level = defaultAppLogLevel();

  final LogFileWriter fileWriter = LogFileWriter();
  await fileWriter.init();
  _appLogFileWriter = fileWriter;

  Logger.root.onRecord.listen((LogRecord record) {
    emitConsoleLog(record);
    fileWriter.write(record);
  });

  return fileWriter;
}
