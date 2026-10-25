import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const List<String> _forbiddenLegacyUiPrefixes = <String>[
  'package:hentai_library/shared/ui/widgets/',
  'package:hentai_library/shared/ui/layout/',
  'package:hentai_library/shared/ui/shell/',
  'package:hentai_library/shared/ui/motion/',
  'package:hentai_library/shared/ui/theme/',
];

List<String> collectMd3eLegacySharedUiImportViolations(Directory libDir) {
  final Directory md3eDir = Directory(p.join(libDir.path, 'md3e'));
  if (!md3eDir.existsSync()) {
    return <String>[];
  }
  final List<String> violations = <String>[];
  for (final FileSystemEntity entity in md3eDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final String rel = p
        .relative(entity.path, from: libDir.path)
        .replaceAll(r'\', '/');
    final List<String> lines = entity.readAsLinesSync();
    for (final String line in lines) {
      final String trimmed = line.trim();
      if (!trimmed.startsWith('import ') &&
          !trimmed.startsWith("import '") &&
          !trimmed.contains("import 'package:hentai_library/")) {
        continue;
      }
      if (!trimmed.startsWith('import ')) {
        continue;
      }
      for (final String prefix in _forbiddenLegacyUiPrefixes) {
        if (trimmed.contains(prefix)) {
          violations.add('$rel: $trimmed');
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

  test('md3e does not import legacy shared/ui UI layers', () {
    final List<String> violations = collectMd3eLegacySharedUiImportViolations(
      libDir,
    );
    expect(
      violations,
      isEmpty,
      reason:
          'MD3E must stay independent of baseline shared/ui widgets/layout/shell/motion/theme:\n'
          '${violations.join('\n')}',
    );
  });
}
