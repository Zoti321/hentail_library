import 'dart:io';

import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';
import 'dart_dependency_graph.dart';

bool _outer(String target) =>
    target.startsWith('composition/') ||
    target.startsWith('infrastructure/') ||
    target.contains('/infrastructure/') ||
    target.contains('/data/') ||
    target.contains('/di/') ||
    target.contains('/presentation/') ||
    target.startsWith('shared/ui/') ||
    target.startsWith('design-system/') ||
    target.startsWith('src/');

void main() {
  final lib = Directory('lib').absolute;
  final graph = DartDependencyGraph.current();
  final files = dartFilesUnder(lib).toList();

  test('core stays pure through its entire dependency graph', () {
    final roots = files.where(
      (file) => libRelativePosixPath(lib, file).startsWith('core/'),
    );
    expect(roots, isNotEmpty);
    expect(
      pureDependencyViolations(
        graph: graph,
        roots: roots.map((file) => file.uri),
        appLib: lib.uri,
        allowsAppPath: (path) => path.startsWith('core/'),
      ),
      isEmpty,
    );
  });

  for (final domain in <bool>[true, false]) {
    test(
      '${domain ? 'domain' : 'application/contracts'} stay pure through the full dependency graph',
      () {
        final roots = files.where((file) {
          final path = libRelativePosixPath(lib, file);
          return domain
              ? isDomainLayerPath(path)
              : isApplicationLayerPath(path) ||
                    path.endsWith('/public/contracts.dart');
        });
        expect(
          pureDependencyViolations(
            graph: graph,
            roots: roots.map((file) => file.uri),
            appLib: lib.uri,
            allowsAppPath: (target) =>
                !_outer(target) && !(domain && isApplicationLayerPath(target)),
          ),
          isEmpty,
        );
      },
    );
  }

  test(
    'outer layers obey core/shared/infrastructure/composition direction',
    () {
      final offenders = <String>[];
      for (final file in files) {
        final source = libRelativePosixPath(lib, file);
        for (final dependency in graph.directives(file.uri)) {
          final resolved = graph.resolve(file.uri, dependency).toString();
          if (!resolved.startsWith(lib.uri.toString())) continue;
          final target = resolved.substring(lib.uri.toString().length);
          final presentation =
              source.contains('/presentation/') ||
              source.startsWith('shared/ui/') ||
              source.startsWith('design-system/');
          final infrastructure =
              source.startsWith('infrastructure/') ||
              source.contains('/infrastructure/');
          final forbidden =
              (target.startsWith('composition/') &&
                  source != 'main.dart' &&
                  !source.startsWith('composition/')) ||
              (presentation &&
                  (target.startsWith('infrastructure/') ||
                      target.contains('/infrastructure/') ||
                      target.startsWith('src/'))) ||
              (infrastructure &&
                  (target.contains('/presentation/') ||
                      target.startsWith('shared/ui/') ||
                      target.startsWith('design-system/'))) ||
              (source.startsWith('infrastructure/') &&
                  target.startsWith('features/')) ||
              (source.startsWith('shared/') &&
                  target.startsWith('infrastructure/'));
          if (forbidden) offenders.add('$source -> $target');
        }
      }
      expect(offenders, isEmpty);
    },
  );

  test(
    'scan includes conditional branches/parts and ignores comments/text',
    () {
      expect(
        dependencyUris('''
// import 'ignored.dart';
import 'pure.dart' if (dart.library.io) 'native.dart';
export 'a.dart' if (dart.library.html) 'b.dart' show X;
part 'generated.dart';
final example = "export 'also_ignored.dart';";
'''),
        <String>[
          'pure.dart',
          'native.dart',
          'a.dart',
          'b.dart',
          'generated.dart',
        ],
      );
      expect(dependencyUris("part of 'owner.dart';"), <String>['owner.dart']);
    },
  );
}
