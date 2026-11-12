import 'package:test/test.dart';

import 'dart_dependency_graph.dart';

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
  List<String> directives(Uri source) => dependencyUris(sources[source]!);

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
