import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'wayfinder_layout_helpers.dart';

void main() {
  late Directory libDir;
  late File allowlistFile;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
    allowlistFile = File(p.join('test', 'gate', 'strangler_shims.txt'));
  });

  group('strangler shim allowlist (#219)', () {
    test('allowlist file exists', () {
      expect(allowlistFile.existsSync(), isTrue);
    });

    test('every export-only shim under lib/ is listed', () {
      final List<String> allowlisted = readStranglerShimAllowlist(
        allowlistFile,
      );
      final List<String> actualShims = collectStranglerShims(libDir);
      final List<String> unlisted = actualShims
          .where((String path) => !allowlisted.contains(path))
          .toList();
      expect(
        unlisted,
        isEmpty,
        reason: 'Add paths to test/gate/strangler_shims.txt or remove shims',
      );
    });

    test('every allowlisted path exists and is an export-only shim', () {
      final List<String> allowlisted = readStranglerShimAllowlist(
        allowlistFile,
      );
      final List<String> missing = <String>[];
      final List<String> notShims = <String>[];
      for (final String relative in allowlisted) {
        final File file = File(p.join(libDir.path, relative));
        if (!file.existsSync()) {
          missing.add(relative);
          continue;
        }
        if (!isStranglerShimSource(file.readAsStringSync())) {
          notShims.add(relative);
        }
      }
      expect(missing, isEmpty, reason: 'Ghost allowlist entries');
      expect(
        notShims,
        isEmpty,
        reason: 'Allowlisted files must be export-only shims',
      );
    });
  });
}
