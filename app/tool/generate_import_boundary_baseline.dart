// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../test/gate/import_boundary_rules.dart';

void main() {
  final Directory libDir = Directory(p.join('lib'));
  final List<ImportViolation> all = collectImportViolations(libDir);
  final List<String> keys = violationKeySet(ratchetViolations(all)).toList()
    ..sort();
  final File out = File(p.join('test', 'gate', 'import_boundary_baseline.json'));
  out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(keys));
  print('Wrote ${keys.length} baseline entries to ${out.path}');
  final int structural = structuralViolations(all).length;
  if (structural > 0) {
    print('WARNING: $structural structural violations remain');
    exit(1);
  }
}
