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

  test('FRB import whitelist: feature data/ layer (Phase C #280)', () {
    expect(
      isFrbImportAllowedSource(
        'features/library_admin/data/adapters/sync_library_frb_adapter.dart',
      ),
      isTrue,
    );
    expect(
      isFrbImportAllowedSource('features/library_admin/domain/foo.dart'),
      isFalse,
    );
    expect(
      isFrbImportAllowedSource(
        'features/reader/application/open_read_session_service.dart',
      ),
      isFalse,
    );
    expect(isFrbImportAllowedSource('shared/data/adapters/foo.dart'), isTrue);
    expect(
      isFrbImportAllowedSource(
        'features/comic_trash/data/adapters/comic_trash_frb_adapter.dart',
      ),
      isTrue,
    );
    expect(
      isFrbImportAllowedSource(
        'features/comic_trash/presentation/views/trash/trash_page.dart',
      ),
      isFalse,
    );
  });

  test('M1 public path allowlist (ADR-0034 / #429)', () {
    expect(
      isFeaturePublicPath('features/library_admin/public/library_admin.dart'),
      isTrue,
    );
    expect(isFeaturePublicPath('features/library_admin/public.dart'), isTrue);
    expect(
      isFeaturePublicPath('features/library_admin/public/ui/commands.dart'),
      isTrue,
    );
    expect(
      isFeaturePublicPath('features/library_admin/application/foo.dart'),
      isFalse,
    );
    expect(
      isFeaturePublicPath('features/library_admin/presentation/bar.dart'),
      isFalse,
    );
    expect(isFeaturePublicPath('shared/domain/foo.dart'), isFalse);
  });

  test('R12 public→presentation export allowlist (only shrink)', () {
    expect(
      isPublicPresentationExportAllowlisted(
        'features/comic/public/ui/comic_detail_page.dart',
      ),
      isTrue,
    );
    expect(
      isPublicPresentationExportAllowlisted(
        'features/library_browse/public/ui/library_page.dart',
      ),
      isTrue,
    );
    expect(
      isPublicPresentationExportAllowlisted(
        'features/comic/public/shell/library_browse_shell_exports.dart',
      ),
      isFalse,
    );
    expect(
      isPublicPresentationExportAllowlisted(
        'features/series/public/shell/library_browse_shell_exports.dart',
      ),
      isFalse,
    );
  });

  test('import boundaries: L1 structural rules are zero-tolerance', () {
    final List<ImportViolation> all = collectImportViolations(libDir);
    final List<ImportViolation> structural = structuralViolations(all);
    if (structural.isNotEmpty) {
      fail(
        'Structural import violations (R1–R12; R13 is ratcheted):\n'
        '${_formatViolations(structural)}',
      );
    }
  });

  test('R13 shared→features edges only shrink', () {
    final List<ImportViolation> all = collectImportViolations(libDir);
    final Set<String> baselineKeys = _readBaselineKeys(baselineFile);
    final Set<String> added = all
        .where((ImportViolation v) => v.ruleId == 'R13')
        .map(violationKey)
        .toSet()
        .difference(baselineKeys);
    expect(
      added,
      isEmpty,
      reason: 'New shared→features imports:\n${added.join('\n')}',
    );
  });

  test('import boundaries: no cycles in public cross-feature graph', () {
    final Map<String, Set<String>> adjacency =
        collectPublicCrossFeatureAdjacency(libDir);
    final List<String>? cycle = findPublicCrossFeatureCycle(adjacency);
    expect(
      cycle,
      isNull,
      reason: cycle == null
          ? null
          : 'Public API dependency cycle: ${cycle.join(' -> ')}',
    );
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
