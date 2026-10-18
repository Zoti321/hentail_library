import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

List<String> readSharedUiFeatureImportAllowlist() {
  final File manifest = File(
    p.join('test', 'gate', 'shared_ui_feature_import_allowlist.txt'),
  );
  return manifest
      .readAsLinesSync()
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty && !line.startsWith('#'))
      .map((String line) => p.posix.normalize(line.replaceAll(r'\', '/')))
      .toList();
}

bool _importsFeature(String line) {
  final String trimmed = line.trim();
  return trimmed.startsWith('import ') &&
      trimmed.contains("package:hentai_library/features/");
}

List<String> collectSharedUiFeatureImportViolations(Directory libDir) {
  final List<String> roots = <String>[
    'shared/ui/widgets',
    'shared/ui/layout',
    'shared/ui/shell',
    'shared/ui/interaction',
  ];
  final List<String> violations = <String>[];
  for (final String root in roots) {
    final Directory dir = Directory(p.join(libDir.path, root));
    if (!dir.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String rel = p
          .relative(entity.path, from: libDir.path)
          .replaceAll(r'\', '/');
      if (readSharedUiFeatureImportAllowlist().contains(rel)) {
        continue;
      }
      final List<String> lines = entity.readAsLinesSync();
      for (final String line in lines) {
        if (_importsFeature(line)) {
          violations.add('$rel: $line');
        }
      }
    }
  }
  return violations;
}

void main() {
  late Directory libDir;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
  });

  test('shared UI layers do not import features (allowlist contract)', () {
    final List<String> violations = collectSharedUiFeatureImportViolations(
      libDir,
    );
    expect(
      violations,
      isEmpty,
      reason:
          'Move feature coupling out of shared UI or add to '
          'test/gate/shared_ui_feature_import_allowlist.txt intentionally:\n'
          '${violations.join('\n')}',
    );
  });
}
