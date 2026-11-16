import 'package:test/test.dart';

import '../architecture/dart_dependency_graph.dart';

final _app = Uri.parse('file:///fixture/lib/');
final _layer = _app.resolve('design-system/');
final _entry = _layer.resolve('design_system.dart');
final _skin = Uri.parse('file:///skin/lib/skin.dart');

class _UiGraph extends DartDependencyGraph {
  _UiGraph(this.sources, {this.declarations = const {}})
    : super(
        packages: {
          'hentai_library': _app,
          'skin': Uri.parse('file:///skin/lib/'),
          'adapter': Uri.parse('file:///adapter/lib/'),
        },
        packageRoots: {},
      );
  final Map<Uri, String> sources;
  final Map<String, Set<String>> declarations;

  @override
  List<String> directives(Uri source) =>
      dependencyUris(sources[source] ?? (throw StateError('Missing $source')));
  @override
  Set<String> runtimeDependencies(String package) =>
      declarations[package] ?? {};
  @override
  Iterable<Uri> packageFiles(String package) => sources.keys.where(
    (uri) => uri.toString().startsWith(packages[package].toString()),
  );
}

Set<String> _scan(_UiGraph graph) => portableUiDependencyViolations(
  graph: graph,
  roots: [_entry],
  appLib: _app,
  layer: _layer,
  uiPackages: {'skin', 'adapter'},
);

void main() {
  test(
    'relative package URI resolution clamps at the package library root',
    () {
      final graph = _UiGraph({});
      expect(
        graph.resolve(
          Uri.parse('file:///skin/lib/components/button.dart'),
          '../../tokens.dart',
        ),
        Uri.parse('file:///skin/lib/tokens.dart'),
      );
    },
  );
  test('accepts a self-contained UI surface with Flutter and local state', () {
    expect(
      _scan(
        _UiGraph({
          _entry: "export 'control.dart';",
          _layer.resolve('control.dart'):
              "import 'package:flutter/widgets.dart';",
        }),
      ),
      isEmpty,
    );
  });
  for (final dependency in [
    '../l10n/app_localizations.dart',
    '../core/helper.dart',
    '../shared/domain/entity.dart',
    '../composition/wiring.dart',
  ]) {
    test('rejects application dependency through barrel: $dependency', () {
      expect(
        _scan(
          _UiGraph({
            _entry: "export 'bridge.dart';",
            _layer.resolve('bridge.dart'): "export '$dependency';",
          }),
        ),
        isNotEmpty,
      );
    });
  }
  test('checks conditional imports/exports and part chains', () {
    final part = _layer.resolve('part.dart');
    expect(
      _scan(
        _UiGraph({
          _entry: "import 'safe.dart' if (dart.library.io) 'bridge.dart'; part 'part.dart';",
          _layer.resolve('safe.dart'): '',
          _layer.resolve('bridge.dart'):
              "export 'package:window_manager/window_manager.dart';",
          part: "part of '../shared/product.dart';",
        }),
      ),
      hasLength(2),
    );
  });
  test(
    'checks all runtime declarations, including unused hidden state dependency',
    () {
      expect(
        _scan(
          _UiGraph(
            {_entry: "import 'package:skin/skin.dart';", _skin: ''},
            declarations: {
              'skin': {'adapter'},
              'adapter': {'riverpod'},
            },
          ),
        ).single,
        contains('non-UI package:riverpod'),
      );
    },
  );
  test('third party source cannot hide application coupling', () {
    expect(
      _scan(
        _UiGraph({
          _entry: "import 'package:skin/skin.dart';",
          _skin: "export 'package:hentai_library/l10n/app_localizations.dart';",
        }),
      ).single,
      contains('application file'),
    );
  });
  test('relative escape cannot bypass runtime manifest policy', () {
    expect(
      _scan(_UiGraph({_entry: "import '../../outside.dart';"})).single,
      contains('outside resolved packages'),
    );
  });
  test('missing sources fail closed', () {
    expect(
      () => _scan(_UiGraph({_entry: "export 'missing.dart';"})),
      throwsStateError,
    );
  });
  test('process and window SDK implementations cannot enter a control', () {
    expect(
      _scan(_UiGraph({_entry: "import 'dart:io';"})).single,
      contains('platform SDK:dart:io'),
    );
  });
}
