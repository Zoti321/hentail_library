import 'package:test/test.dart';

import 'dart_dependency_graph.dart';
import 'outer_layer_dependency_policy.dart';

final _app = Uri.parse('file:///fixture/lib/');
final _core = _app.resolve('core/value.dart');

class _FixtureGraph extends DartDependencyGraph {
  _FixtureGraph(
    this.sources, {
    this.declarations = const <String, Set<String>>{},
  }) : super(
         packages: <String, Uri>{
           'helper': Uri.parse('file:///helper/lib/'),
           'plugin': Uri.parse('file:///plugin/lib/'),
         },
         packageRoots: <String, Uri>{},
       );

  final Map<Uri, String> sources;
  final Map<String, Set<String>> declarations;

  @override
  List<String> directives(Uri source) {
    final code = sources[source];
    if (code == null) throw StateError('Unresolved Dart library: $source');
    return dependencyUris(code);
  }

  @override
  Set<String> runtimeDependencies(String package) =>
      declarations[package] ?? <String>{};

  @override
  Iterable<Uri> packageFiles(String package) => sources.keys.where(
    (uri) => uri.toString().startsWith(packages[package].toString()),
  );
}

Set<String> _violations(_FixtureGraph graph) => pureDependencyViolations(
  graph: graph,
  roots: <Uri>[_core],
  appLib: _app,
  allowsAppPath: (path) => path.startsWith('core/'),
);

void main() {
  group('outer-layer application graph', () {
    Set<String> check(Map<String, String> sources, String root) {
      final graph = _FixtureGraph({
        for (final entry in sources.entries)
          _app.resolve(entry.key): entry.value,
      });
      graph.packages['hentai_library'] = _app;
      return appLayerDependencyViolations(
        graph: graph,
        roots: [_app.resolve(root)],
        appLib: _app,
        allowsAppPath: allowsOuterLayerDependency,
      );
    }

    test('rejects infrastructure reaching UI through a public barrel', () {
      final violations = check({
        'features/a/infrastructure/repository.dart':
            "import 'package:hentai_library/features/b/public.dart';",
        'features/b/public.dart': "export 'presentation/view.dart';",
      }, 'features/a/infrastructure/repository.dart');
      expect(
        violations.single,
        'features/a/infrastructure/repository.dart -> features/b/public.dart -> features/b/presentation/view.dart',
      );
    });

    test('follows private helper imports as well as conditional exports', () {
      final violations = check({
        'features/a/presentation/view.dart': "import '../helper.dart';",
        'features/a/helper.dart':
            "export 'pure.dart' if (dart.library.io) 'infrastructure/io.dart';",
        'features/a/pure.dart': '',
      }, 'features/a/presentation/view.dart');
      expect(
        violations.single,
        endsWith('features/a/helper.dart -> features/a/infrastructure/io.dart'),
      );
    });

    test('part and part-of directives cannot cross layer boundaries', () {
      final violations = check({
        'features/a/infrastructure/repository.dart':
            "part '../presentation/body.dart';",
      }, 'features/a/infrastructure/repository.dart');
      expect(
        violations.single,
        endsWith(' -> features/a/presentation/body.dart'),
      );
      expect(
        check({
          'features/a/presentation/body.dart':
              "part of '../../../composition/owner.dart';",
        }, 'features/a/presentation/body.dart').single,
        endsWith(' -> composition/owner.dart'),
      );
    });

    test('each root keeps its own policy when sharing cached dependencies', () {
      final graph = _FixtureGraph({
        _app.resolve('composition/assembly.dart'):
            "import '../features/a/helper.dart';",
        _app.resolve('features/a/infrastructure/repository.dart'):
            "import '../helper.dart';",
        _app.resolve('features/a/helper.dart'):
            "export 'presentation/view.dart';",
        _app.resolve('features/a/presentation/view.dart'): '',
      });
      final violations = appLayerDependencyViolations(
        graph: graph,
        roots: [
          _app.resolve('composition/assembly.dart'),
          _app.resolve('features/a/infrastructure/repository.dart'),
        ],
        appLib: _app,
        allowsAppPath: allowsOuterLayerDependency,
      );
      expect(
        violations.single,
        'features/a/infrastructure/repository.dart -> features/a/helper.dart -> features/a/presentation/view.dart',
      );
    });

    test(
      'shared bridges cannot give top-level infrastructure product knowledge',
      () {
        final violations = check({
          'infrastructure/technical.dart': "import '../shared/helper.dart';",
          'shared/helper.dart': "export '../features/a/domain/entity.dart';",
        }, 'infrastructure/technical.dart');
        expect(
          violations.single,
          contains('shared/helper.dart -> features/a/domain/entity.dart'),
        );
      },
    );

    test('allows composition assembly and pure export cycles', () {
      expect(
        check({
          'composition/assembly.dart': "import '../features/a/infrastructure/repository.dart'; import '../features/a/presentation/view.dart';",
          'features/a/infrastructure/repository.dart':
              "import '../domain/entity.dart';",
          'features/a/presentation/view.dart':
              "import '../domain/entity.dart';",
          'features/a/domain/entity.dart': "export 'entity.dart';",
        }, 'composition/assembly.dart'),
        isEmpty,
      );
      expect(
        check({
          'features/a/presentation/view.dart':
              "import '../domain/entity.dart';",
          'features/a/domain/entity.dart': "export 'entity.dart';",
        }, 'features/a/presentation/view.dart'),
        isEmpty,
      );
    });

    test('missing app libraries fail and escaped files are rejected', () {
      expect(
        () => check({
          'features/a/presentation/view.dart': "import '../missing.dart';",
        }, 'features/a/presentation/view.dart'),
        throwsStateError,
      );
      expect(
        check({
          'features/a/presentation/view.dart':
              "import '../../../../test/helper.dart';",
        }, 'features/a/presentation/view.dart').single,
        contains('outside app lib'),
      );
    });
  });

  test('rejects a relative import escaping the app lib boundary', () {
    final violations = _violations(
      _FixtureGraph(<Uri, String>{_core: "export '../../test/product.dart';"}),
    );
    expect(
      violations.single,
      contains('file outside lib and resolved packages'),
    );
  });
  test('rejects an upper layer reached through a relative barrel', () {
    final bridge = _app.resolve('core/bridge.dart');
    final violations = _violations(
      _FixtureGraph(<Uri, String>{
        _core: "export 'bridge.dart';",
        bridge: "export '../shared/domain/entity.dart';",
      }),
    );
    expect(
      violations.single,
      contains(
        'core/value.dart -> core/bridge.dart -> shared/domain/entity.dart',
      ),
    );
  });

  test('checks the inactive conditional import branch of a third party', () {
    final helper = Uri.parse('file:///helper/lib/helper.dart');
    final io = helper.resolve('native.dart');
    final violations = _violations(
      _FixtureGraph(<Uri, String>{
        _core: "import 'package:helper/helper.dart';",
        helper: "export 'pure.dart' if (dart.library.io) 'native.dart';",
        helper.resolve('pure.dart'): 'class Value {}',
        io: "import 'dart:io';",
      }),
    );
    expect(violations.any((v) => v.endsWith('dart:io')), isTrue);
  });

  test(
    'rejects a declared transitive Flutter dependency even without imports',
    () {
      final helper = Uri.parse('file:///helper/lib/helper.dart');
      final violations = _violations(
        _FixtureGraph(
          <Uri, String>{
            _core: "import 'package:helper/helper.dart';",
            helper: 'class Value {}',
          },
          declarations: <String, Set<String>>{
            'helper': <String>{'plugin'},
            'plugin': <String>{'flutter'},
          },
        ),
      );
      expect(violations.single, contains('declared package:flutter'));
    },
  );

  test(
    'checks source files of declared dependencies absent from entry exports',
    () {
      final helper = Uri.parse('file:///helper/lib/helper.dart');
      final plugin = Uri.parse('file:///plugin/lib/native.dart');
      final violations = _violations(
        _FixtureGraph(
          <Uri, String>{
            _core: "import 'package:helper/helper.dart';",
            helper: 'class Value {}',
            plugin: "import 'dart:io';",
          },
          declarations: <String, Set<String>>{
            'helper': <String>{'plugin'},
          },
        ),
      );
      expect(violations.single, endsWith('dart:io'));
    },
  );

  test(
    'accepts pure transitive libraries and terminates relative export cycles',
    () {
      final helper = Uri.parse('file:///helper/lib/helper.dart');
      final violations = _violations(
        _FixtureGraph(<Uri, String>{
          _core: "import 'package:helper/helper.dart'; export 'value.dart';",
          helper: "import 'dart:collection'; export 'helper.dart';",
        }),
      );
      expect(violations, isEmpty);
    },
  );
}
