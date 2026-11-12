import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../gate/lib_layout_scan_helpers.dart';

final RegExp _export = RegExp(
  r'''^\s*export\s+['"]([^'"]+)['"]([^;]*);''',
  multiLine: true,
);
final RegExp _factory = RegExp(
  r'^\w[^\n;]*?\b(create[A-Z]\w+|\w+Overrides)\s*\(',
  multiLine: true,
);

void main() {
  final Directory lib = Directory('lib');

  test('module entry points expose contracts, providers and widgets', () {
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(Directory('lib/features'))) {
      final String path = libRelativePosixPath(lib, file);
      if (p.posix.basename(path) != 'public.dart' ||
          p.posix.split(path).length != 3) {
        continue;
      }
      final List<Match> exports = _export
          .allMatches(file.readAsStringSync())
          .toList();
      expect(exports, isNotEmpty, reason: path);
      for (final Match match in exports) {
        if (!<String>{
          'public/contracts.dart',
          'public/providers.dart',
          'public/widgets.dart',
        }.contains(match.group(1))) {
          offenders.add('$path -> ${match.group(1)}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test(
    'general interfaces never export infrastructure, composition or factories',
    () {
      final Set<String> offenders = <String>{};
      final Set<String> visited = <String>{};

      void visit(String source) {
        if (!visited.add(source)) {
          return;
        }
        final File file = File(p.join(lib.path, source));
        if (!file.existsSync()) {
          return;
        }
        final String code = file.readAsStringSync();
        for (final Match match in _factory.allMatches(code)) {
          offenders.add('$source exports ${match.group(1)}');
        }
        for (final Match match in _export.allMatches(code)) {
          final String? target = _resolve(source, match.group(1)!);
          if (target == null) {
            continue;
          }
          final List<String> parts = p.posix.split(target);
          if (parts.contains('composition') ||
              parts.contains('infrastructure') ||
              parts.contains('data')) {
            offenders.add('$source -> $target');
          } else {
            visit(target);
          }
        }
      }

      for (final Directory module in Directory(
        'lib/features',
      ).listSync().whereType<Directory>()) {
        final File entry = File(p.join(module.path, 'public.dart'));
        if (entry.existsSync()) {
          visit(libRelativePosixPath(lib, entry));
        }
      }
      expect(offenders.toList()..sort(), isEmpty);
    },
  );

  test('canonical presentation facets export explicit symbols', () {
    final List<String> offenders = <String>[];
    for (final File file in dartFilesUnder(Directory('lib/features'))) {
      final String source = libRelativePosixPath(lib, file);
      if (!source.endsWith('/public/providers.dart') &&
          !source.endsWith('/public/widgets.dart')) {
        continue;
      }
      for (final Match match in _export.allMatches(file.readAsStringSync())) {
        final String? target = _resolve(source, match.group(1)!);
        final String module = p.posix.split(source)[1];
        if (target == null ||
            !target.startsWith('features/$module/presentation/')) {
          continue;
        }
        final String tail = match.group(2)!.trim();
        if (!tail.startsWith('show ')) {
          offenders.add('$source must explicitly select symbols from $target');
        } else if (source.endsWith('/public/providers.dart')) {
          final List<String> names = tail
              .substring(5)
              .split(',')
              .map((name) => name.trim())
              .toList();
          if (names.any((name) => !name.endsWith('Provider'))) {
            offenders.add('$source exports non-provider symbols from $target');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('legacy di/data source buckets cannot return', () {
    final List<String> offenders = dartFilesUnder(lib)
        .map((file) => libRelativePosixPath(lib, file))
        .where(
          (path) =>
              p.posix.split(path).any((part) => part == 'di' || part == 'data'),
        )
        .toList();
    expect(offenders, isEmpty);
  });

  test(
    'shared contains only domain, application, presentation adapters and UI',
    () {
      final List<String> offenders = <String>[];
      for (final File file in dartFilesUnder(Directory('lib/shared'))) {
        final String path = libRelativePosixPath(lib, file);
        if (!path.startsWith('shared/domain/') &&
            !path.startsWith('shared/application/') &&
            !path.startsWith('shared/presentation/providers/') &&
            !path.startsWith('shared/ui/')) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty);
    },
  );

  test(
    'public files declare exports, with implementation in its owning layer',
    () {
      final List<String> offenders = <String>[];
      for (final File file in dartFilesUnder(Directory('lib/features'))) {
        final String source = libRelativePosixPath(lib, file);
        if (!p.posix.split(source).contains('public')) {
          continue;
        }
        final String remaining = file
            .readAsStringSync()
            .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '')
            .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
            .replaceAll(_export, '')
            .replaceAll(RegExp(r'\blibrary\s*[^;]*;'), '')
            .trim();
        if (remaining.isNotEmpty) {
          offenders.add(source);
        }
      }
      expect(offenders, isEmpty);
    },
  );

  test('every required provider is bound in composition', () {
    final RegExp required = RegExp(
      r'''required(?:Future)?Provider(?:Family)?\(\s*['"]([^'"]+)['"]''',
    );
    final RegExp override = RegExp(
      r'(\w+Provider)\s*\.\s*overrideWith(?:Value)?\s*\(',
    );
    final Set<String> declared = <String>{};
    final Set<String> bound = <String>{};
    for (final File file in dartFilesUnder(lib)) {
      final String source = libRelativePosixPath(lib, file);
      final String code = file.readAsStringSync();
      declared.addAll(
        required.allMatches(code).map((match) => match.group(1)!),
      );
      if (source.startsWith('composition/')) {
        bound.addAll(override.allMatches(code).map((match) => match.group(1)!));
      }
    }
    expect(declared, isNotEmpty);
    expect(declared.difference(bound).toList()..sort(), isEmpty);
  });
}

String? _resolve(String source, String uri) {
  const String prefix = 'package:hentai_library/';
  if (uri.startsWith(prefix)) {
    return uri.substring(prefix.length);
  }
  return uri.contains(':')
      ? null
      : p.posix.normalize(p.posix.join(p.posix.dirname(source), uri));
}
