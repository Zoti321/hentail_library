import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:talker/talker.dart';

class LogManager {
  static Talker? _instance;

  static Talker get instance => _instance ?? init();

  static Talker init() {
    _instance = Talker(
      settings: TalkerSettings(maxHistoryItems: 1000, useConsoleLogs: true),
      logger: TalkerLogger(
        formatter: const ColoredLoggerFormatter(),
        settings: TalkerLoggerSettings(
          level: kDebugMode ? LogLevel.verbose : LogLevel.info,
        ),
      ),
    );

    return _instance!;
  }
}

class LogFileWriter {
  final Talker talker;
  IOSink? _sink;
  File? _logFile;
  final int maxFileSizeBytes = 5 * 1024 * 1024; // 限制 5MB
  static const int maxBackupFiles = 3;

  LogFileWriter(this.talker);

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    final logsDir = Directory(p.join(dir.path, 'logs'));
    await logsDir.create(recursive: true);

    final logPath = p.join(logsDir.path, 'app_log.txt');
    _logFile = File(logPath);

    await _rotateLogsIfNeeded();
    await _pruneOldBackups(logsDir);

    _sink = _logFile!.openWrite(mode: FileMode.append);

    talker.stream.listen((data) {
      _sink?.writeln('${DateTime.now()} [${data.title}] ${data.message}');
    });
  }

  Future<void> _rotateLogsIfNeeded() async {
    try {
      if (_logFile == null) return;
      if (await _logFile!.exists() &&
          await _logFile!.length() > maxFileSizeBytes) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final backupPath =
            _logFile!.path.replaceFirst('.txt', '_$timestamp.bak');
        await _logFile!.rename(backupPath);
      }
    } catch (e, st) {
      talker.handle(e, st, '日志轮转失败');
    }
  }

  Future<void> _pruneOldBackups(Directory logsDir) async {
    try {
      final backups = <FileSystemEntity>[];
      await for (final e in logsDir.list()) {
        if (e is File && e.path.endsWith('.bak')) backups.add(e);
      }
      if (backups.length <= maxBackupFiles) return;
      backups.sort((a, b) =>
          (a as File).lastModifiedSync().compareTo((b as File).lastModifiedSync()));
      for (var i = 0; i < backups.length - maxBackupFiles; i++) {
        await (backups[i] as File).delete();
      }
    } catch (e, st) {
      talker.handle(e, st, '清理旧日志备份失败');
    }
  }

  Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
  }
}
