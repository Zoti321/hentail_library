import 'dart:io';

import 'package:hentai_library/core/logging/app_log.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LogFileWriter {
  IOSink? _sink;
  File? _logFile;
  final int maxFileSizeBytes = 5 * 1024 * 1024;
  static const int maxBackupFiles = 3;

  Future<void> init() async {
    final Directory dir = await getApplicationSupportDirectory();
    final Directory logsDir = Directory(p.join(dir.path, 'logs'));
    await logsDir.create(recursive: true);

    final String logPath = p.join(logsDir.path, 'app_log.txt');
    _logFile = File(logPath);

    await _rotateLogsIfNeeded();
    await _pruneOldBackups(logsDir);

    _sink = _logFile!.openWrite(mode: FileMode.append);
  }

  void write(LogRecord record) {
    _sink?.writeln(_formatRecord(record));
  }

  String _formatRecord(LogRecord record) {
    final StringBuffer buffer = StringBuffer()
      ..write(record.time.toIso8601String())
      ..write(' ')
      ..write(record.level.name)
      ..write(' ')
      ..write(record.loggerName)
      ..write(' ')
      ..write(record.message);
    if (record.error != null) {
      buffer.write(' error=${record.error}');
    }
    if (record.stackTrace != null) {
      buffer.write('\n${record.stackTrace}');
    }
    return buffer.toString();
  }

  Future<void> _rotateLogsIfNeeded() async {
    try {
      if (_logFile == null) {
        return;
      }
      if (await _logFile!.exists() &&
          await _logFile!.length() > maxFileSizeBytes) {
        final int timestamp = DateTime.now().millisecondsSinceEpoch;
        final String backupPath = _logFile!.path.replaceFirst(
          '.txt',
          '_$timestamp.bak',
        );
        await _logFile!.rename(backupPath);
      }
    } catch (e, st) {
      logError(AppLog.core('logging'), '日志轮转失败', e, st);
    }
  }

  Future<void> _pruneOldBackups(Directory logsDir) async {
    try {
      final List<FileSystemEntity> backups = <FileSystemEntity>[];
      await for (final FileSystemEntity entry in logsDir.list()) {
        if (entry is File && entry.path.endsWith('.bak')) {
          backups.add(entry);
        }
      }
      if (backups.length <= maxBackupFiles) {
        return;
      }
      backups.sort(
        (FileSystemEntity a, FileSystemEntity b) =>
            (a as File).lastModifiedSync().compareTo(
              (b as File).lastModifiedSync(),
            ),
      );
      for (int i = 0; i < backups.length - maxBackupFiles; i++) {
        await (backups[i] as File).delete();
      }
    } catch (e, st) {
      logError(AppLog.core('logging'), '清理旧日志备份失败', e, st);
    }
  }

  Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
  }
}
