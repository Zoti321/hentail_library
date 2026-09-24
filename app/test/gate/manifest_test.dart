import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

List<String> readGateManifestEntries() {
  final File manifest = File(p.join('test', 'gate', 'manifest.txt'));
  return manifest
      .readAsLinesSync()
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty && !line.startsWith('#'))
      .toList();
}

void main() {
  group('gate manifest', () {
    test('every entry points to an existing test file or directory', () {
      final List<String> missing = readGateManifestEntries()
          .where(
            (String entry) =>
                FileSystemEntity.typeSync(entry) ==
                FileSystemEntityType.notFound,
          )
          .toList();
      expect(missing, isEmpty);
    });

    test('entries are unique', () {
      final List<String> entries = readGateManifestEntries();
      expect(entries.toSet().length, entries.length);
    });

    test('covers the thin-edge seams, FRB wire, layout and app smoke', () {
      expect(
        readGateManifestEntries(),
        containsAll(<String>[
          'test/domain',
          'test/core',
          'test/data',
          'test/frb_wire',
          'test/project_layout_test.dart',
          'test/widget_test.dart',
        ]),
      );
    });
  });
}
