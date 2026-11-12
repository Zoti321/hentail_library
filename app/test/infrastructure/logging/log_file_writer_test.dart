import 'dart:io';

import 'package:hentai_library/infrastructure/logging/log_file_writer.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('flush preserves level, logger, error and stack in the file', () async {
    final directory = await Directory.systemTemp.createTemp('log_writer_');
    final writer = LogFileWriter();
    await writer.init(supportDirectory: directory);
    try {
      writer.write(
        LogRecord(
          Level.SEVERE,
          'failed',
          'hentai.test',
          StateError('cause'),
          StackTrace.fromString('original stack'),
        ),
      );
      await writer.flush();
      final text = await File(p.join(directory.path, 'logs', 'app_log.txt'))
          .readAsString();
      expect(text, contains('SEVERE hentai.test failed'));
      expect(text, contains('error=Bad state: cause'));
      expect(text, contains('original stack'));
    } finally {
      await writer.dispose();
      await File(p.join(directory.path, 'logs', 'app_log.txt')).delete();
      await Directory(p.join(directory.path, 'logs')).delete();
      await directory.delete();
    }
  });

  test(
    'startup rotates over 5 MiB, retains three backups and ignores other files',
    () async {
      final directory = await Directory.systemTemp.createTemp('log_rotate_');
      final logs = await Directory(p.join(directory.path, 'logs')).create();
      final original = File(p.join(logs.path, 'app_log.txt'));
      await original.writeAsBytes(List<int>.filled(5 * 1024 * 1024 + 1, 65));
      for (int i = 0; i < 3; i++) {
        final file = File(p.join(logs.path, 'app_log_$i.bak'));
        await file.writeAsString('backup $i');
        await file.setLastModified(DateTime(2000, 1, i + 1));
      }
      final unrelated = File(p.join(logs.path, 'notes.txt'));
      await unrelated.writeAsString('keep');
      final writer = LogFileWriter();
      try {
        await writer.init(supportDirectory: directory);
        writer.write(LogRecord(Level.INFO, 'new log', 'hentai.test'));
        await writer.flush();
        final backups = await logs
            .list()
            .where((file) => file.path.endsWith('.bak'))
            .toList();
        expect(backups, hasLength(3));
        expect(
          await File(p.join(logs.path, 'app_log_0.bak')).exists(),
          isFalse,
        );
        expect(await unrelated.readAsString(), 'keep');
        expect(await original.readAsString(), contains('new log'));
        final rotated = backups
            .where(
              (file) =>
                  !file.path.endsWith('_1.bak') &&
                  !file.path.endsWith('_2.bak'),
            )
            .single;
        expect(await File(rotated.path).length(), 5 * 1024 * 1024 + 1);
      } finally {
        await writer.dispose();
        await for (final file in logs.list()) {
          await File(file.path).delete();
        }
        await logs.delete();
        await directory.delete();
      }
    },
  );
}
