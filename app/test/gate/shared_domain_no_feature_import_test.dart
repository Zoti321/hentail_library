import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'shared_feature_import_rules.dart';

void main() {
  late Directory libDir;
  late File baselineFile;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
    baselineFile = File(
      p.join('test', 'gate', 'shared_domain_feature_import_baseline.json'),
    );
  });

  test('shared/data intentional feature-import exemptions stay documented', () {
    expect(
      isSharedDataFeatureImportExempt(
        'shared/data/adapters/reader_frb_mapper.dart',
      ),
      isTrue,
    );
    expect(
      isSharedDataFeatureImportExempt(
        'shared/data/adapters/series_frb_mapper.dart',
      ),
      isTrue,
    );
    expect(
      isSharedDataFeatureImportExempt(
        'shared/data/repositories/named_facet_form_listing.dart',
      ),
      isFalse,
    );
  });

  test('shared/domain -> features import ratchet vs baseline (L3)', () {
    final Set<String> currentKeys =
        collectSharedDomainFeatureImportViolationKeys(libDir);
    final Set<String> baselineKeys = _readBaselineKeys(baselineFile);

    final Set<String> added = currentKeys.difference(baselineKeys);
    expect(
      added,
      isEmpty,
      reason:
          'New shared/domain imports of features/ (not in baseline). '
          'Remove the coupling or, after shrinking edges, regenerate baseline:\n'
          '  cd app && dart run tool/generate_shared_domain_feature_import_baseline.dart\n'
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
