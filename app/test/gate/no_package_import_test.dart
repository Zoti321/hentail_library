import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'lib_layout_scan_helpers.dart';

/// ADR-0031 终态：生产 `lib/features` 与 `lib/shared` 不得再 import 已删除的 `md3e/`。
const String _forbiddenUriFragment = 'package:hentai_library/md3e/';

List<String> collectForbiddenImports(Directory libDir) {
  final List<String> violations = <String>[];
  for (final String root in <String>['features', 'shared']) {
    final Directory dir = Directory(p.join(libDir.path, root));
    if (!dir.existsSync()) {
      continue;
    }
    for (final File file in dartFilesUnder(dir)) {
      final String rel = libRelativePosixPath(libDir, file);
      final String source = file.readAsStringSync();
      if (source.contains(_forbiddenUriFragment)) {
        violations.add(rel);
      }
    }
  }
  violations.sort();
  return violations;
}

void main() {
  late Directory libDir;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
  });

  test(
    'features/ and shared/ must not import package:hentai_library/md3e/',
    () {
      expect(Directory(p.join(libDir.path, 'md3e')).existsSync(), isFalse);
      final List<String> violations = collectForbiddenImports(libDir);
      expect(
        violations,
        isEmpty,
        reason:
            'MD3E Cutover 终态禁止生产代码引用 md3e/（#414 / ADR-0031）:\n'
            '${violations.join('\n')}',
      );
    },
  );
}
