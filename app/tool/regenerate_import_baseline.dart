import 'dart:convert';
import 'dart:io';

import '../test/gate/import_boundary_rules.dart';

void main() {
  final Directory libDir = Directory('lib');
  final List<ImportViolation> all = collectImportViolations(libDir);
  final List<ImportViolation> ratchet = ratchetViolations(all);
  final List<String> keys = violationKeySet(ratchet).toList()..sort();
  stdout.writeln('ratchet edges: ${keys.length}');
  File(
    'test/gate/import_boundary_baseline.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(keys));
}
