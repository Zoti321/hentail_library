import 'package:flutter/foundation.dart';
import 'package:hentai_library/core/logging/log_file_writer.dart';
import 'package:logging/logging.dart';

LogFileWriter? _appLogFileWriter;

LogFileWriter? get appLogFileWriter => _appLogFileWriter;

Future<LogFileWriter> configureAppLogging() async {
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;

  final LogFileWriter fileWriter = LogFileWriter();
  await fileWriter.init();
  _appLogFileWriter = fileWriter;

  Logger.root.onRecord.listen((LogRecord record) {
    _emitConsoleLog(record);
    fileWriter.write(record);
  });

  return fileWriter;
}

void _emitConsoleLog(LogRecord record) {
  final String line = _formatConsoleLine(record);
  debugPrint(line);
}

String _formatConsoleLine(LogRecord record) {
  final String levelLabel = record.level.name.padRight(7);
  final String prefix = _ansiColorForLevel(record.level);
  const String reset = '\x1B[0m';
  final StringBuffer buffer = StringBuffer()
    ..write(prefix)
    ..write(levelLabel)
    ..write(' ')
    ..write(record.loggerName)
    ..write(' | ')
    ..write(record.message)
    ..write(reset);
  if (record.error != null) {
    buffer.write(' error=${record.error}');
  }
  if (record.stackTrace != null) {
    buffer.write('\n${record.stackTrace}');
  }
  return buffer.toString();
}

String _ansiColorForLevel(Level level) {
  if (level >= Level.SEVERE) {
    return '\x1B[31m';
  }
  if (level >= Level.WARNING) {
    return '\x1B[33m';
  }
  if (level >= Level.INFO) {
    return '\x1B[36m';
  }
  return '\x1B[90m';
}
