// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../test/gate/shared_feature_import_rules.dart';

void main() {
  final Directory libDir = Directory(p.join('lib'));
  final List<String> keys = collectSharedDomainFeatureImportViolationKeys(
    libDir,
  ).toList()..sort();
  final File out = File(
    p.join('test', 'gate', 'shared_domain_feature_import_baseline.json'),
  );
  out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(keys));
  print('Wrote ${keys.length} baseline entries to ${out.path}');
}
