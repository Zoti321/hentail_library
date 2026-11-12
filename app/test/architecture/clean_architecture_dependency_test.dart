import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';

final RegExp _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

void main() {
  final Directory lib = Directory('lib');

  test('domain/application stay pure through imports and public exports', () {
    final Map<String, List<String>> dependencies = <String, List<String>>{};
    for (final File file in dartFilesUnder(lib)) {
      final String path = libRelativePosixPath(lib, file);
      dependencies[path] = _directive
          .allMatches(file.readAsStringSync())
          .map((Match match) => match.group(1)!)
          .toList();
    }
    final Set<String> offenders = <String>{};
    for (final String root in dependencies.keys) {
      final bool domain = isDomainLayerPath(root);
      if (!domain &&
          !isApplicationLayerPath(root) &&
          !root.endsWith('/public/contracts.dart')) {
        continue;
      }
      final Set<String> visited = <String>{};

      void visit(String source, List<String> chain) {
        if (!visited.add(source)) {
          return;
        }
        for (final String uri in dependencies[source] ?? <String>[]) {
          final String? target = _resolve(source, uri);
          final bool trustedPackage =
              uri.startsWith('package:hentai_library/') ||
              uri.startsWith('package:freezed_annotation/') ||
              uri.startsWith('package:json_annotation/');
          final bool external =
              uri == 'dart:ui' ||
              uri == 'dart:io' ||
              (uri.startsWith('package:') && !trustedPackage);
          final bool outer =
              target != null &&
              (target.startsWith('composition/') ||
                  target.startsWith('infrastructure/') ||
                  target.contains('/infrastructure/') ||
                  target.contains('/data/') ||
                  target.contains('/di/') ||
                  target.contains('/presentation/') ||
                  target.startsWith('shared/ui/') ||
                  target.startsWith('design-system/') ||
                  target.startsWith('src/rust/') ||
                  (domain && isApplicationLayerPath(target)));
          if (external || outer) {
            offenders.add('${chain.join(' -> ')} -> $uri');
          } else if (target != null) {
            visit(target, <String>[...chain, target]);
          }
        }
      }

      visit(root, <String>[root]);
    }
    expect(offenders.toList()..sort(), isEmpty);
  });

  test('composition is only consumed by the app entry point', () {
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(lib)) {
      final String source = libRelativePosixPath(lib, file);
      if (source == 'main.dart' || source.startsWith('composition/')) {
        continue;
      }
      for (final Match match in _directive.allMatches(
        file.readAsStringSync(),
      )) {
        final String? target = _resolve(source, match.group(1)!);
        if (target != null && target.startsWith('composition/')) {
          offenders.add('$source -> $target');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}

String? _resolve(String source, String uri) {
  const String prefix = 'package:hentai_library/';
  if (uri.startsWith(prefix)) {
    return uri.substring(prefix.length);
  }
  if (uri.contains(':')) {
    return null;
  }
  return p.posix.normalize(p.posix.join(p.posix.dirname(source), uri));
}
