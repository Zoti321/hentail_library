// One-shot: rewrite imports from shared/domain strangler shims to owner feature URIs.
// Usage: dart run tool/migrate_strangler_shim_imports.dart

import 'dart:io';

import 'package:path/path.dart' as p;

Future<void> main() async {
  final Directory appRoot = Directory.current;
  final File allowlist = File(p.join('test', 'gate', 'strangler_shims.txt'));
  if (!allowlist.existsSync()) {
    stderr.writeln('Run from app/');
    exit(1);
  }

  final Map<String, String> replacements = <String, String>{};
  for (final String line in allowlist.readAsLinesSync()) {
    final String trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final String posix = trimmed.replaceAll(r'\', '/');
    final File shim = File(p.join('lib', posix));
    if (!shim.existsSync()) {
      stderr.writeln('Missing shim: $posix');
      exit(2);
    }
    final RegExp exportRe = RegExp(
      r"^export 'package:hentai_library/([^']+)'\s*;\s*$",
    );
    String? target;
    for (final String shimLine in shim.readAsLinesSync()) {
      final Match? match = exportRe.firstMatch(shimLine.trim());
      if (match != null) {
        target = 'package:hentai_library/${match.group(1)!}';
        break;
      }
    }
    if (target == null) {
      stderr.writeln('No package export in $posix');
      exit(3);
    }
    final String oldUri = 'package:hentai_library/$posix';
    replacements[oldUri] = target;
  }

  final List<Directory> scanRoots = <Directory>[
    Directory(p.join('lib')),
    Directory(p.join('test')),
    Directory(p.join('widgetbook')),
  ];

  var filesChanged = 0;
  var totalReplacements = 0;

  for (final Directory root in scanRoots) {
    await for (final FileSystemEntity entity in root.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      var content = entity.readAsStringSync();
      var changed = false;
      for (final MapEntry<String, String> entry in replacements.entries) {
        if (content.contains(entry.key)) {
          final int count = entry.key.allMatches(content).length;
          content = content.replaceAll(entry.key, entry.value);
          totalReplacements += count;
          changed = true;
        }
      }
      if (changed) {
        entity.writeAsStringSync(content);
        filesChanged++;
      }
    }
  }

  stdout.writeln(
    'Replaced $totalReplacements occurrences across $filesChanged files '
    '(${replacements.length} shim URIs).',
  );
}
