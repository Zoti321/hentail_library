import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

List<String> _readGateManifestEntries() {
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
      final List<String> missing = _readGateManifestEntries()
          .where(
            (String entry) =>
                FileSystemEntity.typeSync(entry) ==
                FileSystemEntityType.notFound,
          )
          .toList();
      expect(missing, isEmpty);
    });

    test('entries are unique', () {
      final List<String> entries = _readGateManifestEntries();
      expect(entries.toSet().length, entries.length);
    });

    test('directory entries do not also list their descendants', () {
      final List<String> entries = _readGateManifestEntries();
      final List<String> directories = entries
          .where((String entry) => Directory(entry).existsSync())
          .toList();
      final List<String> overlapping = <String>[
        for (final String entry in entries)
          for (final String directory in directories)
            if (p.isWithin(directory, entry))
              '$entry is already covered by $directory',
      ];
      expect(overlapping, isEmpty);
    });

    test('covers the thin-edge seams, FRB wire, layout and app smoke', () {
      expect(
        _readGateManifestEntries(),
        containsAll(<String>[
          'test/core',
          'test/infrastructure',
          'test/composition',
          'test/shared/presentation/providers',
          'test/frb_wire',
          'test/project_layout_test.dart',
          'test/widget_test.dart',
        ]),
      );
    });
  });
}
