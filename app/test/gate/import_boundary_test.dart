import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'import_boundary_rules.dart';

void main() {
  late Directory libDir;
  late File baselineFile;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
    baselineFile = File(
      p.join('test', 'gate', 'import_boundary_baseline.json'),
    );
  });

  test('import boundaries: L1 structural rules are zero-tolerance', () {
    final List<ImportViolation> all = collectImportViolations(libDir);
    final List<ImportViolation> structural = structuralViolations(all);
    if (structural.isNotEmpty) {
      fail(
        'Structural import violations (R1–R5):\n'
        '${_formatViolations(structural)}',
      );
    }
  });

  test('import boundaries: L2 product graph ratchet vs baseline', () {
    final List<ImportViolation> all = collectImportViolations(libDir);
    final Set<String> currentKeys = violationKeySet(ratchetViolations(all));
    final Set<String> baselineKeys = _readBaselineKeys(baselineFile);

    final Set<String> added = currentKeys.difference(baselineKeys);
    expect(
      added,
      isEmpty,
      reason:
          'New cross-feature import edges (not in baseline):\n'
          '${added.join('\n')}',
    );
  });
}

Set<String> _readBaselineKeys(File baselineFile) {
  expect(baselineFile.existsSync(), isTrue, reason: 'missing baseline file');
  final Object? decoded = jsonDecode(baselineFile.readAsStringSync());
  expect(decoded, isA<List<Object?>>());
  final List<Object?> raw = decoded! as List<Object?>;
  return raw.map((Object? e) => e.toString()).toSet();
}

String _formatViolations(List<ImportViolation> violations) {
  final List<ImportViolation> sorted = List<ImportViolation>.from(violations)
    ..sort((ImportViolation a, ImportViolation b) {
      return violationKey(a).compareTo(violationKey(b));
    });
  return sorted
      .map(
        (ImportViolation v) =>
            '${v.ruleId} ${v.sourceModule}->${v.targetModule} '
            '${v.sourceFile} imports ${v.importUri}',
      )
      .join('\n');
}
