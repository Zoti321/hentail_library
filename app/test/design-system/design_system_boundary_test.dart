import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../architecture/dart_dependency_graph.dart';
import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

// UI libraries and their complete runtime closure. Flutter SDK internals are
// framework dependencies; no product, state-management, router or window plugin.
const designSystemUiPackages = <String>{
  'animations',
  'clock',
  'collection',
  'cupertino_ui',
  'dynamic_color',
  'equatable',
  'flutter_hooks',
  'intl',
  'json_annotation',
  'lucide_icons_flutter',
  'material_3_expressive',
  'material_color_utilities',
  'material_new_shapes',
  'material_symbols_icons',
  'material_ui',
  'meta',
  'motor',
  'path',
  'pinyin_pro_flutter',
  'theme_tailor_annotation',
  'vector_math',
};

void main() {
  final lib = Directory('lib').absolute;
  final layer = Directory('lib/design-system').absolute;
  final graph = DartDependencyGraph.current();
  final files = dartFilesUnder(layer).toList();

  test('design-system retains shared module classification', () {
    expect(classifyLibPath('design-system/design_system.dart'), 'shared');
  });

  test(
    'the full UI dependency graph is portable and excludes application code',
    () {
      expect(files, isNotEmpty);
      expect(
        portableUiDependencyViolations(
          graph: graph,
          roots: files.map((file) => file.uri),
          appLib: lib.uri,
          layer: layer.uri,
          uiPackages: designSystemUiPackages,
        ),
        isEmpty,
      );
    },
  );

  test(
    'one public entry with explicit symbols, no re-export compatibility paths',
    () {
      final entry = File('lib/design-system/design_system.dart').absolute;
      final unit = parseString(content: entry.readAsStringSync()).unit;
      expect(unit.declarations, isEmpty);
      for (final directive in unit.directives.whereType<ExportDirective>()) {
        expect(directive.combinators.whereType<ShowCombinator>(), hasLength(1));
        expect(
          graph.resolve(entry.uri, directive.uri.stringValue!).toString(),
          startsWith(layer.uri.toString()),
        );
      }
      final offenders = <String>[];
      for (final file in files.where(
        (file) => file.absolute.uri != entry.uri,
      )) {
        for (final dependency in graph.directives(file.uri)) {
          if (graph.resolve(file.uri, dependency) == entry.uri) {
            offenders.add('${file.path} imports public barrel');
          }
        }
        final unit = parseString(
          content: file.readAsStringSync(),
          throwIfDiagnostics: false,
        ).unit;
        for (final directive in unit.directives.whereType<ExportDirective>()) {
          // Calendar's material_ui localization type is deliberately selected.
          if (directive.uri.stringValue !=
              'package:material_ui/material_ui.dart') {
            offenders.add(file.path);
          }
        }
      }
      expect(offenders, isEmpty);
    },
  );

  test('production, tests and Widgetbook consume only the public entry', () {
    final offenders = <String>[];
    final entry = File('lib/design-system/design_system.dart').absolute.uri;
    for (final folder in [
      'lib',
      'test',
      'widgetbook',
      'integration_test',
      'tool',
    ]) {
      for (final file in dartFilesUnder(Directory(folder).absolute)) {
        if (p.isWithin(layer.path, file.absolute.path)) continue;
        for (final dependency in graph.directives(file.uri)) {
          final target = graph.resolve(file.uri, dependency);
          if (target.toString().startsWith(layer.uri.toString()) &&
              target != entry) {
            offenders.add('${file.path} -> $dependency');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
