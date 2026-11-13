import 'dart:io';

import 'package:test/test.dart';

import '../gate/import_boundary_rules.dart';
import '../gate/lib_layout_scan_helpers.dart';
import 'dart_dependency_graph.dart';
import 'outer_layer_dependency_policy.dart';

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
      expect(
        appLayerDependencyViolations(
          graph: graph,
          roots: files.map((file) => file.uri),
          appLib: lib.uri,
          allowsAppPath: allowsOuterLayerDependency,
        ),
        isEmpty,
      );
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

  test('native adapters belong to infrastructure and metadata UI does not open files', () {
    final offenders = <String>[];
    for (final file in files) {
      final source = libRelativePosixPath(lib, file);
      final infrastructure =
          source.startsWith('infrastructure/') ||
          source.contains('/infrastructure/');
      final metadataPresentation =
          source.startsWith('features/metadata_backup/presentation/') ||
          source.startsWith('features/comic_metadata/presentation/');
      for (final dependency in graph.directives(file.uri)) {
        if ((!infrastructure &&
                (dependency.startsWith('package:shared_preferences/') ||
                    dependency.startsWith('package:package_info_plus/') ||
                    dependency.startsWith('package:window_manager/') ||
                    dependency.startsWith('package:url_launcher/'))) ||
            (metadataPresentation && dependency == 'dart:io')) {
          offenders.add('$source -> $dependency');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
