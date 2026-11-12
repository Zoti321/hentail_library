import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:yaml/yaml.dart';

/// Includes every conditional branch and part; ignores comments/string contents.
List<String> dependencyUris(String code) {
  final unit = parseString(content: code, throwIfDiagnostics: false).unit;
  return <String>[
    for (final directive in unit.directives)
      ...switch (directive) {
        UriBasedDirective() => <String>[
          if (directive.uri.stringValue case final String value) value,
          if (directive is NamespaceDirective)
            for (final config in directive.configurations)
              if (config.uri.stringValue case final String value) value,
        ],
        PartOfDirective(uri: final uri?) => <String>[
          if (uri.stringValue case final String value) value,
        ],
        _ => <String>[],
      },
  ];
}

class DartDependencyGraph {
  DartDependencyGraph({required this.packages, required this.packageRoots});

  factory DartDependencyGraph.current() {
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config = jsonDecode(configFile.readAsStringSync()) as Map;
    final packages = <String, Uri>{};
    final roots = <String, Uri>{};
    for (final entry in config['packages'] as List) {
      final rootUri = entry['rootUri'] as String;
      final root = configFile.uri.resolve(
        rootUri.endsWith('/') ? rootUri : '$rootUri/',
      );
      final name = entry['name'] as String;
      roots[name] = root;
      packages[name] = root.resolve(entry['packageUri'] as String? ?? 'lib/');
    }
    return DartDependencyGraph(packages: packages, packageRoots: roots);
  }

  final Map<String, Uri> packages;
  final Map<String, Uri> packageRoots;
  final Map<Uri, List<String>> _directives = <Uri, List<String>>{};
  final Map<String, Set<String>> _runtimeDependencies = <String, Set<String>>{};

  Uri resolve(Uri source, String dependency) {
    final uri = Uri.parse(dependency);
    if (uri.scheme == 'package') {
      final parts = uri.pathSegments;
      final base = packages[parts.first];
      if (base == null) {
        throw StateError('Unresolved package: $dependency');
      }
      return base.resolve(parts.skip(1).join('/'));
    }
    return source.resolveUri(uri);
  }

  List<String> directives(Uri source) => _directives.putIfAbsent(source, () {
    final file = File.fromUri(source);
    if (!file.existsSync()) {
      throw StateError('Unresolved Dart library: $source');
    }
    return dependencyUris(file.readAsStringSync());
  });

  Iterable<Uri> packageFiles(String package) =>
      Directory.fromUri(packages[package]!)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.uri);

  Set<String> runtimeDependencies(String package) =>
      _runtimeDependencies.putIfAbsent(package, () {
        final root = packageRoots[package];
        if (root == null) {
          throw StateError('Unresolved package: $package');
        }
        final manifest = loadYaml(
          File.fromUri(root.resolve('pubspec.yaml')).readAsStringSync(),
        ) as YamlMap;
        final dependencies = manifest['dependencies'] as YamlMap?;
        return <String>{
          if (dependencies != null)
            for (final name in dependencies.keys) name as String,
          if (manifest['flutter'] != null) 'flutter',
        };
      });
}

const Set<String> pureDartLibraries = <String>{
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:core',
  'dart:isolate',
  'dart:math',
  'dart:typed_data',
};

/// Evaluate local policy at every hop. Check package manifests recursively as
/// well as reachable source libraries; package names alone establish no trust.
Set<String> pureDependencyViolations({
  required DartDependencyGraph graph,
  required Iterable<Uri> roots,
  required Uri appLib,
  required bool Function(String path) allowsAppPath,
}) {
  final violations = <String>{};
  final visitedFiles = <Uri>{};
  final visitedPackages = <String>{};
  late void Function(Uri file, String chain) visit;

  void package(String name, String chain) {
    if (!visitedPackages.add(name)) return;
    if (name == 'flutter' || name == 'flutter_test' || name == 'sky_engine') {
      violations.add('$chain -> declared package:$name');
      return;
    }
    for (final dependency in graph.runtimeDependencies(name)) {
      package(dependency, '$chain -> declared package:$name');
    }
    for (final file in graph.packageFiles(name)) {
      visit(file, '$chain -> package:$name/${file.pathSegments.last}');
    }
  }

  visit = (Uri file, String chain) {
    if (!visitedFiles.add(file)) return;
    for (final dependency in graph.directives(file)) {
      final uri = Uri.parse(dependency);
      if (uri.scheme == 'dart') {
        if (!pureDartLibraries.contains(dependency)) {
          violations.add('$chain -> $dependency');
        }
        continue;
      }
      if (uri.scheme == 'package' &&
          uri.pathSegments.first != 'hentai_library') {
        final name = uri.pathSegments.first;
        package(name, '$chain -> $dependency');
        if (<String>{'flutter', 'flutter_test', 'sky_engine'}.contains(name)) {
          continue;
        }
      }
      final target = graph.resolve(file, dependency);
      if (target.scheme != 'file') {
        violations.add('$chain -> $dependency');
        continue;
      }
      final appPath = target.toString().startsWith(appLib.toString())
          ? target.toString().substring(appLib.toString().length)
          : null;
      if (appPath == null) {
        final owners = graph.packages.entries.where(
          (entry) => target.toString().startsWith(entry.value.toString()),
        );
        if (owners.isEmpty) {
          violations.add(
            '$chain -> file outside lib and resolved packages: $target',
          );
          continue;
        }
        // Relative imports into a package must not bypass its runtime manifest.
        package(owners.first.key, '$chain -> $dependency');
      }
      if (appPath != null && !allowsAppPath(appPath)) {
        violations.add('$chain -> $appPath');
        continue;
      }
      visit(target, '$chain -> ${appPath ?? dependency}');
    }
  };

  for (final root in roots) {
    visit(root, root.toString().substring(appLib.toString().length));
  }
  return violations;
}
